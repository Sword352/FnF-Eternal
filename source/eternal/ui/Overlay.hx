package eternal.ui;

import openfl.system.System;
import haxe.Timer.stamp as stamp;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

import flixel.util.FlxStringUtil;

class Overlay extends Sprite {
    public var background:Sprite;
    public var text:TextField;

    public var showBackground:Bool = Settings.get("show overlay background");
    public var showFramerate:Bool = Settings.get("show framerate");
    public var showMemory:Bool = Settings.get("show memory");

    // TODO: maybe use another method to calculate the frameate?
    var fps:Array<Float> = [];

    public function new() {
        super();

        // create the background
        background = new Sprite();

        background.graphics.beginFill();
        background.graphics.drawRect(0, 0, 1, 30);
        background.graphics.endFill();

        background.x = background.y = -10;
        background.alpha = 0.45;

        background.visible = showBackground && (showFramerate || showMemory);
        addChild(background);

        // create the text
        text = new TextField();

        text.x = 5;
        text.y = 2.5;
        text.scaleX = 0.85;
        text.scaleY = 0.85;

        text.multiline = true;
        text.selectable = false;
        text.mouseEnabled = false;

        text.defaultTextFormat = new TextFormat(AssetHelper.font("vcr"), 18, 0xFFFFFFFF);
        addChild(text);
    }

    override function __enterFrame(_):Void {
        updateFramerate();

        text.text = ""
            +  ((showFramerate) ? '${Math.min(FlxG.updateFramerate, fps.length)} FPS' : "")
            +  ((showFramerate && showMemory) ? ' / ' : "")
            +  ((showMemory) ? FlxStringUtil.formatBytes(System.totalMemory) : '');

        text.width = text.textWidth;

        background.width = text.width + 20;
        background.visible = showBackground && (showFramerate || showMemory);
    }

    function updateFramerate():Void {
        var currentTime:Float = stamp();
        // we're using an array for interpolation
        fps.push(currentTime);
        while (fps[0] < currentTime - 1)
            fps.shift();
    }
}
