package funkin.core.scripting.events;

import funkin.gameplay.notes.Note;

/**
 * Event dispatched when a note is being held in gameplay.
 */
class NoteHoldEvent extends ScriptEvent {
    /**
     * Target hold note.
     */
    @:eventConstructor public var note(default, null):Note;

    /**
     * Whether the parent of the hold note is the opponent.
     */
    @:eventConstructor public var opponent(default, null):Bool;

    /**
     * Whether the target strumline had cpu enabled.
     */
    @:eventConstructor public var cpu(default, null):Bool;

    /**
     * Health gain.
     */
    @:eventConstructor public var health:Float = 0.023;

    /**
     * Whether to unmute the player vocals.
     */
    @:eventConstructor public var unmutePlayer:Bool = true;

    /**
     * Whether a hold note cover should be spawned.
     */
    @:eventConstructor public var spawnCover:Bool = true;

    /**
     * Whether to make the characters sing.
     */
    @:eventValue public var characterSing:Bool = true;

    /**
     * Whether to play the confirm animation on the target receptor.
     */
    @:eventValue public var playConfirm:Bool = true;

    /**
     * Volume for the player vocals.
     */
    @:eventValue public var playerVolume:Float = 1;

    override function destroy():Void {
        note = null;
    }
}
