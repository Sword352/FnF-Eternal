package funkin.gameplay.events;

import funkin.data.ChartFormat.ChartEvent;

/**
 * Change BPM event. Changes the BPM during playback.
 */
@:build(funkin.core.macros.SongEventMacro.build({
    type: "change bpm",
    name: "Change BPM",
    arguments: [
        {name: "New BPM", type: "Float", tempValue: "100"},
        {name: "Beats per measure", type: "Int", tempValue: "4"}
    ]
}))
class ChangeBpmEvent extends SongEvent {
    // handled by conductor, this class won't stay for long
}
