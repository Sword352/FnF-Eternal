package funkin.states.options;

import funkin.objects.options.BoolOptionItem;

class DebugOptionSubState extends BaseOptionSubState {
    override function create():Void {
        var option:BoolOptionItem = new BoolOptionItem("reload assets");
        option.description = "If enabled, the assets gets refreshed when restarting the song in gameplay,\naccessing the chart editor etc, at the cost of loading time.";
        addOption(option);

        var option:BoolOptionItem = new BoolOptionItem("editor access");
        option.description = "If enabled, allow access to debug editors.";
        addOption(option);

        #if sys
        var option:BoolOptionItem = new BoolOptionItem("overwrite chart files");
        option.description = "If enabled, overwrite the file of charts using the FNF Legacy chart format once\nthey get loaded.";
        addOption(option);
        #end

        super.create();
    }
}
