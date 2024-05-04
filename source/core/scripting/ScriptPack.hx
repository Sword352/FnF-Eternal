package core.scripting;

class ScriptPack {
    public var scripts:Array<HScript> = [];
    public var imports:Map<String, Dynamic> = [];
    public var parent:Dynamic = null;

    var canceller:CancellableCall = new CancellableCall();

    public function new(?parent:Dynamic):Void {
        this.parent = parent;
    }

    public function loadScriptsFrom(path:String):Void {
        var realPath:String = Assets.getPath('${path}/', NONE);
        if (!FileTools.exists(realPath) || !FileTools.isDirectory(realPath)) return;

        var exts:Array<String> = SCRIPT.getExtensions();

        for (entry in FileTools.readDirectory(realPath)) {
            var fullPath:String = realPath + entry;

            if (FileTools.isDirectory(fullPath)) {
                loadScriptsFrom(path + "/" + entry);
                continue;
            }

            for (ext in exts) {
                if (entry.endsWith(ext))
                    loadScript(fullPath);
            }
        }
    }

    public function loadScript(path:String):HScript {
        var script:HScript = new HScript(path);
        if (!script.alive) return null;
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

        // TODO: better way, this should do it for now
        script.set("callFlag", canceller);
        //
        
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
            if (call != null) returnValue = call;
        }

        return returnValue;
    }

    public function cancellableCall(func:String, ?args:Array<Dynamic>):Bool {
        if (scripts == null || scripts.length == 0) return false;

        canceller.cancelled = false;
        hxsCall(func, args);

        return canceller.cancelled;
    }

    public function destroy():Void {
        while (scripts.length > 0)
            scripts[0].destroy();

        canceller = null;
        scripts = null;
        imports = null;
        parent = null;
    }
}
