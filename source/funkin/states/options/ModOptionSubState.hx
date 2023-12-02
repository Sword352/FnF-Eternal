package funkin.states.options;

#if ENGINE_MODDING
import funkin.objects.options.*;

class ModOptionSubState extends BaseOptionSubState {
    override function create():Void {
        for (setting in Settings.modSettings) {
            var key:String = Mods.currentMod.folder + "_" + setting.id;

            var item:BaseOptionItem<Dynamic> = switch ((setting.type ?? "").toLowerCase()) {
                case "string": new ArrayOptionItem<String>(key, setting.valueList);
                case "float": createFloatOption(key, setting);
                case "int": createIntOption(key, setting);
                default: new BoolOptionItem(key);
            };

            item.title = (setting.name ?? setting.id);
            item.description = (setting.description ?? "");

            addOption(item);
        }

        super.create();
    }

    inline static function createFloatOption(key:String, setting:ModSetting):FloatOptionItem {
        var item:FloatOptionItem = new FloatOptionItem(key);

        if (setting.min != null)
            item.minValue = setting.min;
        if (setting.max != null)
            item.maxValue = setting.max;
        if (setting.step != null)
            item.steps = setting.step;
        if (setting.precision != null)
            item.precision = setting.precision;

        return item;
    }

    inline static function createIntOption(key:String, setting:ModSetting):IntOptionItem {
        var item:IntOptionItem = new IntOptionItem(key);

        if (setting.min != null)
            item.minValue = cast setting.min;
        if (setting.max != null)
            item.maxValue = cast setting.max;
        if (setting.step != null)
            item.steps = cast setting.step;

        return item;
    }
}
#end