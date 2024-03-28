package eternal.ui;

import openfl.Lib;
import openfl.system.System;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.util.FlxStringUtil;

class FPSOverlay extends Sprite {
    public var showBg:Bool = Settings.get("show overlay background");
    public var showFps:Bool = Settings.get("show framerate");
    public var showMem:Bool = Settings.get("show memory");

    public var background:Sprite;
    public var text:TextField;

    var lastFPS:Float = 0;
    var delta:Float = 0;

    public function new():Void {
        super();

        background = new Sprite();
        background.graphics.beginFill(0, 0.3);
        background.graphics.drawRect(0, 0, 1, 25);
        background.graphics.endFill();
        addChild(background);

        text = new TextField();
        text.defaultTextFormat = new TextFormat("Monsterrat", 15, FlxColor.WHITE);
        text.x = 5;
        text.y = 2.5;
        addChild(text);
    }

    override function __enterFrame(_):Void {
        visible = #if FLX_DEBUG !FlxG.game.debugger.visible && #end (showFps || showMem);
        if (!visible) return;

        text.text = getText();
        text.width = text.textWidth;

        background.visible = (showBg && (showFps || showMem));
        if (background.visible) background.width = text.width + 10;
    }

    inline function getText():String {
        return ((showFps) ? ('${getFramerate()} FPS' + ((showMem) ? ' | ' : "")) : "")
            + ((showMem) ? (FlxStringUtil.formatBytes(getMemory()).toLowerCase() + " RAM") : "");
    }

    inline function getFramerate():Int {
        // use exponential smoothing to avoid noisy values
        // value = (old * (1 - a)) + (new * a)

        var oldDelta:Float = delta;
        delta = Lib.getTimer();

        lastFPS = (lastFPS * 0.8) + ((1 / ((delta - oldDelta) * 0.001)) * 0.2);
        return Math.floor(Math.min(FlxG.updateFramerate, lastFPS));
    }

    inline function getMemory():Float {
        /*
            #if cpp
            return Gc.memInfo64(Gc.MEM_INFO_USAGE);
            #else
         */
        return cast(System.totalMemory, Float);
        // #end
    }
}
