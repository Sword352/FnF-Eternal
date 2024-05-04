package core;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;

import openfl.media.Sound;
import openfl.display.BitmapData;
import openfl.Assets as OpenFLAssets;
import openfl.system.System;

import lime.media.AudioBuffer;
import lime.media.vorbis.VorbisFile;

// TODO: maybe partially remove the graphic cache in favor of flixel's
class Assets {
    // Directories
    public static final defaultDirectory:String = "assets/";

    #if ENGINE_RUNTIME_ASSETS
    public static var currentDirectory:String = defaultDirectory;
    #end

    // Asset cache
    public static var clearAssets:Bool = true;

    static final loadedGraphics:Map<String, FlxGraphic> = [];
    static final loadedSounds:Map<String, Sound> = [];

    public static function init():Void {
        FlxG.signals.preStateSwitch.add(freeMemory);
        FlxG.signals.preStateCreate.add(freeMemoryPost);
    }

    // Path shortcuts & atlas stuff
    public inline static function image(file:String, ?library:String):FlxGraphic
        return getGraphic('images/${file}', library);

    public inline static function music(file:String, ?library:String):Sound
        return getSound('music/${file}', Options.audioStreaming, library);

    public inline static function sound(file:String, ?library:String):Sound
        return getSound('sounds/${file}', false, library);

    public inline static function songMusic(song:String, file:String, ?library:String):Sound
        return getSound('songs/${song}/music/${file}', Options.audioStreaming, library);

    public inline static function json(file:String, ?library:String):String
        return getPath(file, JSON, library);

    public inline static function yaml(file:String, ?library:String):String
        return getPath(file, YAML, library);

    public inline static function xml(file:String, ?library:String):String
        return getPath(file, XML, library);

    public inline static function txt(file:String, ?library:String):String
        return getPath(file, TEXT, library);

    public inline static function font(file:String, ?library:String):String
        return getPath('fonts/${file}', FONT, library);

    public inline static function script(file:String, ?library:String):String
        return getPath(file, SCRIPT, library);

    #if VIDEO_CUTSCENES
    public inline static function video(file:String, ?library:String):String
        return getPath('videos/${file}', VIDEO, library);
    #end

    public inline static function getSparrowAtlas(file:String, ?library:String):FlxAtlasFrames
        return FlxAtlasFrames.fromSparrow(image(file, library), resolveAtlasData(xml('images/${file}', library)));

    public inline static function getPackerAtlas(file:String, ?library:String):FlxAtlasFrames
        return FlxAtlasFrames.fromSpriteSheetPacker(image(file, library), resolveAtlasData(txt('images/${file}', library)));

    public inline static function getAseAtlas(file:String, ?library:String):FlxAtlasFrames
        return FlxAtlasFrames.fromAseprite(image(file, library), resolveAtlasData(json('images/${file}', library)));

    public inline static function getFrames(file:String, ?type:String, ?library:String):FlxAtlasFrames {
        return switch ((type ?? "").toLowerCase().trim()) {
            case "packer": getPackerAtlas(file, library);
            case "aseprite": getAseAtlas(file, library);
            default: getSparrowAtlas(file, library);
        }
    }

    public static function findFrames(file:String, ?library:String):FlxAtlasFrames {
        if (FileTools.exists(xml('images/${file}', library))) return getSparrowAtlas(file, library);
        if (FileTools.exists(txt('images/${file}', library))) return getPackerAtlas(file, library);
        if (FileTools.exists(json('images/${file}', library))) return getAseAtlas(file, library);
        return null;
    }

    public static function getPath(file:String, type:AssetType, ?library:String):String {
        var basePath:String = file;
        if (library != null)
            basePath = '${library}/' + file;

        #if ENGINE_RUNTIME_ASSETS
        var modPath:String = type.cycleExtensions(currentDirectory + basePath);
        if (FileTools.exists(modPath))
            return modPath;
        #end

        return type.cycleExtensions(defaultDirectory + basePath);
    }

    public static function filterPath(path:String, type:AssetType):String {
        var extensions:Array<String> = type.getExtensions();
        var ext:String = extensions.pop();

        while (!FileTools.exists(path + ext) && extensions.length > 0)
            ext = extensions.pop();

        return path + ext;
    }

    // Asset handling & cache
    public static function getGraphic(path:String, ?library:String, ?key:String):FlxGraphic {
        if (key == null)
            key = path;

        var graphic:FlxGraphic = loadedGraphics.get(key);

        if (graphic == null) {
            graphic = createGraphic(path, library, key);
            if (graphic != null)
                registerGraphic(key, graphic);
        }

        return graphic;
    }

    public static function getSound(path:String, stream:Bool = false, ?library:String, ?key:String):Sound {
        if (key == null)
            key = path;

        var sound:Sound = loadedSounds.get(key);

        if (sound == null) {
            sound = createSound(path, library, stream);
            if (sound != null)
                registerSound(key, sound);
        }

        return sound;
    }

    public static function createGraphic(path:String, ?library:String, ?key:String):FlxGraphic {
        var realPath:String = getPath(path, IMAGE, library);

        var bitmap:BitmapData = #if ENGINE_RUNTIME_ASSETS BitmapData.fromFile(realPath) #else OpenFLAssets.getBitmapData(realPath) #end;
        if (bitmap == null) {
            trace('Invalid graphic path "${realPath}"!');
            return null;
        }

        var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key ?? path, true);
        graphic.persist = true;
        return graphic;
    }

    public static function createSound(path:String, ?library:String, stream:Bool = false):Sound {
        var realPath:String = getPath(path, SOUND, library);

        /*
        if (realPath.contains(":"))
            realPath = realPath.substring(realPath.indexOf(":") + 1);
        */

        if (!FileTools.exists(realPath)) {
            trace('Invalid sound path "${realPath}"!');
            return null;
        }

        var sound:Sound = null;
        
        if (stream) {
            // var bytes:haxe.io.Bytes = #if ENGINE_RUNTIME_ASSETS sys.io.File.getBytes(realPath) #else OpenFLAssets.getBytes(realPath) #end ;
            // using fromBytes is broken for now... (TODO: do not use filesystem if ENGINE_RUNTIME_ASSETS is disabled)

            var buffer:AudioBuffer = AudioBuffer.fromVorbisFile(VorbisFile.fromFile(realPath));
            sound = Sound.fromAudioBuffer(buffer);
        }
        else {
            #if ENGINE_RUNTIME_ASSETS 
            sound = Sound.fromFile(realPath);
            #else
            sound = OpenFLAssets.getSound(realPath);
            #end
        }

        OpenFLAssets.cache.setSound(path, sound);
        return sound;
    }

    public inline static function registerSound(key:String, asset:Sound):Void
        loadedSounds.set(key, asset);

    public inline static function registerGraphic(key:String, asset:FlxGraphic):Void
        loadedGraphics.set(key, asset);

    inline static function resolveAtlasData(key:String):String {
        #if ENGINE_RUNTIME_ASSETS
        return (key.startsWith(currentDirectory) && currentDirectory != defaultDirectory) ? FileTools.getContent(key) : key;
        #else
        return key;
        #end
    }

    // Assets clearing
    public inline static function freeMemory():Void {
        if (!clearAssets)
            return;

        // Clear the cache entirely
        clearCache();

        // Clear the OpenFL cache
        OpenFLAssets.cache.clear();
    }

    public inline static function freeMemoryPost(?_):Void {
        // If it is false, set it to true
        clearAssets = true;
        // Run the garbage collector
        System.gc();
    }

    public inline static function clearCache():Void {
        clearSounds();
        clearGraphics();
        clearFonts();
    }

    public static function clearSounds():Void {
        for (key in loadedSounds.keys()) {
            loadedSounds.get(key).close();
            OpenFLAssets.cache.removeSound(key);
            loadedSounds.remove(key);
        }
    }

    public static function clearGraphics():Void {
        @:privateAccess
        for (key in FlxG.bitmap._cache.keys()) {
            var graphic:FlxGraphic = FlxG.bitmap.get(key);
            if (graphic.persist && !loadedGraphics.exists(key))
                continue;

            graphic.dump();
            graphic.destroy();
            FlxG.bitmap.removeKey(key);
        }

        for (key in loadedGraphics.keys()) {
            var graphic:FlxGraphic = loadedGraphics.get(key);

            graphic.dump();
            graphic.destroy();

            FlxG.bitmap.remove(graphic);
            loadedGraphics.remove(key);
        }
    }

    public static function clearFonts():Void {
        var cache:openfl.utils.AssetCache = cast OpenFLAssets.cache;
        for (key in cache.font.keys())
            cache.font.remove(key);
    }
}

enum abstract AssetType(String) from String to String {
    var IMAGE = "image";
    var SOUND = "sound";
    var FONT = "font";

    var XML = "xml";
    var TEXT = "txt";
    var JSON = "json";
    var YAML = "yaml";

    #if ENGINE_SCRIPTING
    var SCRIPT = "script";
    #end
    #if VIDEO_CUTSCENES
    var VIDEO = "video";
    #end

    var NONE = "none";

    public function getExtensions():Array<String> {
        return switch (this:AssetType) {
            case IMAGE: [".png"];
            case SOUND: [".ogg", ".wav", #if web "mp3" #end];
            case FONT:  [".ttf", ".otf"];

            case XML:   [".xml"];
            case TEXT:  [".txt"];
            case JSON:  [".json"];
            case YAML:  [".yaml", ".yml"];

            #if ENGINE_SCRIPTING
            case SCRIPT: [".hx", ".hxs", ".hscript"];
            #end
            #if VIDEO_CUTSCENES
            case VIDEO:  [".mp4", ".webm", ".mov", ".avi"];
            #end

            case NONE: [""];
        }
    }

    public function cycleExtensions(path:String):String {
        for (ext in getExtensions())
            if (FileTools.exists(path + ext))
                return path + ext;

        return path;
    }
}
