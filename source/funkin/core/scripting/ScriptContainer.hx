package funkin.core.scripting;

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
     * @param global Whether to check for scripts in all asset sources.
     */
    public function loadScripts(path:String, global:Bool = false):Void {
        if (!global) {
            var realPath:String = path + "/";
            var source:IAssetSource = Assets.getSourceFromPath(realPath, NONE);

            if (source != null)
                _loadScripts(realPath, source);
        }
        else {
            Assets.invoke((source) ->  {
                if (source.exists(path + "/"))
                    _loadScripts(path + "/", source);
            });
        }
    }

    /**
     * Loads a script, automatically adds it to this script container and returns it.
     * @param path Path of the script to load.
     */
    public function load(path:String):Script {
        var content:String = Paths.script(path);
        if (content == null) return null;

        var script:Script = Script.load(content, path);
        if (!script.alive) return null;
        return add(script);
    }

    function _loadScripts(path:String, source:IAssetSource):Void {
        var extensions:Array<String> = SCRIPT.getExtensions();

        for (script in source.readDirectory(path)) {
            var srcPath:String = path + script;

            if (source.isDirectory(srcPath)) {
                _loadScripts(srcPath + "/", source);
                continue;
            }

            for (extension in extensions) {
                if (!script.endsWith(extension))
                    continue;

                var content:String = source.getContent(srcPath);
                var instance:Script = Script.load(content, srcPath);

                if (instance.alive)
                    add(instance);
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
     * Calls a method on every scripts and returns the output.
     * @param method Method to call.
     */
    public inline extern overload function call(method:String):Dynamic {
        if (_scripts == null || _scripts.length == 0)
            return null;

        var output:Dynamic = null;

        for (i in _scripts) {
            var call:Dynamic = i.call(method);
            if (call != null) output = call;
        }

        return output;
    }

    /**
     * Calls a method on every scripts and returns the output.
     * @param method Method to call.
     * @param v1 Optional argument.
     */
    public inline extern overload function call(method:String, v1:Dynamic):Dynamic {
        if (_scripts == null || _scripts.length == 0)
            return null;

        var output:Dynamic = null;

        for (i in _scripts) {
            var call:Dynamic = i.call(method, v1);
            if (call != null) output = call;
        }

        return output;
    }

    /**
     * Calls a method on every scripts and returns the output.
     * @param method Method to call.
     * @param v1 Optional argument.
     * @param v2 Optional argument.
     */
    public inline extern overload function call(method:String, v1:Dynamic, v2:Dynamic):Dynamic {
        if (_scripts == null || _scripts.length == 0)
            return null;

        var output:Dynamic = null;

        for (i in _scripts) {
            var call:Dynamic = i.call(method, v1, v2);
            if (call != null) output = call;
        }

        return output;
    }

    /**
     * Calls a method on every scripts and returns the output.
     * @param method Method to call.
     * @param v1 Optional argument.
     * @param v2 Optional argument.
     * @param v3 Optional argument.
     */
    public inline extern overload function call(method:String, v1:Dynamic, v2:Dynamic, v3:Dynamic):Dynamic {
        if (_scripts == null || _scripts.length == 0)
            return null;

        var output:Dynamic = null;

        for (i in _scripts) {
            var call:Dynamic = i.call(method, v1, v2, v3);
            if (call != null) output = call;
        }

        return output;
    }

    /**
     * Calls a method on every scripts with an undefined amount of arguments and returns the output.
     * @param method Method to call.
     * @param arguments Optional arguments.
     */
    public function callDyn(method:String, ?arguments:Array<Dynamic>):Dynamic {
        if (_scripts == null || _scripts.length == 0)
            return null;

        var output:Dynamic = null;

        for (i in _scripts) {
            var call:Dynamic = i.callDyn(method, arguments);
            if (call != null) output = call;
        }

        return output;
    }

    /**
     * Dispatch an event on all scripts of this container and returns it.
     * @param method Method to call.
     * @param event Event to dispatch.
     * @param put Whether to put the event after it's dispatchment.
     */
    public function dispatchEvent<T:ScriptEvent>(method:String, event:T, put:Bool = true):T {
        for (script in _scripts) {
            script.call(method, event);

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
