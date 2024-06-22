package funkin.core.scripting;

/*
#if (ENGINE_SCRIPTING && cpp)
class CppiaScript extends Script {
    var _host:Dynamic;

    override function execute():Void {
        var cppiaHost:Dynamic = cpp.cppia.Module.fromString(script);
        _host = Type.createInstance(cppiaHost.resolveClass(fileName), []);
    }

    override function set(key:String, value:Dynamic):Dynamic {
        if (_host != null)
            Reflect.setField(_host, key, value);

        return value;
    }

    override function get(key:String):Dynamic {
        if (_host != null)
            return Reflect.getProperty(_host, key);

        return null;
    }

    override function exists(key:String):Bool {
        return _host != null && Reflect.hasField(_host, key);
    }

    override function destroy():Void {
        super.destroy();
        _host = null;
    }
}
#end
*/
