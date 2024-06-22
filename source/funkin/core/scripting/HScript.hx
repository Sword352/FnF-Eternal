package funkin.core.scripting;

#if ENGINE_SCRIPTING
import hscript.Parser;
import hscript.Interp;

/**
 * HScript implementation.
 */
class HScript extends Script {
    /**
     * HScript parser for this script
     */
    var _parser:Parser;

    /**
     * HScript interpreter for this script
     */
    var _interp:Interp;

    override function execute():Void {
        _parser = new Parser();
        _interp = new Interp();

        _parser.allowJSON = _parser.allowMetadata = _parser.allowTypes = true;
        _interp.allowPublicVariables = _interp.allowStaticVariables = true;
        _interp.staticVariables = Script.staticFields;

        _interp.execute(_parser.parseString(script, fileName));
    }

    override function set(key:String, v:Dynamic):Dynamic {
        _interp?.variables.set(key, v);
        return v;
    }

    override function get(key:String):Dynamic {
        return _interp?.variables.get(key);
    }

    override function exists(key:String):Bool {
        return _interp?.variables.exists(key);
    }

    override function buildPosInfos(_):haxe.PosInfos {
        return _interp.posInfos();
    }

    // temporary until I can find a way not to trace the file pos again (TODO)
    override function buildError(exception:String):String {
        return exception; // exception.substring(exception.lastIndexOf(":") + 2, exception.length);
    }

    override function applyPresets():Void {
        super.applyPresets();

        set("importModule", (module:String) -> {
            var path:String = Assets.script(module);
            if (!FileTools.exists(path)) {
                trace('Could not find module "${module}"!');
                return;
            }

            var moduleScript:HScript = new HScript(path);
            if (!moduleScript.alive) return;

            for (customClass in moduleScript._interp.customClasses.keys()) {
                var cls = moduleScript._interp.customClasses.get(customClass);
                parent?.set(customClass, cls);
                set(customClass, cls);
            }

            // add the script to the script container as well in case it has code outside of classes
            parent?.add(moduleScript);
        });
    }

    override function destroy():Void {
        super.destroy();

        _interp = null;
        _parser = null;
    }

    override function get_object():Dynamic
        return _interp?.scriptObject;

    override function set_object(v:Dynamic):Dynamic
        return _interp.scriptObject = v;
}
#end
