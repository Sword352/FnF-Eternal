package funkin.core.scripting;

import funkin.core.scripting.ScriptException;
import funkin.core.macros.ScriptMacros;
import lime.app.Promise;
import lime.app.Future;
import haxe.Exception;

/**
 * A script is an object able to dynamically execute code at runtime.
 * This class isn't meant to be instansiated directly; it is used as a base for implementing other classes executing code for a specific programming language.
 * For creating a script, use the appropriate factory functions or create instances of classes inheriting from this class such as `HScript`.
 */
@:noCustomClass
class Script implements IFlxDestroyable {
    /**
     * Recursively loads each script located at the given directory, in all asset sources.
     * @param directory Directory to scan.
     * @return Array<Script>
     */
    public static function fromDirectory(directory:String):Array<Script> {
        var output:Array<Script> = [];

        Assets.invoke((source) -> {
            if (!source.exists(directory) || !source.isDirectory(directory)) return;

            var files:Array<String> = _scanDirectory(source, directory);
            for (file in files) {
                var script:Script = _scriptFromFile(source, file);
                if (script != null) output.push(script);
            }
        });
        
        return output;
    }

    /**
     * Recursively loads each script located at the given directory asynchronously, in all asset sources.
     * @param directory Directory to scan.
     * @return Future<Array<Script>> Future object.
     */
    public static function loadFromDirectory(directory:String):Future<Array<Script>> {
        var promise:Promise<Array<Script>> = new Promise();
        new Future<Void>(_loadAsync.bind(directory, promise), true);
        return promise.future;
    }

    /**
     * Creates a script executing the given string content.
     * @param content Content to execute.
     * @param path Path of the script file.
     * @return Script
     */
    public static function fromString(content:String, path:String):Script {
        var name:String = path.substring(path.lastIndexOf("/") + 1, path.length);
        var script:Script = null;

        try {
            // only haxe scripts are supported as of now
            script = new HScript(content, name);
        }
        catch (e:ScriptException) {
            switch (e.reason) {
                case PARSING_ERROR(error):
                    Logging.traceString(error, DefaultLogStyle.ERROR);
                case MALICIOUS_CONTENT:
                    Logging.traceString('${name}: Script content is suspected to be malicious, aborting.', DefaultLogStyle.ERROR);
            }

            script = null;
        }

        return script;
    }

    /**
     * Identifier for this script.
     */
    public var name(default, null):String;

    /**
     * Creates a `Script` instance.
     * @param content Code to execute.
     * @param name Optional identifier for this script.
     * @throws ScriptException Script content was considered malicious.
     * @throws ScriptException Parsing the script content failed.
     */
    function new(content:String, ?name:String):Void {
        this.name = name;

        if (!isContentSafe(content))
            throw new MaliciousScriptException();

        try execute(content)
        catch (e:Exception) {
            this.destroy();
            throw new ParsingScriptException(e.message);
        }
    }

    /**
     * Registers a variable in this script and returns it's value.
     * @param key Variable name.
     * @param value Variable value.
     */
    public function set(key:String, value:Any):Any {
        return value;
    }

    /**
     * Returns a variable from this script.
     * @param key Variable name.
     */
    public function get(key:String):Any {
        return null;
    }

    /**
     * Returns whether a variable exists in this script.
     * @param key Variable name.
     */
    public function exists(key:String):Bool {
        return false;
    }

    /**
     * Creates an instance of the first scripted class from this script.
     * @param cls Optional, existing class the scripted class should extend.
     * @param args Optional array of arguments to pass to the constructor of the class.
     * @return An instance of a scripted class, or null if not found.
     */
    public function buildClass<T>(?cls:Class<T>, ?args:Array<Any>):T {
        return null;
    }

    /**
     * Creates instances of each scripted classes from this script.
     * @param cls Optional, existing class the scripted classes should extend.
     * @param args Optional array of arguments to pass to the constructor of each classes.
     * @return An array of each initialized class instances, or null if not found.
     */
    public function buildClasses<T>(?cls:Class<T>, ?args:Array<Any>):Array<T> {
        return null;
    }

    /**
     * Creates an instance of a scripted class from this script by it's name.
     * @param name Name of the scripted class to instansiate.
     * @param args Optional array of arguments to pass to the constructor of the class.
     * @return An instance of the desired scripted class, or null if not found.
     */
    public function buildClassByName<T>(name:String, ?args:Array<Any>):T {
        return null;
    }

    /**
     * Clean up memory.
     */
    public function destroy():Void {
        name = null;
    }

    /**
     * Internal method which executes the script content.
     * This method should be overrode by classes inheriting from this class.
     */
    function execute(content:String):Void {}

    /**
     * Internal method which pre-imports variables.
     * NOTE: this should be called manually by class extensions.
     */
    function applyPresets():Void {
        for (name => value in ScriptManager._presets)
            set(name, value);
    }

    /**
     * Internal method which checks if the script content is malicious.
     * @param content Content to verify.
     * @return `true` if the content is not malicious, `false` otherwise.
     */
    inline function isContentSafe(content:String):Bool {
        return !__blacklistRegex.match(content);
    }

    static function _loadAsync(directory:String, promise:Promise<Array<Script>>):Void {
        var scripts:Array<Script> = [];
        var paths:Map<IAssetSource, Array<String>> = [];

        var total:Int = 0;
        var progress:Int = 0;

        Assets.invoke((source) -> {
            var files:Array<String> = _scanDirectory(source, directory);
            paths.set(source, files);
            total += files.length;
        });

        // dispatch progress/complete feedback in the main thread to avoid race conditions
        haxe.MainLoop.runInMainThread(() -> promise.progress(progress, total));

        Assets.invoke((source) -> {
            var files:Array<String> = paths.get(source);
            for (file in files) {
                var script:Script = _scriptFromFile(source, file);

                if (script != null) {
                    progress++;
                    scripts.push(script);
                }
                else {
                    total--;
                }

                haxe.MainLoop.runInMainThread(() -> promise.progress(progress, total));
            }
        });

        haxe.MainLoop.runInMainThread(() -> promise.complete(scripts));
    }

    static function _scanDirectory(source:IAssetSource, directory:String):Array<String> {
        var entries:Array<String> = source.readDirectory(directory);
        if (entries.length == 0) return [];

        var output:Array<String> = [];

        for (entry in entries) {
            var path:String = directory + entry;

            if (source.isDirectory(path)) {
                output = output.concat(_scanDirectory(source, path + "/"));
                continue;
            }

            if (SCRIPT.hasExtension(entry)) {
                output.push(path);
            }
        }

        return output;
    }

    static inline function _scriptFromFile(source:IAssetSource, path:String):Script {
        return fromString(source.getContent(path), path);
    }

    /**
     * Internal regex used to determinate whether a script contains malicious code.
     */
    static final __blacklistRegex:EReg = ScriptMacros.buildSafetyRegex([
        // Disallow sys, filesystem and network apis
        "sys.io",
        "sys.net",
        "sys.db",
        "sys.ssl",
        "FileSystem",
        "FsAssetSource",
        "openfl.filesystem",
        "Http",
        "Sys",

        // Disallow the ability to run external code (NDLLs, external processes, etc.)
        "openfl.desktop.NativeProcess",
        "lime.system.System",
        "lime.system.CFFI",
        "lime.system.JNI",
        "hscript.Interp",
        "hscript.Parser",
        "hscript.Expr",

        #if cpp
        // CPP-specific apis
        "cpp.Lib",
        "cpp.NativeFile",
        "cpp.NativeProcess",
        "cpp.NativeSocket",
        "cpp.NativeSsl",
        "cpp.NativeSys",
        "cpp.Prime",
        "cpp.Stdio",
        #end

        // Disallow reflection
        "Reflect",
        "Type",

        // Disallow access to the haxe unserializer as it can resolve classes
        "haxe.Unserializer",

        // OpenFL's Assets API has 2 static methods related to reflection,
        // so we blacklist the methods instead of locking access to the entirety of the class
        // as it can be fairly useful
        "resolveClass",
        "resolveEnum",

        // Disallow blacklist manipulation
        "__blacklistRegex"
    ]);
}
