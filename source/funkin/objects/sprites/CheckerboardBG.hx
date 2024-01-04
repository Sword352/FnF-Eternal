package funkin.objects.sprites;

import flixel.graphics.FlxGraphic;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxAxes;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

class CheckerboardBG extends FlxBackdrop
{
	private var _actualImage:FlxGraphic;

	public var color1(default, set):Null<FlxColor> = 0xFF000000; // top-left, bottom-right
	public var color2(default, set):Null<FlxColor> = 0xFFFFFFFF; // top-right, bottom-left

	override public function new(width:Int, height:Int, color1:Null<FlxColor>, color2:Null<FlxColor>, repeatAxes:FlxAxes = XY, spacingX:Float = 0.0,
			spacingY:Float = 0.0)
	{
		this.color1 = color1;
		this.color2 = color2;

		var initialBitmap:BitmapData = new BitmapData(width, height, true, 0);

		initialBitmap.lock();

		var remainderWidth:Int = 0;
		var remainderHeight:Int = 0;

		if (width % 2 != 0)
			remainderWidth = Math.floor(width % 2);
		if (height % 2 != 0)
			remainderHeight = Math.floor(height % 2);

		if (color1 != null && color1.alpha > 0)
		{
			var topLeft:Rectangle = new Rectangle(0, 0, Math.ceil(width / 2), Math.ceil(height / 2));
			initialBitmap.fillRect(topLeft, color1);

			var bottomRight:Rectangle = new Rectangle(topLeft.width, topLeft.height, Math.ceil(width / 2) + remainderWidth,
				Math.ceil(height / 2) + remainderHeight);
			initialBitmap.fillRect(bottomRight, color1);
		}

		if (color2 != null && color2.alpha > 0)
		{
			var bottomLeft:Rectangle = new Rectangle(0, Math.ceil(height / 2), Math.ceil(width / 2), Math.ceil(height / 2));
			initialBitmap.fillRect(bottomLeft, color2);

			var topRight:Rectangle = new Rectangle(Math.ceil(width / 2), 0, Math.ceil(width / 2) + remainderWidth, Math.ceil(height / 2) + remainderHeight);
			initialBitmap.fillRect(topRight, color2);
		}

		initialBitmap.unlock();

		_actualImage = FlxGraphic.fromBitmapData(initialBitmap, false, 'checkerboard_${width}_${height}_${color1}_${color2}');

		super(_actualImage, XY, spacingX, spacingY);
	}

	function set_color1(newColor:Null<FlxColor>):Null<FlxColor>
	{
		color1 = newColor;

		var checkBitmap:BitmapData = _actualImage?.bitmap;

		if (checkBitmap != null)
		{
			var remainderWidth:Int = 0;
			var remainderHeight:Int = 0;

			if (width % 2 != 0)
				remainderWidth = Math.floor(width % 2);
			if (height % 2 != 0)
				remainderHeight = Math.floor(height % 2);

			if (color1 != null && color1.alpha > 0)
			{
				var topLeft:Rectangle = new Rectangle(0, 0, Math.ceil(width / 2), Math.ceil(height / 2));
				checkBitmap.fillRect(topLeft, color1);

				var bottomRight:Rectangle = new Rectangle(topLeft.width, topLeft.height, Math.ceil(width / 2) + remainderWidth,
					Math.ceil(height / 2) + remainderHeight);
				checkBitmap.fillRect(bottomRight, color1);
			}
		}

		return newColor;
	}

	function set_color2(newColor:Null<FlxColor>):Null<FlxColor>
	{
		color2 = newColor;

		var checkBitmap:BitmapData = _actualImage?.bitmap;

		if (checkBitmap != null)
		{
			var remainderWidth:Int = 0;
			var remainderHeight:Int = 0;

			if (width % 2 != 0)
				remainderWidth = Math.floor(width % 2);
			if (height % 2 != 0)
				remainderHeight = Math.floor(height % 2);

			if (color2 != null && color2.alpha > 0)
			{
				var bottomLeft:Rectangle = new Rectangle(0, Math.ceil(height / 2), Math.ceil(width / 2), Math.ceil(height / 2));
				checkBitmap.fillRect(bottomLeft, color2);

				var topRight:Rectangle = new Rectangle(Math.ceil(width / 2), 0, Math.ceil(width / 2) + remainderWidth, Math.ceil(height / 2) + remainderHeight);
				checkBitmap.fillRect(topRight, color2);
			}
		}

		return newColor;
	}
}
