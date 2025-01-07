package funkin.core.scripting;

import flixel.FlxSubState;

// @:build(funkin.core.macros.ScriptMacros.buildEventDispatcher())
// https://github.com/HaxeFoundation/haxe/issues/6567

/**
 * A state able to dispatch script events.
 * Most states of the game inherits from this class.
 * 
 * This object dispatches the following event(s):
 * - `Events.CREATE` (handled by script manager)
 * - `Events.CREATE_POST` (handled by script manager)
 * - `Events.UPDATE`
 * - `Events.UPDATE_POST`
 * - `Events.STATE_SWITCH`
 * - `Events.SUBSTATE_OPEN`
 * - `Events.SUBSTATE_CLOSE`
 * - `Events.DESTROY`
 */
class ScriptableState extends TransitionState {
    /**
     * Method called by flixel to update the state.
     * @param elapsed Elapsed time between the last and current frame.
     */
    override function tryUpdate(elapsed:Float):Void {
        if (persistentUpdate || subState == null) {
            dispatchEvent(Events.UPDATE, elapsed);
            update(elapsed);
            dispatchEvent(Events.UPDATE_POST, elapsed);
        }

		if (_requestSubStateReset) {
			_requestSubStateReset = false;
			resetSubState();
		}

		if (subState != null) {
			subState.tryUpdate(elapsed);
		}
    }

    /**
     * Method called by flixel to switch states.
     * @param onOutroComplete Function responsible of switching states.
     */
    override function startOutro(onOutroComplete:Void->Void):Void {
        var event:StateSwitchEvent = dispatchEvent(Events.STATE_SWITCH, new StateSwitchEvent(onOutroComplete));
        if (event.cancelled) return;

        super.startOutro(onOutroComplete);
    }

    /**
     * Opens an `FlxSubState` on top of this state.
     * @param subState Substate to open.
     */
    override function openSubState(subState:FlxSubState):Void {
        var event:SubStateEvent = dispatchEvent(Events.SUBSTATE_OPEN, new SubStateEvent(subState));
        if (event.cancelled) return;

        onSubStateOpen(subState);
        super.openSubState(subState);
    }

    /**
     * Closes the substate if one is opened.
     */
    override function closeSubState():Void {
        var event:SubStateEvent = dispatchEvent(Events.SUBSTATE_CLOSE, new SubStateEvent(subState));
        if (event.cancelled) return;

        onSubStateClose(subState);
        super.closeSubState();
    }

    /**
     * Method called when a substate is about to open.
     * @param subState Pending substate.
     */
    function onSubStateOpen(subState:FlxSubState):Void {}

    /**
     * Method called when a substate is about to close.
     * @param subState Pending substate.
     */
    function onSubStateClose(subState:FlxSubState):Void {}

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        dispatchEvent(Events.DESTROY);

        _eventDispatcher = FlxDestroyUtil.destroy(_eventDispatcher);
        super.destroy();
    }

    @:noCompletion private var _eventDispatcher:EventDispatcher = new EventDispatcher();

    @:inheritDoc(funkin.core.scripting.EventDispatcher.addListener)
    public inline function addEventListener(event:String, callback:haxe.Constraints.Function, priority:Int = -1):Void {
        return _eventDispatcher.addListener(event, callback, priority);
    }

    @:inheritDoc(funkin.core.scripting.EventDispatcher.removeListener)
    public inline function removeEventListener(event:String, callback:haxe.Constraints.Function):Bool {
        return _eventDispatcher.removeListener(event, callback);
    }

    @:inheritDoc(funkin.core.scripting.EventDispatcher.hasListener)
    public inline function hasEventListener(event:String, callback:haxe.Constraints.Function):Bool {
        return _eventDispatcher.hasListener(event, callback);
    }

    @:inheritDoc(funkin.core.scripting.EventDispatcher.stopPropagation)
    public inline function stopEventPropagation():Void {
        return _eventDispatcher.stopPropagation();
    }

    @:inheritDoc(funkin.core.scripting.EventDispatcher.dispatch)
    public inline function dispatchEvent(event:String, ?value:Any):Any {
        return _eventDispatcher.dispatch(event, value);
    }
}

/**
 * A substate able to dispatch script events.
 * Most substates of the game inherits from this class.
 * 
 * This object dispatches the following event(s):
 * - `Events.STATE_SWITCH` if opened as a regular state
 * - `Events.UPDATE`
 * - `Events.UPDATE_POST`
 * - `Events.DESTROY`
 */
class ScriptableSubState extends FlxSubState {
    /**
     * Method called by flixel to update the substate.
     * @param elapsed Elapsed time between the last and current frame.
     */
    override function tryUpdate(elapsed:Float):Void {
        if (persistentUpdate || subState == null) {
            dispatchEvent(Events.UPDATE, elapsed);
            update(elapsed);
            dispatchEvent(Events.UPDATE_POST, elapsed);
        }

		if (_requestSubStateReset) {
			_requestSubStateReset = false;
			resetSubState();
		}

		if (subState != null) {
			subState.tryUpdate(elapsed);
		}
    }

    /**
     * Method called by flixel to switch states.
     * @param onOutroComplete Function responsible of switching states.
     */
    override function startOutro(onOutroComplete:Void->Void):Void {
        var event:StateSwitchEvent = dispatchEvent(Events.STATE_SWITCH, new StateSwitchEvent(onOutroComplete));
        if (event.cancelled) return;

        super.startOutro(onOutroComplete);
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        dispatchEvent(Events.DESTROY);
        
        _eventDispatcher = FlxDestroyUtil.destroy(_eventDispatcher);
        super.destroy();
    }

    @:noCompletion private var _eventDispatcher:EventDispatcher = new EventDispatcher();

    @:inheritDoc(funkin.core.scripting.EventDispatcher.addListener)
    public inline function addEventListener(event:String, callback:haxe.Constraints.Function, priority:Int = -1):Void {
        return _eventDispatcher.addListener(event, callback, priority);
    }

    @:inheritDoc(funkin.core.scripting.EventDispatcher.removeListener)
    public inline function removeEventListener(event:String, callback:haxe.Constraints.Function):Bool {
        return _eventDispatcher.removeListener(event, callback);
    }

    @:inheritDoc(funkin.core.scripting.EventDispatcher.hasListener)
    public inline function hasEventListener(event:String, callback:haxe.Constraints.Function):Bool {
        return _eventDispatcher.hasListener(event, callback);
    }

    @:inheritDoc(funkin.core.scripting.EventDispatcher.stopPropagation)
    public inline function stopEventPropagation():Void {
        return _eventDispatcher.stopPropagation();
    }

    @:inheritDoc(funkin.core.scripting.EventDispatcher.dispatch)
    public inline function dispatchEvent(event:String, ?value:Any):Any {
        return _eventDispatcher.dispatch(event, value);
    }
}
