package funkin.states;

import flixel.FlxState;
import funkin.states.menus.TitleScreen;

#if ENGINE_CRASH_HANDLER
import eternal.core.crash.CrashHandler;
#end

#if mac
import flixel.input.keyboard.FlxKey;
#end

// State used to initialize some stuff before the launch of the game
class InitState extends FlxState {
    override function create():Void {
        // Init some backend stuff
        #if ENGINE_CRASH_HANDLER
        CrashHandler.init();
        #end

        #if ENGINE_DISCORD_RPC
        DiscordPresence.init();
        #end

        // Setup controls
        Controls.globalControls = new Controls("main");
        Controls.reloadVolumeKeys();

        // Changes to some Flixel global variables
        FlxG.fixedTimestep = false;
        FlxG.mouse.visible = false;

        // Check if the game was fullscreen last time
        if (FlxG.save.data.fullscreen != null)
            FlxG.fullscreen = FlxG.save.data.fullscreen;

        // Add callbacks to clear memory when switching states
        FlxG.signals.preStateSwitch.add(AssetHelper.freeMemory);
        FlxG.signals.preStateCreate.add(AssetHelper.freeMemoryPost);

        #if mac
        // Fix for the "+" key not working on MacOS
        @:privateAccess FlxG.keys._nativeCorrection.set("0_43", FlxKey.PLUS);
        #end

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
        FlxG.switchState(new TitleScreen());
    }
}
