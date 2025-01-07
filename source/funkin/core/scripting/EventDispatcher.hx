package funkin.core.scripting;

import haxe.Constraints.Function;

/**
 * Object used for registering listeners and dispatching events.
 * Listeners are callbacks tied to a specific event.
 * Dispatching an event fires all of the listeners that were listening to it.
 */
@:noCustomClass
class EventDispatcher implements IFlxDestroyable {
    /**
     * Internal listener container.
     */
    var _listeners:Map<String, Array<Function>>;

    /**
     * Internal flag which determines whether the current `dispatch` call should stop, usually done by calling the `stopPropagation` method.
     */
    var _stopPropagation:Bool;
    
    /**
     * Creates a new `EventDispatcher`.
     */
    public function new():Void {
        _listeners = new Map();
    }

    /**
     * Registers an event listener.
     * @param event Event to listen to.
     * @param callback Callback to fire when dispatching the event.
     * @param priority Priority of the callback. If equal to `-1`, the callback is inserted behind every other callbacks.
     */
    public function addListener(event:String, callback:Function, priority:Int = -1):Void {
        if (event == null || callback == null) return;
        
        var listeners:Array<Function> = _listeners.get(event);
        if (listeners == null) _listeners.set(event, listeners = []);

        // insert backwards so that listeners can be removed during dispatch() calls
        if (priority == -1) priority = 0;
        else priority = listeners.length - priority;

        listeners.insert(priority, callback);
    }

    /**
     * Removes an event listener.
     * @param event Event containing the callback to remove.
     * @param callback Callback to remove.
     * @return `true` if the listener was existant and removed, `false` otherwise.
     */
    public function removeListener(event:String, callback:Function):Bool {
        var listeners:Array<Function> = _listeners.get(event);
        if (listeners == null) return false;
        return listeners.remove(callback);
    }

    /**
     * Returns whether an event listener has been registered.
     * @param event Target event.
     * @param callback Callback to check.
     * @return Bool
     */
    public function hasListener(event:String, callback:Function):Bool {
        var listeners:Array<Function> = _listeners.get(event);
        if (listeners == null) return false;
        return listeners.contains(callback);
    }

    /**
     * Immediatly stops dispatching the current event.
     */
    public inline function stopPropagation():Void {
        _stopPropagation = true;
    }

    /**
     * Fires all of the listeners for a specific event.
     * @param event Event to dispatch.
     * @param value Optional value to pass to the listeners.
     * @return Dispatched value.
     */
    public function dispatch(event:String, ?value:Any):Any {
        var listeners:Array<Function> = _listeners.get(event);
        if (listeners == null) return value;

        _stopPropagation = false;

        var current:Int = listeners.length - 1;

        while (current >= 0) {
            var listener:Function = listeners[current];

            if (value != null)
                listener(value);
            else
                listener();

            // if `stopPropagation` has been called by one of the listener, stop dispatching
            if (_stopPropagation)
                break;

            current--;
        }

        return value;
    }

    /**
     * Destroys this `EventDispatcher`.
     */
    public function destroy():Void {
        _listeners = null;
    }
}
