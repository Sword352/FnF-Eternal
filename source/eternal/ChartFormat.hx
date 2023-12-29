package eternal;

import funkin.states.substates.GameOverScreen.GameOverProperties;

/**
 * TODO:
 * - `Chart`: move `speed` and `bpm` to `SongMetadata`
 * - `ChartNote`: remove `animSuffix` and use notetypes for anim suffixes
 */

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