package funkin.core.scripting.events;

import funkin.gameplay.notes.Note;

/**
 * Event dispatched when a note is being held during gameplay.
 */
class NoteHoldEvent extends ScriptEvent {
    /**
     * Note associated with this event.
     */
    public var note(default, null):Note;

    /**
     * Whether to make the characters sing.
     */
    public var characterSing:Bool = false;

    /**
     * Whether to unmute the player vocals.
     */
    public var unmutePlayer:Bool = true;

    /**
     * Whether to play the confirm animation on the target receptor.
     */
    public var playConfirm:Bool = true;

    /**
     * Resets this event.
     * @param note Note associated with this event.
     * @return NoteHoldEvent
     */
    public function reset(note:Note):NoteHoldEvent {
        this.note = note;

        characterSing = note.missed;
        unmutePlayer = (note.strumLine.owner != OPPONENT || PlayState.self.music.voices?.length == 1);
        playConfirm = true;

        cancelled = false;
        return this;
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        note = null;
    }
}
