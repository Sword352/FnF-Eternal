package;

import flixel.FlxGame;

import funkin.data.NoteSkin;
import funkin.save.SongProgress;

import funkin.menus.TitleScreen;
import funkin.menus.ScriptLoadScreen;

import funkin.ui.SoundTray;
import funkin.ui.FPSOverlay;

#if CRASH_HANDLER
import funkin.core.CrashHandler;
#end

import funkin.utils.Logging;

import openfl.ui.Keyboard;
import openfl.display.Sprite;
import openfl.events.KeyboardEvent;

import haxe.ui.Toolkit;

/**
 * Main entry point of the program.
 */
class Main extends Sprite {
    public static var game:GameInstance;
    public static var fpsOverlay:FPSOverlay;

    public function new():Void {
        #if CRASH_HANDLER
        // Initialize the crash handler before anything else
        CrashHandler.init();
        #end
        
        super();

        // Bind the save file before the game launches so it's tied to the correct save file
        FlxG.save.bind("save", Tools.savePath);

        game = new GameInstance();
        addChild(game);

        fpsOverlay = new FPSOverlay();
        game.addChild(fpsOverlay);
    }
}

/**
 * Custom `FlxGame` which adds a custom soundtray.
 */
private class GameInstance extends FlxGame {
    public function new():Void {
        super(0, 0, InitState.new, 60, 60, true);
        _customSoundTray = SoundTray;
    }
}

/**
 * Small state used to initialize the backstage of the engine.
 * NOTE: this is a state because initializing Flixel things in the `Main` class constructor is a bit unreliable.
 */
class InitState extends ScriptableState {
    override function create():Void {
        // Initialize backend
        ScriptManager.init();
        Logging.init();
        Conductor.init();
        Controls.init();
        NoteSkin.init();

        // Initialize HaxeUI
        Toolkit.theme = "eternal";
        Toolkit.init();

        // Load mods
        Mods.reload();

        // Load save data
        OptionsManager.load();
        SongProgress.load();
        Scoring.self.load();

        #if DISCORD_RPC
        // Starts the Discord Rich Presence
        new DiscordRPC();
        #end

        // Apply some changes to the game
        FlxG.fixedTimestep = false;
        FlxG.mouse.visible = false;

        // Check if the game was fullscreen last time
        if (FlxG.save.data.fullscreen != null)
            FlxG.fullscreen = FlxG.save.data.fullscreen;

        // Setup few key actions
        FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, (ev) -> {
            switch (ev.keyCode) {
                case Keyboard.F5:
                    ScriptLoadOverlay.open();
                case Keyboard.F11:
                    FlxG.fullscreen = !FlxG.fullscreen;
                    FlxG.save.data.fullscreen = FlxG.fullscreen;
                    FlxG.save.flush();
            }
        });

        /*
        // If no mods has been found, it automatically switch to an exception state, no need to go to the next screen
        if (Mods.mods.length == 0) return;
        */

        Transition.skipNextTransOut = true;

        // Go to the script load screen
        FlxG.switchState(ScriptLoadScreen.new.bind(TitleScreen.new));
    }
}
