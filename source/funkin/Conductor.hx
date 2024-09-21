package funkin;

import flixel.sound.FlxSound;
import flixel.util.FlxSignal.FlxTypedSignal;

/**
 * An object which handles all rythmic logics and timing calculations for an audio track.
 */
class Conductor extends FlxBasic {
    /**
     * Main conductor instance, used globally by most objects.
     */
    public static var self:Conductor;

    /**
     * `FlxSound` audio object this conductor should follow.
     */
    public var music:FlxSound;

    /**
     * Current position in the song in milliseconds.
     */
    public var time(get, set):Float;

    /**
     * Current position in the song in milliseconds, unaffected by offsets applied to `time`.
     */
    public var rawTime:Float;

    /**
     * Determines by how much `time` should be offset, in milliseconds.
     */
    public var offset:Float = 0;

    /**
     * The playback rate of this conductor.
     */
    public var rate(get, default):Float = 1;

    /**
     * Determines whether the time should increase without relying on a parent audio.
     */
    public var interpolate:Bool = false;

    /**
     * Determines how much beats there are in a minute.
     */
    public var bpm(default, set):Float = 100;

    /**
     * Represents how much time to wait in milliseconds in order to get a beat.
     */
    public var crotchet:Float = 600;

    /**
     * Represents how much time to wait in milliseconds in order to get a step.
     */
    public var semiQuaver:Float = 150;

    /**
     * Determines the current step (or note) in the song.
     */
    public var step(get, set):Int;

    /**
     * Determines the current beat in the song.
     */
    public var beat(get, set):Int;

    /**
     * Determines the current measure in the song.
     */
    public var measure(get, set):Int;

    /**
     * Decimal representation of `step`.
     */
    public var decStep(get, set):Float;

    /**
     * Decimal representation of `beat`.
     */
    public var decBeat(get, set):Float;

    /**
     * Decimal representation of `measure`.
     */
    public var decMeasure(get, set):Float;

    /**
     * Represents how much a measure is split into, in steps.
     */
    public var measureLength(get, never):Int;

    /**
     * Determines how much steps is a beat divided into.
     */
    public var stepsPerBeat(default, set):Int = 4;

    /**
     * Represents how much beats are required to get a measure.
     */
    public var beatsPerMeasure:Int = 4;

    /**
     * Signal dispatched when the current step changes.
     */
    public var onStep:FlxTypedSignal<Int->Void> = new FlxTypedSignal();

    /**
     * Signal dispatched when the current beat changes.
     */
    public var onBeat:FlxTypedSignal<Int->Void> = new FlxTypedSignal();

    /**
     * Signal dispatched when the current measure changes.
     */
    public var onMeasure:FlxTypedSignal<Int->Void> = new FlxTypedSignal();

    // used for bpm change events
    public var beatOffset:BeatOffset = new BeatOffset();

    /**
     * Internal, stores the song's last recorded timestamp.
     */
    var _lastMix:Float = 0;

    /**
     * Initializes the global conductor.
     */
    public static function init():Void {
        self = new Conductor();
        FlxG.plugins.addPlugin(self);
    }

    /**
     * Creates a new `Conductor`.
     */
    public function new():Void {
        super();
        FlxG.signals.preStateCreate.add(onPreStateCreate);
    }

    /**
     * Update behaviour.
     */
    override function update(elapsed:Float):Void {
        // store the last values to compare them with the new ones in order to dispatch callbacks
        var previousStep:Int = step;
        var previousBeat:Int = beat;
        var previousMeasure:Int = measure;

        // updates the current time which may change the current step as well
        updateTime(elapsed);

        // no callbacks should be dispatched if the current step is negative
        if (step < 0)
            return;

        // dispatch callbacks
        if (previousStep != step)
            onStep.dispatch(step);

        if (previousBeat != beat)
            onBeat.dispatch(beat);

        if (previousMeasure != measure)
            onMeasure.dispatch(measure);
    }

    /**
     * Updates the current position of this conductor.
     * @param elapsed How much time has been elapsed since the last and current frame.
     */
    function updateTime(elapsed:Float):Void {
        // no need to follow the music if we interpolate the position
        if (interpolate) {
            rawTime += elapsed * rate * 1000;
            return;
        }

        // no music has been defined yet
        if (music == null)
            return;

        // the music isn't playing yet
        if (!music.playing) {
            rawTime = music.time;
            _lastMix = rawTime;
            return;
        }

        /**
         * Using `music.time` directly is unreliable for our use case because it lacks of precision:
         * - It changes each 20-30 milliseconds rather than each frame, causing visual stutters and delayed timing.
         * - Since music is playing linearly without relying on the update loop, this variable can change between frames.
         * The code below workarounds that to give a more precise time value.
         */

        var frameDelta:Float = elapsed * 1000 * rate;

        if (music.time == _lastMix) {
            // the music timestamp hasn't changed yet, so we approximate the current song position
            rawTime += frameDelta;
        }
        else {
            var difference:Float = rawTime + frameDelta - music.time;

            /**
             * If this condition is true, it means the music time has updated between frames so we still need to approximate our time,
             * otherwise we're going back to the past and get a delay equal or less than `frameDelta` (up to 16ms at 60fps).
             * However if this condition is false, it means we're off from the music time so we must reset our time
             * in order to stay synced with the music.
             */

            if (difference >= 0 && difference <= frameDelta)
                rawTime += frameDelta;
            else {
                /*
                if (difference < 0)
                    trace("late time: " + difference);
                else if (difference > frameDelta)
                    trace("early time: " + difference);
                */
                
                rawTime = music.time;
            }

            _lastMix = music.time;
        }
    }

    /**
     * Resets each properties of this conductor.
     */
    public function reset():Void {
        resetTime();

        onStep.removeAll();
        onBeat.removeAll();
        onMeasure.removeAll();

        interpolate = false;
        music = null;
        rate = 1;
        offset = 0;

        beatsPerMeasure = 4;
        stepsPerBeat = 4;
        bpm = 100;

        _lastMix = 0;
    }

    /**
     * Resets the current position of this conductor along with the applied beat offset.
     */
    public function resetTime():Void {
        rawTime = 0;
        beatOffset.reset();
    }

    function onPreStateCreate(_):Void {
        active = true;
        reset();
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        FlxG.signals.preStateCreate.remove(onPreStateCreate);

        onMeasure = cast FlxDestroyUtil.destroy(onMeasure);
        onBeat = cast FlxDestroyUtil.destroy(onBeat);
        onStep = cast FlxDestroyUtil.destroy(onStep);

        beatOffset = null;
        music = null;

        super.destroy();
    }

    function set_bpm(v:Float):Float {
        crotchet = ((60 / v) * 1000);
        semiQuaver = (crotchet / stepsPerBeat);
        return bpm = v;
    }

    function set_stepsPerBeat(v:Int):Int {
        semiQuaver = (crotchet / v);
        return stepsPerBeat = v;
    }

    function set_time(v:Float):Float
        return rawTime = v;

    function get_time():Float
        return rawTime - Options.audioOffset - offset;

    function get_rate():Float
        return music?.pitch ?? rate;

    function get_measureLength():Int
        return stepsPerBeat * beatsPerMeasure;

    function get_decStep():Float {
        return ((time - beatOffset.time) / semiQuaver) + beatOffset.step;
    }

    function get_decBeat():Float
        return decStep / stepsPerBeat;

    function get_decMeasure():Float
        return decBeat / beatsPerMeasure;

    function get_step():Int
        return Math.floor(decStep);

    function get_beat():Int
        return Math.floor(decBeat);

    function get_measure():Int
        return Math.floor(decMeasure);

    function set_decStep(v:Float):Float {
        rawTime = semiQuaver * v;
        return v;
    }

    function set_decBeat(v:Float):Float {
        decStep = v * stepsPerBeat;
        return v;
    }

    function set_decMeasure(v:Float):Float {
        decBeat = v * beatsPerMeasure;
        return v;
    }

    function set_step(v:Int):Int
        return Math.floor(set_decStep(v));

    function set_beat(v:Int):Int
        return Math.floor(set_decBeat(v));

    function set_measure(v:Int):Int
        return Math.floor(set_decMeasure(v));
}

private class BeatOffset {
    public var time:Float = 0;
    public var step:Float = 0;

    public function new():Void {}

    public function reset():Void {
        time = 0;
        step = 0;
    }
}
