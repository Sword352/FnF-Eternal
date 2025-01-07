package funkin.core.scripting.events;

import flixel.FlxSubState;

/**
 * Event dispatched when a substate is about to open or close.
 */
class SubStateEvent extends ScriptEvent {
    /**
     * Substate that is about to open/close.
     */
    public var subState:FlxSubState;

    /**
     * Creates a new `SubStateEvent`.
     * @param subState Substate that is about to open/close.
     */
    public function new(subState:FlxSubState):Void {
        this.subState = subState;
        super();
    }
}
