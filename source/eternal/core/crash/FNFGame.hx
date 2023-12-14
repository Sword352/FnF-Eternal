package eternal.core.crash;

#if ENGINE_CRASH_HANDLER
import flixel.FlxGame;
import haxe.Exception;

// FlxGame with error handling
// original by @superpowers04
class FNFGame extends FlxGame {
    override function create(_):Void {
        try
            super.create(_)
        catch (e:Exception)
            return onCrash(e, "create");
    }

    override function update():Void {
        try
            super.update()
        catch (e:Exception)
            return onCrash(e, "update");
    }

    override function draw():Void {
        try
            super.draw()
        catch (e:Exception)
            return onCrash(e, "draw");
    }

    override function onEnterFrame(_):Void {
        try
            super.onEnterFrame(_)
        catch (e:Exception)
            return onCrash(e, "onEnterFrame");
    }

    override function onFocus(_):Void {
        try
            super.onFocus(_)
        catch (e:Exception)
            return onCrash(e, "onFocus");
    }

    override function onFocusLost(_):Void {
        try
            super.onFocusLost(_)
        catch (e:Exception)
            return onCrash(e, "onFocusLost");
    }

    private function onCrash(event:Exception, func:String = "[UNKNOWN]"):Void {        
        CrashHandler.processCrash(event);
        AssetHelper.clearAssets = true;
        
        TransitionSubState.onComplete.removeAll();
        Tools.stopAllSounds();
        
        _requestedState = new CrashScreen(func);
        switchState();
    }
}
#end