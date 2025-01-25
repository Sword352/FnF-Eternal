package funkin.gameplay.components;

import funkin.gameplay.notes.Note;
import funkin.gameplay.components.Rank;

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
     * Rank representing a neutral full combo.
     */
    public var rankFC:Rank = new Rank("FC", 0xFF70BD44);

    /**
     * Rank representing a single-digit combo break.
     */
    public var rankSDCB:Rank = new Rank("SDCB", FlxColor.YELLOW);

    /**
     * Holds how many time each judgement has been hit.
     */
    var judgementHits:Map<String, Int> = [for (entry in Judgement.list) entry.name => 0];

    /**
     * Creates a new `GameStats` instance.
     */
    public function new():Void {}

    /**
     * Registers a judgement hit.
     * @param judgement Judgement that has been hit.
     */
    public function addHit(judgement:Judgement):Void {
        judgementHits[judgement.name]++;
    }

    /**
     * Returns the most relevant `Rank`.
     */
    public function getRank():Rank {
        var output:Rank = null;

        for (judgement in Judgement.list) {
            if (judgementHits[judgement.name] < 1) continue;

            if (judgement.rank != null) {
                if (misses < judgement.missThreshold)
                    output = judgement.rank;
            }
            else if (judgement.invalidateRank)
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
        rankSDCB = FlxDestroyUtil.destroy(rankSDCB);
        rankFC = FlxDestroyUtil.destroy(rankFC);
        judgementHits = null;
    }

    function set_health(v:Float):Float {
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
