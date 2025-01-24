package funkin.menus.options;

import funkin.menus.options.items.*;

class GameplayOptionSubState extends BaseOptionSubState {
    override function create():Void {
        var option = new BoolOptionItem("Downscroll");
        option.description = "If enabled, the strumlines gets positioned down.";
        addOption(option);

        var option = new BoolOptionItem("Centered Strumline");
        option.description = "If enabled, centers the player strumline and hides the opponent strumline.";
        addOption(option);

        var option = new BoolOptionItem("Ghost Tapping");
        option.description = "If enabled, pressing the keys with no notes on screen won't count as a miss.";
        addOption(option);

        var option = new BoolOptionItem("Disable Note Splashes", "noNoteSplash");
        option.description = "Whether to disable note splashes.";
        addOption(option);

        super.create();
    }
}
