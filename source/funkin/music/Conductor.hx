package funkin.music;

import flixel.sound.FlxSound;
import flixel.util.FlxSignal.FlxTypedSignal;

/**
 * Object handling all rythmic logics and timing calculations for an audio track.
 */
class Conductor extends FlxBasic {
    /**
     * A pre-made conductor instance most objects listens to by default.
     */
    public static var self:Conductor;

    /**
     * `FlxSound` this conductor should follow.
     */
    public var music:FlxSound;

    /**
     * Current position of the conductor in milliseconds.
     */
    public var time(get, set):Float;

    /**
     * Current position of the conductor in milliseconds, unaffected by the audio offset preference.
     * Use this value to play sounds at a specific point of the song (eg. metronome).
     */
    public var audioTime(get, never):Float;

    /**
     * Current position of the conductor in milliseconds, unaffected by offsets applied to `time`.
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
     * Determines whether this conductor's position should change as intended without a track.
     */
    public var interpolate:Bool = false;

    /**
     * Determines how much beats are there per minute.
     */
    public var bpm(get, set):Float;

    /**
     * Time it takes to get from one beat to another.
     */
    public var beatLength(get, never):Float;

    /**
     * Time it takes to get from one measure to another.
     */
    public var measureLength(get, never):Float;

    /**
     * Current beat of the conductor.
     */
    public var beat(get, set):Int;

    /**
     * Current measure of the conductor.
     */
    public var measure(get, set):Int;

    /**
     * Similar to `beat`, but with decimal precision.
     */
    public var decBeat(get, set):Float;

    /**
     * Similar to `measure`, but with decimal precision.
     */
    public var decMeasure(get, set):Float;

    /**
     * Representation of `measureLength` in beats.
     * Determines the amount of beats required in order to get from one measure to another.
     * This is the numerator (or "top number") of the time signature.
     */
    public var beatsPerMeasure(get, set):Int;

    /**
     * Timing points controlling the rythm of this conductor.
     */
    public var timingPoints:Array<TimingPoint> = [{time: 0, bpm: 100}];

    /**
     * Signal dispatched when the current beat changes.
     */
    public var onBeat:FlxTypedSignal<Int->Void> = new FlxTypedSignal();

    /**
     * Signal dispatched when the current measure changes.
     */
    public var onMeasure:FlxTypedSignal<Int->Void> = new FlxTypedSignal();

    /**
     * Holds the last audio timestamp `music` has given.
     * Used in the time approximation algorithm to determine whether we should interpolate the position.
     */
    var _lastMix:Float = 0;

    /**
     * Factor used to slow down the conductor if we're ahead of the music timestamp.
     */
    var _resyncFactor:Float = 1;

    /**
     * Initializes the global conductor.
     */
    public static function init():Void {
        FlxG.plugins.addPlugin(self = new Conductor());
    }

    /**
     * Creates a new `Conductor` instance.
     */
    public function new():Void {
        super();
        FlxG.signals.preStateCreate.add(onPreStateCreate);
        visible = false;
    }

    /**
     * Returns the most relevant timing point at a given position.
     * @param time Position to find the timing point from.
     * @return TimingPoint
     */
    public function getTimingPointAtTime(time:Float):TimingPoint {
        var output:TimingPoint = timingPoints[0];

        for (i in 1...timingPoints.length) {
            var point:TimingPoint = timingPoints[i];
            if (time < point.time) break;
            output = point;
        }

        return output;
    }

    /**
     * Returns the most relevant timing point at a given beat.
     * @param beat Beat to find the timing point from.
     * @return TimingPoint
     */
    public function getTimingPointAtBeat(beat:Float):TimingPoint {
        var output:TimingPoint = timingPoints[0];

        for (i in 1...timingPoints.length) {
            var point:TimingPoint = timingPoints[i];
            if (beat < point.beatOffset) break;
            output = point;
        }

        return output;
    }

    /**
     * Returns the most relevant timing point at a given measure.
     * @param measure Measure to find the timing point from.
     * @return TimingPoint
     */
    public function getTimingPointAtMeasure(measure:Float):TimingPoint {
        var output:TimingPoint = timingPoints[0];

        for (i in 1...timingPoints.length) {
            var point:TimingPoint = timingPoints[i];
            if (measure < point.measureOffset) break;
            output = point;
        }

        return output;
    }

    /**
     * Returns the beat corresponding to the given position.
     * @param time Position of the beat.
     * @return Float
     */
    public function getBeatAt(time:Float):Float {
        var point:TimingPoint = getTimingPointAtTime(time);
        return point.beatOffset + (time - point.time) / point.beatLength;
    }

    /**
     * Returns the measure corresponding to the given position.
     * @param time Position of the measure.
     * @return Float
     */
    public function getMeasureAt(time:Float):Float {
        var point:TimingPoint = getTimingPointAtTime(time);
        return point.measureOffset + (time - point.time) / point.measureLength;
    }

    /**
     * Returns a beat's position.
     * @param beat The beat.
     * @return Float
     */
    public function beatToMs(beat:Float):Float {
        var point:TimingPoint = getTimingPointAtBeat(beat);
        return point.time + point.beatLength * (beat - point.beatOffset);
    }

    /**
     * Returns a measure's position.
     * @param measure The measure.
     * @return Float
     */
    public function measureToMs(measure:Float):Float {
        var point:TimingPoint = getTimingPointAtMeasure(measure);
        return point.time + point.measureLength * (measure - point.measureOffset);
    }

    override function update(elapsed:Float):Void {
        // store the last values to compare them with the new ones in order to dispatch callbacks
        var previousBeat:Int = beat;
        var previousMeasure:Int = measure;

        // updates the current time which may change the current beat as well
        updateTime(elapsed);

        // dispatch callbacks
        if (previousBeat != beat)
            onBeat.dispatch(beat);

        if (previousMeasure != measure)
            onMeasure.dispatch(measure);

        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end
    }

    function updateTime(elapsed:Float):Void {
        // no need to follow the music if we interpolate the position
        if (interpolate) {
            rawTime += elapsed * rate * 1000;
            return;
        }

        // no music has been defined yet
        if (music == null) return;

        // the music isn't playing yet
        if (!music.playing) {
            rawTime = music.time;
            _lastMix = rawTime;
            return;
        }

        /**
         * Using `music.time` directly is unreliable for our use case because it lacks of precision:
         * - It changes each 20 milliseconds rather than each frame, resulting in visual stutters and slight innacuracies.
         * - Since music is playing linearly without relying on the update loop, this variable can change between frames.
         * The code below attemps to compute a more precise value for smoother results.
         */

        var frameDelta:Float = elapsed * 1000 * rate;

        if (_resyncFactor != 1) {
            frameDelta *= _resyncFactor;
            if (music.time == _lastMix) {
                // gradually resync until the next timestamp
                rawTime += frameDelta;
                return;
            }
            if (music.time - rawTime >= frameDelta) {
                // music managed to catch up, stop the resync
                rawTime = music.time;
                _resyncFactor = 1;
            } else {
                // music didn't catch up, so continue
                rawTime += frameDelta;
            }
            _lastMix = music.time;
            return;
        }
 
        if (music.time == _lastMix) {
            // the music timestamp hasn't changed yet, so we approximate the current song position
            rawTime += frameDelta;
        } else {
            var difference:Float = rawTime + frameDelta - music.time;
            if (difference >= 0 && difference <= frameDelta) {
                // the music time has updated between frames so it makes sense to continue approximating
                // as the result might be more accurate than hard resetting to music.time
                rawTime += frameDelta;
            } else if (difference < 0 || difference > 50) {
                // if the difference is negative, the difference between `music.time` and `rawTime` would be slightly higher than `frameDelta`
                // meaning hard resetting to music.time would be smooth, unless something unexpected happened (such as lag)
                // if the difference is unexpectedly huge, the music has most likely been forced to play at a specific point
                // in both cases, it is safe to hard reset to music.time
                rawTime = music.time;
            } else if (difference > frameDelta) {
                // gradually resync instead of causing stutters to happen
                _resyncFactor = 0.85;
                rawTime += frameDelta * _resyncFactor;
            }

            _lastMix = music.time;
        }
    }

    /**
     * Resets each properties of this conductor.
     */
    public function reset():Void {
        time = 0;

        onBeat.removeAll();
        onMeasure.removeAll();

        timingPoints.resize(1);

        interpolate = false;
        music = null;
        rate = 1;
        offset = 0;

        beatsPerMeasure = 4;
        bpm = 100;

        _resyncFactor = 1;
        _lastMix = 0;
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

        timingPoints = null;
        music = null;

        super.destroy();
    }

    function set_bpm(v:Float):Float {
        return getTimingPointAtTime(0).bpm = v;
    }

    function get_bpm():Float {
        return getTimingPointAtTime(time).bpm;
    }

    function get_beatLength():Float {
        return getTimingPointAtTime(time).beatLength;
    }

    function get_measureLength():Float {
        return getTimingPointAtTime(time).measureLength;
    }

    function set_beatsPerMeasure(v:Int):Int {
        return getTimingPointAtTime(0).beatsPerMeasure = v;
    }
    
    function get_beatsPerMeasure():Int {
        return getTimingPointAtTime(time).beatsPerMeasure;
    }

    function set_time(v:Float):Float {
        rawTime = v;
        return get_time();
    }

    function get_time():Float {
        return rawTime - Options.audioOffset - offset;
    }

    function get_audioTime():Float {
        return rawTime - offset;
    }

    function get_rate():Float {
        return music?.pitch ?? rate;
    }

    function get_decBeat():Float {
        return getBeatAt(time);
    }

    function get_decMeasure():Float {
        return getMeasureAt(time);
    }

    function set_decBeat(v:Float):Float {
        rawTime = beatToMs(v);
        return get_decBeat();
    }

    function set_decMeasure(v:Float):Float {
        rawTime = measureToMs(v);
        return get_decMeasure();
    }

    function get_beat():Int {
        return Math.floor(decBeat);
    }

    function get_measure():Int {
        return Math.floor(decMeasure);
    }

    function set_beat(v:Int):Int {
        return Math.floor(set_decBeat(v));
    }

    function set_measure(v:Int):Int {
        return Math.floor(set_decMeasure(v));
    }
}
