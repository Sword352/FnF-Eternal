package ui;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

class FPSOverlay extends Sprite {
    static final memoryUnits:Array<String> = ["bytes", "kb", "mb", "gb"];

    public var showFps(default, set):Bool;
    public var showMem(default, set):Bool;
    public var showBg(default, set):Bool;

    public var relativeX(default, set):Float = -1;
    public var relativeY(default, set):Float = -1;

    public var background:Sprite;
    public var text:TextField;

    var timeout:Float = 0;
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
        text.selectable = false;
        addChild(text);

        text.y = 2.5;
        text.x = 5;

        showBg = Options.showFpsBg;
        showFps = Options.showFramerate;
        showMem = Options.showMemory;

        FlxG.signals.gameResized.add((_, _) -> updateRelativePosition());

        #if FLX_DEBUG
        FlxG.debugger.visibilityChanged.add(updateVisibility);
        #end
    }

    override function __enterFrame(delta:Int):Void {
        if (!visible) return;

        timeout += delta;
        updateFPS();

        if (timeout < 1000) return;

        var display:String = getText();
        if (text.text != display) {
            text.text = display;
            
            var textWidth:Float = text.textWidth;
            if (background.visible) background.width = textWidth + 10;
            text.width = textWidth;
        }

        timeout = 0;
    }

    public function resetPosition():Void {
        relativeX = relativeY = -1;
        x = y = 0;
    }

    public inline function forceRefresh():Void {
        timeout = 1000;
    }

    inline function updateRelativePosition():Void {
        if (relativeX != -1) x = relativeX * FlxG.scaleMode.scale.x;
        if (relativeY != -1) y = relativeY * FlxG.scaleMode.scale.y;
    }

    inline function updateVisibility():Void {
        visible = #if FLX_DEBUG !FlxG.game.debugger.visible && #end (showFps || showMem);
    }

    inline function updateFPS():Void {
        /**
         * Uses exponential smoothing to avoid noisy values
         * value = (old * (1 - a)) + (new * a)
         */

        var deltaTime:Int = FlxG.game.ticks - ticks;
        fps = (fps * 0.8) + (Math.floor(1000 / deltaTime) * 0.2);
        ticks = FlxG.game.ticks;
    }

    inline function getText():String {
        return ((showFps) ? ('${getFramerate()} FPS' + ((showMem) ? ' | ' : "")) : "")
            + ((showMem) ? (getMemory() + " RAM") : "");
    }

    inline function getFramerate():Int {
        return Math.floor(Math.min(FlxG.drawFramerate, fps));
    }

    inline function getMemory():String {
        var memory:Float = #if windows external.Memory.get(); #else openfl.system.System.totalMemory; #end
        var iterations:Int = 0;

        while (memory >= 1024) {
            memory /= 1024;
            iterations++;
        }

        // 100 = 2 unit precision
        return Std.string(Math.fround(memory * 100) / 100) + memoryUnits[iterations];
    }

    function set_showFps(v:Bool):Bool {
        showFps = v;
        updateVisibility();
        forceRefresh();
        return v;
    }

    function set_showMem(v:Bool):Bool {
        showMem = v;
        updateVisibility();
        forceRefresh();
        return v;
    }

    function set_showBg(v:Bool):Bool {
        background.visible = v;
        if (v && (showFps || showMem)) background.width = text.textWidth + 10;
        return showBg = v;
    }

    function set_relativeX(v:Float):Float {
        relativeX = v;
        updateRelativePosition();
        return v;
    }

    function set_relativeY(v:Float):Float {
        relativeY = v;
        updateRelativePosition();
        return v;
    }
}
