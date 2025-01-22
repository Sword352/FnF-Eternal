package funkin.music;

/**
 * Data structure representing a timing point in a song.
 * A timing point defines a song's BPM and time signature at a given point of a song.
 */
@:structInit
class TimingPoint {
    /**
     * Position of this timing point in a song.
     */
    public var time:Float;

    /**
     * Beats per minute for this timing point.
     */
    public var bpm(default, set):Float;

    /**
     * The number of beats in a measure.
     */
    public var beatsPerMeasure(default, set):Int = 4;

    /**
     * Length of a beat.
     */
    public var beatLength(default, null):Float;

    /**
     * Length of a measure.
     */
    public var measureLength(default, null):Float;

    /**
     * By how much should the current beat be offset
     * in order to stay consistent with past timing points.
     */
    public var beatOffset:Float = 0;

    /**
     * By how much should the current measure be offset
     * in order to stay consistent with past timing points.
     */
    public var measureOffset:Float = 0;

    /**
     * Creates a new `TimingPoint` instance.
     * @param time Position of this timing point in a song.
     * @param bpm Beats per minute for this timing point.
     * @param beatsPerMeasure The number of beats in a measure.
     * @param beatOffset By how much should the current beat be offset.
     * @param measureOffset By how much should the current measure be offset.
     */
    public function new(time:Float, bpm:Float, beatsPerMeasure:Int = 4, beatOffset:Float = 0, measureOffset:Float = 0):Void {
        this.time = time;
        this.bpm = bpm;
        this.beatsPerMeasure = beatsPerMeasure;
        this.beatOffset = beatOffset;
        this.measureOffset = measureOffset;
    }

    function set_bpm(v:Float):Float {
        beatLength = TimingTools.computeBeatLength(v);
        measureLength = beatLength * beatsPerMeasure;
        return bpm = v;
    }

    function set_beatsPerMeasure(v:Int):Int {
        measureLength = beatLength * v;
        return beatsPerMeasure = v;
    }
}
