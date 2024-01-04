package funkin.objects.sprites;

import flixel.addons.display.FlxBackdrop;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxAxes;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

class CheckerboardBG extends FlxBackdrop
{
	private var _actualImage:FlxGraphic;

	public var color1(default, set):Null<FlxColor> = 0xFF000000; // top-left, bottom-right
	public var color2(default, set):Null<FlxColor> = 0xFFFFFFFF; // top-right, bottom-left

	override public function new(width:Int, height:Int, color1:Null<FlxColor>, color2:Null<FlxColor>, repeatAxes:FlxAxes = XY, spacingX:Float = 0.0,
			spacingY:Float = 0.0) {
		this.color1 = color1;
		this.color2 = color2;

		var initialBitmap:BitmapData = new BitmapData(width, height, true, 0);

        setColor1Rects(color1, initialBitmap);
        setColor2Rects(color2, initialBitmap);

		_actualImage = FlxGraphic.fromBitmapData(initialBitmap, false, 'checkerboard_${width}_${height}_${color1}_${color2}');

		super(_actualImage, XY, spacingX, spacingY);
	}

	function set_color1(newColor:Null<FlxColor>):Null<FlxColor> {
		color1 = newColor;

		setColor1Rects(color1, _actualImage?.bitmap);

		return newColor;
    }

	function set_color2(newColor:Null<FlxColor>):Null<FlxColor> {
		color2 = newColor;

        setColor2Rects(color2, _actualImage?.bitmap);

		return newColor;
	}

	inline function setColor1Rects(newColor:FlxColor, bitmap:BitmapData):Void {
		if (bitmap != null) {
			bitmap.lock();

			var remainder:Array<Int> = getRemainder();

			if (color1 != null && color1.alpha > 0) {
				var topLeft:Rectangle = new Rectangle(0, 0, Math.ceil(width / 2), Math.ceil(height / 2));
				bitmap.fillRect(topLeft, color1);

				var bottomRight:Rectangle = new Rectangle(topLeft.width, topLeft.height, Math.ceil(width / 2) + remainder[0],
					Math.ceil(height / 2) + remainder[1]);
				bitmap.fillRect(bottomRight, color1);
			}

			bitmap.unlock();
		}
	}

	inline function setColor2Rects(newColor:FlxColor, bitmap:BitmapData):Void {
		if (bitmap != null) {
			bitmap.lock();

			var remainder:Array<Int> = getRemainder();

			if (color2 != null && color2.alpha > 0) {
				var bottomLeft:Rectangle = new Rectangle(0, Math.ceil(height / 2), Math.ceil(width / 2), Math.ceil(height / 2));
				bitmap.fillRect(bottomLeft, color2);

				var topRight:Rectangle = new Rectangle(Math.ceil(width / 2), 0, Math.ceil(width / 2) + remainder[0], Math.ceil(height / 2) + remainder[1]);
				bitmap.fillRect(topRight, color2);
			}

			bitmap.unlock();
		}
	}

	// better way to do this? will come back to this later
	inline function getRemainder():Array<Int> {
		var remainderWidth:Int = 0;
		var remainderHeight:Int = 0;

		if (width % 2 != 0)
			remainderWidth = Math.floor(width % 2);
		if (height % 2 != 0)
			remainderHeight = Math.floor(height % 2);

		return [remainderWidth, remainderHeight];
	}

    override public function destroy() {
        super.destroy();

        _actualImage.destroy();
        _actualImage = null;
    }
}
