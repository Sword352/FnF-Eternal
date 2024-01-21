package eternal.ui;

import openfl.system.System;
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

    var frames:Array<Float> = [];

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

        text.defaultTextFormat = new TextFormat(Assets.font("vcr"), 18, 0xFFFFFFFF);
        addChild(text);
    }

    override function __enterFrame(_):Void {
        visible = #if FLX_DEBUG !FlxG.game.debugger.visible && #end (showFramerate || showMemory);
        
        if (!visible)
            return;

        text.text = ""
            + ((showFramerate) ? '${Math.min(FlxG.updateFramerate, getFramerate())} FPS' : "")
            + ((showFramerate && showMemory) ? ' / ' : "")
            + ((showMemory) ? FlxStringUtil.formatBytes(cast(System.totalMemory, Float)) : '');
        text.width = text.textWidth;

        background.width = text.width + 20;
        background.visible = showBackground && (showFramerate || showMemory);
    }

    inline function getFramerate():Int {
        var ticks:Float = FlxG.game.ticks;
        frames.push(ticks);

        while (frames[0] < ticks - 1000)
            frames.shift();

        return frames.length;
    }
}
