package eternal;

import funkin.states.substates.GameOverScreen.GameOverProperties;

@:structInit class Chart {
   public var meta:SongMetadata;

   public var notes:Array<ChartNote>;
   public var events:Array<ChartEvent>;

   public var speed:Float;
   public var bpm:Float;
}

typedef SongMetadata = {
   var name:String;
   var rawName:String;

   var instFile:String;
   var voiceFiles:Array<String>;

   var ?stepsPerBeat:Int;
   var ?beatsPerMeasure:Int;

   var ?player:String;
   var ?opponent:String;
   var ?spectator:String;
   var ?stage:String;

   var ?gameOverProperties:GameOverProperties;
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
   var ?animSuffix:String;
}