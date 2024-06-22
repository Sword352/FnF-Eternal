package funkin.objects;

import flixel.util.FlxAxes;
import flixel.graphics.FlxGraphic;
import flixel.addons.display.FlxBackdrop;

import openfl.geom.Rectangle;
import openfl.display.BitmapData;

class CheckerboardBG extends FlxBackdrop {
    public var color1(default, set):FlxColor = 0xFF000000; // top-left, bottom-right
    public var color2(default, set):FlxColor = 0xFFFFFFFF; // top-right, bottom-left

    var _actualImage:FlxGraphic;

    public function new(width:Int, height:Int, color1:FlxColor, color2:FlxColor, repeatAxes:FlxAxes = XY, spacingX:Float = 0, spacingY:Float = 0):Void {
        super(null, repeatAxes, spacingX, spacingY);

        _actualImage = getGraphic(width, height, color1, color2);
        loadGraphic(_actualImage);

        this.color1 = color1;
        this.color2 = color2;
    }

    function set_color1(newColor:FlxColor):FlxColor {
        setColor1Rects(newColor, _actualImage?.bitmap);
        return color1 = newColor;
    }

    function set_color2(newColor:FlxColor):FlxColor {
        setColor2Rects(newColor, _actualImage?.bitmap);
        return color2 = newColor;
    }

    inline function setColor1Rects(newColor:FlxColor, bitmap:BitmapData):Void {
        if (bitmap == null)
            return;

        var remainder:Array<Int> = getRemainder();

        var topLeft:Rectangle = new Rectangle(0, 0, Math.ceil(width / 2), Math.ceil(height / 2));
        bitmap.fillRect(topLeft, newColor);

        var bottomRight:Rectangle = new Rectangle(topLeft.width, topLeft.height, Math.ceil(width / 2) + remainder[0], Math.ceil(height / 2) + remainder[1]);
        bitmap.fillRect(bottomRight, newColor);
    }

    inline function setColor2Rects(newColor:FlxColor, bitmap:BitmapData):Void {
        if (bitmap == null)
            return;

        var remainder:Array<Int> = getRemainder();

        var bottomLeft:Rectangle = new Rectangle(0, Math.ceil(height / 2), Math.ceil(width / 2), Math.ceil(height / 2));
        bitmap.fillRect(bottomLeft, newColor);

        var topRight:Rectangle = new Rectangle(Math.ceil(width / 2), 0, Math.ceil(width / 2) + remainder[0], Math.ceil(height / 2) + remainder[1]);
        bitmap.fillRect(topRight, newColor);
    }

    // better way to do this? will come back to this later
    inline function getRemainder():Array<Int>
        return [Math.floor(width % 2), Math.floor(height % 2)];

    override function destroy():Void {
        _actualImage = null;
        super.destroy();
    }

    inline static function getGraphic(width:Int, height:Int, color1:FlxColor, color2:FlxColor):FlxGraphic {
        var key:String = 'checkerboard_${width}_${height}_${color1}_${color2}';
        return FlxG.bitmap.get(key) ?? FlxGraphic.fromBitmapData(new BitmapData(width, height, true, 0), false, key);
    }
}
