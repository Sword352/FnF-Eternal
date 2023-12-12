package eternal;

#if ENGINE_MODDING
import eternal.core.scripting.HScript;

typedef ModSetting = {
    var id:String;

    var ?name:String;
    var ?description:String;
    var ?backendKey:String;

    var ?type:String;
    var ?defaultVal:Dynamic;
    
    var ?min:Float;
    var ?max:Float;
    var ?step:Float;
    var ?precision:Int;
    var ?valueList:Array<String>;
}
#end

class Settings {
    /**
     * Setting format:
     * 
     * ```
     * // "T" defines the setting's type (Bool, Float... etc)
     * "setting name" => new Setting<T>(defaultValue),
     * // You can optionally pass a custom callback that gets called when the value changes
     * "other setting" => new Setting<T>(defaultValue, (v) -> trace(v))
     * ```
     */
    public static final settings:Map<String, Setting<Dynamic>> = [
        // Gameplay settings
        "downscroll" => new Setting<Bool>(false),
        "ghost tapping" => new Setting<Bool>(false),
        "centered strumline" => new Setting<Bool>(false),
        "disable hold stutter" => new Setting<Bool>(false),

        "hold notes behind receptors" => new Setting<Bool>(false),
        "disable combo stacking" => new Setting<Bool>(false),
        "disable note splashes" => new Setting<Bool>(false),
        "judgements on user interface" => new Setting<Bool>(false),
        "simplify combo number" => new Setting<Bool>(false),
        "hide user interface" => new Setting<Bool>(false),
        "smooth health bar" => new Setting<Bool>(true),
        "timer type" => new Setting<String>("none"),

        // General settings
        "framerate" => new Setting<Int>(60, (v) -> Tools.changeFramerateCap(v)),

        "show framerate" => new Setting<Bool>(true, (v) -> {
            if (Main.overlay != null)
                Main.overlay.showFramerate = v;
        }),
        "show memory" => new Setting<Bool>(false, (v) -> {
            if (Main.overlay != null)
                Main.overlay.showMemory = v;
        }),
        "show overlay background" => new Setting<Bool>(true, (v) -> {
            if (Main.overlay != null)
                Main.overlay.showBackground = v;
        }),

        "disable antialiasing" => new Setting<Bool>(false, (v) -> FlxSprite.defaultAntialiasing = !v),
        "silent soundtray" => new Setting<Bool>(false, (v) -> FlxG.game.soundTray.silent = v),
        "auto pause" => new Setting<Bool>(true, (v) -> FlxG.autoPause = v),

        "reduced movements" => new Setting<Bool>(false),
        "disable flashing lights" => new Setting<Bool>(false),

        #if ENGINE_DISCORD_RPC
        "disable discord rpc" => new Setting<Bool>(false, (v) -> DiscordPresence.presence.hide(v)),
        #end

        "audio offset" => new Setting<Float>(0, (v) -> Conductor.offset = v),

        // Debug settings
        "editor access" => new Setting<Bool>(false),
        #if sys "overwrite chart files" => new Setting<Bool>(true), #end
        "reload assets" => new Setting<Bool>(false),

        // Chart editor preferences
        "CHART_autoSave" => new Setting<Bool>(true),
        "CHART_metronomeVolume" => new Setting<Float>(0),
        "CHART_hitsoundVolume" => new Setting<Float>(0),
        "CHART_muteInst" => new Setting<Bool>(false),
        "CHART_measureText" => new Setting<Bool>(true),
        "CHART_timeOverlay" => new Setting<Bool>(true),
        "CHART_receptors" => new Setting<Bool>(false),
        "CHART_rStaticGlow" => new Setting<Bool>(false),
        "CHART_lateAlpha" => new Setting<Bool>(true),
        "CHART_checkerAlpha" => new Setting<Float>(1),
        "CHART_strumlineSnap" => new Setting<Bool>(false),
        "CHART_pitch" => new Setting<Float>(1)
    ];

    #if ENGINE_MODDING
    public static final modSettings:Array<ModSetting> = [];
    static var setterScript:HScript;
    #end

    public static function load():Void {
        Tools.invokeTempSave((save) -> {
            var data:Map<String, Any> = save.data.settings;
            if (data != null) {
                for (key in data.keys()) {
                    if (settings.exists(key))
                        settings[key].value = data.get(key);
                }
            }
        }, "settings");
    }

    public static function save():Void {
        Tools.invokeTempSave((save) -> {
            var map:Map<String, Any> = [];
            for (setting in settings.keys())
                map.set(setting, settings.get(setting).value);

            save.data.settings = map;
        }, "settings");
    }

    #if ENGINE_MODDING
    public static function reloadModSettings():Void {
        setterScript?.destroy();
        setterScript = null;

        while (modSettings.length > 0)
            settings.remove(modSettings.shift().backendKey);

        var settingConfig:String = AssetHelper.yaml("data/settings");
        if (!FileTools.exists(settingConfig))
            return;

        var setters:String = AssetHelper.getPath("data/settings", SCRIPT);
        if (FileTools.exists(setters))
            setterScript = new HScript(setters, false);

        var customSettings:Array<ModSetting> = Tools.parseYAML(FileTools.getContent(settingConfig));

        for (setting in customSettings) {
            var id:String = setting.id;
            if (id == null)
                continue;

            var instance:Setting<Dynamic> = switch ((setting.type ?? "").toLowerCase().trim()) {
                case "string": new Setting<String>(setting.defaultVal ?? "");
                case "float": new Setting<Float>(setting.defaultVal ?? 0);
                case "int": new Setting<Int>(setting.defaultVal ?? 0);
                default: new Setting<Bool>(setting.defaultVal ?? false);
            }
            instance.onChange = (val) -> setterScript?.call('onChange_${id}', [val]);

            setting.backendKey = Mods.currentMod.folder + "_" + id;
            modSettings.push(setting);
            settings.set(setting.backendKey, instance);
        }

        load();
        save();
    }
    #end

    inline public static function get(key:String):Dynamic {
        #if ENGINE_MODDING
        var modKey:String = Mods.currentMod.folder + "_" + key;
        if (settings.exists(modKey))
            return settings.get(modKey).value;
        #end

        return settings.get(key).value;
    }
}

// setting wrapper used to call `onChange` when the setting's value gets changed.
private class Setting<T> {
    public var value(default, set):T;
    public var onChange:T->Void = null;

    public function new(defaultValue:T, ?callback:T->Void):Void {
        this.value = defaultValue;

        if (callback != null)
            this.onChange = callback;
    }

    inline function set_value(v:T):T {
        if (onChange != null)
            onChange(v);
        return value = v;
    }
}