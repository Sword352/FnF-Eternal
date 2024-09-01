package funkin.core.scripting.events;

import funkin.gameplay.notes.Note;

/**
 * Event dispatched when a note miss happens in gameplay.
 */
class NoteMissEvent extends ScriptEvent {
    /**
     * Target note.
     */
    @:eventConstructor public var note(default, null):Note;

    /**
     * Whether this note is being held.
     */
    @:eventConstructor public var holding(default, null):Bool = false;

    /**
     * Score to lose.
     */
    @:eventValue public var scoreLoss:Float = 10;

    /**
     * Health to lose.
     */
    @:eventValue public var healthLoss:Float = 0.0475;

    /**
     * Health the player gains each second by holding this note (if it's a hold note).
     */
    @:eventValue public var holdHealth:Float = 0.1;

    /**
     * Whether to increase the total amount of misses.
     */
    @:eventValue public var increaseMisses:Bool = true;

    /**
     * Whether to decrease the gameplay accuracy.
     */
    @:eventValue public var decreaseAccuracy:Bool = true;

    /**
     * Whether to break the player's combo.
     */
    @:eventValue public var breakCombo:Bool = true;

    /**
     * Whether to make the character play a miss animation.
     */
    @:eventValue public var characterMiss:Bool = true;

    /**
     * Whether to make the spectator play the sad animation.
     */
    @:eventValue public var spectatorSad:Bool = true;

    /**
     * Whether to play the miss sound.
     */
    @:eventValue public var playSound:Bool = true;

    /**
     * Default volume for the miss sound.
     */
    @:eventValue public var soundVolume:Float = 0.1;

    /**
     * How much can the miss sound's volume vary.
     */
    @:eventValue public var soundVolDiff:Float = 0.1;

    /**
     * Volume of the players vocal.
     */
    @:eventValue public var playerVolume:Float = 0;

    /**
     * Visibility of the note after it has been missed. Only counts if this is a hold note.
     */
    @:eventValue public var noteVisible:Bool = false;

    /**
     * Defines the note's alpha.
     */
    @:eventValue public var noteAlpha:Float = 0.3;

    override function destroy():Void {
        note = null;
    }
}
