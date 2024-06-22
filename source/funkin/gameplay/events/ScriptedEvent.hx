package funkin.gameplay.events;

#if ENGINE_SCRIPTING
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
            script.call("onPreload", event.arguments);
    }

    override function execute(event:ChartEvent):Void {
        var script:Script = _scripts[event.type];

        if (script != null)
            script.call("onExecution", event.arguments);
    }

    public function add(event:String):Void {
        var path:String = Assets.script("data/events/" + event);

        if (FileTools.exists(path))
            _scripts.set(event, game.scripts.load(path));
        else
            _scripts.set(event, null);
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
#end
