package funkin.core.scripting.events;

import funkin.gameplay.notes.Note;

/**
 * Event dispatched when a hold note gets invalidated in gameplay.
 */
class NoteHoldInvalidationEvent extends ScriptEvent {
    /**
     * Target note.
     */
    @:eventConstructor public var note(default, null):Note;

    /**
     * Split remaining length of the hold note.
     */
    @:eventConstructor public var fraction:Float;

    /**
     * Score to lose. NOTE: this is multiplied by the fraction!
     */
    @:eventValue public var scoreLoss:Float = 10;

    /**
     * Health to lose. NOTE: this is multiplied by the fraction!
     */
    @:eventValue public var healthLoss:Float = 0.0475;

    /**
     * Whether to decrease the gameplay accuracy.
     */
    @:eventValue public var decreaseAccuracy:Bool = true;

    /**
     * Whether to break the combo.
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
    @:eventValue public var soundVolume:Float = 0.4;

    /**
     * How much can the miss sound's volume vary.
     */
    @:eventValue public var soundVolDiff:Float = 0.1;

    /**
     * Volume for the player vocals.
     */
    @:eventValue public var playerVolume:Float = 0;

    override function destroy():Void {
        note = null;
    }
}
