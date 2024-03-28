package funkin.globals;

import funkin.states.substates.GameOverScreen.GameOverData;

typedef SongMeta = {
    var name:String;
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
