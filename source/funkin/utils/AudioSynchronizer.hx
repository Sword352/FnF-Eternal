package funkin.utils;

/**
 * Helper class for synchronizing visuals to audio.
 */
class AudioSynchronizer {
    /**
     * Schedules a function to be ran when audio normally plays.
     * This is used for synchronizing visual elements to audio.
     * @param callback Function to run.
     */
    public static function schedule(callback:Void->Void):Void {
        if (Options.audioOffset <= 0) {
            callback();
        } else {
            FlxTimer.wait(Options.audioOffset / 1000, callback);
        }
    }
}
