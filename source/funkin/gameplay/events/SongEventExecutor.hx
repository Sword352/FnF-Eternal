package funkin.gameplay.events;

import flixel.FlxBasic;
import funkin.data.ChartFormat.ChartEvent;

/**
 * Event runner which executes song events during gameplay.
 */
class SongEventExecutor extends FlxBasic {
    /**
     * Stored event executors.
     */
    var _executors:Map<String, SongEvent>;

    /**
     * Internal reference to the song events.
     */
    var _events:Array<ChartEvent>;

    /**
     * Internal counter which track the next event to execute.
     */
    var _currentEvent:Int = 0;

    /**
     * Creates a `SongEventExecutor` instance.
     */
    public function new():Void {
        super();
        visible = false;

        _events = PlayState.song.events;
        _events.sort((a, b) -> Std.int(a.time - b.time));

        _executors = [];

        #if ENGINE_SCRIPTING
        // declare the executor so scripted events share the same
        var scriptedExecutor:ScriptedEvent = null;
        #end

        for (event in _events) {
            if (_executors.exists(event.type)) {
                preloadEvent(event);
                continue;
            }

            var cls:Class<SongEvent> = EventList.list.get(event.type);

            if (cls != null)
                _executors.set(event.type, Type.createInstance(cls, []));
            else {
                #if ENGINE_SCRIPTING
                if (scriptedExecutor == null)
                    scriptedExecutor = new ScriptedEvent();

                _executors.set(event.type, scriptedExecutor);
                scriptedExecutor.add(event.type);
                #else
                _executors.set(event.type, null);
                #end
            }

            preloadEvent(event);
        }

        // if the first event's time is less than 10ms, it means that it has to be executed immediatly.
        if (_events[0]?.time <= 10) {
            executeEvent(_events[0]);
            _currentEvent++;
        }
    }

    /**
     * Update behaviour.
     */
    override function update(elapsed:Float):Void {
        while (_currentEvent < _events.length) {
            var relevantEvent:ChartEvent = _events[_currentEvent];
            if (relevantEvent.time > Conductor.self.time) break;

            executeEvent(relevantEvent);
            _currentEvent++;
        }

        super.update(elapsed);
    }

    /**
     * Executes an event.
     * @param event Event to execute
     */
    function executeEvent(event:ChartEvent):Void {
        var executor:SongEvent = _executors[event.type];
        if (executor == null) return;

        var scriptEvent:SongEventActionEvent = PlayState.current.scripts.dispatchEvent("onEventExecution", Events.get(SongEventActionEvent).setup(event, executor));
        if (scriptEvent.cancelled) return;

        executor.currentEvent = event;
        executor.execute(event);

        PlayState.current.stage.onEventExecution(event);
    }

    /**
     * Preloads an event.
     * @param event Event to preload
     */
    function preloadEvent(event:ChartEvent):Void {
        var executor:SongEvent = _executors[event.type];
        if (executor == null) return;

        var scriptEvent:SongEventActionEvent = PlayState.current.scripts.dispatchEvent("onEventPreload", Events.get(SongEventActionEvent).setup(event, executor));
        if (scriptEvent.cancelled) return;
        
        executor.currentEvent = event;
        executor.preload(event);

        PlayState.current.stage.onEventPreload(event);
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        for (executor in _executors)
            executor.destroy();

        _executors.clear();
        _executors = null;

        _events = null;
        super.destroy();
    }
}
