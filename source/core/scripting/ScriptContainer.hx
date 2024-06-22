package core.scripting;

#if ENGINE_SCRIPTING
/**
 * Script colletion which can contain scripts and manage them.
 */
class ScriptContainer implements IFlxDestroyable {
    /**
     * Parent object for all scripts.
     */
    public var parent:Dynamic;

    /**
     * Internal map containing variables assigned with `set`, so that scripts added later still get these variables assigned.
     */
    var _imports:Map<String, Dynamic> = [];

    /**
     * Internal array containing all of the scripts.
     */
    var _scripts:Array<Script> = [];

    /**
     * Creates a new `ScriptContainer`.
     * @param parent Parent object for all scripts.
     */
    public function new(?parent:Dynamic):Void {
        this.parent = parent;
    }

    /**
     * Loads all scripts from the specified directory.
     * @param path Directory to scan.
     * @param global Whether to check for scripts in all asset trees.
     */
    public function loadScripts(path:String, global:Bool = false):Void {
        #if ENGINE_RUNTIME_ASSETS
        if (global) {
            var directories:Array<String> = Assets.listFiles((structure) -> {
                var path:String = structure.getPath('${path}/', NONE);
                structure.entryExists(path) ? path : null;
            });
    
            for (directory in directories)
                _loadScripts(directory);

            return;
        }
        #end

        var realPath:String = Assets.getPath('${path}/', NONE);
        if (!FileTools.exists(realPath) || !FileTools.isDirectory(realPath)) return;
        _loadScripts(realPath);
    }

    /**
     * Loads a script, automatically adds it to this script container and returns it.
     * @param path Path of the script to load.
     */
    public function load(path:String):Script {
        var script:Script = Script.load(path);
        if (!script.alive) return null;
        return add(script);
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
                    load(fullPath);
            }
        }
    }

    /**
     * Adds a script to this script container and returns it.
     * @param script Script to add to this container.
     */
    public function add(script:Script):Script {
        script.parent = this;
        script.object = parent;

        for (i in _imports.keys())
            script.set(i, _imports.get(i));

        _scripts.push(script);
        return script;
    }

    /**
     * Removes a script from this container.
     * @param script Script to remove from this container.
     * @return `true` if the script was contained and got removed, `false` otherwise
     */
    public function remove(script:Script):Bool {
        return _scripts.remove(script);
    }

    /**
     * Sets a variable to apply on all scripts and returns it.
     * @param key The variable's name.
     * @param v The variable's value.
     */
    public function set(key:String, v:Dynamic):Dynamic {
        for (i in _scripts)
            i.set(key, v);

        _imports.set(key, v);
        return v;
    }

    /**
     * Call a method on all scripts of this container and returns the output.
     * @param method Method to call.
     * @param arguments Optional arguments to pass.
     */
    public function call(method:String, ?arguments:Array<Dynamic>):Dynamic {
        if (_scripts == null || _scripts.length == 0)
            return null;

        var output:Dynamic = null;

        for (i in _scripts) {
            var call:Dynamic = i.call(method, arguments);
            if (call != null) output = call;
        }

        return output;
    }

    /**
     * Dispatch an event on all scripts of this container and returns it.
     * @param method Method to call.
     * @param event Event to dispatch.
     * @param put Whether to put the event after it's dispatchement.
     */
    public function dispatchEvent<T:ScriptEvent>(method:String, event:T, put:Bool = true):T {
        for (script in _scripts) {
            script.call(method, [event]);

            if (!event.propagate)
                break;
        }

        if (put)
            event.put();

        return event;
    }

    /**
     * Dispatches a basic event, useful for simple cancellable calls.
     * @param method Method to call.
     * @return Event
     */
    public inline function quickEvent(method:String):ScriptEvent {
        return dispatchEvent(method, Events.get(ScriptEvent));
    }

    /**
     * Destroys and removes any contained scripts.
     */
    public function clear():Void {
        while (_scripts.length > 0)
            _scripts[0].destroy();
    }

    /**
     * Clean up memory.
     */
    public function destroy():Void {
        clear();
        _scripts = null;
        _imports = null;
        parent = null;
    }
}
#end
