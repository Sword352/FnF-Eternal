package funkin.core.scripting.events;

/**
 * Event dispatched when the countdown is about to start in gameplay.
 */
class CountdownStartEvent extends ScriptEvent {
    /**
     * Asset to use for the countdown sprite.
     */
    public var graphicAsset:String = "game/countdown";

    /**
     * Total amount of ticks the countdown will have.
     */
    public var totalTicks:Int = 4;

    /**
     * Creates a new `CountdownStartEvent`.
     * @param style Style for the graphic asset.
     */
    public function new(?style:String):Void {
        super();

        if (style != null)
            graphicAsset += style;
    }
}
