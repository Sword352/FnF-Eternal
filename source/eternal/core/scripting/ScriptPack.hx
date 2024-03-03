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

        script.set("loadScriptsFrom", loadScriptsFrom);
        script.set("loadScript", loadScript);
        script.set("addScript", addScript);

        script.set("cancellableCall", cancellableCall);
        script.set("hxsCall", hxsCall);
        script.set("hxsSet", hxsSet);

        scripts.push(script);
        return script;
    }

    public function hxsSet(key:String, obj:Dynamic):Void {
        for (i in scripts)
            i.set(key, obj);
        imports.set(key, obj);
    }

    public function hxsCall(func:String, ?args:Array<Dynamic>):Dynamic {
        if (scripts == null || scripts.length == 0) return null;

        var returnValue:Dynamic = null;
        for (i in scripts) {
            var call:Dynamic = i.call(func, args);
            if (call != null) // avoid conflicts with voids (they would most likely return null)
                returnValue = call;
        }

        return returnValue;
    }

    public function cancellableCall(func:String, ?args:Array<Dynamic>):Bool {
        if (scripts == null || scripts.length == 0) return false;

        var call:CancellableCall = new CancellableCall();

        if (args == null) args = [];
        args.push(call);

        var ret:Dynamic = hxsCall(func, args);

        // backward compatibility with the old method, cancel the call if the output is false
        if (ret != null && ret is Bool)
            call.cancelled = (cast(ret, Bool) == false);

        return call.cancelled;
    }

    public function destroy():Void {
        while (scripts.length > 0)
            scripts[0].destroy();

        scripts = null;
        imports = null;
        parent = null;
    }
}
