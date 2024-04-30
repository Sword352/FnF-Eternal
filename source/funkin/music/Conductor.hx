package funkin.music;

import flixel.FlxBasic;
import flixel.sound.FlxSound;
import flixel.util.FlxSignal.FlxTypedSignal;

class Conductor extends FlxBasic {
    public static var self:Conductor;
    public var music:FlxSound;

    public var time(get, set):Float;
    public var rawTime:Float;

    // since music time is actually in chunck and not ms, the time value won't be changing each frames.
    // this is to compensate and makes stuff a lot more accurate (beats, inputs...)
    // shoutout to RapperGF for the idea, really cool guy I can't thank them enough
    public var timeApprox:Float = 0; 

    public var playbackRate(get, default):Float = 1;
    public var offset:Float = Settings.get("audio offset");

    public var enableInterpolation:Bool = false;
    // increase each frames by the delta time, used for smoother visuals
    public var interpolatedTime:Float;

    public var bpm(default, set):Float = 100;
    public var stepCrochet:Float = 150;
    public var crochet:Float = 600;

    public var step(get, set):Int;
    public var beat(get, set):Int;
    public var measure(get, set):Int;

    public var decStep(get, set):Float;
    public var decBeat(get, set):Float;
    public var decMeasure(get, set):Float;

    public var measureLength(get, never):Int;
    public var stepsPerBeat(default, set):Int = 4;
    public var beatsPerMeasure:Int = 4;

    public var onStep:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
    public var onBeat:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
    public var onMeasure:FlxTypedSignal<Int->Void> = new FlxTypedSignal();

    // used for bpm change events
    public var beatOffset:BeatOffset = {};

    var _prevTime:Float = -1;
    var _prevStep:Int = -1;

    public static function init():Void {
        FlxG.plugins.addPlugin(self = new Conductor());
    }

    public function new():Void {
        super();
        FlxG.signals.preStateCreate.add(onPreStateCreate);
        FlxG.signals.focusGained.add(onFocusGained);
    }

    override function destroy():Void {
        FlxG.signals.preStateCreate.remove(onPreStateCreate);
        FlxG.signals.focusGained.remove(onFocusGained);

        onMeasure = cast FlxDestroyUtil.destroy(onMeasure);
        onBeat = cast FlxDestroyUtil.destroy(onBeat);
        onStep = cast FlxDestroyUtil.destroy(onStep);

        beatOffset = null;
        music = null;

        super.destroy();
    }

    function onPreStateCreate(_):Void {
        active = true;
        reset();
    }

    function onFocusGained():Void {
        if (!FlxG.autoPause || music == null)
            return;

        // reset the time approx to avoid stutters when going back to the game
        // (this only narrow things down, stutters can still rarely happen)
        // TODO: fix them for good

        rawTime -= timeApprox;
        timeApprox = 0;
    }

    override function update(elapsed:Float):Void {
        updateTime(elapsed);
        updateCallbacks();
    }

    public function updateTime(elapsed:Float):Void {
        if (music == null) {
            if (enableInterpolation) {
                rawTime += elapsed * playbackRate * 1000;
                interpolatedTime = time;
            }
            return;
        }

        var delta:Float = music.time - _prevTime;
        _prevTime = music.time;

        if (music.playing && Math.abs(delta) <= 0) {
            timeApprox += elapsed * playbackRate * 1000;
        }
        else {
            timeApprox = 0;
        }

        rawTime = music.time + timeApprox;

        if (enableInterpolation) {
            // TODO: find a smarter solution to smooth out the time for notes
            // a 20ms delay shouldn't hurt... for now.

            interpolatedTime += elapsed * playbackRate * 1000;
            if (Math.abs(interpolatedTime - time) > (20 * playbackRate))
                interpolatedTime = time;
        }
    }

    public function updateCallbacks():Void {
        if (step == _prevStep || step <= -1) return;

        _prevStep = step;
        onStep.dispatch(step);

        if (step % stepsPerBeat == 0) {
            onBeat.dispatch(beat);

            if (beat % beatsPerMeasure == 0)
                onMeasure.dispatch(measure);
        }
    }

    public function reset():Void {
        resetTime();
        resetCallbacks();

        enableInterpolation = false;
        playbackRate = 1;
        music = null;

        beatsPerMeasure = 4;
        stepsPerBeat = 4;
        bpm = 100;
    }

    public function resetTime():Void {
        rawTime = 0;
        interpolatedTime = 0;
        beatOffset.reset();
        resetPrevTime();
    }

    public function resetPrevTime():Void {
        _prevStep = -1;
        _prevTime = -1;
        timeApprox = 0;
    }

    public function resetCallbacks():Void {
        onStep.removeAll();
        onBeat.removeAll();
        onMeasure.removeAll();
    }

    public inline function getSignature():String
        return '${beatsPerMeasure} / ${stepsPerBeat}';

    function set_bpm(v:Float):Float {
        crochet = ((60 / v) * 1000);
        stepCrochet = (crochet / stepsPerBeat);
        return bpm = v;
    }

    function set_stepsPerBeat(v:Int):Int {
        stepCrochet = (crochet / v);
        return stepsPerBeat = v;
    }

    function set_time(v:Float):Float {
        if (enableInterpolation)
            interpolatedTime = v - offset;

        return rawTime = v;
    }

    function get_time():Float         return rawTime - offset;
    function get_playbackRate():Float return music?.pitch ?? playbackRate;
    function get_measureLength():Int  return stepsPerBeat * beatsPerMeasure;

    function get_decStep():Float {
        return ((time - beatOffset.time) / stepCrochet) + beatOffset.step;
    }

    function get_decBeat():Float    return decStep / stepsPerBeat;
    function get_decMeasure():Float return decBeat / beatsPerMeasure;

    function get_step():Int    return Math.floor(decStep);
    function get_beat():Int    return Math.floor(decBeat);
    function get_measure():Int return Math.floor(decMeasure);

    function set_decStep(v:Float):Float {
        rawTime = (stepCrochet * v);
        return v;
    }

    function set_decBeat(v:Float):Float {
        set_decStep(v * stepsPerBeat);
        return v;
    }

    function set_decMeasure(v:Float):Float {
        set_decBeat(v * beatsPerMeasure);
        return v;
    }

    function set_step(v:Int):Int    return Math.floor(set_decStep(v));
    function set_beat(v:Int):Int    return Math.floor(set_decBeat(v));
    function set_measure(v:Int):Int return Math.floor(set_decMeasure(v));
}

@:structInit class BeatOffset {
    public var time:Float = 0;
    public var step:Float = 0;
    public var beat:Float = 0;

    public function new():Void {}

    public function reset():Void {
        time = 0;
        step = 0;
        beat = 0;
    }
}
