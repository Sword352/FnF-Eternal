package funkin.save;

class Options {
    // GENERAL SETTINGS
    public static var framerate(default, set):Int = 60;

    public static var noAntialiasing(default, set):Bool = false;
    public static var silentSoundtray(default, set):Bool = false;
    public static var autoPause(default, set):Bool = true;
    public static var noFlashingLights:Bool = false;

    #if DISCORD_RPC
    public static var noDiscordRpc(default, set):Bool = false;
    #end

    public static var audioStreaming:Bool = false;
    public static var audioOffset:Float = 0;

    // GAMEPLAY SETTINGS
    public static var downscroll:Bool = false;
    public static var centeredStrumline:Bool = false;
    public static var ghostTapping:Bool = false;

    public static var simplifyComboNum:Bool = false;
    public static var noComboStack:Bool = false;
    public static var noNoteSplash:Bool = false;

    // DEBUG SETTINGS
    public static var editorAccess:Bool = false;
    public static var reloadAssets:Bool = false;

    #if sys
    public static var chartOverwrite:Bool = true;
    #end
    //

    static function set_framerate(v:Int):Int {
        Tools.changeFramerateCap(v);
        return framerate = v;
    }

    static function set_noAntialiasing(v:Bool):Bool {
        FlxSprite.defaultAntialiasing = !v;
        return noAntialiasing = v;
    }

    static function set_silentSoundtray(v:Bool):Bool {
        FlxG.game.soundTray.silent = v;
        return silentSoundtray = v;
    }

    static function set_autoPause(v:Bool):Bool {
        FlxG.autoPause = v;
        return autoPause = v;
    }

    #if DISCORD_RPC
    static function set_noDiscordRpc(v:Bool):Bool {
        if (DiscordRPC.self != null)
            DiscordRPC.self.hidden = v;
        return noDiscordRpc = v;
    }
    #end
}

class OptionsManager {
    public static function load():Void {
        if (FlxG.save.data.settings == null)
            FlxG.save.data.settings = {};

        for (key in Type.getClassFields(Options)) {
            if (!validKey(key)) continue;

            if (Reflect.hasField(FlxG.save.data.settings, key))
                Reflect.setProperty(Options, key, Reflect.getProperty(FlxG.save.data.settings, key));

            // call the setter anyways (if it exists)
            else if (Reflect.hasField(Options, 'set_${key}'))
                Reflect.callMethod(Options, Reflect.getProperty(Options, 'set_${key}'), [Reflect.getProperty(Options, key)]);
        }
    }

    public static function save():Void {
        for (key in Type.getClassFields(Options)) {
            if (!validKey(key)) continue;
            Reflect.setProperty(FlxG.save.data.settings, key, Reflect.getProperty(Options, key));
        }

        FlxG.save.flush();
    }

    inline static function validKey(key:String):Bool {
        return !Reflect.isFunction(Reflect.field(Options, key));
    }
}
