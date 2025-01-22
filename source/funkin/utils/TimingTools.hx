package funkin.utils;

import funkin.music.TimingPoint;

/**
 * Utility class containing timing/rythm related tools.
 */
class TimingTools {
    /**
     * Amount of beats per measure commonly used in music.
     */
    public static final BEATS_PER_MEASURE_COMMON:Int = 4;

    /**
     * Sorts a set of timing points and applies an offset to each for consistent playback.
     * @param timingPoints Array of timing points.
     */
    public static function prepareTimingPoints(timingPoints:Array<TimingPoint>):Void {
        var timeOffset:Float = 0;
        var beatOffset:Float = 0;
        var measureOffset:Float = 0;

        // the top number in the time signature represents the amount of beats per measure
        var lastTopNumber:Float = 0;
        var lastBPM:Float = 0;

        sort(timingPoints);

        for (point in timingPoints) {
            if (point.time == 0) {
                // avoids few divisions by 0 that led to issues, assuming the first timing point is always at the start of a song
                lastTopNumber = point.beatsPerMeasure;
                lastBPM = point.bpm;
                continue;
            }

            var beatDifference:Float = (point.time - timeOffset) / computeBeatLength(lastBPM);

            measureOffset += beatDifference / lastTopNumber;
            beatOffset += beatDifference;

            point.measureOffset = measureOffset;
            point.beatOffset = beatOffset;

            timeOffset = point.time;
            lastTopNumber = point.beatsPerMeasure;
            lastBPM = point.bpm;
        }
    }

    /**
     * Sorts an array of timed objects by their positions.
     * @param timedObjects Array to sort.
     */
    public static function sort<T:TimedObject>(timedObjects:Array<T>):Void {
        timedObjects.sort(sortByTime);
    }

    /**
     * Algorithm used to sort timed objects by their positions.
     * @param a Object to compare with the second.
     * @param b Object to compare with the first.
     * @return Int
     */
    public static function sortByTime<T:TimedObject>(a:T, b:T):Int {
        return Std.int(a.time - b.time);
    }

    /**
     * Calculates the length of a beat from a given BPM, in milliseconds.
     * @param bpm Beats per minute.
     * @return Float
     */
    public static function computeBeatLength(bpm:Float):Float {
        return 60 / bpm * 1000;
    }
}

/**
 * Type containing common fields timed objects should hold.
 */
typedef TimedObject = {
    /**
     * Position of the timed object in a song.
     */
    var time:Float;
}
