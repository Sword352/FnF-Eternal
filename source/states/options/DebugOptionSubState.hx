package states.options;

import states.options.items.BoolOptionItem;

class DebugOptionSubState extends BaseOptionSubState {
    override function create():Void {
        var option:BoolOptionItem = new BoolOptionItem("Audio Streaming");
        option.description = 'EXPERIMENTAL - If enabled, music assets are streamed, resuling in faster load\ntimes and saves a lot of memory.';
        addOption(option);

        var option:BoolOptionItem = new BoolOptionItem("Reload Assets");
        option.description = 'If enabled, reload assets when leaving "temporary" menus, at the cost of longer\nloading times.';
        addOption(option);

        var option:BoolOptionItem = new BoolOptionItem("Editor Access");
        option.description = "If enabled, allow access to debug editors.";
        addOption(option);

        #if sys
        var option:BoolOptionItem = new BoolOptionItem("Overwrite Chart Files", "chartOverwrite");
        option.description = "If enabled, overwrite the file of charts using the FNF Legacy chart format once\nthey get loaded.";
        addOption(option);
        #end

        super.create();
    }
}
