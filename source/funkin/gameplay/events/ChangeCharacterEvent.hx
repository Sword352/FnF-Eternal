package funkin.gameplay.events;

import funkin.gameplay.notes.StrumLine;
import funkin.gameplay.components.Character;

/**
 * Change character event. Changes the opponent/spectator/player into another character.
 */
@:build(funkin.core.macros.SongEventMacro.build({
    type: "change character",
    name: "Change Character",
    arguments: [
        {name: "Target", type: "List", tempValue: "Opponent", list: ["Opponent", "Spectator", "Player"]},
        {name: "To", type: "String", tempValue: "?"}
    ]
}))
class ChangeCharacterEvent extends SongEvent {
    /**
     * Internal character storage.
     */
    var _characters:Map<String, Map<String, Character>> = [];

    override function preload(_):Void {
        if (_characters[target] == null)
            _characters.set(target, []);

        switch (target) {
            case "Opponent":
                if (game.opponent?.character == to)
                    _characters[target].set(to, game.opponent);
            case "Spectator":
                if (game.spectator?.character == to)
                    _characters[target].set(to, game.spectator);
            case "Player":
                if (game.player?.character == to)
                    _characters[target].set(to, game.player);
        }

        if (_characters[target].exists(to))
            return;

        var character:Character = Character.create(0, 0, to);
        _characters[target].set(to, character);

        // preload the health icon
        if (character.healthIcon != null)
            Paths.image('icons/${character.healthIcon}');

        // hide the character while still allowing it to preload (TODO: find a smarter solution)
        character.alpha = 0.0000001;

        var targetCharacter:Character = getTarget(target);

        if (targetCharacter != null)
            game.insert(game.members.indexOf(targetCharacter) + 1, character);
        else
            game.add(character);
    }

    override function execute(_):Void {
        var intended:Character = _characters[target]?.get(to);
        if (intended == null) return;

        var targetCharacter:Character = getTarget(target);
        var targetStrumline:StrumLine = getStrumline(target);

        if (targetCharacter != null) {
            intended.setPosition(targetCharacter.x, targetCharacter.y + targetCharacter.height - intended.height);

            // hide the character.
            targetStrumline?.characters.remove(targetCharacter);
            targetCharacter.alpha = 0;

            // update the camera position if the old character is the current focus.
            if (game.cameraFocus == targetCharacter)
                game.cameraFocus = intended;

            // play the corresponding animation.
            if (targetCharacter.animState != DANCING)
                intended.playAnim(targetCharacter.animation.name, targetCharacter.animState, targetCharacter.animTime, targetCharacter.animDuration);
            else
                intended.forceDance(game.conductor.beat, true);
        }

        intended.alpha = 1;

        switch (target) {
            case "Player":
                game.playField.healthBar.playerColor = intended.healthBarColor;
                game.playField.playerIcon.character = intended.healthIcon;
                game.player = intended;
            case "Opponent":
                game.playField.healthBar.opponentColor = intended.healthBarColor;
                game.playField.opponentIcon.character = intended.healthIcon;
                game.opponent = intended;
            case "Spectator":
                game.spectator = intended;
        }

        targetStrumline?.characters.push(intended);
    }

    override function destroy():Void {
        for (map in _characters)
            map.clear();

        _characters.clear();
        _characters = null;

        super.destroy();
    }

    inline function getTarget(target:String):Character {
        return switch (target) {
            case "Player": game.player;
            case "Spectator": game.spectator;
            case _: game.opponent;
        }
    }

    inline function getStrumline(target:String):StrumLine {
        return switch (target) {
            case "Player": game.playField.playerStrumLine;
            case "Opponent": game.playField.opponentStrumLine;
            case _: null;
        }
    }
}
