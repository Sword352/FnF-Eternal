package funkin.core.scripting.events;

#if ENGINE_SCRIPTING
import flixel.FlxSubState;

/**
 * Event dispatched when a substate opens or closes.
 */
class SubStateEvent extends ScriptEvent {
    /**
     * Defines whether this is a substate open or close event.
     */
    @:eventConstructor public var action(default, null):SubStateEventAction;

    /**
     * Target substate.
     */
    @:eventConstructor public var subState:FlxSubState;

    override function destroy():Void {
        action = null;
        subState = null;
    }
}

enum abstract SubStateEventAction(String) from String to String {
    var OPEN = "OPEN";
    var CLOSE = "CLOSE";
}
#end
