package funkin.data;

import funkin.data.GameOverData;
import funkin.gameplay.notes.StrumLine.StrumLineOwner;
using funkin.utils.TimingTools;

@:structInit
class Chart {
    public var notes:Array<ChartNote>;
    public var events:Array<ChartEvent>;
    public var gameplayInfo:GameplayInfo;
    public var meta:SongMeta;

    /**
     * Returns the noteskin corresponding to the strumline owner.
     * @param owner Strumline owner.
     * @return String
     */
    public function getNoteskin(owner:StrumLineOwner):String {
        if (gameplayInfo.noteSkins == null)
            return "default";

        return gameplayInfo.noteSkins[owner] ?? "default";
    }

    /**
     * Applies tempo properties from this chart to a conductor.
     * @param conductor Conductor instance.
     */
    public function prepareConductor(conductor:Conductor):Void {
        conductor.beatsPerMeasure = gameplayInfo.beatsPerMeasure ?? TimingTools.BEATS_PER_MEASURE_COMMON;
        conductor.bpm = gameplayInfo.bpm;

        for (event in events) {
            if (event.type == "change bpm") {
                conductor.timingPoints.push({
                    time: event.time,
                    bpm: event.arguments[0],
                    beatsPerMeasure: event.arguments[1] ?? TimingTools.BEATS_PER_MEASURE_COMMON
                });
            }
        }

        conductor.timingPoints.prepareTimingPoints();
    }

    public inline function toStruct():ChartJson {
        return {
            gameplayInfo: this.gameplayInfo,
            events: this.events,
            notes: this.notes
        };
    }

    public static inline function fromStruct(struct:ChartJson):Chart {
        return {
            gameplayInfo: struct.gameplayInfo,
            events: struct.events,
            notes: struct.notes,
            meta: null
        };
    }

    public static inline function resolve(data:Dynamic):Chart
        return data is Chart ? data : fromStruct(data);
}

typedef ChartJson = {
    var notes:Array<ChartNote>;
    var ?events:Array<ChartEvent>;
    var ?gameplayInfo:GameplayInfo;
}

typedef ChartEvent = {
    var type:String;
    var time:Float;
    var arguments:Array<Any>;
}

typedef ChartNote = {
    var time:Float;
    var direction:Int;
    var strumline:Int;
    var ?length:Float;
    var ?type:String;
}

typedef SongMeta = {
    var name:String;
    var ?folder:String; // NOTE: this shouldn't be set in the json
    var ?difficulties:Array<String>;
    var ?gameplayInfo:GameplayInfo;
    var freeplayInfo:FreeplayInfo;
}

typedef FreeplayInfo = {
    var ?icon:String;
    var ?color:Dynamic;
    var ?parentWeek:String;
}

typedef GameplayInfo = {
    var instrumental:String;
    var voices:Array<String>;

    var bpm:Float;
    var scrollSpeed:Float;
    var ?beatsPerMeasure:Int;

    var ?player:String;
    var ?opponent:String;
    var ?spectator:String;
    var ?stage:String;

    var ?noteSkins:Array<String>;
    var ?gameOverData:GameOverData;
}

typedef BaseGameChart = {
    var notes:Array<BaseGameSection>;
    var song:String;

    var speed:Float;
    var bpm:Float;

    var stage:String;
    var player1:String;
    var player2:String;
    var player3:String;
    var gfVersion:String;

    var needsVoices:Bool;
    var validScore:Bool;
}

typedef BaseGameSection = {
    var sectionNotes:Array<Dynamic>;
    var lengthInSteps:Int;
    var typeOfSection:Int;

    var mustHitSection:Bool;
    var changeBPM:Bool;
    var altAnim:Bool;

    var bpm:Float;
}
