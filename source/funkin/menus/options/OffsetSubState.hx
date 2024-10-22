package funkin.menus.options;

import flixel.text.FlxText;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class OffsetSubState extends MusicBeatSubState {
    var offsetText:FlxText;
    var music:FlxSound;
    var logo:FlxSprite;

    var holdTime:Float = 0;
    var lastBPM:Float = 0;

    override function create():Void {
        super.create();

        initStateScripts();
        scripts.call("onCreate");

        conductor = new Conductor();
        conductor.bpm = 80;
        add(conductor);

        logo = new FlxSprite(0, FlxG.height, Paths.image("menus/logo"));
        logo.scale.set(0.4, 0.4);
        logo.updateHitbox();
        logo.screenCenter(X);
        logo.y += logo.height;
        add(logo);

        offsetText = new FlxText();
        offsetText.setFormat(Paths.font('vcr'), 34, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        offsetText.updateHitbox();
        offsetText.y = FlxG.height - offsetText.height - 25;
        offsetText.alpha = 0;
        refreshText();
        add(offsetText);

        music = FlxG.sound.load(Paths.music("offsetSong"), 1, true);
        music.onComplete = conductor.resetTime;
        FlxG.sound.music.fadeOut(0.5, 0);
        conductor.music = music;
        
        var beatDuration:Float = conductor.crotchet / 1000;
        FlxTween.tween(offsetText, {alpha: 1}, beatDuration);
        FlxTween.tween(logo, {y: (FlxG.height - logo.height) * 0.5}, beatDuration, {ease: FlxEase.backOut, onComplete: (_) -> music.play()});

        scripts.call("onCreatePost");
    }

    override function update(elapsed:Float):Void {
        scripts.call("onUpdate", elapsed);
        super.update(elapsed);

        if (music.playing) {
            logo.scale.set(Tools.lerp(logo.scale.x, 0.4, 6), Tools.lerp(logo.scale.y, 0.4, 6));
            logo.angle += elapsed * 10;
        }

        if (controls.anyPressed(["left", "right"])) {
            holdTime += elapsed * 5;
            if (holdTime > ((FlxG.keys.pressed.SHIFT) ? 0.0015 : 0.5)) {
                Options.audioOffset += (controls.lastAction == "left" ? -1 : 1);
                refreshText();
                holdTime = 0;
            }
        }

        if (controls.justPressed("back")) {
            OptionsManager.save();
            close();
        }

        scripts.call("onUpdatePost", elapsed);
    }

    override function beatHit(beat:Int):Void {
        if (!music.playing)
            return;

        if (beat > 31 && beat < 112)
            cast(FlxG.state, OptionsMenu).background.scale.add(0.05, 0.05);

        logo.scale.add(0.05, 0.05);
        super.beatHit(beat);
    }

    function refreshText():Void {
        var offset:Float = Options.audioOffset;
        offsetText.text = '< Offset: ${offset}ms (${(offset > 0) ? "LATE" : ((offset == 0) ? "DEFAULT" : "EARLY")}) >';
        offsetText.screenCenter(X);
    }

    override function close():Void {
        music.fadeOut(0.2, 0, (_) -> {
            FlxG.sound.list.remove(music, true);
            music.destroy();
        });
        FlxG.sound.music.fadeOut(0.5, 1);

        super.close();
    }
}
