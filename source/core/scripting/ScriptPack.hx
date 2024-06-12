package core.scripting;

#if ENGINE_SCRIPTING
class ScriptPack {
    public var scripts:Array<Script> = [];
    public var imports:Map<String, Dynamic> = [];
    public var parent:Dynamic = null;

    var canceller:CancellableCall = new CancellableCall();

    public function new(?parent:Dynamic):Void {
        this.parent = parent;
    }

    public function loadScriptsFrom(path:String):Void {
        var realPath:String = Assets.getPath('${path}/', NONE);
        if (!FileTools.exists(realPath) || !FileTools.isDirectory(realPath)) return;
        _loadScripts(realPath);
    }

    public function loadScriptsGlobally(path:String):Void {
        #if ENGINE_RUNTIME_ASSETS
        var directories:Array<String> = Assets.listFiles((structure) -> {
            var path:String = structure.getPath('${path}/', NONE);
            structure.entryExists(path) ? path : null;
        });

        for (directory in directories)
            _loadScripts(directory);
        #else
        loadScriptsFrom(path);
        #end
    }

    public function loadScript(path:String):Script {
        var script:Script = Script.load(path);
        if (!script.alive) return null;
        return addScript(script);
    }

    function _loadScripts(path:String):Void {
        var exts:Array<String> = SCRIPT.getExtensions();

        for (entry in FileTools.readDirectory(path)) {
            var fullPath:String = path + entry;

            if (FileTools.isDirectory(fullPath)) {
                _loadScripts(fullPath + "/");
                continue;
            }

            for (ext in exts) {
                if (entry.endsWith(ext))
                    loadScript(fullPath);
            }
        }
    }

    public function addScript(script:Script):Script {
        script.parent = this;
        script.object = parent;

        for (i in imports.keys())
            script.set(i, imports.get(i));

        script.set("loadScriptsFrom", loadScriptsFrom);
        script.set("loadScript", loadScript);
        script.set("addScript", addScript);

        script.set("cancellableCall", cancellableCall);
        script.set("hxsCall", call);

        // TODO: better way, this should do it for now
        script.set("callFlag", canceller);
        //
        
        script.set("hxsSet", set);

        scripts.push(script);
        return script;
    }

    public function set(key:String, obj:Dynamic):Void {
        for (i in scripts)
            i.set(key, obj);
        imports.set(key, obj);
    }

    public function call(func:String, ?args:Array<Dynamic>):Dynamic {
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
        call(func, args);

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
#end
