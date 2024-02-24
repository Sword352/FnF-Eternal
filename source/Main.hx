package;

import flixel.FlxGame;
import flixel.FlxState;

import haxe.ui.Toolkit;
import eternal.ui.SoundTray;
import eternal.ui.FPSOverlay;

import openfl.ui.Keyboard;
import openfl.display.Sprite;
import openfl.events.KeyboardEvent;

#if ENGINE_CRASH_HANDLER
import eternal.core.crash.CrashHandler;
#end

import funkin.states.menus.TitleScreen;

class Main extends Sprite {
   public static var game(default, null):GameInstance;
   public static var fpsOverlay(default, null):FPSOverlay;

   public function new():Void {
      super();

      // Bind the save file before the game launches so it's tied to the correct save file
      FlxG.save.bind("misc", Tools.savePath);

      game = new GameInstance();
      addChild(game);

      fpsOverlay = new FPSOverlay();
      addChild(fpsOverlay);
   }
}

class GameInstance extends FlxGame {
   public function new():Void {
      super(0, 0, InitState, 60, 60, true);
      _customSoundTray = SoundTray;
   }
}

// State used to initialize some stuff when the game instance is ready
class InitState extends FlxState {
   override function create():Void {
      // Init some backend stuff
      #if ENGINE_CRASH_HANDLER
      CrashHandler.init();
      #end

      #if ENGINE_DISCORD_RPC
      DiscordPresence.init();
      #end

      Controls.init();
      Toolkit.init();
      Assets.init();

      // Changes to some Flixel global variables
      FlxG.fixedTimestep = false;
      FlxG.mouse.visible = false;

      // Check if the game was fullscreen last time
      if (FlxG.save.data.fullscreen != null)
         FlxG.fullscreen = FlxG.save.data.fullscreen;

      // To go on/off fullscreen by pressing F11
      FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, (ev) -> {
         switch (ev.keyCode) {
            case Keyboard.F11:
                  FlxG.fullscreen = !FlxG.fullscreen;
                  FlxG.save.data.fullscreen = FlxG.fullscreen;
                  FlxG.save.flush();
            }
       });

      #if ENGINE_MODDING
      // Load mods
      Mods.init();
      #end

      // Load options
      Settings.load();

      // Load scores
      HighScore.load();
       
      #if ENGINE_MODDING        
      // If no mods has been found, it automatically switch to an exception state, no need to go to the titlescreen
      if (Mods.mods.length < 1)
         return;
      #end

      // Go to the titlescreen
      TransitionSubState.skipNextTransOut = true;
      FlxG.switchState(TitleScreen.new);
   }
}