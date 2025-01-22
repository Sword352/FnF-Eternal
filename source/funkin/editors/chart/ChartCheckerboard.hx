package funkin.editors.chart;

import flixel.math.FlxRect;
import openfl.display.BitmapData;
import flixel.group.FlxSpriteGroup;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

class ChartCheckerboard extends FlxSpriteGroup {
    static var PRIMARY_COLOR_DARK:FlxColor = 0xFF4D4949;
    static var SECONDARY_COLOR_DARK:FlxColor = 0xFF353131;

    static var PRIMARY_COLOR_LIGHT:FlxColor = 0xFFC8C7C7;
    static var SECONDARY_COLOR_LIGHT:FlxColor = 0xFFACAAAA;

    // public var theme(default, set):ChartTheme = DARK;
    public var bottom(default, set):Float = 0;

    public var measureSep:FlxBackdrop;
    public var beatSep:FlxBackdrop;

    var opponentSide:FlxBackdrop;
    var playerSide:FlxBackdrop;
    var eventGrid:FlxBackdrop;

    var overlayTop:FlxSprite;
    var overlayBottom:FlxSprite;
    var bottomLine:FlxSprite;

    public function new():Void {
        super(FlxG.width * 0.5 - ChartEditor.checkerSize * 4);

        var bmd:BitmapData = createGrid(PRIMARY_COLOR_DARK, SECONDARY_COLOR_DARK);

        opponentSide = new FlxBackdrop(bmd, Y);
        add(opponentSide);

        playerSide = new FlxBackdrop(bmd, Y);
        playerSide.x = playerSide.width + ChartEditor.separatorWidth;
        add(playerSide);

        for (i in 0...3) {
            var separator:FlxSprite = new FlxSprite(x + ChartEditor.checkerSize * 4 * i);
            separator.makeRect(ChartEditor.separatorWidth, FlxG.height, FlxColor.BLACK, false, "charteditor_checkerline");
            separator.x += separator.width * (i - 1);
            separator.x = Math.floor(separator.x); // avoids weird width
            separator.scrollFactor.set();
            group.add(separator);
        }
        
        eventGrid = new FlxBackdrop(bmd, Y);
        eventGrid.clipRect = FlxRect.get(0, 0, ChartEditor.checkerSize, ChartEditor.checkerSize * 2); // just to avoid making another bmd lol
        eventGrid.x = -ChartEditor.checkerSize - ChartEditor.separatorWidth;
        eventGrid.y = -ChartEditor.checkerSize;
        eventGrid.alpha = 0.4;
        add(eventGrid);

        beatSep = new FlxBackdrop(null, Y);
        beatSep.makeRect(ChartEditor.checkerSize * 8 + ChartEditor.separatorWidth, 1, FlxColor.WHITE, false, "charteditor_beatsep");
        beatSep.visible = FlxG.save.data.chartingPrefs.beatSep ?? true;
        add(beatSep);

        measureSep = new FlxBackdrop(null, Y);
        measureSep.makeRect(beatSep.width, 3, FlxColor.WHITE, false, "charteditor_beatsep");
        measureSep.visible = FlxG.save.data.chartingPrefs.measureSep ?? true;
        add(measureSep);

        overlayTop = new FlxSprite();
        // 125 being the camera target offset
        overlayTop.makeRect(ChartEditor.checkerSize * 8 + ChartEditor.separatorWidth * 2, FlxG.height * 0.5 - 125, FlxColor.BLACK);
        overlayTop.y = -overlayTop.height;
        overlayTop.screenCenter(X);
        overlayTop.alpha = 0.6;
        group.add(overlayTop);

        overlayBottom = new FlxSprite();
        overlayBottom.makeRect(overlayTop.width, FlxG.height * 0.5 + 130, FlxColor.BLACK);
        overlayBottom.screenCenter(X);
        overlayBottom.alpha = 0.6;
        group.add(overlayBottom);

        refreshMeasureSep();
        refreshBeatSep();

        bottomLine = new FlxSprite();
        bottomLine.makeRect(ChartEditor.checkerSize * 8 + ChartEditor.separatorWidth, 4, 0xFF8DA5C4);
        add(bottomLine);
        
        active = false;
    }

    override function destroy():Void {
        // theme = null;
        super.destroy();
    }

    public inline function refreshMeasureSep():Void {
        // without reducing by 1 makes the spacing somehow
        measureSep.spacing.y = ChartEditor.checkerSize * Conductor.self.beatsPerMeasure * 4 / measureSep.height - 1;
    }

    public inline function refreshBeatSep():Void {
        beatSep.spacing.y = ChartEditor.checkerSize * 4 - 1;
    }

    /*
    function set_theme(v:ChartTheme):ChartTheme {
        if (v != null) {
            var firstColor:Int = (v == DARK ? PRIMARY_COLOR_DARK : PRIMARY_COLOR_LIGHT);
            var secondColor:Int = (v == DARK ? SECONDARY_COLOR_DARK : SECONDARY_COLOR_LIGHT);

            var bmd:BitmapData = createGrid(firstColor, secondColor);
            eventGrid.loadGraphic(bmd);
            opponentSide.loadGraphic(bmd);
            playerSide.loadGraphic(bmd);

            beatSep.color = measureSep.color = (v == DARK ? FlxColor.WHITE : FlxColor.BLACK);
        }

        return theme = v;
    }
    */

    function set_bottom(v:Float):Float {
        return bottom = bottomLine.y = overlayBottom.y = v;
    }

    override function get_width():Float {
        return playerSide.width + opponentSide.width + ChartEditor.separatorWidth;
    }

    inline function createGrid(color1:Int, color2:Int):BitmapData {
        return FlxGridOverlay.createGrid(
            ChartEditor.checkerSize,
            ChartEditor.checkerSize,
            ChartEditor.checkerSize * 4,
            ChartEditor.checkerSize * 2,
            true, 
            color1, 
            color2
        );
    }
}
