package funkin.core.assets;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;

import openfl.media.Sound;
import openfl.display.BitmapData;
import openfl.Assets as OpenFLAssets;
import openfl.system.System;

// TODO: maybe partially remove the graphic cache in favor of flixel's
class Assets {
    public static var clearAssets:Bool = true;
    
    public static final defaultAssetStructure:DefaultAssetStructure = new DefaultAssetStructure();

    #if ENGINE_RUNTIME_ASSETS
    public static final assetStructures:Array<AssetStructure> = [];
    #end

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
        return FlxAtlasFrames.fromSparrow(image(file, library), resolveAtlasData('images/${file}', XML, library));

    public inline static function getPackerAtlas(file:String, ?library:String):FlxAtlasFrames
        return FlxAtlasFrames.fromSpriteSheetPacker(image(file, library), resolveAtlasData('images/${file}', TEXT, library));

    public inline static function getAseAtlas(file:String, ?library:String):FlxAtlasFrames
        return FlxAtlasFrames.fromAseprite(image(file, library), resolveAtlasData('images/${file}', JSON, library));

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

    public static inline function getPath(file:String, type:AssetType, ?library:String):String {
        return getStructure(file, type, library).getPath(file, type, library);
    }

    public static function getStructure(file:String, type:AssetType, ?library:String):AssetStructure {
        #if ENGINE_RUNTIME_ASSETS
        for (structure in assetStructures) {
            var path:String = structure.getPath(file, type, library);
            if (structure.entryExists(path)) return structure;
        }
        #end

        return defaultAssetStructure;
    }

    public static function listFiles(method:AssetStructure->String):Array<String> {
        var output:Array<String> = [];

        var defaultString:String = method(defaultAssetStructure);
        if (defaultString != null) output.push(defaultString);

        for (structure in assetStructures) {
            var string:String = method(structure);
            if (string != null) output.push(string);
        }

        return output;
    }

    public static function filterPath(path:String, type:AssetType):String {
        var extensions:Array<String> = type.getExtensions();
        var output:String = null;

        while (extensions.length != 0) {
            var current:String = path + extensions.pop();
            if (FileTools.exists(current)) {
                output = current;
                break;
            }
        }

        return output;
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
        var structure:AssetStructure = getStructure(path, IMAGE, library);
        var realPath:String = structure.getPath(path, IMAGE, library);
        var bitmap:BitmapData = structure.createBitmapData(realPath);

        if (bitmap == null) {
            trace('Invalid graphic path "${realPath}"!');
            return null;
        }

        var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key ?? path, true);
        graphic.persist = true;
        return graphic;
    }

    public static function createSound(path:String, ?library:String, stream:Bool = false):Sound {
        var structure:AssetStructure = getStructure(path, SOUND, library);
        var realPath:String = structure.getPath(path, SOUND, library);

        if (!structure.entryExists(realPath)) {
            trace('Invalid sound path "${realPath}"!');
            return null;
        }

        var sound:Sound = (stream) ? structure.createSoundStream(realPath) : structure.createSound(realPath);
        OpenFLAssets.cache.setSound(path, sound);
        return sound;
    }

    public inline static function registerSound(key:String, asset:Sound):Void
        loadedSounds.set(key, asset);

    public inline static function registerGraphic(key:String, asset:FlxGraphic):Void
        loadedGraphics.set(key, asset);

    public static function resolveAtlasData(path:String, type:AssetType, library:String):String {
        var structure:AssetStructure = getStructure(path, type, library);
        var path:String = structure.getPath(path, type, library);
        return structure.getAtlasData(path);
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
}
