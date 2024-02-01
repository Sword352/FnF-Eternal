package eternal.core.scripting;

class ScriptPack {
    public var scripts:Array<HScript> = [];
    public var imports:Map<String, Dynamic> = [];

    public var parent:Dynamic = null;

    public function new(?parent:Dynamic):Void {
        this.parent = parent;
    }

    public function loadScriptsFrom(path:String):Void {
        var realPath:String = Assets.getPath('${path}/', NONE);
        if (!FileTools.exists(realPath))
            return;

        var exts:Array<String> = SCRIPT.getExtensions();
        for (file in FileTools.readDirectory(realPath)) {
            for (ext in exts) {
                if (!file.endsWith(ext))
                    continue;
                loadScript(realPath + file);
            }
        }
    }

    public function loadScript(path:String):HScript {
        var script:HScript = new HScript(path);
        if (script.state != ALIVE)
            return null;

        return addScript(script);
    }

    public function addScript(script:HScript):HScript {
        script.parent = this;
        script.object = parent;

        for (i in imports.keys())
            script.set(i, imports.get(i));

        scripts.push(script);
        return script;
    }

    public function hxsSet(key:String, obj:Dynamic):Void {
        for (i in scripts)
            i.set(key, obj);
        imports.set(key, obj);
    }

    public function hxsCall(funcToCall:String, ?args:Array<Dynamic>):Dynamic {
        if (scripts == null || scripts.length < 1)
            return null;

        var returnValue:Dynamic = null;
        for (i in scripts) {
            var call:Dynamic = i.call(funcToCall, args);
            if (call != null) // avoid conflicts with voids (they would most likely return null)
                returnValue = call;
        }

        return returnValue;
    }

    public function cancellableCall(funcToCall:String, ?args:Array<Dynamic>):Bool {
        var ret:Dynamic = hxsCall(funcToCall, args);
        return ret != null && ret is Bool && cast(ret, Bool) == false;
    }

    public function destroy():Void {
        while (scripts.length > 0)
            scripts[0].destroy();

        scripts = null;
        imports = null;
        parent = null;
    }
}