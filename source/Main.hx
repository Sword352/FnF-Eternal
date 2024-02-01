package;

import eternal.ui.Overlay;
import eternal.ui.SoundTray;

import funkin.states.InitState;
import openfl.display.Sprite;

class Main extends Sprite {
   public static var game(default, null):GameInstance;
   public static var overlay(default, null):Overlay;

   public function new():Void {
      super();

      FlxG.save.bind("misc", Tools.savePath);

      game = new GameInstance();
      addChild(game);

      overlay = new Overlay();
      addChild(overlay);
   }
}

class GameInstance extends #if ENGINE_CRASH_HANDLER eternal.core.crash.FNFGame #else flixel.FlxGame #end {
   public function new():Void {
      super(0, 0, InitState, 60, 60, true);
      _customSoundTray = SoundTray;
   }
}