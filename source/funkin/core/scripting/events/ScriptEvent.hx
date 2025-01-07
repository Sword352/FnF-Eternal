package funkin.core.scripting.events;

/**
 * Base event class for all scripting events.
 */
class ScriptEvent implements IFlxDestroyable {
    /**
     * Determines whether this event has been cancelled.
     */
    public var cancelled:Bool = false;

    public function new():Void {}

    /**
     * Cancels this event and skips the default behavior entirely.
     */
    public function cancel():Void {
        cancelled = true;
    }

    /**
     * Clean up memory.
     */
    public function destroy():Void {}
}
