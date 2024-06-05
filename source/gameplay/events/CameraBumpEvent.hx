package gameplay.events;

/**
 * Camera bump event. Modifies the camera bump interval and it's intensity.
 */
@:build(core.macros.SongEventMacro.build({
    type: "change camera bump",
    name: "Change Camera Bumping",
    arguments: [
        {name: "Bump interval in beats", type: "Float", tempValue: "4"},
        {name: "Game bumping intensity", type: "Float", tempValue: "1"},
        {name: "HUD bumping intensity", type: "Float", tempValue: "1"}
    ]
}))
class CameraBumpEvent extends BaseSongEvent {
    override function execute(_):Void {
        game.camBumpInterval = bumpIntervalInBeats;
        game.gameBeatBump = 0.03 * gameBumpingIntensity;
        game.hudBeatBump = 0.05 * hudBumpingIntensity;
    }
}
