package eternal.ui;

import openfl.system.System;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.util.FlxStringUtil;

class FPSOverlay extends Sprite {
    public var relativeX:Float = -1;
    public var relativeY:Float = -1;

    public var showBg:Bool = Settings.get("show overlay background");
    public var showFps:Bool = Settings.get("show framerate");
    public var showMem:Bool = Settings.get("show memory");

    public var background:Sprite;
    public var text:TextField;

    var ticks:Int = 0;
    var fps:Float = 0;

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

        if (relativeX != -1) x = relativeX * FlxG.scaleMode.scale.x;
        if (relativeY != -1) y = relativeY * FlxG.scaleMode.scale.y;

        text.text = getText();
        text.width = text.textWidth;

        background.visible = (showBg && (showFps || showMem));
        if (background.visible) background.width = text.width + 10;
    }

    public function resetPosition():Void {
        relativeX = relativeY = -1;
        x = y = 0;
    }

    inline function getText():String {
        return ((showFps) ? ('${getFramerate()} FPS' + ((showMem) ? ' | ' : "")) : "")
            + ((showMem) ? (FlxStringUtil.formatBytes(getMemory()).toLowerCase() + " RAM") : "");
    }

    inline function getFramerate():Int {
        // use exponential smoothing to avoid noisy values
        // value = (old * (1 - a)) + (new * a)

        var deltaTime:Int = FlxG.game.ticks - ticks;
        ticks = FlxG.game.ticks;

        fps = (fps * 0.8) + (Math.floor(1000 / deltaTime) * 0.2);
        return Math.floor(Math.min(FlxG.drawFramerate, fps));
    }

    inline function getMemory():Float {
        return cast System.totalMemory;
    }
}
