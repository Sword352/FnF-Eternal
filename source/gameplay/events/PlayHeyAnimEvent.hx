package gameplay.events;

/**
 * Play hey anim event. Makes a character play the "Hey!" animation if available, for a short amount of time.
 */
@:build(core.macros.SongEventMacro.build({
    name: "Play \"Hey!\" Animation",
    type: "play hey anim",
    arguments: [
        {name: "Character", type: "List", tempValue: "Player", list: ["Opponent", "Spectator", "Player"]},
        {name: "Duration in beats", type: "Float", tempValue: "1"}
    ]
}))
class PlayHeyAnimEvent extends BaseSongEvent {
    override function execute(_):Void {
        var target:Character = getCharacter(character);
        if (target == null) return;

        target.playAnimation("hey", true);
        target.animEndTime = game.conductor.crochet * durationInBeats / 1000;
    }

    inline function getCharacter(value:String):Character {
        return switch (value) {
            case "Player": game.player;
            case "Spectator": game.spectator;
            case _: game.opponent;
        }
    }
}
