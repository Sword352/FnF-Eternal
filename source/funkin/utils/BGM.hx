package funkin.utils;

import openfl.media.Sound;
import flixel.sound.FlxSound;

/**
 * Utility for playing music tracks in the background.
 */
class BGM extends FlxSound {
    /**
     * Plays a music track if it is not already.
     * @param music Track in the `musics` folder.
     */
    public static function playMusic(music:String):Void {
        var track:FlxSound = FlxG.sound.music;
        var asset:Sound = Paths.music(music);

        if (track == null) {
            FlxG.sound.music = track = new BGM();
            FlxG.sound.defaultMusicGroup.add(track);
            track.persist = true;
        }

        if (!track.playing) {
            track.loadEmbedded(asset, true);
            track.play();
        }

        // exclude the asset so that the track can persist between states
        Assets.cache.excludeSound(asset);
    }

    /**
     * Stops the current playing track.
     */
    public static function stopMusic():Void {
        if (FlxG.sound.music == null || !FlxG.sound.music.playing)
            return;

        FlxG.sound.music.persist = false;
        FlxG.sound.music.stop();
    }

    override function destroy():Void {
        if (_sound != null && Assets.clearCache)  {
            // allows the track to be cleared from memory as it has been stopped
            Assets.cache.unexcludeSound(_sound);
        }

        super.destroy();
    }
}
