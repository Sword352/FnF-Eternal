package globals;

class SongProgress {
    public static var container:Array<String> = [];

    public static function unlock(key:String, week:Bool = false):Void {
        /*
        #if ENGINE_MODDING
        key = Mods.currentMod.id + "_" + key;
        #end
        */

        var fullKey:String = (week ? "week_" : "song_") + key;
        if (container.contains(fullKey)) return;

        container.push(fullKey);
        save();
    }

    public static function unlocked(key:String, week:Bool = false):Bool {
        /*
        #if ENGINE_MODDING
        key = Mods.currentMod.id + "_" + key;
        #end
        */

        return container.contains((week ? "week_" : "song_") + key);
    }

    public static function load():Void {
        Tools.invokeTempSave((save) -> {
            var data:Array<String> = save.data.unlocked;
            if (data != null) container = data.copy();
        }, "unlocked_songs");
    }

    public static function save():Void {
        Tools.invokeTempSave((save) -> save.data.unlocked = container, "unlocked_songs");
    }
}
