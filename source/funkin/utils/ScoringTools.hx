package funkin.utils;

import funkin.gameplay.notes.Note;
import funkin.gameplay.components.Judgement;

/**
 * Utility class serving to judge the player's actions and reward/penalize them accordingly.
 */
class ScoringTools {
    /**
     * Judges a note hit with the default judgement preset.
     * @param note Note to judge.
     * @return Judgement
     */
    public static function judgeNote(note:Note):Judgement {
        return judge(Math.abs(note.time - note.strumLine.conductor.time) / note.strumLine.conductor.rate, Judgement.list);
    }

    /**
     * Judges the given timestamp and returns the appropriate judgement from the given judgements array.
     * @param timestamp Timestamp to judge.
     * @param judgements Array containing the judgements.
     * @return Judgement
     */
    public static function judge(timestamp:Float, judgements:Array<Judgement>):Judgement {
        for (judgement in judgements)
            if (timestamp <= judgement.hitWindow)
                return judgement;

        return judgements[judgements.length - 1];
    }
}
