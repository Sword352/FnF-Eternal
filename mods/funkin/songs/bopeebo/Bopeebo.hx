import funkin.gameplay.PlayState;
import funkin.core.scripting.Events;
import funkin.core.scripting.Element.SongElement;

class Bopeebo extends SongElement {
    public function new():Void {
        super("bopeebo");
    }

    override function onGameplayStart():Void {
        PlayState.self.addEventListener(Events.BEAT_HIT, onBeatHit);
    }

    function onBeatHit(beat):Void {
        if (beat <= 0 || beat % 8 != 7)
            return;

        if (StringTools.startsWith(game.player.animation.name, "miss")) {
            // game.stats.health = Math.max(game.stats.health, 1);
            return;
        }

        game.spectator.playSpecialAnim("hey", game.conductor.crotchet);
        game.player.playSpecialAnim("hey", game.conductor.crotchet);

        game.camGame.zoom += 0.12;
    }
}
