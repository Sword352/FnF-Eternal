package funkin.music;

import flixel.sound.FlxSound;
import flixel.util.FlxSignal.FlxTypedSignal;

// TODO: fix beat delays
class Conductor {
    public static var time(get, set):Float;
    public static var rawTime(get, set):Float;
    public static var interpTime:Float = 0;

    public static var playbackRate:Float = 1;
    public static var offset:Float = 0;

    public static var active:Bool = true;
    public static var updateInterp:Bool = false;
    public static var music:FlxSound;

    public static var bpm(default, set):Float = 100;
    public static var crochet(default, null):Float = 600;
    public static var stepCrochet(default, null):Float = 150;

    public static var currentStep(get, set):Int;
    public static var currentBeat(get, set):Int;
    public static var currentMeasure(get, set):Int;

    public static var decimalStep(get, set):Float;
    public static var decimalBeat(get, set):Float;
    public static var decimalMeasure(get, set):Float;

    public static var stepsPerBeat(default, set):Int = 4;
    public static var beatsPerMeasure:Int = 4;

    public static var measureLength(get, never):Int;

    public static final onStep:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
    public static final onBeat:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
    public static final onMeasure:FlxTypedSignal<Int->Void> = new FlxTypedSignal();

    // used for bpm change events
    public static final beatOffset:BeatOffset = {};

    static var _prevStep:Int = -1;
    static var _prevBeat:Int = -1;
    static var _prevMeas:Int = -1;

    /*
        static var _stepTmr:Float = 0;
        static var _fakeStep:Int = 0;
        static var _fakeBeat:Int = 0;
        static var _fakeMeas:Int = 0; 
     */
    public static inline function update(elapsed:Float):Void {
        if (!active) return;
        if (updateInterp) updateTime(elapsed);
        updateCallbacks();
    }

    public static inline function updateTime(elapsed:Float):Void {
        // TODO: make this more synced to the music time
        interpTime += elapsed * playbackRate * 1000;
        if (music != null && Math.abs(time - interpTime) > (20 * playbackRate))
            interpTime = time;
    }

    public static inline function updateCallbacks():Void {
        var step:Int = currentStep;
        if (step <= _prevStep) return;

        _prevStep = step;
        onStep.dispatch(step);

        var beat:Int = currentBeat;
        var measure:Int = currentMeasure;

        if (step % stepsPerBeat == 0 && beat != _prevBeat) {
            _prevBeat = beat;
            onBeat.dispatch(beat);
        }

        if (beat % beatsPerMeasure == 0 && measure != _prevMeas) {
            _prevMeas = measure;
            onMeasure.dispatch(measure);
        }

        /*
                if (music == null || music.playing) {
                    while (time >= _stepTmr + stepCrochet) {
                        _stepTmr += stepCrochet;
                        onStep.dispatch(++_fakeStep);

                        if (_fakeStep % stepsPerBeat == 0) {
                            onBeat.dispatch(++_fakeBeat);
                            if (_fakeMeas % beatsPerMeasure == 0)
                                onMeasure.dispatch(++_fakeMeas);
                        }
                    }
                }
                else {
                    var step:Float = (time / stepCrochet);
                    _stepTmr = stepCrochet * step;

                    _fakeStep = Math.floor(step);
                    _fakeBeat = Math.floor(_fakeStep / stepsPerBeat);
                    _fakeMeas = Math.floor(_fakeBeat / beatsPerMeasure);
                }
         */
    }

    public static inline function reset():Void {
        resetTime();
        resetCallbacks();

        playbackRate = 1;
        music = null;

        beatsPerMeasure = 4;
        stepsPerBeat = 4;
        bpm = 100;

        updateInterp = false;
    }

    public static inline function resetTime():Void {
        interpTime = 0;
        resetPrevTime();
        beatOffset.reset();
    }

    public static inline function resetPrevTime(to:Int = -1):Void {
        _prevStep = _prevBeat = _prevMeas = to;
        // _fakeStep = _fakeBeat = _fakeMeas = to + 1;
        // _stepTmr = 0;
    }

    public static inline function resetCallbacks():Void {
        onStep.removeAll();
        onBeat.removeAll();
        onMeasure.removeAll();
    }

    public static inline function getSignature():String
        return '${beatsPerMeasure} / ${stepsPerBeat}';

    static function set_bpm(v:Float):Float {
        crochet = ((60 / v) * 1000);
        stepCrochet = (crochet / stepsPerBeat);
        return bpm = v;
    }

    static function set_stepsPerBeat(v:Int):Int {
        stepCrochet = (crochet / v);
        return stepsPerBeat = v;
    }

    static function set_rawTime(v:Float):Float {
        if (music != null)
            music.time = v;
        else if (updateInterp)
            interpTime = v;

        return v;
    }

    static function get_rawTime():Float {
        return (music?.time ?? interpTime);
    }

    static function set_time(v:Float):Float
        return rawTime = v;

    static function get_time():Float
        return rawTime - offset;

    static function get_decimalStep():Float {
        return ((time - beatOffset.time) / stepCrochet) + beatOffset.step;
    }

    static function set_decimalStep(v:Float):Float {
        rawTime = (stepCrochet * v);
        return v;
    }

    static function get_decimalBeat():Float
        return decimalStep / stepsPerBeat;

    static function set_decimalBeat(v:Float):Float {
        set_decimalStep(v * stepsPerBeat);
        return v;
    }

    static function get_decimalMeasure():Float
        return decimalBeat / beatsPerMeasure;

    static function set_decimalMeasure(v:Float):Float {
        set_decimalBeat(v * beatsPerMeasure);
        return v;
    }

    static function get_currentStep():Int
        return Math.floor(decimalStep);

    static function set_currentStep(v:Int):Int
        return Math.floor(set_decimalStep(v));

    static function get_currentBeat():Int
        return Math.floor(decimalBeat);

    static function set_currentBeat(v:Int):Int
        return Math.floor(set_decimalBeat(v));

    static function get_currentMeasure():Int
        return Math.floor(decimalMeasure);

    static function set_currentMeasure(v:Int):Int
        return Math.floor(set_decimalMeasure(v));

    static function get_measureLength():Int
        return stepsPerBeat * beatsPerMeasure;
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
