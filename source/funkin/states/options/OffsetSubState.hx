package funkin.states.options;

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

    #if ENGINE_SCRIPTING
    var overrideCode:Bool = false;
    #end

    override function create():Void {
        super.create();

        #if ENGINE_SCRIPTING
        initStateScript();
        hxsCall("onCreate");

        if (overrideCode) {
            hxsCall("onCreatePost");
            return;
        }
        #end

        logo = new FlxSprite(0, FlxG.height, Assets.image("menus/logo"));
        logo.scale.set(0.4, 0.4);
        logo.updateHitbox();
        logo.screenCenter(X);
        logo.y += logo.height;
        add(logo);

        offsetText = new FlxText();
        offsetText.setFormat(Assets.font('vcr'), 34, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        offsetText.updateHitbox();
        offsetText.y = FlxG.height - offsetText.height - 25;
        offsetText.alpha = 0;
        refreshText();
        add(offsetText);

        music = FlxG.sound.load(Assets.music("offsetSong"), 1, true);
        music.onComplete = Conductor.resetTime;
        FlxG.sound.music.fadeOut(0.5, 0);

        lastBPM = Conductor.bpm;
        Conductor.bpm = 80;

        Conductor.resetTime();
        Conductor.music = music;

        var beatDuration:Float = Conductor.crochet / 1000;
        FlxTween.tween(offsetText, {alpha: 1}, beatDuration);
        FlxTween.tween(logo, {y: (FlxG.height - logo.height) * 0.5}, beatDuration, {ease: FlxEase.backOut, onComplete: (_) -> music.play()});

        #if ENGINE_SCRIPTING
        hxsCall("onCreatePost");
        #end
    }

    override function update(elapsed:Float):Void {
        #if ENGINE_SCRIPTING
        hxsCall("onUpdate", [elapsed]);
        super.update(elapsed);

        if (overrideCode) {
            hxsCall("onUpdatePost", [elapsed]);
            return;
        }
        #else
        super.update(elapsed);
        #end

        if (music.playing) {
            logo.scale.set(Tools.lerp(logo.scale.x, 0.4, 6), Tools.lerp(logo.scale.y, 0.4, 6));
            logo.angle += elapsed * 10;
        }

        if (controls.anyPressed(["left", "right"])) {
            holdTime += elapsed * 5;
            if (holdTime > ((FlxG.keys.pressed.SHIFT) ? 0.0015 : 0.5)) {
                Settings.settings["audio offset"].value += ((controls.lastAction == "left") ? -1 : 1);
                refreshText();
                holdTime = 0;
            }
        }

        if (controls.justPressed("back")) {
            Settings.save();
            close();
        }

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    override function beatHit(currentBeat:Int):Void {
        if (!music.playing)
            return;

        if (currentBeat > 31 && currentBeat < 112)
            cast(FlxG.state, OptionsMenu).background.scale.add(0.05, 0.05);

        logo.scale.add(0.05, 0.05);
        super.beatHit(currentBeat);
    }

    inline function refreshText():Void {
        offsetText.text = '< Offset: ${Conductor.offset}ms (${(Conductor.offset > 0) ? "LATE" : ((Conductor.offset == 0) ? "DEFAULT" : "EARLY")}) >';
        offsetText.screenCenter(X);
    }

    override function close():Void {
        music.fadeOut(0.2, 0, (_) -> {
            music.stop();
            FlxG.sound.list.remove(music, true);
            music.destroy();
        });
        FlxG.sound.music.fadeOut(0.5, 1);

        Conductor.music = null;
        Conductor.bpm = lastBPM;
        Conductor.resetTime();

        super.close();
    }
}