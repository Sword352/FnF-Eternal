package funkin.core.modding;

import funkin.core.assets.IAssetSource;
import funkin.core.assets.FsAssetSource;
import sys.FileSystem;

class Mods {
    public static final FOLDER:String = "mods/";
    public static final metaBlacklist:Array<String> = [
        "priority", "assetStructure", "folder", "enabled"
    ];
    
    public static var mods:Array<ModStructure> = [];
    public static var enabledMods:Array<ModStructure> = [];

    public static function init():Void {
        reload();

        // TODO: is this a good idea?
        /*
        FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, (ev) -> {
            if (Controls.global.keybinds["open mods"][0].contains(ev.keyCode) && (FlxG.state.subState == null || !Std.isOfType(FlxG.state.subState, ModsOverlay)))
                FlxG.state.openSubState(new ModsOverlay());
        });
        */
    }

    public static function reload():Void {
        clear();

        var entries:Array<String> = FileSystem.readDirectory(FOLDER);

        for (entry in entries) {
            if (!FileSystem.isDirectory(FOLDER + entry))
                continue;

            var source:IAssetSource = new FsAssetSource(FOLDER + entry);
            var metaExtension:String = YAML.findExtension("meta", source);

            if (metaExtension == null) {
                source.dispose();
                continue;
            }

            var metaData:Dynamic = Tools.parseYAML(source.getContent("meta" + metaExtension));
            var mod:ModStructure = {folder: entry};

            for (field in Type.getInstanceFields(ModStructure)) {
                if (!metaBlacklist.contains(field) && Reflect.hasField(metaData, field))
                    Reflect.setProperty(mod, field, Reflect.getProperty(metaData, field));
            }

            if (mod.title == null)
                mod.title = mod.folder;

            if (mod.id == null)
                mod.id = mod.folder;

            mod.assetSource = source;
            mods.push(mod);
        }

        refreshEnabledMods();
    }

    public static function refreshEnabledMods():Void {
        var list:Array<String> = FlxG.save.data.enabledMods;
        if (list == null || list.length == 0) {
            enableAllMods();
            return;
        }

        for (mod in mods) {
            if (!list.contains(mod.id)) continue;

            mod.priority = list.indexOf(mod.id);
            enabledMods.push(mod);
        }

        sortList();

        // if the mods to enable haven't been found, enable all mods
        if (enabledMods.length == 0)
            enableAllMods();
    }

    public static function enableAllMods():Void {
        for (i in 0...mods.length) {
            var mod:ModStructure = mods[i];
            Assets.addAssetSource(mod.assetSource);
            enabledMods.push(mod);
            mod.priority = i;
        }

        saveEnabledMods();
    }

    public static function saveEnabledMods():Void {
        FlxG.save.data.enabledMods = [for (mod in enabledMods) mod.id];
        FlxG.save.flush();
    }

    public static function clear():Void {
        while (mods.length > 0) {
            var mod:ModStructure = mods.pop();
            Assets.removeAssetSource(mod.assetSource);
            mod.dispose();
        }

        enabledMods.splice(0, enabledMods.length);
    }

    public static function sortList():Void {
        enabledMods.sort(sortByPriority);

        for (mod in enabledMods) {
            Assets.removeAssetSource(mod.assetSource);
            Assets.addAssetSource(mod.assetSource);
        }            
    }

    public static function sortByPriority(a:ModStructure, b:ModStructure):Int {
        if (a.priority == -1) return 1;
        if (b.priority == -1) return -1;
        return Std.int(a.priority - b.priority);
    }
}

@:structInit
class ModStructure {
    public var title:String;
    public var description:String;

    public var folder:String;
    public var id:String;

    public var credits:Array<ModAuthor>;
    public var dependencies:Array<String>;

    public var modVersion:String;
    public var apiVersion:String;
    public var license:String;
    public var extra:Dynamic;

    public var assetSource:IAssetSource;
    public var priority:Int = -1;

    public var enabled(get, set):Bool;

    public function new(folder:String):Void {
        this.folder = folder;
    }

    public function getVersionState():ModVersionState {
        if (apiVersion == null) return UPDATED;

        var apiDigits:Array<Int> = [for (i in Tools.gameVersion.split(".")) Std.parseInt(i)];
        var digits:Array<Int> = [for (i in apiVersion.split(".")) Std.parseInt(i)];

        if (apiDigits.length == 0 || digits.length == 0) return UPDATED;

        while (digits.length < 3)
            digits.push(0);

        for (i in 0...apiDigits.length) {
            if (digits[i] == apiDigits[i]) continue;
            return (digits[i] > apiDigits[i]) ? OUTDATED_BUILD : OUTDATED_MOD;
        }

        return UPDATED;
    }

    public function dispose():Void {
        title = null;
        description = null;
        folder = id = null;

        dependencies = null;
        credits = null;
        modVersion = null;
        apiVersion = null;
        license = null;
        extra = null;

        assetSource.dispose();
        assetSource = null;
    }

    inline function get_enabled():Bool {
        return Mods.enabledMods.contains(this);
    }

    function set_enabled(v:Bool):Bool {
        if (v && !Mods.enabledMods.contains(this)) {
            Mods.enabledMods.push(this);
            priority = Mods.enabledMods.length - 1;
        }
        else if (!v && Mods.enabledMods.contains(this)) {
            Mods.enabledMods.remove(this);
            priority = -1;
        }

        return v;
    }
}

typedef ModAuthor = {
    var name:String;
    var ?icon:String;
    var ?role:String;
}

enum ModVersionState {
    UPDATED;
    OUTDATED_BUILD;
    OUTDATED_MOD;
}
