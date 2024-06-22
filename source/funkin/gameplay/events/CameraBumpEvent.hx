package funkin.gameplay.events;

/**
 * Camera bump event. Modifies the camera bump interval and it's intensity.
 */
@:build(core.macros.SongEventMacro.build({
    type: "change camera bump",
    name: "Change Camera Bumping",
    arguments: [
        {name: "Bump interval", type: "Float", tempValue: "4", unit: "beats"},
        {name: "Game bumping intensity", type: "Float", tempValue: "1"},
        {name: "HUD bumping intensity", type: "Float", tempValue: "1"}
    ]
}))
class CameraBumpEvent extends SongEvent {
    override function execute(_):Void {
        game.camBumpInterval = bumpInterval;
        game.gameBeatBump = 0.03 * gameBumpingIntensity;
        game.hudBeatBump = 0.05 * hudBumpingIntensity;
    }
}
