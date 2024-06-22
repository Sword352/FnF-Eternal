package funkin.gameplay.events;

import funkin.data.ChartFormat.ChartEvent;

/**
 * Base song event class. Extend this to code your song events.
 */
class SongEvent {
    /**
     * Reference to the current relevant event.
     */
    public var currentEvent:ChartEvent;

    /**
     * Quick access to the gameplay instance.
     */
    var game(get, never):PlayState;
    inline function get_game():PlayState
        return PlayState.current;

    public function new():Void {}

    /**
     * Method ran when an event is being executed. Use this for your event's logic.
     */
    public function execute(event:ChartEvent):Void {}
    
    /**
     * Method ran when an event is being preloaded. Use this to preload anything required for your event.
     */
    public function preload(event:ChartEvent):Void {}
    
    /**
     * Destroys this event. Use this to destroy anything if required.
     */
    public function destroy():Void {
        currentEvent = null;
    }
}
