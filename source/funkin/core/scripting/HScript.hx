package funkin.core.scripting;

import haxe.PosInfos;
import hscript.Expr;
import hscript.Parser;
import hscript.Interp;
import hscript.CustomClassHandler;

/**
 * A script able to parse and execute Haxe code at runtime.
 */
@:noCustomClass
class HScript extends Script {
    /**
     * HScript parser.
     */
    @:unreflective var _parser:Parser;

    /**
     * HScript interpreter.
     */
    @:unreflective var _interp:Interp;

    /**
     * Initializes the hscript context and executes the script content.
     * @param content Code to execute.
     */
    override function execute(content:String):Void {
        _parser = new Parser();
        _interp = new Interp();

        _parser.allowJSON = true;
        _parser.allowMetadata = true;
        _parser.allowTypes = true;

        _interp.allowStaticVariables = true;
        _interp.staticVariables = ScriptManager._sharedVariables;
        _interp.errorHandler = _onError;
        applyPresets();

        var ast:Expr = _parser.parseString(content, name);
        _interp.execute(ast);

        _registerClasses(ast.e);
    }

    @:inheritDoc(funkin.core.scripting.Script.set)
    override function set(key:String, value:Any):Any {
        if (_interp == null) return null;
        _interp.variables.set(key, value);
        return value;
    }

    @:inheritDoc(funkin.core.scripting.Script.get)
    override function get(key:String):Any {
        return _interp?.variables.get(key);
    }

    @:inheritDoc(funkin.core.scripting.Script.exists)
    override function exists(key:String):Bool {
        return _interp?.variables.exists(key);
    }

    @:inheritDoc(funkin.core.scripting.Script.buildClass)
    override function buildClass<T>(?cls:Class<T>, ?args:Array<Any>):T {
        if (_interp == null) return null;

        var classHandlers:Map<String, CustomClassHandler> = cast _interp.customClasses;

        for (handler in classHandlers) {
            if (!classExtends(handler, cls))
                continue;
            return cast handler.hnew(args ?? []);
        }
        return null;
    }

    @:inheritDoc(funkin.core.scripting.Script.buildClasses)
    override function buildClasses<T>(?cls:Class<T>, ?args:Array<Any>):Array<T> {
        if (_interp == null) return null;

        var classHandlers:Map<String, CustomClassHandler> = cast _interp.customClasses;
        var output:Array<T> = null;

        for (handler in classHandlers) {
            if (!classExtends(handler, cls))
                continue;

            output ??= [];
            args ??= [];

            output.push(cast handler.hnew(args));
        }

        return output;
    }

    @:inheritDoc(funkin.core.scripting.Script.buildClassByName)
    override function buildClassByName<T>(name:String, ?args:Array<Any>):T {
        if (name == null || _interp == null) return null;

        var classHandlers:Map<String, CustomClassHandler> = cast _interp.customClasses;
        var handler:CustomClassHandler = classHandlers.get(name);

        if (handler != null)
            return cast handler.hnew(args ?? []);

        return null;
    }

    /**
     * Internal method which returns whether a scripted class extends an existing class.
     * @param handler Custom class handler.
     * @param cls Class extenstion.
     * @return Bool
     */
    function classExtends(handler:CustomClassHandler, cls:Class<Any>):Bool {
        if (handler.extend == null) return cls == null;

        var extension:Class<Any> = Type.resolveClass(handler.extend);
        while (Type.getClassName(extension) != Type.getClassName(cls)) {
            // TODO: check if the extension is a custom class once extending scripted classes is supported in hscript improved
            var superClass:Class<Any> = Type.getSuperClass(extension);
            if (superClass == null) return false;
            extension = superClass;
        }

        return true;
    }

    /**
     * Internal method used to register classes from this script to the script manager.
     * @param expr HScript expression.
     */
    function _registerClasses(expr:ExprDef):Void {
        switch (expr) {
            case EClass(name, _, _, _, _, isPrivate):
                if (!isPrivate)
                    ScriptManager.addVariable(name, _interp.customClasses.get(name));
            case EBlock(exprs):
                for (expr in exprs)
                    _registerClasses(expr.e);
            case _:
        }
    }

    /**
     * Method called whenever an error happens during code execution.
     * @param error Error object.
     * @param infos Position informations.
     */
    function _onError(error:Error, infos:PosInfos):Void {
        switch (error.e) {
            case ECustom(msg):
                // error is always ECustom
                if (msg.startsWith(name)) {
                    // don't append pos infos if they're already included
                    Logging.traceString(msg, ERROR);
                }
                else {
                    Logging.traceString('${name}:${infos.lineNumber}: ${msg}', ERROR);
                }
            default:
        }
    }

    @:inheritDoc(funkin.core.scripting.Script.destroy)
    override function destroy():Void {
        super.destroy();

        _parser = null;
        _interp = null;
    }
}
