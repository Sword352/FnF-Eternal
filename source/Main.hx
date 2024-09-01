package;

import flixel.FlxGame;
import flixel.FlxState;

import funkin.data.NoteSkin;
import funkin.save.SongProgress;
import funkin.menus.TitleScreen;

import funkin.ui.SoundTray;
import funkin.ui.FPSOverlay;

#if CRASH_HANDLER
import funkin.core.CrashHandler;
#end

import openfl.ui.Keyboard;
import openfl.display.Sprite;
import openfl.events.KeyboardEvent;

import haxe.ui.Toolkit;

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
        #if DISCORD_RPC
        DiscordPresence.init();
        #end

        Conductor.init();
        Controls.init();
        Assets.init();
        NoteSkin.init();
        Events.init();

        Toolkit.theme = "eternal";
        Toolkit.init();

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

        // Load mods
        Mods.init();

        // Load save data
        OptionsManager.load();
        SongProgress.load();
        Scoring.self.load();

        /*
        // If no mods has been found, it automatically switch to an exception state, no need to go to the titlescreen
        if (Mods.mods.length == 0) return;
        */

        // Go to the titlescreen
        Transition.skipNextTransIn = true;
        FlxG.switchState(TitleScreen.new);
    }
}
