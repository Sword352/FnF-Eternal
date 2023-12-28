package flixel.system.ui;

#if FLX_SOUND_SYSTEM
import openfl.Lib;

import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

// TODO: move the code to a custom class without having to shadow the base FlxSoundTray class

/**
 * Eternal Engine modifications:
 * - Modified soundtray visual
 * - Changed soundtray sound
 */

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 */
class FlxSoundTray extends Sprite {
	/**
	 * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
	 */
	public var active:Bool;

	/**
	 * Helps us auto-hide the sound tray after a volume change.
	 */
	var _timer:Float;

	var _bars:Array<Bitmap>;
	var text:TextField;
	var bg:Bitmap;

	/**
	 * How wide the sound tray background is.
	 */
	var _width:Int = 80;

	var _defaultScale:Float = 2;

    var _intendedY:Float;

	/**
     * The sound used when increasing the volume.
     */
	public var volumeUpSound:String = "scrollVolume";

	/**
     * The sound used when decreasing the volume.
     */
	public var volumeDownSound:String = "scrollVolume";

	/**
     * Whether or not changing the volume should make noise.
     */
	public var silent:Bool = false;

	@:keep public function new() {
		super();

		visible = false;

		scaleX = _defaultScale;
		scaleY = _defaultScale;

		// TODO: maybe add support for modded soundtray assets?
		bg = new Bitmap(BitmapData.fromFile("assets/images/ui/soundtray.png"));
		bg.scaleX = bg.scaleY = 0.5;
		bg.smoothing = true;
		bg.alpha = 0.65;
		screenCenter();
		addChild(bg);

		text = new TextField();
		text.width = bg.width;
		text.height = bg.height;
		text.multiline = true;
		text.wordWrap = true;
		text.selectable = false;

		var dtf:TextFormat = new TextFormat("assets/fonts/vcr.ttf", 10, FlxColor.WHITE);
		dtf.align = TextFormatAlign.CENTER;
		text.defaultTextFormat = dtf;

		text.text = "VOLUME";
		text.y = bg.y + bg.height / 4;
		addChild(text);

		_bars = [];

		var bx:Int = 10;

		for (i in 0...10) {
			var tmp:Bitmap = new Bitmap(new BitmapData(4, 1, false, FlxColor.WHITE));
			tmp.x = bx;
			tmp.y = text.y;
			addChild(tmp);
			_bars.push(tmp);
			bx += 6;
		}

		y = -height;
        _intendedY = y;
	}

	public function update(MS:Float):Void {
		var elapsed:Float = MS / 1000;

		if (_timer > 0)
			_timer -= elapsed;
		else if (_intendedY > -height) {
			_intendedY -= elapsed * height * 4;

			if (_intendedY <= -height) {
				visible = false;
				active = false;

				// Save sound preferences
				if (FlxG.save.isBound) {
					FlxG.save.data.mute = FlxG.sound.muted;
					FlxG.save.data.volume = FlxG.sound.volume;
					FlxG.save.flush();
				}
			}
		}

        y = FlxMath.lerp(y, _intendedY, FlxMath.bound(elapsed * 24, 0, 1));
	}

	/**
	 * Makes the little volume tray slide out.
	 * @param up Whether the volume is increasing.
	 */
	public function show(up:Bool = false):Void {
		if (!silent)
			FlxG.sound.play(Assets.sound(up ? volumeUpSound : volumeDownSound));

		_timer = 1;
		_intendedY = 0;

		visible = true;
		active = true;

		var volume:Int = (FlxG.sound.muted) ? 0 : Math.floor(FlxG.sound.volume * 100);
		var globalVolume:Int = (FlxG.sound.muted) ? 0 : Math.round(FlxG.sound.volume * 10);

		text.text = 'VOLUME: ${volume}%';

		for (i in 0..._bars.length)
            _bars[i].alpha = (i < globalVolume) ? 1 : 0.5;
	}

	public function screenCenter():Void {
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		x = (0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
	}
}
#end