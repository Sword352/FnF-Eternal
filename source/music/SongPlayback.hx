package music;

import flixel.FlxBasic;
import flixel.util.FlxSignal;
import flixel.sound.FlxSound;

class SongPlayback extends FlxBasic {
    public var song:String;

    public var instrumental:FlxSound;
    public var musics:Array<FlxSound> = [];
    public var voices:Array<FlxSound> = [];
    public var mainVoice:FlxSound;

    public var time(get, set):Float;
    public var pitch(get, set):Float;
    public var playing(get, never):Bool;

    public var playerVolume(default, set):Float = 1;
    public var onSongEnd:FlxSignal = new FlxSignal();

    public function new(song:String):Void {
        super();
        this.song = song;
        active = visible = false;
    }

    public function setupInstrumental(file:String):Void {
        instrumental = FlxG.sound.load(Assets.songMusic(song, file));
        instrumental.onComplete = onSongEnd.dispatch;
        musics.push(instrumental);
    }

    public function createVoice(file:String):Void {
        var voice:FlxSound = FlxG.sound.load(Assets.songMusic(song, file));
        if (voices.length == 0) mainVoice = voice;

        musics.push(voice);
        voices.push(voice);
    }

    public function play(startTime:Float = 0):Void {
        for (music in musics)
            music.play(false, startTime);
    }

    public function pause():Void {
        for (music in musics)
            music.pause();
    }

    public function resume():Void {
        for (music in musics)
            music.resume();
    }

    public function stop():Void {
        for (music in musics)
            music.stop();
    }

    public function resync():Void {
        for (voice in voices)
            if (voice.playing && Math.abs(voice.time - instrumental.time) > 5)
                voice.time = instrumental.time;
    }

    public function destroyMusic():Void {
        for (music in musics) {
            FlxG.sound.list.remove(music, true);
            music.destroy();
        }

        instrumental = null;
        mainVoice = null;
    }

    override function destroy():Void {
        onSongEnd = cast FlxDestroyUtil.destroy(onSongEnd);

        destroyMusic();
        musics = null;
        voices = null;
        song = null;

        super.destroy();
    }

    function set_playerVolume(v:Float):Float {
        if (mainVoice != null)
            mainVoice.volume = v;
        return playerVolume = v;
    }

    function set_time(v:Float):Float {
        if (musics != null) {
            for (music in musics)
                music.time = v;
        }

        return v;
    }

    function set_pitch(v:Float):Float {
        if (musics != null) {
            for (music in musics)
                music.pitch = v;
        }

        return v;
    }

    function get_time():Float
        return instrumental?.time ?? 0;

    function get_pitch():Float
        return instrumental?.pitch ?? 1;

    function get_playing():Bool
        return instrumental?.playing ?? false;
}
