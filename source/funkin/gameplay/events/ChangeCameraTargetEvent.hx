package funkin.gameplay.events;

import funkin.data.ChartFormat.ChartEvent;
import funkin.gameplay.components.Character;

/**
 * Change camera target event. Changes the camera's focus.
 * 
 * TODO:
 * - switch from an int value to a string
 * - rename this to "Change Camera Focus"
 */
@:build(funkin.core.macros.SongEventMacro.build({
    type: "change camera target",
    name: "Change Camera Target",
    arguments: [
        {name: "Target Character", type: "Int", tempValue: "0"},
        {name: "Snap?", type: "Bool", tempValue: "false"}
    ]
}))
class ChangeCameraTargetEvent extends SongEvent {
    override function execute(event:ChartEvent) {
        var target:Character = getCharacter(targetCharacter);
        if (target == null) return;

        game.cameraFocus = target;
        if (snap) game.snapCamera();
    }

    inline function getCharacter(character:Int):Character {
        return switch (character) {
            case 1: game.spectator;
            case 2: game.player;
            case _: game.opponent;
        }
    }
}
