package funkin.gameplay.events;

import funkin.gameplay.components.Character;

/**
 * Play hey anim event. Makes a character play the "Hey!" animation if available, for a short amount of time.
 */
@:build(funkin.core.macros.SongEventMacro.build({
    name: "Play \"Hey!\" Animation",
    type: "play hey anim",
    arguments: [
        {name: "Character", type: "List", tempValue: "Player", list: ["Opponent", "Spectator", "Player"]},
        {name: "Duration", type: "Float", tempValue: "1", unit: "beats", list: null} // must provide null list (TODO: figure out why)
    ]
}))
class PlayHeyAnimEvent extends SongEvent {
    override function execute(_):Void {
        var target:Character = getCharacter(character);
        target?.playSpecialAnim("hey", game.conductor.beatLength * duration);
    }

    inline function getCharacter(value:String):Character {
        return switch (value) {
            case "Player": game.player;
            case "Spectator": game.spectator;
            case _: game.opponent;
        }
    }
}
