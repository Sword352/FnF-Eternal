package funkin.core.scripting;

#if ENGINE_SCRIPTING
import haxe.PosInfos;
import haxe.Exception;

/**
 * Base script class.
 */
class Script implements IFlxDestroyable {
    /**
     * List of variables imported by default in all scripts.
     */
    public static final presets:Map<String, Dynamic> = [
        // Flixel
        "FlxG" => flixel.FlxG,
        "FlxSprite" => flixel.FlxSprite,
        "FlxText" => flixel.text.FlxText,
        "FlxSound" => flixel.sound.FlxSound,

        "FlxGroup" => flixel.group.FlxGroup,
        "FlxTween" => flixel.tweens.FlxTween,
        "FlxEase" => flixel.tweens.FlxEase,
        "FlxTimer" => flixel.util.FlxTimer,
        "FlxMath" => flixel.math.FlxMath,

        "FlxAxes" => flixel.util.FlxAxes.FlxAxes_HSC,
        "FlxPoint" => flixel.math.FlxPoint.FlxPoint_HSC,
        "FlxColor" => flixel.util.FlxColor.FlxColor_HSC,
        "FlxTweenType" => flixel.tweens.FlxTween.FlxTweenType_HSC,

        #if ENGINE_DISCORD_RPC
        "DiscordPresence" => DiscordPresence,
        #end

        "OffsetSprite" => funkin.objects.OffsetSprite,
        "Conductor" => Conductor,
        "Options" => Options,

        // Transition stuff
        "Transition" => Transition,
        "TranitionState" => TransitionState,
        "TransitionSubState" => TransitionSubState,

        // Misc
        "PlayState" => funkin.gameplay.PlayState,
        "FlxRuntimeShader" => flixel.addons.display.FlxRuntimeShader,
        "ShaderFilter" => openfl.filters.ShaderFilter,

        // Tools
        "Std" => Std,
        "Math" => Math,
        "Tools" => Tools,
        "StringTools" => StringTools,
        "Assets" => Assets,
        "Paths" => Assets, // base game compat
    ];

    /**
     * Used so you can declare and use static variables in scripts.
     */
    public static final staticFields:Map<String, Dynamic> = [];

    /**
     * Loads a script from the specified path and returns it.
     * @param path The path to look for
     */
    public static inline function load(path:String):Script {
        /*
        switch (haxe.io.Path.extension(path)) {
            case "cppia":
                #if cpp
                return new CppiaScript(path);
                #else
                trace("CPPIA scripts aren't supported in this target!");
                return null;
                #end
            default:
                return new HScript(path);
        }
        */

        // only hscript is supported as of now
        return new HScript(path);
    }

    /**
     * File path of this script.
     */
    public var path(default, null):String;

    /**
     * File name of this script.
     */
    public var fileName(default, null):String;

    /**
     * File content of this script.
     */
    public var script(default, null):String;

    /**
     * Defines whether this script is alive. If `false`, it can't be used anymore.
     */
    public var alive(default, null):Bool = true;

    /**
     * Defines the script's parent object, meaning all of the object's properties are available in this script.
     */
    public var object(get, set):Dynamic;

    /**
     * `ScriptContainer` this script belongs to.
     */
    public var parent:ScriptContainer;

    // public var priority:Int = -1; // TODO

    /**
     * Creates a `Script` instance and execute the code from the file specified by `path`.
     * @param path Path of the file to load
     */
    public function new(path:String):Void {
        this.path = path;
        this.fileName = path.substring(path.lastIndexOf("/") + 1);

        try {
            this.script = FileTools.getContent(path);
            execute();
            applyPresets();
        }
        catch (e:Exception) {
            trace('Failed to execute script "${path}"! [${e.message}]');
            destroy();
        }
    }

    /**
     * Sets a variable in this script and returns it.
     * @param key The variable's name
     * @param v The variable's value
     */
    public function set(key:String, v:Dynamic):Dynamic {
        return v;
    }

    /**
     * Returns a variable from this script if it exists.
     * @param key The variable's name
     */
    public function get(key:String):Dynamic {
        return null;
    }

    /**
     * Returns whether a variable exists in this script.
     * @param key Variable to look for
     */
    public function exists(key:String):Bool {
        return false;
    }

    /**
     * Calls a method from this script if it exists, and returns it's output.
     * @param method Method to call
     * @param arguments Optional arguments to pass
     */
    public function call(method:String, ?arguments:Array<Dynamic>):Dynamic {
        var func:Dynamic = get(method);
        
        if (func == null || !Reflect.isFunction(func))
            return null;

        try
            return Reflect.callMethod(null, func, arguments)
        catch (e:Exception) {
            haxe.Log.trace('${method}: ${buildError(e.message)}', buildPosInfos(e));
            return null;
        }
    }

    /**
     * Clean up memory.
     */
    public function destroy():Void {
        call("onDestroy");

        if (parent != null)
            parent.remove(this);

        alive = false;
        fileName = null;
        script = null;
        parent = null;
        path = null;
    }

    /**
     * Internal method which adds variables that should be pre-imported.
     */
    function applyPresets():Void {
        // apply default presets
        for (i in presets.keys())
            set(i, presets.get(i));

        // allows to close the script at any time
        set("closeScript", destroy);
    }

    /**
     * Internal method which returns pos infos for the call error trace. (override me!)
     * @param exception Error exception.
     */
    function buildPosInfos(exception:Exception):PosInfos {
        return null;
    }

    /**
     * Internal method allowing to modify the error to trace. (override me!)
     * @param exception Error string.
     */
    function buildError(exception:String):String {
        return exception;
    }

    /**
     * Internal method which executes the script. (override me!)
     */
    function execute():Void {}

    function get_object():Dynamic
        return null;

    function set_object(v:Dynamic):Dynamic
        return null;
}
#end
