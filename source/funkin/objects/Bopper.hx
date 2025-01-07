package funkin.objects;

/**
 * Simple `OffsetSprite` extension with the ability to play specific animations on beat.
 */
class Bopper extends OffsetSprite {
    /**
     * Animations to play on beat.
     */
    public var danceSteps:Array<String> = [];

    /**
     * Defines how many `X` beats an animation should be played.
     */
    public var danceInterval:Float = 1;

    /**
     * Plays a beat animation.
     * @param beat Current beat.
     * @param forced Whether the animation is forced to be played.
     */
    public function dance(beat:Float, forced:Bool = false):Void {
        if (beat % danceInterval == 0)
            playAnimation(danceSteps[Math.floor(beat / danceInterval) % danceSteps.length], forced);
    }

    /**
     * Plays the first dance animation.
     */
    public function resetDance():Void {
        playAnimation(danceSteps[0], true);
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        danceSteps = null;
        super.destroy();
    }
}
