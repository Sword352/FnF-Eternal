package core.scripting.events;

#if ENGINE_SCRIPTING
import gameplay.events.SongEvent;
import globals.ChartFormat.ChartEvent;

/**
 * Event dispatched whenever a song event is going to be preloaded or executed in gameplay.
 */
class SongEventActionEvent extends ScriptEvent {
    /**
     * Target event.
     */
    @:eventConstructor public var event:ChartEvent;

    /**
     * Parent executor for the target event.
     */
    @:eventConstructor public var executor:SongEvent;

    override function destroy():Void {
        event = null;
        executor = null;
    }
}
#end
