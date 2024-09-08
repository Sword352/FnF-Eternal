package funkin.core.modding;

/*
import funkin.menus.ModExceptionScreen;
import funkin.core.scripting.HScript;

class DeprecatedMods {
    public static final MODS_PATH:String = "mods/";

    public static var currentMod(default, null):Mod;
    public static var mods(default, null):Array<Mod> = [];

    static var initScript:HScript;

    public static function init():Void {
        refreshMods(false);

        if (mods.length < 1)
            return;

        checkLastMod();

        // If the last mod hasn't been found, set the current mod to the first entry in the list
        if (currentMod == null)
            loadFirstMod();
    }

    public static function refreshMods(checkCurrentMod:Bool = true):Void {
        mods.splice(0, mods.length);

        if (!FileTools.exists(MODS_PATH)) {
            FileTools.createDirectory(MODS_PATH);
            goToErrorScreen();
            return;
        }

        var folders:Array<String> = FileTools.readDirectory(MODS_PATH);
        if (folders.length < 1) {
            goToErrorScreen();
            return;
        }

        for (folder in folders) {
            var path:String = MODS_PATH + folder;
            if (!FileTools.isDirectory(path))
                continue;

            var pack:String = Assets.filterPath(path + "/pack", YAML);
            if (!FileTools.exists(pack)) {
                trace('${folder}: Missing pack configuration file!');
                continue;
            }

            var data:Dynamic = Tools.parseYAML(FileTools.getContent(pack));
            var mod:Mod = {folder: folder};

            // configuration file is empty
            if (data == null) {
                mod.title = folder;
                mod.id = folder;
                mods.push(mod);
                continue;
            }

            mod.title = data.title ?? folder;
            mod.description = data.description;
            mod.id = data.id ?? folder;

            mod.license = data.license;
            mod.apiVersion = data.apiVersion;

            mod.restartGame = data.restartGame ?? false;

            #if DISCORD_RPC
            mod.discordClient = data.discordClient;
            #end

            mods.push(mod);
        }

        if (!checkCurrentMod)
            return;

        if (currentMod == null) {
            checkLastMod();
            return;
        }

        for (mod in mods) {
            if (mod.id == currentMod.id) {
                // current mod has been found, just switch mod instance
                currentMod = mod;
                return;
            }
        }

        // If we made it this far, set the current mod to the first entry in the list
        loadFirstMod();
    }

    // Reason this is not a setter to `currentMod` is to prevent it from being called several times
    // for example, when refreshing the mods in the mods menu, to not call the init script of the current mod
    public static function loadMod(mod:String):Void {
        if (mod == null || mods.length < 1) {
            _loadMod(null);
            return;
        }

        for (modInstance in mods) {
            if (modInstance.folder == mod) {
                _loadMod(modInstance);
                break;
            }
        }
    }

    public static function getModApiState(mod:Mod):ModApiState {
        if (mod == null || mod.apiVersion == null || !mod.apiVersion.contains("."))
            return NONE;

        var modVersion:Array<Int> = [for (i in mod.apiVersion.split(".")) Std.parseInt(i)];
        var version:Array<Int> = [for (i in Tools.gameVersion.split(".")) Std.parseInt(i)];

        if (modVersion.length < 1 || version.length < 1) {
            trace('Could not resolve API version for "${mod.id}"');
            return NONE;
        }

        for (i in 0...modVersion.length) {
            if (modVersion[i] == version[i]) continue;
            return (modVersion[i] > version[i]) ? OUTDATED_BUILD : OUTDATED_MOD;
        }

        return UPDATED;
    }

    static function loadFirstMod():Void {
        if (currentMod != null)
            trace('Mod "${currentMod.id}" has not been found, setting current mod to "${mods[0].id}"');

        _loadMod(mods[0]);
        FlxG.save.data.lastMod = currentMod.id;
        FlxG.save.flush();
    }

    static function checkLastMod():Void {
        var lastMod:String = FlxG.save.data.lastMod;
        if (lastMod == null)
            return;

        for (mod in mods) {
            if (mod.id == lastMod) {
                _loadMod(mod);
                break;
            }
        }
    }

    static function goToErrorScreen():Void {
        _loadMod(null);

        if (!(FlxG.state is ModExceptionScreen)) {
            Transition.skipNextTransOut = Transition.skipNextTransIn = true;
            FlxG.switchState(ModExceptionScreen.new);
        }
    }

    static function _loadMod(mod:Mod):Void {
        currentMod = mod;

        Assets.currentDirectory = (currentMod == null) ? Assets.defaultDirectory : '${MODS_PATH}${currentMod.folder}/';

        #if DISCORD_RPC
        DiscordRPC.reconnect(currentMod?.discordClient ?? DiscordRPC.DEFAULT_ID);
        #end

        // clear all the static variables
        HScript.sharedFields.clear();
        
        // reload init script
        if (initScript != null) {
            initScript.destroy();
            initScript = null;
        }

        var scriptPath:String = Assets.script("scripts/Init");
        if (FileTools.exists(scriptPath)) {
            initScript = new HScript(scriptPath);
            initScript.call("init");
        }
    }
}

@:structInit class Mod {
    public var title:String;
    public var folder:String;
    public var id:String;

    public var description:String;
    public var license:String;
    public var apiVersion:String;

    public var restartGame:Bool;

    #if DISCORD_RPC
    public var discordClient:String;
    #end

    public function new(folder:String):Void {
        this.folder = folder;
    }

    public inline function getApiState():ModApiState
        return Mods.getModApiState(this);
}

enum abstract ModApiState(String) from String to String {
    var OUTDATED_BUILD = "Outdated build";
    var OUTDATED_MOD = "Outdated mod";
    var UPDATED = "Updated";
    var NONE = "None";

    public function isOutdated():Bool
        return this == OUTDATED_BUILD || this == OUTDATED_MOD;

    public function getHandle():String {
        return switch (this:ModApiState) {
            case UPDATED | NONE: "Updated";
            default: this;
        }
    }
}
#end
*/
