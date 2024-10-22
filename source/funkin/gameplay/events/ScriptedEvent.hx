package funkin.gameplay.events;

import funkin.data.ChartFormat.ChartEvent;

/**
 * Scripted event executor.
 * NOTE: this does not and shouldn't rely on the macro!
 */
class ScriptedEvent extends SongEvent {
    var _scripts:Map<String, Script> = [];

    override function preload(event:ChartEvent):Void {
        var script:Script = _scripts[event.type];

        if (script != null)
            script.callDyn("onPreload", event.arguments);
    }

    override function execute(event:ChartEvent):Void {
        var script:Script = _scripts[event.type];

        if (script != null)
            script.callDyn("onExecution", event.arguments);
    }

    public function add(event:String):Void {
        _scripts.set(event, game.scripts.load("data/events/" + event));
    }

    override function destroy():Void {
        // this executor can have destroy be called multiple times.
        if (_scripts == null)
            return;

        _scripts.clear();
        _scripts = null;

        super.destroy();
    }
}
