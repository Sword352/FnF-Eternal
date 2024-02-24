package eternal.core;

#if ENGINE_MODDING
import funkin.states.menus.ModExceptionScreen;

#if ENGINE_SCRIPTING
import eternal.core.scripting.HScript;
#end

class Mods {
    public static final MODS_PATH:String = "mods/";

    public static var currentMod(default, null):Mod;
    public static var mods(default, null):Array<Mod> = [];

    #if ENGINE_SCRIPTING
    static var initScript:HScript;
    #end

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
        while (mods.length > 0)
            mods.shift();

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

            #if ENGINE_DISCORD_RPC
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
        var engineVersion:Array<Int> = [for (i in Tools.gameVersion.split(".")) Std.parseInt(i)];

        if (modVersion.length < 1 || engineVersion.length < 1) {
            trace('Could not resolve API version for "${mod.id}"');
            return NONE;
        }

        for (i in 0...modVersion.length) {
            if (modVersion[i] == engineVersion[i])
                continue;

            return (modVersion[i] > engineVersion[i]) ? OUTDATED_BUILD : OUTDATED_MOD;
        }

        return UPDATED;
    }

    private static inline function loadFirstMod():Void {
        if (currentMod != null)
            trace('Mod "${currentMod.id}" has not been found, setting current mod to "${mods[0].id}"');

        _loadMod(mods[0]);
        FlxG.save.data.lastMod = currentMod.id;
        FlxG.save.flush();
    }

    private static inline function checkLastMod():Void {
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

    inline private static function goToErrorScreen():Void {
        _loadMod(null);
            
        if (!(FlxG.state is ModExceptionScreen)) {
            TransitionSubState.skipNextTransOut = TransitionSubState.skipNextTransIn = true;
            FlxG.switchState(ModExceptionScreen.new);
        }
    }

    inline private static function _loadMod(mod:Mod):Void {
        currentMod = mod;

        Assets.currentDirectory = (currentMod == null) ? Assets.defaultDirectory : '${MODS_PATH}${currentMod.folder}/';
        Settings.reloadModSettings();

        #if ENGINE_DISCORD_RPC
        DiscordPresence.reconnect(currentMod?.discordClient ?? DiscordPresence.DEFAULT_ID);
        #end

        #if ENGINE_SCRIPTING
        // reload init script
        if (initScript != null) {
            initScript.destroy();
            initScript = null;
        }

        var scriptPath:String = Assets.getPath("data/Init", SCRIPT);
        if (FileTools.exists(scriptPath)) {
            initScript = new HScript(scriptPath);
            initScript.call("init");
        }
        #end
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

    #if ENGINE_DISCORD_RPC
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