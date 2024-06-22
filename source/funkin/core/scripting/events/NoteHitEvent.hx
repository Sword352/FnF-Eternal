package funkin.core.scripting.events;

import funkin.gameplay.notes.Note;
import funkin.gameplay.components.Rating;

/**
 * Event dispatched whenever a note hit happens in gameplay.
 */
class NoteHitEvent extends ScriptEvent {
    /**
     * Target note.
     */
    @:eventConstructor public var note(default, null):Note;

    /**
     * Whether this note has been hit by the opponent.
     */
    @:eventConstructor public var opponent(default, null):Bool;

    /**
     * Whether the target strumline had cpu set to true.
     */
    @:eventConstructor public var cpu(default, null):Bool;

    /**
     * Rating for this note hit.
     */
    @:eventConstructor public var rating(default, null):Rating = null;

    /**
     * Score gain.
     */
    @:eventConstructor public var score:Float = 0;

    /**
     * Health gain.
     */
    @:eventConstructor public var health:Float = 0;

    /**
     * Accuracy gain.
     */
    @:eventConstructor public var accuracy:Float = 0;

    /**
     * Whether to allow the combo to be displayed.
     */
    @:eventConstructor public var displayCombo:Bool = true;

    /**
     * Whether to pop a splash.
     */
    @:eventConstructor public var displaySplash:Bool = true;

    /**
     * Whether to spawn a hold cover if this is a hold note.
     */
    @:eventConstructor public var spawnCover:Bool = true;

    /**
     * Whether to make a rating popup.
     */
    @:eventConstructor public var displayRating:Bool = true;

    /**
     * Whether to allow accuracy gain.
     */
    @:eventConstructor public var increaseAccuracy:Bool = true;

    /**
     * Whether to allow combo gain.
     */
    @:eventConstructor public var increaseCombo:Bool = true;

    /**
     * Whether to allow hit gain.
     */
    @:eventConstructor public var increaseHits:Bool = true;

    /**
     * Whether to unmute the player vocals.
     */
    @:eventConstructor public var unmutePlayer:Bool = true;

    /**
     * Whether to resize the hold length if this is a hold note.
     */
    @:eventConstructor public var resizeLength:Bool = true;

    /**
     * Whether to update the score text.
     */
    @:eventConstructor public var updateScoreText:Bool = true;

    /**
     * Whether to play the confirm animation on the target receptor.
     */
    @:eventValue public var playConfirm:Bool = true;

    /**
     * Whether to make the characters sing.
     */
    @:eventValue public var characterSing:Bool = true;

    /**
     * Whether to remove the note.
     */
    @:eventValue public var removeNote:Bool = true;

    /**
     * Visibility of the note after it has been hit. Only counts if this is a hold note.
     */
    @:eventValue public var noteVisible:Bool = false;

    /**
     * Volume for the player vocals. Doesn't have an effect if `unmutePlayer` is false.
     */
    @:eventValue public var playerVolume:Float = 1;

    /**
     * Destroys this event.
     */
    override function destroy():Void {
        note = null;
        rating = null;
    }
}
