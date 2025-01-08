package funkin.ui;

import openfl.ui.Keyboard;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.events.KeyboardEvent;
import external.Memory;

/**
 * An OpenFL sprite which displays the framerate overlay on top of the game.
 */
class FPSOverlay extends Sprite {
    /**
     * Determines whether the overlay is placed at the top left or bottom left corner of the screen.
     */
    public var position(default, set):FPSPos;

    /**
     * Defines the visibility of the overlay.
     */
    public var visibility(default, set):Int;

    /**
     * Determines whether the memory usage of the program should also be displayed.
     */
    public var displayMemory(default, set):Bool;

    /**
     * Defines the refresh rate of the overlay in milliseconds.
     */
    public var pollingRate(default, set):Float = 1000;

    /**
     * Determines how much frames should be accounted in the average framerate calculation.
     */
    public var framerateChecks(default, set):Int = 5;

    /**
     * Overlay background.
     */
    public var background:Sprite;

    /**
     * Text displaying the current framerate.
     */
    public var text:TextField;

    /**
     * Determines the time to wait before increasing `_fpsAverage`.
     * This value is determined by `pollingRate` and `framerateChecks`.
     */
    var _fpsPollingRate:Float = 200;

    /**
     * Stores the accumulation of each accounted frames to calculate the average framerate.
     */
    var _fpsAverage:Float = 0;

    /**
     * Tracks the elapsed time since `_fpsAverage` was last increased.
     */
    var _fpsDelay:Float = 0;

    /**
     * Tracks the elapsed time since the last update.
     * The overlay updates if this value exceeds `pollingRate`.
     */
    var _delay:Float = 0;

    /**
     * Stores how much time has been elapsed since the launch of the game.
     * Used to calculate the current framerate.
     */
    var _ticks:Int = 0;

    /**
     * Current framerate.
     */
    var _fps:Float = 0;

    /**
     * Creates a new `FPSOverlay`.
     */
    public function new():Void {
        super();

        background = new Sprite();
        background.graphics.beginFill(0, 0.3);
        background.graphics.drawRect(0, 0, 1, 1);
        background.graphics.endFill();
        addChild(background);

        text = new TextField();
        text.defaultTextFormat = new TextFormat("Monsterrat", 13, FlxColor.WHITE);
        text.selectable = false;
        text.autoSize = LEFT;
        addChild(text);

        text.x = 6;
        text.y = 9;
        background.x = 5;
        background.y = 8;

        visibility = FlxG.save.data.fpsVisibility ?? 1;
        displayMemory = FlxG.save.data.displayMemory ?? false;
        updateText("?");

        FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
        FlxG.signals.gameResized.add((_, _) -> resizeOverlay());

        #if FLX_DEBUG
        FlxG.debugger.visibilityChanged.add(updateVisibility);
        #end
    }

    /**
     * Update behaviour.
     */
    override function __enterFrame(delta:Int):Void {
        if (!visible)
            return;

        _delay += delta;
        updateFramerate();

        if (_delay < pollingRate)
            return;

        var display:String = getText();
        if (text.htmlText != display)
            updateText(display);

        _delay = 0;
    }

    /**
     * Forces the overlay to update.
     */
    public inline function forceRefresh():Void {
        _delay = pollingRate;
    }

    /**
     * Updates the displayed text.
     * @param display String to display.
     */
    function updateText(display:String):Void {
        text.htmlText = display;

        // fix text cutting off
        text.width = text.textWidth;

        // and resize background
        background.width = text.width + 5;
    }

    #if FLX_DEBUG
    /**
     * Synchronizes the overlay's visibility with the debugger's.
     * The overlay becomes hidden if the debugger is visible.
     */
    inline function updateVisibility():Void {
        visible = !FlxG.game.debugger.visible && visibility > 0;
    }
    #end

    /**
     * Resizes the overlay to match the game's size and position.
     */
    function resizeOverlay():Void {
        scaleX = FlxG.scaleMode.scale.x;
        scaleY = FlxG.scaleMode.scale.y;

        if (position == BOTTOM)
            updateBottomPos();
    }

    /**
     * Updates the vertical position of the overlay to align with the bottom left corner of the game screen.
     */
    inline function updateBottomPos():Void {
        y = FlxG.scaleMode.offset.y + FlxG.scaleMode.gameSize.y - ((background.height + 20) * scaleY);
    }

    /**
     * Computes the current framerate.
     */
    function updateFramerate():Void {
        var deltaTime:Int = FlxG.game.ticks - _ticks;
        _ticks = FlxG.game.ticks;

        // the delta time can somewhat be 0 from time to times on some targets (notably hashlink)
        if (deltaTime > 0) {
            // use exponential smoothing to avoid "flickering" values
            _fps = (_fps * 0.8) + (Math.floor(1000 / deltaTime) * 0.2);
        }

        _fpsDelay += deltaTime;
        if (_fpsDelay >= _fpsPollingRate) {
            _fpsAverage += _fps;
            _fpsDelay = 0;
        }
    }

    /**
     * Returns the text to be displayed.
     * @return String
     */
    function getText():String {
        var output:String = '<font size="17">' + getAverageFramerate() + "</font> FPS";

        if (displayMemory)
            output += "\n" + getMemory();

        return  output;
    }

    /**
     * Returns the average framerate since the last elapsed second.
     * @return Int
     */
    function getAverageFramerate():Int {
        // need to bound the framerate due to an issue with lime's main loop, which is going to be fixed soon
        var average:Float = _fpsAverage / framerateChecks;
        var output:Int = Math.floor(Math.min(FlxG.drawFramerate, average));

        _fpsAverage = 0;
        return output;
    }

    /**
     * Method which outputs a formatted string displaying the current memory usage.
     * @return String
     */
    function getMemory():String {
        static var memoryUnits:Array<String> = ["B", "KB", "MB", "GB"];
        
        var memory:Float = Memory.getProcessUsage();
        var iterations:Int = 0;

        while (memory >= 1000) {
            memory /= 1000;
            iterations++;
        }

        // use 100 for a decimal precision of 2
        return Std.string(Math.fround(memory * 100) / 100) + " " + memoryUnits[iterations];
    }

    /**
     * Method called whenever a key has been released.
     */
    function onKeyRelease(event:KeyboardEvent):Void {
        switch (event.keyCode) {
            case Keyboard.F3:
                visibility = (visibility + 1) % 3;
                forceRefresh();

                FlxG.save.data.fpsVisibility = visibility;
                FlxG.save.flush();
            case Keyboard.F4:
                displayMemory = !displayMemory;
                forceRefresh();

                if (position == BOTTOM)
                    updateBottomPos();

                FlxG.save.data.displayMemory = displayMemory;
                FlxG.save.flush();       
        }
    }

    function set_pollingRate(v:Float):Float {
        _fpsPollingRate = v / framerateChecks;
        return pollingRate = v;
    }

    function set_framerateChecks(v:Int):Int {
        _fpsPollingRate = pollingRate / v;
        return framerateChecks = v;
    }

    function set_position(v:FPSPos):FPSPos {
        switch (v) {
            case TOP:
                y = 0;
            case BOTTOM:
                updateBottomPos();
        }

        return position = v;
    }

    function set_visibility(v:Int):Int {
        switch (v) {
            case 0:
                visible = false;
            case 1 | 2:
                visible = true;
                background.visible = (v == 2);
        }

        return visibility = v;
    }

    function set_displayMemory(v:Bool):Bool {
        background.height = (v ? 43 : 24);
        return displayMemory = v;
    }
}

enum abstract FPSPos(Int) from Int to Int {
    var TOP;
    var BOTTOM;
}
