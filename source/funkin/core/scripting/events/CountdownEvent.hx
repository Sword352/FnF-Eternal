package funkin.core.scripting.events;

/**
 * Event dispatched whenever a countdown starts or a countdown tick happens in gameplay.
 */
class CountdownEvent extends ScriptEvent {
    /**
     * Defines whether this is a countdown start or tick event.
     */
    @:eventConstructor public var action(default, null):CountdownAction;

    /**
     * Current countdown tick.
     */
    @:eventConstructor public var tick(default, null):Int = -1;

    /**
     * Graphic asset for the countdown sprite.
     */
    @:eventConstructor public var graphicAsset:String = null;

    /**
     * Sound to play this tick.
     */
    @:eventConstructor public var soundAsset:String = null;

    /**
     * Current frame for the countdown sprite. Setting it to -1 hides the sprite.
     */
    @:eventConstructor public var spriteFrame:Int = -1;

    /**
     * Whether to change the Discord rich presence on available platforms.
     */
    @:eventValue public var changePresence:Bool = true;

    /**
     * Whether to allow beat events during the countdown, such as characters dancing.
     */
    @:eventValue public var allowBeatEvents:Bool = true;

    /**
     * Whether to allow the countdown sprite to tween.
     */
    @:eventValue public var allowTween:Bool = true;

    /**
     * Total amount of ticks.
     */
    @:eventValue public var totalTicks:Int = 4;

    /**
     * Destroys this event.
     */
    override function destroy():Void {
        action = null;
        graphicAsset = null;
        soundAsset = null;
    }
}

enum abstract CountdownAction(String) to String {
    var START = "START";
    var TICK = "TICK";
}
