package funkin.core.scripting.events;

#if ENGINE_SCRIPTING
/**
 * Event dispatched whenever a beat happens in gameplay.
 */
class BeatHitEvent extends ScriptEvent {
    /**
     * Current step.
     */
    @:eventConstructor public var step(default, null):Int;

    /**
     * Current beat.
     */
    @:eventConstructor public var beat(default, null):Int;

    /**
     * Current measure.
     */
    @:eventConstructor public var measure(default, null):Int;

    /**
     * Whether to make the camera bump.
     */
    @:eventConstructor public var cameraBump:Bool = true;

    /**
     * Whether to allow characters and stage elements to react.
     */
    @:eventValue public var allowDance:Bool = true;

    /**
     * Whether to allow the HUD icons to bop.
     */
    @:eventValue public var iconBops:Bool = true;
}
#end
