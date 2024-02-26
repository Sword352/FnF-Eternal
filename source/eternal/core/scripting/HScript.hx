package eternal.core.scripting;

#if ENGINE_SCRIPTING
import hscript.Parser;
import hscript.Interp;

enum ScriptStatus {
    NONE;
    ALIVE;
    DEAD;
}

class HScript {
    public static final defaultImports:Map<String, Dynamic> = [
        // Flixel
		"FlxG" => flixel.FlxG,
		"FlxSprite" => flixel.FlxSprite,
        "FlxText" => flixel.text.FlxText,
		"FlxSound" => flixel.sound.FlxSound,
		"FlxTween" => flixel.tweens.FlxTween,
		"FlxEase" => flixel.tweens.FlxEase,
		"FlxTimer" => flixel.util.FlxTimer,
		"FlxMath" => flixel.math.FlxMath,
        "FlxPoint" => flixel.math.FlxPoint.FlxPoint_HSC,
		"FlxGroup" => flixel.group.FlxGroup,
        "FlxAxes" => flixel.util.FlxAxes.FlxAxes_HSC,
		"FlxColor" => flixel.util.FlxColor.FlxColor_HSC,
        "FlxTweenType" => flixel.tweens.FlxTween.FlxTweenType_HSC,

        // Eternal
        "Settings" => Settings,

        #if ENGINE_DISCORD_RPC
        "DiscordPresence" => DiscordPresence,
        #end

        // Funkin
        "Conductor" => Conductor,
        "OffsetSprite" => OffsetSprite,
        "DancingSprite" => funkin.objects.sprites.DancingSprite,

        // Transition stuff
        "Transition" => Transition,
        "TranitionState" => TransitionState,
        "TransitionSubState" => TransitionSubState,

        #if ENGINE_MODDING
        // Custom state and substate
        "ModState" => eternal.core.scripting.ScriptableState.ModState,
        "ModSubState" => eternal.core.scripting.ScriptableState.ModSubState,
        #end

        // Misc
        "PlayState" => funkin.states.PlayState,
        "FlxRuntimeShader" => flixel.addons.display.FlxRuntimeShader,
        "ShaderFilter" => openfl.filters.ShaderFilter,

        // Tools
        "Std" => Std,
		"Math" => Math,

        "Tools" => Tools,
        "StringTools" => StringTools,

		"Assets" => Assets,
        "Paths" => Assets, // base game compat
        "OpenFLAssets" => openfl.Assets,
        "FileTools" => FileTools,

        #if sys
        "Sys" => Sys,
        "File" => sys.io.File,
        "FileSystem" => sys.FileSystem,
        #end

        "Reflect" => Reflect,
        "Type" => Type,
	];

    public var state(default, null):ScriptStatus = NONE;
    
    public var parser(default, null):Parser;
    public var interp(default, null):Interp;

    public var script(default, null):String;
    public var path(default, null):String;

    public var object(get, set):Dynamic;
    public var parent:ScriptPack;

    public function new(path:String):Void {
        this.path = path;

        parser = new Parser();
        interp = new Interp();
        parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
		interp.allowPublicVariables = interp.allowStaticVariables = true;
        script = FileTools.getContent(this.path);

        try {
            interp.execute(parser.parseString(script, this.path.substring(this.path.lastIndexOf("/") + 1)));
            applyPresets();
            state = ALIVE;
        }
        catch (e) {
            trace('Failed to load script "${path}"! [${e.message}]');
            destroy();
            return;
        }
    }

    public function get(key:String):Null<Dynamic> {
        if (state == DEAD)
            return null;
        return interp.variables.get(key);
    }

    public function set(key:String, obj:Dynamic):Dynamic {
        if (state == DEAD)
            return obj;

        interp.variables.set(key, obj);
        return obj;
    }

    public function exists(key:String):Bool {
        if (state == DEAD)
            return false;
        return interp.variables.exists(key);
    }

    public function call(func:String, ?args:Array<Dynamic>):Dynamic {
        if (!exists(func))
            return null;

        var func:Dynamic = get(func);
        try return Reflect.callMethod(null, func, args)
        catch (e) {
            trace('${path}: Failed to call "${func}"! [${e.message}]');
            return null;
        }
    }

    public function destroy():Void {
        if (interp != null)
            call("onDestroy");

        if (parent != null) {
            parent.scripts.remove(this);
            parent = null;
        }
        
        state = DEAD;
        parser = null;
        interp = null;
        script = null;
        path = null;
    }

    inline function applyPresets():Void {
        for (i in defaultImports.keys())
            set(i, defaultImports.get(i));

        set("closeSCR", destroy);
    }

    inline function set_object(v:Dynamic):Dynamic {
	    if (interp != null)
	        interp.scriptObject = v;
        return v;
    }

    inline function get_object():Dynamic
        return interp?.scriptObject ?? null;
}
#end