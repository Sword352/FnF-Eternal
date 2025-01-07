import funkin.utils.Tools;
import funkin.gameplay.PlayState;
import funkin.core.scripting.Events;
import funkin.core.scripting.Events.GameEvents;
import funkin.core.scripting.Element.SongElement;

class Tutorial extends SongElement {
    public function new():Void {
        super("tutorial");
    }

    var intendedZoom:Float = 1;

    override function onGameplayStart():Void {
        PlayState.self.addEventListener(Events.CREATE_POST, onCreatePost);
        PlayState.self.addEventListener(GameEvents.GAME_OVER, onGameOver);
        PlayState.self.addEventListener(Events.UPDATE, onUpdate);
        intendedZoom = 1;
    }

    function onCreatePost():Void {
        // place girlfriend at the intended position
        game.opponent.setPosition(game.stage.spectatorPos[0], game.stage.spectatorPos[1]);

        game.events.addEventListener(GameEvents.EVENT_EXECUTION, onEventExecution);
        game.gameBeatBump = game.hudBeatBump = 0;
        game.camGame.zoom = 1;
    }

    function onUpdate():Void {
        game.cameraZoom = Tools.lerp(game.cameraZoom, intendedZoom, 5);
    }

    function onEventExecution(event):Void {
        if (event.event.type == "change camera target") {
            intendedZoom = switch (event.event.arguments[0]) {
                case 0: 1.1; // spectator
                case 2: 0.9; // player
            }
        }
    }

    function onGameOver(event):Void {
        // no gameover in the tutorial!
        event.cancel();
    }
}
