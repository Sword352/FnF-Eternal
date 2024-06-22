package funkin.core.scripting.events;

/**
 * Event dispatched whenever the song ends in gameplay.
 */
class SongEndEvent extends ScriptEvent {
    /**
     * Unlocked week.
     */
    @:eventConstructor public var unlockedWeek:String;

    /**
     * Whether to save the song score.
     */
    @:eventConstructor public var saveScore:Bool;

    /**
     * Whether to reset the amount of chained losses.
     */
    @:eventValue public var resetLossCount:Bool = true;

    /**
     * Whether to immediatly leave the gameplay state.
     */
    @:eventValue public var leaveState:Bool = true;

    override function destroy():Void {
        unlockedWeek = null;
    }
}
