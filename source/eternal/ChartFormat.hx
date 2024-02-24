package eternal;

import funkin.states.substates.GameOverScreen.GameOverProperties;

// TODO: move `speed` and `bpm` to `SongMetadata`

@:structInit class Chart {
   public var meta:SongMetadata;

   public var notes:Array<ChartNote>;
   public var events:Array<ChartEvent>;

   public var speed:Float;
   public var bpm:Float;

   public inline function toStruct():Dynamic {
      return {
         meta: this.meta,

         notes: this.notes.copy(),
         events: this.events.copy(),

         speed: this.speed,
         bpm: this.bpm
      };
   }

   public static inline function fromStruct(struct:Dynamic):Chart {
      return {
         meta: struct.meta,

         notes: struct.notes,
         events: struct.events,

         speed: struct.speed,
         bpm: struct.bpm
      };
   }

   public static inline function resolve(data:Dynamic):Chart {
      if (data is Chart)
         return data;

      return fromStruct(data);
   }
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

   var ?playerNoteSkin:String;
   var ?oppNoteSkin:String;

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