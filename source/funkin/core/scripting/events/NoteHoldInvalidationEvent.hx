package funkin.core.scripting.events;

import funkin.gameplay.notes.Note;

/**
 * Event dispatched when a hold note is about to be invalidated during gameplay.
 */
class NoteHoldInvalidationEvent extends ScriptEvent {
    /**
     * Note associated with this event.
     */
    public var note(default, null):Note;

    /**
     * Split remaining length of the hold note.
     */
    public var fraction:Float;

    /**
     * Score to lose.
     * NOTE: this is multiplied by the fraction!
     */
    public var scoreLoss:Float = 10;

    /**
     * Health to lose.
     * NOTE: this is multiplied by the fraction!
     */
    public var healthLoss:Float = 0.02375;

    /**
     * By how much the note's sustain alpha should be multiplied.
     */
    public var alphaMultiplier:Float = 0.5;

    /**
     * Whether to break the combo.
     */
    public var breakCombo:Bool = true;

    /**
     * Whether to make the character play a miss animation.
     */
    public var characterMiss:Bool = true;

    /**
     * Whether to make the spectator play the sad animation.
     */
    public var spectatorSad:Bool = true;

    /**
     * Whether to play the miss sound.
     */
    public var playSound:Bool = true;

    /**
     * Whether to mute the player voices.
     */
    public var mutePlayer:Bool = true;

    /**
     * Resets this event.
     * @param note Note associated with this event.
     * @return NoteHoldInvalidationEvent
     */
    public function reset(note:Note):NoteHoldInvalidationEvent {
        this.note = note;

        var remainingLength:Float = note.length - (Conductor.self.time - note.time);
        fraction = (remainingLength / (Conductor.self.beatLength / 2)) + 1;

        scoreLoss = 10;
        healthLoss = 0.02375;
        alphaMultiplier = 0.5;
        breakCombo = true;
        characterMiss = true;
        spectatorSad = true;
        playSound = true;
        mutePlayer = true;

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
