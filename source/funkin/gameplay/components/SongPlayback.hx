package funkin.gameplay.components;

import flixel.sound.FlxSound;
import flixel.group.FlxGroup;
import flixel.util.FlxSignal;
import funkin.data.ChartFormat.Chart;

/**
 * Collection of `FlxSound`s with utilities for song playback.
 */
class SongPlayback extends FlxTypedGroup<FlxSound> {
    /**
     * Main audio which plays most of the instruments of the song.
     */
    public var instrumental:FlxSound;

    /**
     * Array containing every voice audios this song has.
     */
    public var voices(default, set):Array<FlxSound>;

    /**
     * Represents the player voice audio.
     */
    public var playerVoice(get, never):FlxSound;

    /**
     * Determines the volume for the player audio.
     */
    public var playerVolume(get, set):Float;

    /**
     * Determines the current position in the song in milliseconds.
     */
    public var time(get, set):Float;

    /**
     * Determines the playback rate for the song.
     */
    public var pitch(get, set):Float;

    /**
     * Determines whether the song audio is currently playing.
     */
    public var playing(get, never):Bool;

    /**
     * Signal dispatched whenever the song ends.
     */
    public var onComplete:FlxSignal = new FlxSignal();

    /**
     * Creates a new `SongPlayback`.
     * @param song Parent chart.
     */
    public function new(?song:Chart):Void {
        super();
        visible = false;
        active = false;

        if (song != null)
            loadSong(song);
    }

    /**
     * Loads a song's audio files.
     * @param song Song chart.
     */
    public function loadSong(song:Chart):Void {
        instrumental = FlxG.sound.load(Assets.songMusic(song.meta.folder, song.gameplayInfo.instrumental));
        instrumental.onComplete = onComplete.dispatch;
        add(instrumental);

        if (song.gameplayInfo.voices != null) {
            if (voices == null)
                voices = [];

            for (audio in song.gameplayInfo.voices) {
                var voiceSound:FlxSound = FlxG.sound.load(Assets.songMusic(song.meta.folder, audio));
                voices.push(add(voiceSound));
            }
        }
    }

    /**
     * Destroys every contained audio.
     */
    public function unload():Void {
        for (audio in members) {
            FlxG.sound.list.remove(audio, true);
            this.remove(audio);
            audio.destroy();
        }

        instrumental = null;
        voices = null;
    }

    /**
     * Update behaviour.
     */
    override function update(elapsed:Float):Void {
        if (!instrumental.playing)
            return;

        // makes sure voices doesn't go offsync with the instrumental
        for (audio in voices)
            if (audio.playing && Math.abs(audio.time - instrumental.time) > 5)
                audio.time = instrumental.time;
    }

    /**
     * Starts playing the song.
     * @param startTime Time where to start.
     */
    public function play(startTime:Float = 0):Void {
        for (audio in members)
            audio.play(false, startTime);
    }

    /**
     * Pauses the song.
     */
    public function pause():Void {
        for (audio in members)
            audio.pause();
    }

    /**
     * Resumes the song.
     */
    public function resume():Void {
        for (audio in members)
            audio.resume();
    }

    /**
     * Stops the song.
     */
    public function stop():Void {
        for (audio in members)
            audio.stop();
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        onComplete = cast FlxDestroyUtil.destroy(onComplete);
        this.unload();
        super.destroy();
    }

    // Properties

    function get_playerVoice():FlxSound
        return (voices == null ? null : voices[0]);

    function get_playerVolume():Float
        return playerVoice?.volume;

    function get_time():Float
        return instrumental?.time;

    function get_pitch():Float
        return instrumental?.pitch;

    function get_playing():Bool
        return instrumental?.playing;

    function set_voices(v:Array<FlxSound>):Array<FlxSound> {
        this.active = (v != null);
        return voices = v;
    }

    function set_playerVolume(v:Float):Float {
        var voice:FlxSound = playerVoice;

        if (voice != null)
            voice.volume = v;

        return v;
    }

    function set_time(v:Float):Float {
        for (member in members)
            member.time = v;

        return v;
    }

    function set_pitch(v:Float):Float {
        for (member in members)
            member.pitch = v;

        return v;
    }
}
