package funkin.gameplay.components;

import funkin.gameplay.notes.Note;
import funkin.gameplay.components.Rating.Rank;

/**
 * Object which holds gameplay statistics such as the score.
 */
class GameStats implements IFlxDestroyable {
    /**
     * Total score.
     */
    public var score:Float = 0;

    /**
     * Total misses.
     */
    public var misses:Int = 0;

    /**
     * Current health amount, ranging from 0 to 1.
     */
    public var health(default, set):Float = 0.5;

    /**
     * Current amount of chained note hits.
     */
    public var combo:Int = 0;

    /**
     * Final accuracy amount.
     */
    public var accuracy(get, never):Float;

    /**
     * Accuracy amount, ranging from 0 to 1.
     */
    public var accuracyPercent(get, never):Float;

    /**
     * Notes to count for the accuracy calculation.
     */
    public var accuracyNotes:Int = 0;

    /**
     * Total accuracy mod used to calculate the accuracy.
     */
    public var accuracyMod:Float = 0;

    /**
     * Ratings list.
     */
    public var ratings:Array<Rating> = Rating.getDefault();

    /**
     * Rank representing a neutral full combo.
     */
    public var rankFC:Rank = new Rank("FC", 0xFF70BD44);

    /**
     * Rank representing a single-digit combo break.
     */
    public var rankSDCB:Rank = new Rank("SDCB", FlxColor.YELLOW);

    /**
     * Creates a `GameStats` instance.
     */
    public function new():Void {}

    /**
     * Returns a `Rating` with a hit window matching the note's timestamp.
     * @param note Note to evaluate.
     * @return Corresponding `Rating`.
     */
    public inline function evaluateNote(note:Note):Rating {
        return evaluate(Math.abs(note.time - Conductor.self.time) / Conductor.self.rate);
    }

    /**
     * Returns a `Rating` with a hit window matching a timestamp.
     * @param timestamp Timestamp to evaluate.
     * @return Corresponding `Rating`.
     */
    public function evaluate(timestamp:Float):Rating {
        for (rating in ratings)
            if (timestamp <= rating.hitWindow)
                return rating;

        return ratings[ratings.length - 1];
    }

    /**
     * Returns the most relevant `Rank`.
     */
    public function getRank():Rank {
        if (PlayState.self.playField.botplay)
            return null;

        var output:Rank = null;

        for (rating in ratings) {
            if (rating.hits < 1) continue;

            if (rating.rank != null) {
                if (misses < rating.missThreshold)
                    output = rating.rank;
            }
            else if (rating.invalidateRank)
                output = null;
        }

        if (output != null)
            return output;

        if (misses < 1)
            return rankFC;

        if (misses < 10)
            return rankSDCB;

        return null;
    }

    /**
     * Handy method which returns the name of the most relevant `Rank`.
     * If none is found, an empty string is returned instead.
     */
    public inline function getRankName():String {
        return getRank()?.name ?? "";
    }

    /**
     * Clean up memory.
     */
    public function destroy():Void {
        ratings = FlxDestroyUtil.destroyArray(ratings);
        rankSDCB = FlxDestroyUtil.destroy(rankSDCB);
        rankFC = FlxDestroyUtil.destroy(rankFC);
    }

    function set_health(v:Float):Float {
        PlayState.self._checkGameOver = (v < health && v <= 0);
        return health = FlxMath.bound(v, 0, 1);
    }

    function get_accuracy():Float {
        return FlxMath.roundDecimal(accuracyPercent * 100, 2);
    }

    function get_accuracyPercent():Float {
        if (accuracyNotes != 0)
            return FlxMath.bound(accuracyMod / accuracyNotes, 0, 1);

        return 0;
    }
}
