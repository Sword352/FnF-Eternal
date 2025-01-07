package funkin.core.scripting.events;

/**
 * Event dispatched when a ghost press happens during gameplay.
 */
class GhostPressEvent extends ScriptEvent {
    /**
     * Direction associated with this event.
     */
    public var direction:Int;

    /**
     * Whether ghost tapping is allowed.
     */
    public var ghostTapping:Bool;

    /**
     * Score to lose.
     */
    public var scoreLoss:Float = 10;

    /**
     * Health to lose.
     */
    public var healthLoss:Float = 0.02375;

    /**
     * Whether to break the player's combo.
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
     * Whether to play the press animation on the target receptor.
     */
    public var playPress:Bool = true;

    /**
     * Whether to mute the player voices.
     */
    public var mutePlayer:Bool = true;

    /**
     * Resets this event.
     * @param direction Direction associated with this event.
     * @param ghostTapping Whether ghost tapping is allowed.
     * @return GhostPressEvent
     */
    public function reset(direction:Int, ghostTapping:Bool):GhostPressEvent {
        this.direction = direction;
        this.ghostTapping = ghostTapping;

        scoreLoss = 10;
        healthLoss = 0.02375;
        breakCombo = true;
        characterMiss = true;
        spectatorSad = true;
        playSound = true;
        playPress = true;
        mutePlayer = true;

        cancelled = false;
        return this;
    }
}
