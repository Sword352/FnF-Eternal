package funkin.core.scripting;

import flixel.FlxState;
import flixel.FlxSubState;
import funkin.core.scripting.events.StateEvents;

class ScriptableState extends TransitionState {
    public var scripts:ScriptContainer;

    public function new():Void {
        super();
        scripts = new ScriptContainer(this);
    }

    inline function initStateScripts():Void {
        var stateString:String = formatStateName(this);

        // we first check if there's a single script for this state
        var script = scripts.load('scripts/states/${stateString}');

        if (script == null) {
            // if not, it might be a directory
            scripts.loadScripts('scripts/states/${stateString}');
        }
    }

    override function openSubState(subState:FlxSubState):Void {
        if (!subStateEvent(OPEN, subState)) return;
        super.openSubState(subState);
    }

    override function closeSubState():Void {
        if (!subStateEvent(CLOSE, subState)) return;
        super.closeSubState();
    }

    function subStateEvent(type:SubStateEventAction, subState:FlxSubState):Bool {
        var event:SubStateEvent = Events.get(SubStateEvent).setup(type, subState);
        scripts.dispatchEvent("onSubState" + Tools.capitalize(type), event);

        if (!event.cancelled) {
            switch (type) {
                case OPEN:
                    onSubStateOpen(subState);
                case CLOSE:
                    onSubStateClose(subState);
            }
        }

        return !event.cancelled;
    }

    function onSubStateOpen(subState:FlxSubState):Void {}
    function onSubStateClose(subState:FlxSubState):Void {}

    function superOpenSubState(subState:FlxSubState):Void {
        super.openSubState(subState);
    }

    function superCloseSubState():Void {
        super.closeSubState();
    }

    override function destroy():Void {
        scripts = FlxDestroyUtil.destroy(scripts);
        super.destroy();
    }

    public static inline function formatStateName(state:FlxState):String {
        var statePackage:String = Type.getClassName(Type.getClass(state));
        return statePackage.substring(statePackage.lastIndexOf('.') + 1);
    }
}

class ScriptableSubState extends FlxSubState {
    public var scripts:ScriptContainer;

    public function new():Void {
        super();
        scripts = new ScriptContainer(this);
    }

    inline function initStateScripts():Void {
        var stateString:String = ScriptableState.formatStateName(this);
        var script = scripts.load('scripts/states/${stateString}');

        if (script == null) {
            scripts.loadScripts('scripts/states/${stateString}');
        }
    }

    override function close():Void {
        scripts.call("onClose");
        super.close();
    }

    override function destroy():Void {
        scripts = FlxDestroyUtil.destroy(scripts);
        super.destroy();
    }
}
