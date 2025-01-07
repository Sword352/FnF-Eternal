package funkin.core.scripting.events;

import funkin.gameplay.events.SongEvent;
import funkin.data.ChartFormat.ChartEvent;

/**
 * Event dispatched when a song event is about to be executed or preloaded during gameplay.
 */
class SongEventScriptEvent extends ScriptEvent {
    /**
     * Song event associated with this event.
     */
    public var event:ChartEvent;

    /**
     * Parent executor for the song event.
     */
    public var executor:SongEvent;

    /**
     * Resets this event.
     * @param event Song event associated with this event.
     * @param executor Parent executor for the song event.
     * @return SongEventScriptEvent
     */
    public function reset(event:ChartEvent, executor:SongEvent):SongEventScriptEvent {
        this.event = event;
        this.executor = executor;
        cancelled = false;
        return this;
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        executor = null;
        event = null;
    }
}
