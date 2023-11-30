package eternal.tools;

import openfl.media.Sound;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;

// Mostly for base game compat
@:keep class Paths {
    inline public static function getPath(file:String, type:AssetType, ?library:String):String
        return AssetHelper.getPath(file, type, library);

    inline public static function txt(file:String, ?library:String):String
        return AssetHelper.txt(file, library);

    inline public static function xml(file:String, ?library:String):String
        return AssetHelper.xml(file, library);

    inline public static function json(file:String, ?library:String):String
        return AssetHelper.json(file, library);

    inline public static function sound(file:String, ?library:String):Sound
        return AssetHelper.sound(file, library);

    inline public static function soundRandom(file:String, min:Int, max:Int, ?library:String):Sound
        return AssetHelper.sound(file + FlxG.random.int(min, max), library);

    inline public static function music(file:String, ?library:String):Sound
        return AssetHelper.music(file, library);
    
    inline public static function voices(song:String):Sound
        return AssetHelper.songAudio(song, "song/Voices");

    inline public static function inst(song:String):Sound
        return AssetHelper.songAudio(song, "song/Inst");
    
    inline public static function image(file:String, ?library:String):FlxGraphic
        return AssetHelper.image(file, library);

    inline public static function font(file:String, ?library:String):String
        return AssetHelper.font(file, library);

    #if VIDEO_CUTSCENES
    inline public static function video(file:String, ?library:String):String
        return AssetHelper.video(file, library);
    #end

    inline public static function getSparrowAtlas(file:String, ?library:String):FlxAtlasFrames
        return AssetHelper.getSparrowAtlas(file, library);

    inline public static function getPackerAtlas(file:String, ?library:String):FlxAtlasFrames
        return AssetHelper.getPackerAtlas(file, library);

    inline public static function getAseAtlas(file:String, ?library:String):FlxAtlasFrames
        return AssetHelper.getAseAtlas(file, library);
}