package funkin.menus.options;

import funkin.menus.options.items.BoolOptionItem;

class DebugOptionSubState extends BaseOptionSubState {
    override function create():Void {
        var option:BoolOptionItem = new BoolOptionItem("Reload Assets");
        option.description = 'If enabled, reload assets when leaving "temporary" menus, at the cost of longer\nloading times.';
        addOption(option);

        var option:BoolOptionItem = new BoolOptionItem("Editor Access");
        option.description = "If enabled, allow access to debug editors.";
        addOption(option);

        super.create();
    }
}
