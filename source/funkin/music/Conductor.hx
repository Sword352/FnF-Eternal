package funkin.music;

import flixel.sound.FlxSound;
import flixel.util.FlxSignal.FlxTypedSignal;

class Conductor {
    public static final onStep:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
    public static final onBeat:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
    public static final onMeasure:FlxTypedSignal<Int->Void> = new FlxTypedSignal();

    public static var active:Bool = true;
    public static var music:FlxSound;

    public static var position(get, set):Float;
    public static var rawPosition:Float = 0;
    public static var offset:Float = 0;
    
    public static var bpm(default, set):Float = 100;
    public static var crochet:Float = 0;
    public static var stepCrochet:Float = 0;
    // public static var playbackRate(default, set):Float = 1;

    public static var measureLength(get, never):Int;
    public static var timeSignature(get, never):Float;
    public static var timeSignatureSTR(get, never):String;

    public static var stepsPerBeat:Int = 4;
    public static var beatsPerMeasure:Int = 4;

    public static var currentStep(default, null):Int;
    public static var currentBeat(default, null):Int;
    public static var currentMeasure(default, null):Int;

    public static var decimalStep(default, null):Float;
    public static var decimalBeat(default, null):Float;
    public static var decimalMeasure(default, null):Float;

    private static var previousStep:Int = -1;
    private static var previousBeat:Int = -1;
    private static var previousMeasure:Int = -1;

    public static function update(elapsed:Float):Void {
        if (!active)
            return;

        if (music != null)
            position = music.time;
        else
            rawPosition += elapsed * 1000;

        decimalStep = position / stepCrochet;
        currentStep = Math.floor(decimalStep);

        decimalBeat = decimalStep / stepsPerBeat;
        currentBeat = Math.floor(decimalBeat);

        decimalMeasure = decimalBeat / beatsPerMeasure;
        currentMeasure = Math.floor(decimalMeasure);

        if (currentStep > previousStep) {
            previousStep = currentStep;
            onStep.dispatch(currentStep);
        }

        if (currentStep % stepsPerBeat == 0 && currentBeat > previousBeat) {
            previousBeat = currentBeat;
            onBeat.dispatch(currentBeat);
        }

        if (currentBeat % beatsPerMeasure == 0 && currentMeasure > previousMeasure) {
            previousMeasure = currentMeasure;
            onMeasure.dispatch(currentMeasure);
        }
    }

    public static function reset():Void {
        resetPosition();
        resetCallbacks();

        music = null;
        // playbackRate = 1;

        beatsPerMeasure = 4;
        stepsPerBeat = 4;
        bpm = 100;
    }

    public static function resetPosition():Void {
        position = 0;
        currentStep = 0;
        decimalStep = 0;
        currentBeat = 0;
        decimalBeat = 0;
        currentMeasure = 0;
        decimalMeasure = 0;
        resetPreviousPosition();
    }

    public static function resetPreviousPosition():Void {
        previousStep = -1;
        previousBeat = -1;
        previousMeasure = -1;
    }

    public static function resetCallbacks():Void {
        onStep.removeAll();
        onBeat.removeAll();
        onMeasure.removeAll();
    }

    public static function timeToStep(time:Float, ?bpm:Float, ?stepsPerBeat:Int):Int {
        return Math.floor(time / (calculateCrochet(bpm ?? Conductor.bpm) / (stepsPerBeat ?? Conductor.stepsPerBeat)));
    }

    public static function timeToBeat(time:Float, ?bpm:Float, ?stepsPerBeat:Int):Int {
        return Math.floor(timeToStep(time, bpm, stepsPerBeat) / 4);
    }

    public static function timeToMeasure(time:Float, ?bpm:Float, ?stepsPerBeat:Int):Int {
        return Math.floor(timeToBeat(time, bpm, stepsPerBeat) / 4);
    }

    public static function calculateCrochet(bpm:Float):Float {
        return calculateBeatTime(bpm) * 1000;
    }

    public static function calculateBeatTime(bpm:Float):Float {
        return 60 / bpm;
    }

    public static function calculateMeasureTime(bpm:Float, ?stepsPerBeat:Int, ?measureLength:Float):Float {
        return (calculateCrochet(bpm) / (stepsPerBeat ?? Conductor.stepsPerBeat)) * (measureLength ?? Conductor.measureLength);
    }

    static function set_bpm(b:Float):Float {
        crochet = calculateCrochet(b);
        stepCrochet = crochet / stepsPerBeat;
        return bpm = b;
    }

    static function set_position(v:Float):Float
        return rawPosition = v;
    static function get_position():Float
        return rawPosition - offset;

    static function get_measureLength():Int
        return stepsPerBeat * beatsPerMeasure;

    static function get_timeSignature():Float
        return beatsPerMeasure / stepsPerBeat;

    static function get_timeSignatureSTR():String
        return '${beatsPerMeasure} / ${stepsPerBeat}';

    /*
    static function set_playbackRate(v:Float):Float {
        bpm *= v;
        return playbackRate = v;
    }
    */
}
