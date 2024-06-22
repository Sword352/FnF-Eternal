package funkin.gameplay.events;

import funkin.data.ChartFormat.ChartEvent;

/**
 * Change BPM event. Changes the BPM during playback.
 * 
 * TODO:
 * - make it be able to modify the time signature to
 * - rename this to "Timing Point"
 */
@:build(core.macros.SongEventMacro.build({
    type: "change bpm",
    name: "Change BPM",
    arguments: [{
        name: "New BPM",
        type: "Float",
        tempValue: "100"
    }]
}))
class ChangeBpmEvent extends SongEvent {
    override function execute(event:ChartEvent):Void {
        game.conductor.beatOffset.step += (event.time - game.conductor.beatOffset.time) / game.conductor.stepCrochet;
        game.conductor.beatOffset.time = event.time;
        game.conductor.bpm = newBpm;
    }
}
