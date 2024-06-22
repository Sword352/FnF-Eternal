package funkin.core.scripting.events;

#if ENGINE_SCRIPTING
/**
 * Basic scripting event class.
 */
@:autoBuild(funkin.core.macros.ScriptEventMacro.build())
class ScriptEvent implements IFlxDestroyable {
    /**
     * Defines whether this event has been cancelled.
     */
    public var cancelled:Bool = false;

    /**
     * Defines whether this event should propagate.
     */
    public var propagate:Bool = true;

    public function new():Void {}

    /**
     * Sets `propagate` to false.
     */
    public function stopPropagation():Void {
        propagate = false;
    }

    /**
     * Sets `cancelled` to true.
     */
    public function cancel():Void {
        cancelled = true;
    }

    /**
     * Reset properties for this event so that it can be re-used.
     */
    public function reset():Void {
        cancelled = false;
        propagate = true;
    }

    /**
     * Puts this event to the global pool.
     */
    public inline function put():Void {
        Events.put(this);
    }

    /**
     * Destroys this event instance, meaning it can't be used anymore.
     */
    public function destroy():Void {

    }
}
#end
