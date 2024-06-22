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

        var option = new BoolOptionItem("Hold Notes Behind Receptors", "holdBehindStrums");
        option.description = "If enabled, hold notes goes behind receptors.";
        addOption(option);

        var option = new BoolOptionItem("Disable Hold Stutter", "noHoldStutter");
        option.description = "If enabled, disable character animation stuttering from hold notes.";
        addOption(option);

        var option = new BoolOptionItem("Disable Combo Stacking", "noComboStack");
        option.description = "If enabled, combo and ratings won't stack. Improves performance and save memory.";
        addOption(option);

        var option = new BoolOptionItem("Disable Note Splashes", "noNoteSplash");
        option.description = "Whether to disable note splashes. Improves performance and save memory.";
        addOption(option);

        var option = new BoolOptionItem("Smooth Health Bar", "smoothHealth");
        option.description = "If enabled, make the health bar smooth.";
        addOption(option);

        var option = new BoolOptionItem("Hide User Interface", "hideUi");
        option.description = "If enabled, hide the user interface in gameplay.";
        addOption(option);

        var option = new BoolOptionItem("Judgements On User Interface", "uiJudgements");
        option.description = "If enabled, show combo and ratings on the user interface instead of the game\nworld, making them easier to read.";
        addOption(option);

        var option = new BoolOptionItem("Simplify Combo Number", "simplifyComboNum");
        option.description = "If enabled, no additional zero gets displayed at the start of the combo number.";
        addOption(option);

        var option = new ArrayOptionItem<String>("Time Mark Type", ["none", "left time", "elapsed time", "full"], "timeMark");
        option.description = "Defines the time display type.";
        addOption(option);

        super.create();
    }
}