package funkin.ui;

import openfl.media.Sound;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFormat;

import flixel.system.ui.FlxSoundTray;

class SoundTray extends FlxSoundTray {
    var _text:TextField;
    var _intendedY:Float;
    var _sound:Sound;

    @:keep
    public function new():Void {
        super();

        var background:Bitmap = cast getChildAt(0);

        // dispose old bitmap data
        background.bitmapData.dispose();

        // load custom bitmap data
        background.bitmapData = BitmapData.fromFile("assets/images/ui/soundtray.png");
        background.bitmapData.disposeImage();
        
        background.scaleX = background.scaleY = 0.5;
        background.smoothing = true;
        background.alpha = 0.65;

        _text = cast getChildAt(1);

        // get_defaultTextFormat returns a copy of the actual text format...
        var textFormat:TextFormat = _text.defaultTextFormat;
        textFormat.font = "assets/fonts/vcr.ttf";
        _text.defaultTextFormat = textFormat;

        _text.y = background.height * 0.25;

        for (i in 0...10) {
            var bar:Bitmap = cast getChildAt(2 + i);
            bar.bitmapData.disposeImage();
            bar.bitmapData.dispose();

            bar.bitmapData = new BitmapData(4, 1, false, FlxColor.WHITE);
            bar.y = _text.y;
        }

        _sound = Sound.fromFile("assets/sounds/scrollVolume.ogg");
        y = _intendedY = -height;
    }

    override function update(ms:Float):Void {
        var elapsed:Float = (ms * 0.001);

        if (_timer > 0)
            _timer -= elapsed;
        else if (_intendedY > -height) {
            _intendedY -= elapsed * height * 4;
            if (_intendedY <= -height) {
                active = visible = false;
                saveSoundPreferences();
            }
        }

        if (_intendedY != y)
            y = Tools.lerp(y, _intendedY, 24);
    }

    override function show(up:Bool = false):Void {
        var volume:Int = (FlxG.sound.muted) ? 0 : Math.floor(FlxG.sound.volume * 100);
        var globalVolume:Int = (FlxG.sound.muted) ? 0 : Math.round(FlxG.sound.volume * 10);

        _text.text = 'VOLUME: ${volume}%';

        for (i in 0..._bars.length)
            _bars[i].alpha = (i < globalVolume) ? 1 : 0.5;

        if (!silent)
            _sound.play();

        active = visible = true;
        _intendedY = 0;
        _timer = 1;
    }

    function saveSoundPreferences():Void {
        if (!FlxG.save.isBound)
            return;

        FlxG.save.data.mute = FlxG.sound.muted;
        FlxG.save.data.volume = FlxG.sound.volume;
        FlxG.save.flush();
    }
}
