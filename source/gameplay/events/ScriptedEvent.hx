package gameplay.events;

#if ENGINE_SCRIPTING
import core.scripting.HScript;
import globals.ChartFormat.ChartEvent;

/**
 * Scripted event executor.
 * NOTE: this does not and shouldn't rely on the macro!
 */
class ScriptedEvent extends BaseSongEvent {
    var _scripts:Map<String, HScript> = [];

    override function preload(event:ChartEvent):Void {
        var script:HScript = _scripts[event.type];

        if (script != null)
            script.call("onPreload", event.arguments);
    }

    override function execute(event:ChartEvent):Void {
        var script:HScript = _scripts[event.type];

        if (script != null)
            script.call("onTrigger", event.arguments);
    }

    public function add(event:String):Void {
        var path:String = Assets.script("data/events/" + event);

        if (FileTools.exists(path))
            _scripts.set(event, game.loadScript(path));
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
