package globals;

import states.substates.GameOverScreen.GameOverData;

@:structInit class Chart {
    public static var current:Chart;

    public var notes:Array<ChartNote>;
    public var events:Array<ChartEvent>;
    public var gameplayInfo:GameplayInfo;
    public var meta:SongMeta;

    public function new(notes:Array<ChartNote>, meta:SongMeta, gameplayInfo:GameplayInfo, events:Array<ChartEvent>):Void {
        this.notes = notes;
        this.events = events;
        
        this.gameplayInfo = gameplayInfo;
        this.meta = meta;

        current = this;
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
    var event:String;
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
    var ?stepsPerBeat:Int;

    var ?player:String;
    var ?opponent:String;
    var ?spectator:String;
    var ?stage:String;

    var ?noteSkins:Array<String>;
    var ?gameOverData:GameOverData;
}

// using it as dynamic somewhat makes the game crash, this anonymous structure fixes it
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
