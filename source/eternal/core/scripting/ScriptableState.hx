package eternal.core.scripting;

#if ENGINE_SCRIPTING
import flixel.FlxSubState;

#if ENGINE_MODDING
@:keep class ModState extends ScriptableState {
    var controls:Controls = Controls.globalControls;

    public function new(script:String):Void {
        super();

        var path:String = Assets.getPath('data/states/${script}', SCRIPT);
        if (!FileTools.exists(path)) {
            trace('Could not find state script "${script}"!');
            return;
        }

        loadScript(path);
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
    var controls:Controls = Controls.globalControls;

    public function new(script:String):Void {
        super();

        var path:String = Assets.getPath('data/substates/${script}', SCRIPT);
        if (!FileTools.exists(path)) {
            trace('Could not find substate script "${script}"!');
            return;
        }

        loadScript(path);
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

    public inline function loadScript(path:String):HScript
        return scriptPack.loadScript(path);

    public inline function addScript(script:HScript):HScript
        return scriptPack.addScript(script);

    public inline function hxsSet(key:String, obj:Dynamic):Void
        scriptPack.hxsSet(key, obj);

    public inline function hxsCall(func:String, ?args:Array<Dynamic>):Dynamic
        return scriptPack.hxsCall(func, args);

    public inline function cancellableCall(func:String, ?args:Array<Dynamic>):Bool
        return scriptPack.cancellableCall(func, args);

    inline function initStateScript():Bool {
        var statePackage:String = Type.getClassName(Type.getClass(this));
        var path:String = Assets.getPath('data/states/${statePackage.substring(statePackage.lastIndexOf('.') + 1)}', SCRIPT);

        if (!FileTools.exists(path))
            return false;
        
        loadScript(path);
        return true;
    }

    override function openSubState(SubState:FlxSubState):Void {
        if (!noSubstateCalls)
            hxsCall("onOpenSubState", [SubState]);

        super.openSubState(SubState);
        hxsCall("onOpenSubStatePost", [SubState]);
    }

    override function closeSubState():Void {
        if (!noSubstateCalls)
            hxsCall("onCloseSubState");

        super.closeSubState();
        hxsCall("onCloseSubStatePost");
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

class ScriptableSubState extends FlxSubState {
    public var scriptPack:ScriptPack;

    public function new():Void {
        super();
        scriptPack = new ScriptPack(this);
    }

    public inline function loadScriptsFrom(path:String):Void
        scriptPack.loadScriptsFrom(path);

    public inline function loadScript(path:String):HScript
        return scriptPack.loadScript(path);

    public inline function addScript(script:HScript):HScript
        return scriptPack.addScript(script);

    public inline function hxsSet(key:String, obj:Dynamic):Void
        scriptPack.hxsSet(key, obj);

    public inline function hxsCall(func:String, ?args:Array<Dynamic>):Dynamic
        return scriptPack.hxsCall(func, args);

    public inline function cancellableCall(func:String, ?args:Array<Dynamic>):Bool
        return scriptPack.cancellableCall(func, args);

    inline function initStateScript():Bool {
        var statePackage:String = Type.getClassName(Type.getClass(this));
        var path:String = Assets.getPath('data/substates/${statePackage.substring(statePackage.lastIndexOf('.') + 1)}', SCRIPT);

        if (!FileTools.exists(path))
            return false;
        
        loadScript(path);
        return true;
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