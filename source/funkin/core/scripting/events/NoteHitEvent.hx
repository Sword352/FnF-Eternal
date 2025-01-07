package funkin.core.scripting.events;

import funkin.gameplay.notes.Note;
import funkin.gameplay.components.Rating;

/**
 * Event dispatched when a `StrumLine` hits a note, typically during gameplay.
 */
class NoteHitEvent extends ScriptEvent {
    /**
     * Note associated with this event.
     */
    public var note(default, null):Note;

    /**
     * Rating for this note hit.
     */
    public var rating:Rating;

    /**
     * Score gain.
     */
    public var score:Float = 0;

    /**
     * Health gain.
     */
    public var health:Float = 0;

    /**
     * Amount of health gained each second while holding this note, if it's a hold note.
     */
    public var holdHealth:Float = 0;

    /**
     * Accuracy gain.
     */
    public var accuracy:Null<Float> = 0;

    /**
     * Current combo count.
     */
    public var combo:Int = 0;

    /**
     * Whether to pop a splash.
     */
    public var displaySplash:Bool = true;

    /**
     * Whether to unmute the player vocals.
     */
    public var unmutePlayer:Bool = true;

    /**
     * Whether to play the confirm animation on the target receptor.
     */
    public var playConfirm:Bool = true;

    /**
     * Whether to make the characters sing.
     */
    public var characterSing:Bool = true;

    /**
     * Whether to remove the note.
     */
    public var removeNote:Bool = true;

    /**
     * Visibility of the note after it has been hit. Only counts if this is a hold note.
     */
    public var noteVisible:Bool = false;

    /**
     * Resets this event.
     * @param note Note associated with this event.
     * @param combo Current combo count.
     * @return NoteHitEvent
     */
    public function reset(note:Note, combo:Int):NoteHitEvent {
        this.note = note;
        this.combo = combo;

        score = 0;
        health = 0;
        accuracy = null;
        rating = null;

        if (!note.strumLine.cpu) {
            rating = PlayState.self.stats.evaluateNote(note);

            score = rating.score;
            accuracy = rating.accuracyMod;
            health = rating.health;

            if (rating.breakCombo)
                this.combo = 0;
            else
                this.combo++;
        }
        else if (note.strumLine.owner == PLAYER) {
            health = PlayState.self.stats.ratings[0].health;
        }

        holdHealth = Math.max(health * 10, 0);

        displaySplash = (!note.strumLine.cpu && rating.displaySplash && !Options.noNoteSplash);
        unmutePlayer = (note.strumLine.owner != OPPONENT || PlayState.self.music.voices?.length == 1);

        playConfirm = true;
        characterSing = true;
        removeNote = true;
        noteVisible = false;

        cancelled = false;
        return this;
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        rating = null;
        note = null;
    }
}
