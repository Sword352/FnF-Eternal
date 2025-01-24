package funkin.gameplay.events;

import funkin.data.ChartFormat.ChartEvent;
import funkin.utils.TimingTools;

/**
 * Event runner which executes song events during gameplay.
 * This object dispatches the following event(s):
 * - `GameEvents.EVENT_EXECUTION`
 * - `GameEvents.EVENT_PRELOAD`
 */
@:build(funkin.core.macros.ScriptMacros.buildEventDispatcher())
class SongEventExecutor extends FlxBasic {
    /**
     * Conductor this object will listen to.
     */
    public var conductor:Conductor = Conductor.self;

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
     * Cached script event object.
     */
    var _scriptEvent:SongEventScriptEvent = new SongEventScriptEvent();

    /**
     * Creates a `SongEventExecutor` instance.
     */
    public function new():Void {
        super();
        visible = false;

        _events = PlayState.song.events;
        TimingTools.sort(_events);

        _executors = [];

        for (event in _events) {
            if (_executors.exists(event.type)) {
                preloadEvent(event);
                continue;
            }

            var cls:Class<SongEvent> = SongEventList.list.get(event.type);

            if (cls != null)
                _executors.set(event.type, Type.createInstance(cls, []));
            else
                findScriptedExecutor(event.type);

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
            if (relevantEvent.time > conductor.time) break;

            executeEvent(relevantEvent);
            _currentEvent++;
        }

        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end
    }

    /**
     * Executes an event.
     * @param event Event to execute
     */
    function executeEvent(event:ChartEvent):Void {
        var executor:SongEvent = _executors[event.type];
        if (executor == null) return;

        dispatchEvent(GameEvents.EVENT_EXECUTION, _scriptEvent.reset(event, executor));
        if (_scriptEvent.cancelled) return;

        executor.currentEvent = event;
        executor.execute(event);
    }

    /**
     * Preloads an event.
     * @param event Event to preload
     */
    function preloadEvent(event:ChartEvent):Void {
        var executor:SongEvent = _executors[event.type];
        if (executor == null) return;

        dispatchEvent(GameEvents.EVENT_PRELOAD, _scriptEvent.reset(event, executor));
        if (_scriptEvent.cancelled) return;
        
        executor.currentEvent = event;
        executor.preload(event);
    }

    /**
     * Attemps to find and create a scripted event executor if no executor is available for a specific event type.
     * @param event Event type.
     */
    function findScriptedExecutor(event:String):Void {
        // set to null just in case there was no scripted executor, so that we don't re-attemp to find one
        _executors.set(event, null);

        var script:Script = ScriptManager.getScript(event);
        if (script == null) return;

        var executor:SongEvent = script.buildClass(SongEvent);
        if (executor != null) _executors.set(event, executor);
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        _scriptEvent = FlxDestroyUtil.destroy(_scriptEvent);

        for (executor in _executors)
            executor?.destroy();
        
        _executors = null;
        conductor = null;
        _events = null;
        
        super.destroy();
    }
}
