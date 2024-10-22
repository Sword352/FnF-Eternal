package funkin.core.scripting;

import haxe.PosInfos;
import haxe.Exception;
import haxe.Constraints.Function;

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

        #if DISCORD_RPC
        "DiscordRPC" => DiscordRPC,
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
        "Paths" => Paths
    ];

    /**
     * Used so you can declare and use static variables in scripts.
     */
    public static final staticFields:Map<String, Dynamic> = [];

    /**
     * Executes code from a string and returns the script.
     * @param content Script to execute.
     * @param name Optional name to use for logging.
     */
    public static inline function load(content:String, ?name:String):Script {
        // only hscript is supported as of now
        return new HScript(content, name);
    }

    /**
     * Name of this script, used for logging.
     */
    public var name(default, null):String;

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
     * Creates a `Script` instance.
     * @param content Script to execute.
     * @param name Optional name to use for logging.
     */
    public function new(content:String, ?name:String):Void {
        this.name = name;

        try {
            execute(content);
            applyPresets();
        }
        catch (e:Exception) {
            trace('Failed to execute script "${name}"! [${e.message}]');
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
     * Calls a method from this script and returns it's output.
     * @param method Method to call.
     * @return Dynamic
     */
    public inline extern overload function call(method:String):Dynamic {
        var func:Function = get(method);

        if (func == null)
            return null;

        try
            return func()
        catch (e:Exception) {
            haxe.Log.trace('${method}: ${buildError(e.message)}', buildPosInfos(e));
            return null;
        }
    }

    /**
     * Calls a method from this script and returns it's output.
     * @param method Method to call.
     * @param v1 Optional argument.
     * @return Dynamic
     */
    public inline extern overload function call(method:String, v1:Dynamic):Dynamic {
        var func:Function = get(method);

        if (func == null)
            return null;

        try
            return func(v1)
        catch (e:Exception) {
            haxe.Log.trace('${method}: ${buildError(e.message)}', buildPosInfos(e));
            return null;
        }
    }

    /**
     * Calls a method from this script and returns it's output.
     * @param method Method to call.
     * @param v1 Optional argument.
     * @param v2 Optional argument.
     * @return Dynamic
     */
    public inline extern overload function call(method:String, v1:Dynamic, v2:Dynamic):Dynamic {
        var func:Function = get(method);

        if (func == null)
            return null;

        try
            return func(v1, v2)
        catch (e:Exception) {
            haxe.Log.trace('${method}: ${buildError(e.message)}', buildPosInfos(e));
            return null;
        }
    }

    /**
     * Calls a method from this script and returns it's output.
     * @param method Method to call.
     * @param v1 Optional argument.
     * @param v2 Optional argument.
     * @param v3 Optional argument.
     * @return Dynamic
     */
    public inline extern overload function call(method:String, v1:Dynamic, v2:Dynamic, v3:Dynamic):Dynamic {
        var func:Function = get(method);

        if (func == null)
            return null;

        try
            return func(v1, v2, v3)
        catch (e:Exception) {
            haxe.Log.trace('${method}: ${buildError(e.message)}', buildPosInfos(e));
            return null;
        }
    }

    /**
     * Calls a method from this script with an undefined amount of arguments and returns it's output.
     * @param method Method to call.
     * @param arguments Optional arguments.
     * @return Dynamic
     */
    public function callDyn(method:String, ?arguments:Array<Dynamic>):Dynamic {
        var func:Function = get(method);
        
        if (func == null)
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
        parent = null;
        name = null;
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
    function execute(content:String):Void {}

    function get_object():Dynamic
        return null;

    function set_object(v:Dynamic):Dynamic
        return null;
}
