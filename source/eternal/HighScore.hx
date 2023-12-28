package eternal;

class HighScore {
    public static var scoreMap(default, null):Map<String, ScoreMeasure> = [];
    public static final defaultMeasure:ScoreMeasure = {score: 0, misses: 0, accuracy: 0, rank: "?"};

    public static function set(song:String, data:ScoreMeasure):Void {
        #if ENGINE_MODDING
        song = Mods.currentMod.id + "_" + song;
        #end

        var original:ScoreMeasure = scoreMap.get(song) ?? defaultMeasure;

        if (data.score > original.score) {
            scoreMap.set(song, data);
            save();
        }
    }

    public static function get(song:String):ScoreMeasure {
        #if ENGINE_MODDING
        song = Mods.currentMod.id + "_" + song;
        #end
        
        if (!scoreMap.exists(song))
            return defaultMeasure;
        return scoreMap.get(song);
    }

    public static function load():Void {
        Tools.invokeTempSave((save) -> {
            var data:Map<String, ScoreMeasure> = save.data.scores;
            if (data != null)
                scoreMap = data.copy();
        }, "scores");
    }

    public static function save():Void {
        Tools.invokeTempSave((save) -> save.data.scores = scoreMap, "scores");
    }
}

typedef ScoreMeasure = {
    ?score:Float,
    ?misses:Int,
    ?accuracy:Float,
    ?rank:String
}