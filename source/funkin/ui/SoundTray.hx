package funkin.ui;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFormat;

import flixel.system.ui.FlxSoundTray;

class SoundTray extends FlxSoundTray {
    var text:TextField;
    var intendedY:Float;

    @:keep
    public function new():Void {
        super();

        var background:Bitmap = cast getChildAt(0);

        // dispose old bitmap data
        background.bitmapData.disposeImage();
        background.bitmapData.dispose();

        background.bitmapData = openfl.Assets.getBitmapData("assets/images/ui/soundtray.png");
        background.scaleX = background.scaleY = 0.5;
        background.smoothing = true;
        background.alpha = 0.65;

        text = cast getChildAt(1);

        // get_defaultTextFormat returns a copy of the actual text format...
        var textFormat:TextFormat = text.defaultTextFormat;
        textFormat.font = "assets/fonts/vcr.ttf";
        text.defaultTextFormat = textFormat;

        text.y = background.height * 0.25;

        for (i in 0...10) {
            var bar:Bitmap = cast getChildAt(2 + i);
            bar.bitmapData.disposeImage();
            bar.bitmapData.dispose();

            bar.bitmapData = new BitmapData(4, 1, false, FlxColor.WHITE);
            bar.y = text.y;
        }

        volumeUpSound = volumeDownSound = "assets/sounds/scrollVolume.ogg";
        y = intendedY = -height;
    }

    override function update(ms:Float):Void {
        var elapsed:Float = (ms * 0.001);

        if (_timer > 0)
            _timer -= elapsed;
        else if (intendedY > -height) {
            intendedY -= elapsed * height * 4;
            if (intendedY <= -height) {
                active = visible = false;
                saveSoundPreferences();
            }
        }

        if (intendedY != y)
            y = Tools.lerp(y, intendedY, 24);
    }

    override function show(up:Bool = false):Void {
        var volume:Int = (FlxG.sound.muted) ? 0 : Math.floor(FlxG.sound.volume * 100);
        var globalVolume:Int = (FlxG.sound.muted) ? 0 : Math.round(FlxG.sound.volume * 10);

        for (i in 0..._bars.length)
            _bars[i].alpha = (i < globalVolume) ? 1 : 0.5;

        text.text = 'VOLUME: ${volume}%';

        if (!silent)
            FlxG.sound.play((up) ? volumeUpSound : volumeDownSound);

        active = visible = true;
        intendedY = 0;
        _timer = 1;
    }

    inline function saveSoundPreferences():Void {
        if (!FlxG.save.isBound)
            return;

        FlxG.save.data.mute = FlxG.sound.muted;
        FlxG.save.data.volume = FlxG.sound.volume;
        FlxG.save.flush();
    }
}
