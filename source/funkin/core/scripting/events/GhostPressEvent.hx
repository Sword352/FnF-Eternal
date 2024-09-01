package funkin.core.scripting.events;

/**
 * Event dispatched when a ghost press happens in gameplay.
 */
class GhostPressEvent extends ScriptEvent {
    /**
     * Direction.
     */
    @:eventConstructor public var direction:Int;

    /**
     * Whether ghost tapping is allowed.
     */
    @:eventConstructor public var ghostTapping:Bool;

    /**
     * Score to lose.
     */
    @:eventValue public var scoreLoss:Float = 10;

    /**
     * Health to lose.
     */
    @:eventValue public var healthLoss:Float = 0.0475;

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
     * Whether to play the press animation on the target receptor.
     */
    @:eventValue public var playPress:Bool = true;

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
}
