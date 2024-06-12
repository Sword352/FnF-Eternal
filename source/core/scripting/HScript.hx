package core.scripting;

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

        var fileName:String = path.substring(path.lastIndexOf("/") + 1);
        _interp.execute(_parser.parseString(script, fileName));
    }

    override function set(key:String, value:Dynamic):Dynamic {
        _interp?.variables.set(key, value);
        return value;
    }

    override function get(key:String):Dynamic {
        return _interp?.variables.get(key);
    }

    override function exists(key:String):Bool {
        return _interp?.variables.exists(key);
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

            for (customClass in moduleScript._interp.customClasses.keys())
                set(customClass, moduleScript._interp.customClasses.get(customClass));

            // add the script to the pack as well in case it has code outside of classes
            parent?.addScript(moduleScript);
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
