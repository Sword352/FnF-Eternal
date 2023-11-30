package eternal;

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

   var ?player:String;
   var ?opponent:String;
   var ?spectator:String;
   var ?stage:String;

   var instFile:String;
   var voiceFiles:Array<String>;
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