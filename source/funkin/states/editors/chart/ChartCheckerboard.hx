package funkin.states.editors.chart;

import flixel.math.FlxRect;
import openfl.display.BitmapData;
import flixel.group.FlxSpriteGroup;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

class ChartCheckerboard extends FlxSpriteGroup {
    public var bottom(default, set):Float = 0;

    var opponentSide:FlxBackdrop;
    var playerSide:FlxBackdrop;

    var overlayTop:FlxSprite;
    var overlayBottom:FlxSprite;
    var bottomLine:FlxSprite;

    public function new():Void {
        var width:Int = ChartEditor.checkerSize * 4;
        var pattern:Int = ChartEditor.checkerSize * 2;
        var bmd:BitmapData = FlxGridOverlay.createGrid(ChartEditor.checkerSize, ChartEditor.checkerSize, width, pattern, true, 0xFF4D4949, 0xFF353131);

        super(FlxG.width * 0.5 - width);

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
        
        var eventGrid:FlxBackdrop = new FlxBackdrop(bmd, Y);
        eventGrid.clipRect = FlxRect.get(0, 0, ChartEditor.checkerSize, pattern); // just to avoid making another bmd lol
        eventGrid.x = -ChartEditor.checkerSize - ChartEditor.separatorWidth;
        eventGrid.y = -ChartEditor.checkerSize;
        eventGrid.alpha = 0.4;
        add(eventGrid);

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

        bottomLine = new FlxSprite();
        bottomLine.makeRect(ChartEditor.checkerSize * 8 + ChartEditor.separatorWidth, 5, 0xFF8DA5C4);
        add(bottomLine);
        
        active = false;
    }

    function set_bottom(v:Float):Float {
        return bottom = bottomLine.y = overlayBottom.y = v;
    }

    override function get_width():Float {
        return playerSide.width + opponentSide.width + ChartEditor.separatorWidth;
    }
}
