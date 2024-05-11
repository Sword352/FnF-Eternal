package core.scripting;

#if ENGINE_SCRIPTING
import flixel.FlxState;
import flixel.FlxSubState;

#if ENGINE_MODDING
@:keep class ModState extends ScriptableState {
    var controls:Controls = Controls.global;

    public function new(script:String):Void {
        super();

        var path:String = Assets.script('scripts/states/${script}');
        if (!FileTools.exists(path)) {
            trace('Could not find state script(s) at "${script}"!');
            return;
        }

        if (!FileTools.isDirectory(path)) loadScript(path);
        loadScriptsFrom('scripts/states/${script}');
    }

    override function create():Void {
        hxsCall("onCreate");
        super.create();
        hxsCall("onCreatePost");
    }

    override function update(elapsed:Float):Void {
        hxsCall("onUpdate", [elapsed]);
        super.update(elapsed);
        hxsCall("onUpdatePost", [elapsed]);
    }

    override function destroy():Void {
        controls = null;
        super.destroy();
    }
}

@:keep class ModSubState extends ScriptableSubState {
    var controls:Controls = Controls.global;

    public function new(script:String):Void {
        super();

        var path:String = Assets.script('scripts/substates/${script}');
        if (!FileTools.exists(path)) {
            trace('Could not find substate script(s) at "${script}"!');
            return;
        }

        if (!FileTools.isDirectory(path)) loadScript(path);
        loadScriptsFrom('scripts/substates/${script}');
    }

    override function create():Void {
        hxsCall("onCreate");
        super.create();
        hxsCall("onCreatePost");
    }

    override function update(elapsed:Float):Void {
        hxsCall("onUpdate", [elapsed]);
        super.update(elapsed);
        hxsCall("onUpdatePost", [elapsed]);
    }

    override function destroy():Void {
        controls = null;
        super.destroy();
    }
}
#end

class ScriptableState extends TransitionState {
    public var scriptPack:ScriptPack;
    var noSubstateCalls:Bool = false;

    public function new():Void {
        super();
        scriptPack = new ScriptPack(this);
    }

    public inline function loadScriptsFrom(path:String):Void
        scriptPack.loadScriptsFrom(path);

    public inline function loadScriptsGlobally(path:String):Void
        scriptPack.loadScriptsGlobally(path);

    public inline function loadScript(path:String):HScript
        return scriptPack.loadScript(path);

    public inline function addScript(script:HScript):HScript
        return scriptPack.addScript(script);

    public inline function hxsSet(key:String, obj:Dynamic):Void
        scriptPack.set(key, obj);

    public inline function hxsCall(func:String, ?args:Array<Dynamic>):Dynamic
        return scriptPack.call(func, args);

    public inline function cancellableCall(func:String, ?args:Array<Dynamic>):Bool
        return scriptPack.cancellableCall(func, args);

    inline function initStateScripts():Void {
        var stateString:String = formatStateName(this);

        var singleScript:String = Assets.script('scripts/states/${stateString}');
        if (FileTools.exists(singleScript) && !FileTools.isDirectory(singleScript)) loadScript(singleScript);

        loadScriptsFrom('scripts/states/${stateString}');
    }

    override function openSubState(SubState:FlxSubState):Void {
        if (!noSubstateCalls)
            hxsCall("onSubStateOpened", [SubState]);

        super.openSubState(SubState);
        hxsCall("onSubStateOpenedPost", [SubState]);
    }

    override function closeSubState():Void {
        if (!noSubstateCalls)
            hxsCall("onSubStateClosed");

        super.closeSubState();
        hxsCall("onSubStateClosedPost");
    }

    override function onFocusLost():Void {
        hxsCall("onFocusLost");
    }

    override function onFocus():Void {
        hxsCall("onFocus");
    }

    override function draw():Void {
        if (cancellableCall("onDraw"))
            return;

        super.draw();
        hxsCall("onDrawPost");
    }

    override function destroy():Void {
        scriptPack.destroy();
        scriptPack = null;
        super.destroy();
    }

    public static inline function formatStateName(state:FlxState):String {
        var statePackage:String = Type.getClassName(Type.getClass(state));
        return statePackage.substring(statePackage.lastIndexOf('.') + 1);
    }
}

class ScriptableSubState extends FlxSubState {
    public var scriptPack:ScriptPack;

    public function new():Void {
        super();
        scriptPack = new ScriptPack(this);
    }

    public inline function loadScriptsFrom(path:String):Void
        scriptPack.loadScriptsFrom(path);

    public inline function loadScriptsGlobally(path:String):Void
        scriptPack.loadScriptsGlobally(path);

    public inline function loadScript(path:String):HScript
        return scriptPack.loadScript(path);

    public inline function addScript(script:HScript):HScript
        return scriptPack.addScript(script);

    public inline function hxsSet(key:String, obj:Dynamic):Void
        scriptPack.set(key, obj);

    public inline function hxsCall(func:String, ?args:Array<Dynamic>):Dynamic
        return scriptPack.call(func, args);

    public inline function cancellableCall(func:String, ?args:Array<Dynamic>):Bool
        return scriptPack.cancellableCall(func, args);

    inline function initStateScripts():Void {
        var stateString:String = ScriptableState.formatStateName(this);

        var singleScript:String = Assets.script('scripts/substates/${stateString}');
        if (FileTools.exists(singleScript) && !FileTools.isDirectory(singleScript)) loadScript(singleScript);

        loadScriptsFrom('scripts/substates/${stateString}');
    }

    override function close():Void {
        hxsCall("onClose");
        super.close();
        hxsCall("onClosePost");
    }

    override function onFocusLost():Void {
        hxsCall("onFocusLost");
    }

    override function onFocus():Void {
        hxsCall("onFocus");
    }

    override function draw():Void {
        if (cancellableCall("onDraw"))
            return;

        super.draw();
        hxsCall("onDrawPost");
    }

    override function destroy():Void {
        scriptPack.destroy();
        scriptPack = null;
        super.destroy();
    }
}
#end
