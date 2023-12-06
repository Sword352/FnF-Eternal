package funkin.music;

import flixel.FlxBasic;
import flixel.util.FlxSignal;
import flixel.sound.FlxSound;

class MusicPlayback extends FlxBasic {
    public var song:String;

    public var instrumental:FlxSound;
    public var mainVocals:FlxSound;

    public var musics(default, null):Array<FlxSound> = [];
    public var vocals(default, null):Array<FlxSound> = [];

    public var vocalsVolume(default, set):Float = 1;
    public var pitch(default, set):Float = 1;

    public var onSongEnd(default, null):FlxSignal;
    public var playing(get, never):Bool;
    
    public function new(song:String):Void {
        super();

        this.song = song;
        onSongEnd = new FlxSignal();
    }

    public function setupInstrumental(file:String):Void {
        instrumental = FlxG.sound.load(AssetHelper.songAudio(song, 'song/${file}'));
        instrumental.onComplete = onSongEnd.dispatch;
        musics.push(instrumental);
    }

    public function createVoice(file:String):Void {
        var voice:FlxSound = FlxG.sound.load(AssetHelper.songAudio(song, 'song/${file}'));
        if (vocals.length < 1)
            mainVocals = voice;

        musics.push(voice);
        vocals.push(voice);
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

    public function resyncCheck():Void {        
        for (music in musics) {
            if (!music.playing)
                continue;

            if (Math.abs(music.time - Conductor.position) > 25) {
                resyncMusic();
                break;
            }
        }
    }
        
    public function resyncMusic():Void {
        Conductor.position = instrumental.time;

        for (voice in vocals) {
            if (voice.playing)
                voice.time = instrumental.time;
        }
    }

    public function destroyMusic():Void {
        for (music in musics) {
            FlxG.sound.list.remove(music, true);
            music.destroy();
        }

        instrumental = null;
        mainVocals = null;
    }

    override function destroy():Void {
        super.destroy();
        
        onSongEnd = cast FlxDestroyUtil.destroy(onSongEnd);

        destroyMusic();
        musics = null;
        vocals = null;
        song = null;
    }

    function set_vocalsVolume(v:Float):Float {
        if (mainVocals != null)
            mainVocals.volume = v;
        return vocalsVolume = v;
    }

    function set_pitch(v:Float):Float {
        if (musics != null) {
            for (music in musics)
                music.pitch = v;
        }
        return pitch = v;
    }

    inline function get_playing():Bool
        return instrumental?.playing ?? false;
}
