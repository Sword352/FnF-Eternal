package eternal.tools;

import openfl.media.Sound;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;

// Mostly for base game compat
@:keep class Paths {
    inline public static function getPath(file:String, type:AssetType, ?library:String):String
        return Assets.getPath(file, type, library);

    inline public static function txt(file:String, ?library:String):String
        return Assets.txt(file, library);

    inline public static function xml(file:String, ?library:String):String
        return Assets.xml(file, library);

    inline public static function json(file:String, ?library:String):String
        return Assets.json(file, library);

    inline public static function sound(file:String, ?library:String):Sound
        return Assets.sound(file, library);

    inline public static function soundRandom(file:String, min:Int, max:Int, ?library:String):Sound
        return Assets.sound(file + FlxG.random.int(min, max), library);

    inline public static function music(file:String, ?library:String):Sound
        return Assets.music(file, library);
    
    inline public static function voices(song:String):Sound
        return Assets.songAudio(song, "song/Voices");

    inline public static function inst(song:String):Sound
        return Assets.songAudio(song, "song/Inst");
    
    inline public static function image(file:String, ?library:String):FlxGraphic
        return Assets.image(file, library);

    inline public static function font(file:String, ?library:String):String
        return Assets.font(file, library);

    #if VIDEO_CUTSCENES
    inline public static function video(file:String, ?library:String):String
        return Assets.video(file, library);
    #end

    inline public static function getSparrowAtlas(file:String, ?library:String):FlxAtlasFrames
        return Assets.getSparrowAtlas(file, library);

    inline public static function getPackerAtlas(file:String, ?library:String):FlxAtlasFrames
        return Assets.getPackerAtlas(file, library);

    inline public static function getAseAtlas(file:String, ?library:String):FlxAtlasFrames
        return Assets.getAseAtlas(file, library);
}