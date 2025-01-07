package funkin.core.scripting.events;

/**
 * Event dispatched before a countdown tick in gameplay.
 */
class CountdownTickEvent extends ScriptEvent {
    /**
     * Current countdown tick.
     */
    public var tick(default, null):Int;

    /**
     * Sound to play.
     */
    public var soundAsset:String = null;

    /**
     * Current frame for the countdown sprite. Setting it to -1 hides the sprite.
     */
    public var spriteFrame:Int = -1;

    /**
     * Creates a new `CountdownTickEvent`.
     * @param tick Current countdown tick.
     * @param sound Sound to play.
     * @param spriteFrame Current frame for the countdown sprite.
     */
    public function new(tick:Int, ?sound:String, spriteFrame:Int = -1):Void {
        this.tick = tick;
        this.soundAsset = sound;
        this.spriteFrame = spriteFrame;
        super();
    }
}
