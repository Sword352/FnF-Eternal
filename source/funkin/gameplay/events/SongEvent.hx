package funkin.gameplay.events;

import funkin.data.ChartFormat.ChartEvent;

/**
 * Base song event class.
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
        return PlayState.self;

    public function new():Void {}

    /**
     * Method ran when an event is being executed.
     */
    public function execute(event:ChartEvent):Void {}
    
    /**
     * Method ran when an event is being preloaded.
     */
    public function preload(event:ChartEvent):Void {}
    
    /**
     * Destroys this event.
     */
    public function destroy():Void {
        currentEvent = null;
    }
}
