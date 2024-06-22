package funkin.save;

class HighScore {
    public static var scoreMap:Map<String, ScoreMeasure> = [];
    public static final defaultMeasure:ScoreMeasure = {
        score: 0,
        misses: 0,
        accuracy: 0,
        rank: "?"
    };

    public static function set(song:String, data:ScoreMeasure):Void {
        /*
        song = Mods.currentMod.id + "_" + song;
        */

        var original:ScoreMeasure = scoreMap.get(song) ?? defaultMeasure;

        if (data.score > original.score) {
            scoreMap.set(song, data);
            save();
        }
    }

    public static function get(song:String):ScoreMeasure {
        /*
        song = Mods.currentMod.id + "_" + song;
        */

        return scoreMap.get(song) ?? defaultMeasure;
    }

    public static function load():Void {
        Tools.invokeTempSave((save) -> {
            var data:Map<String, ScoreMeasure> = save.data.scores;
            if (data != null) scoreMap = data.copy();
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
