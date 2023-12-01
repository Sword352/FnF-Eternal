package eternal.core.scripting;

#if ENGINE_SCRIPTING
import flixel.FlxSubState;

@:keep class ModState extends ScriptableState {
    var controls:Controls = Controls.globalControls;

    public function new(script:String):Void {
        super();

        var path:String = AssetHelper.getPath('data/states/${script}', SCRIPT);
        if (!FileTools.exists(path)) {
            trace('Could not find state script ${script}!');
            return;
        }

        loadScript(path, false);
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
        super.destroy();
        controls = null;
    }
}

@:keep class ModSubState extends ScriptableSubState {
    var controls:Controls = Controls.globalControls;

    public function new(script:String):Void {
        super();

        var path:String = AssetHelper.getPath('data/substates/${script}', SCRIPT);
        if (!FileTools.exists(path)) {
            trace('Could not find substate script ${script}!');
            return;
        }

        loadScript(path, false);
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
        super.destroy();
        controls = null;
    }
}

class ScriptableState extends TransitionState implements IScriptable {
    public var scriptPack:Array<HScript>;
    public var imports:Map<String, Dynamic>;

    // Used to avoid some automatic callbacks when overriding some states
    var avoidCallbacks:Array<String>;

    public function new():Void {
        super();

        scriptPack = [];
        imports = [];
        avoidCallbacks = [];
    }

    public function loadScriptsFrom(path:String):Void {
        var realPath:String = AssetHelper.getPath('${path}/', NONE);
        if (!FileTools.exists(realPath))
            return;

        var exts:Array<String> = SCRIPT.getExtensions();
        for (file in FileTools.readDirectory(realPath)) {
            for (ext in exts) {
                if (!file.endsWith(ext))
                    continue;
                loadScript(realPath + file, false);
            }
        }
    }

    public function loadScript(path:String, check:Bool = true):HScript {
        var script = new HScript(path, check);
        if (script.state != ALIVE)
            return null;
        return addScript(script);
    }

    public function addScript(script:HScript):HScript {
        script.parent = this;
        script.object = this;

        for (i in imports.keys())
            script.set(i, imports.get(i));
        scriptPack.push(script);
        return script;
    }

    public function hxsSet(key:String, obj:Dynamic):Void {
        for (i in scriptPack)
            i.set(key, obj);
        imports.set(key, obj);
    }

    public function hxsCall(funcToCall:String, ?args:Array<Dynamic>):Dynamic {
        if (scriptPack == null || scriptPack.length < 1)
            return null;

        var returnValue:Dynamic = null;
        for (i in scriptPack) {
            var call:Dynamic = i.call(funcToCall, args);
            if (call != null)
                returnValue = call;
        }
        return returnValue;
    }

    public function cancellableCall(funcToCall:String, ?args:Array<Dynamic>):Bool {
        var ret:Dynamic = hxsCall(funcToCall, args);
        return ret != null && ret is Bool && cast(ret, Bool) == false;
    }

    private function initStateScript():Bool {
        var statePackage:String = Type.getClassName(Type.getClass(this));
        var path:String = AssetHelper.getPath('data/states/${statePackage.substring(statePackage.lastIndexOf('.') + 1)}', SCRIPT);

        if (!FileTools.exists(path))
            return false;
        
        loadScript(path, false);
        return true;
    }

    override function openSubState(SubState:FlxSubState):Void {
        if (!avoidCallbacks.contains("onOpenSubState"))
            hxsCall("onOpenSubState", [SubState]);

        super.openSubState(SubState);
        hxsCall("onOpenSubStatePost", [SubState]);
    }

    override function closeSubState():Void {
        if (!avoidCallbacks.contains("onCloseSubState"))
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
        while (scriptPack.length > 0)
            scriptPack.shift().destroy();
        scriptPack = null;

        imports = null;
        avoidCallbacks = null;

        super.destroy();
    }
}

class ScriptableSubState extends FlxSubState implements IScriptable {
    public var scriptPack:Array<HScript>;
    public var imports:Map<String, Dynamic>;

    // Used to avoid some automatic callbacks when overriding some subtates.
    var avoidCallbacks:Array<String>;

    public function new():Void {
        super();

        scriptPack = [];
        imports = [];
        avoidCallbacks = [];
    }

    public function loadScriptsFrom(path:String):Void {
        var realPath:String = AssetHelper.getPath('${path}/', NONE);
        if (!FileTools.exists(realPath))
            return;

        var exts:Array<String> = SCRIPT.getExtensions();
        for (file in FileTools.readDirectory(realPath)) {
            for (ext in exts) {
                if (!file.endsWith(ext))
                    continue;
                loadScript(realPath + file, false);
            }
        }
    }

    public function loadScript(path:String, check:Bool = true):HScript {
        var script = new HScript(path, check);
        if (script.state != ALIVE)
            return null;
        return addScript(script);
    }

    public function addScript(script:HScript):HScript {
        script.parent = this;
        script.object = this;
        
        for (i in imports.keys())
            script.set(i, imports.get(i));
        scriptPack.push(script);
        return script;
    }

    public function hxsSet(key:String, obj:Dynamic):Void {
        for (i in scriptPack)
            i.set(key, obj);
        imports.set(key, obj);
    }

    public function hxsCall(funcToCall:String, ?args:Array<Dynamic>):Dynamic {
        if (scriptPack == null || scriptPack.length < 1)
            return null;

        var returnValue:Dynamic = null;
        for (i in scriptPack) {
            var call:Dynamic = i.call(funcToCall, args);
            if (call != null)
                returnValue = call;
        }
        return returnValue;
    }

    public function cancellableCall(funcToCall:String, ?args:Array<Dynamic>):Bool {
        var ret:Dynamic = hxsCall(funcToCall, args);
        return ret != null && ret is Bool && cast(ret, Bool) == false;
    }

    private function initStateScript():Bool {
        var statePackage:String = Type.getClassName(Type.getClass(this));
        var path:String = AssetHelper.getPath('data/substates/${statePackage.substring(statePackage.lastIndexOf('.') + 1)}', SCRIPT);

        if (!FileTools.exists(path))
            return false;
        
        loadScript(path, false);
        return true;
    }

    override function close():Void {
        if (!avoidCallbacks.contains("onClose"))
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
        while (scriptPack.length > 0)
            scriptPack.shift().destroy();
        scriptPack = null;

        imports = null;
        avoidCallbacks = null;
        
        super.destroy();
    }
}

interface IScriptable {
    public var scriptPack:Array<HScript>;
}
#end