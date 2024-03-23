package funkin.states.debug.chart;

import flixel.math.FlxRect;
import openfl.display.BitmapData;
import flixel.group.FlxSpriteGroup;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.display.FlxGridOverlay;

class ChartCheckerboard extends FlxSpriteGroup {
    var opponentSide:FlxTiledSprite;
    var playerSide:FlxTiledSprite;
    var bottom:FlxSprite;

    public function new():Void {
        var width:Float = ChartEditor.checkerSize * 4;
        var patternSize:Int = ChartEditor.checkerSize * 2;
        var bmd:BitmapData = FlxGridOverlay.createGrid(ChartEditor.checkerSize, ChartEditor.checkerSize, patternSize, patternSize, true, 0xFF4D4949, 0xFF353131);

        super(FlxG.width * 0.5 - width);

        var behind:FlxSprite = new FlxSprite();
        behind.makeRect(ChartEditor.checkerSize * 8 + ChartEditor.separatorWidth * 2, FlxG.height, FlxColor.BLACK);
        behind.scrollFactor.set();
        behind.screenCenter(X);
        behind.alpha = 0.4;
        group.add(behind);

        opponentSide = new FlxTiledSprite(bmd, width, 0);
        add(opponentSide);

        playerSide = new FlxTiledSprite(bmd, width, 0);
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
        eventGrid.clipRect = FlxRect.get(0, 0, ChartEditor.checkerSize, patternSize); // just to avoid making another bmd lol
        eventGrid.x = -ChartEditor.checkerSize - ChartEditor.separatorWidth;
        eventGrid.y = -ChartEditor.checkerSize;
        eventGrid.alpha = 0.4;
        add(eventGrid);

        bottom = new FlxSprite();
        bottom.makeRect(ChartEditor.checkerSize * 8 + ChartEditor.separatorWidth, 5, 0xFF8DA5C4);
        add(bottom);
        
        active = false;
    }

    override function set_height(v:Float):Float {
        if (playerSide != null) {
            playerSide.height = opponentSide.height = v;
            bottom.y = v;
        }

        return height = v;
    }

    override function get_height():Float {
        return height;
    }

    override function get_width():Float {
        return playerSide.width + opponentSide.width + ChartEditor.separatorWidth;
    }
}
