package funkin.core.scripting.events;

import funkin.gameplay.notes.Note;

/**
 * Event dispatched when a note is about to be missed during gameplay.
 */
class NoteMissEvent extends ScriptEvent {
    /**
     * Note associated with this event.
     */
    public var note(default, null):Note;

    /**
     * Whether the note is being held.
     */
    public var holding(default, null):Bool = false;

    /**
     * Score to lose.
     */
    public var scoreLoss:Float = 10;

    /**
     * Health to lose.
     */
    public var healthLoss:Float = 0.02375;

    /**
     * Health the player gains each second by holding this note (if it's a hold note).
     */
    public var holdHealth:Float = 0.05;

    /**
     * Whether to decrease the gameplay accuracy.
     */
    public var decreaseAccuracy:Bool = true;

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
     * Visibility of the note after it has been missed. Only counts if this is a hold note.
     */
    public var noteVisible:Bool = false;

    /**
     * Defines the note's alpha.
     */
    public var noteAlpha:Float = 0.3;

    /**
     * Resets this event.
     * @param note Note associated with this event.
     * @param holding Whether the note is being held.
     * @return NoteMissEvent
     */
    public function reset(note:Note, holding:Bool = false):NoteMissEvent {
        this.note = note;
        this.holding = holding;

        scoreLoss = 10;
        healthLoss = 0.02375;
        holdHealth = 0.05;
        noteAlpha = 0.3;

        decreaseAccuracy = true;
        characterMiss = true;
        spectatorSad = true;
        playSound = true;
        mutePlayer = true;
        noteVisible = false;

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
