package funkin.states.options;

import funkin.objects.options.*;

class GameplayOptionSubState extends BaseOptionSubState {
    override function create():Void {
        var option = new BoolOptionItem("downscroll");
        option.description = "If enabled, the strumlines gets positioned down.";
        addOption(option);

        var option = new BoolOptionItem("centered strumline");
        option.description = "If enabled, centers the player strumline and hides the opponent strumline.";
        addOption(option);

        var option = new BoolOptionItem("ghost tapping");
        option.description = "If enabled, pressing the keys with no notes on screen won't count as a miss.";
        addOption(option);

        var option = new BoolOptionItem("disable hold stutter");
        option.description = "If enabled, disable character animation stuttering from hold notes.";
        addOption(option);

        var option = new BoolOptionItem("disable combo stacking");
        option.description = "If enabled, combo and ratings won't stack. Improves performance and save memory.";
        addOption(option);

        var option = new BoolOptionItem("disable note splashes");
        option.description = "Whether to disable note splashes. Improves performance and save memory.";
        addOption(option);

        var option = new BoolOptionItem("smooth health bar");
        option.description = "If enabled, make the health bar smooth.";
        addOption(option);

        var option = new BoolOptionItem("hide user interface");
        option.description = "If enabled, hide the user interface in gameplay.";
        addOption(option);

        var option = new BoolOptionItem("judgements on user interface");
        option.description = "If enabled, show combo and ratings on the user interface instead of the\ngame world, making them easier to read.";
        addOption(option);

        var option = new BoolOptionItem("simplify combo number");
        option.description = "If enabled, no additional zero gets displayed at the start of the combo number.";
        addOption(option);

        super.create();
    }
}