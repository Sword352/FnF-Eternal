package funkin.core.assets;

import flixel.graphics.FlxGraphic;
import lime.media.vorbis.VorbisFile;
import lime.media.AudioBuffer;
import openfl.media.Sound;
import haxe.io.Bytes;

/**
 * One of the most important building-block of the engine, the `Assets` singleton is an API for helping with assets retrieval.
 * It contains methods and helpers for managing assets.
 */
class Assets {
    /**
     * Asset cache used by the `Assets` singleton.
     */
    public static final cache:AssetCache = new AssetCache();

    /**
     * Determines whether the cache should automatically be cleared during next state switch.
     */
    public static var clearCache(get, set):Bool;

    /**
     * Internal, contains each registered asset sources.
     */
    static final __assetSources:Array<IAssetSource> = [new FsAssetSource("assets")];

    /**
     * Registers an asset source.
     * @param assetSource Asset source to register.
     */
    public static function addAssetSource(assetSource:IAssetSource):Void {
        if (assetSource != null) {
            // use insert as the default asset source should always be last
            __assetSources.insert(__assetSources.length - 1, assetSource);
        }
    }

    /**
     * Removes an asset source.
     * @param assetSource Asset source to remove.
     */
    public static function removeAssetSource(assetSource:IAssetSource):Void {
        if (assetSource != null)
            __assetSources.remove(assetSource);
    }

    /**
     * Runs an anonymous function on each registered asset sources.
     * @param closure Function accepting an `IAssetSource`.
     */
    public static function invoke(closure:IAssetSource->Void):Void {
        for (source in __assetSources)
            closure(source);
    }

    /**
     * Retrieves a graphic from the cache, or load it if not existing yet.
     * @param path Path to the image file.
     * @param hardware Whether to dispose the image from ram, leaving it in GPU memory.
     * @param key Optional cache key for the graphic.
     * @return FlxGraphic
     */
    public static function getGraphic(path:String, hardware:Bool = true, ?key:String):FlxGraphic {
        key ??= path;

        var cachedGraphic:FlxGraphic = cache.getGraphic(key);
        if (cachedGraphic != null)
            return cachedGraphic;

        var bytes:Bytes = getBytes(path, IMAGE);
        if (bytes == null) {
            Logging.warning('Couldn\'t find graphic from path "${path}"!');
            return null;
        }

        return cache.loadGraphic(key, bytes, hardware);
    }

    /**
     * Retrieves a sound from the cache, or load it if not existing yet.
     * @param path Path to the sound file.
     * @param stream Whether the audio should be streamed.
     * @param key Optional cache key for the sound.
     * @return Sound
     */
    public static function getSound(path:String, stream:Bool = false, ?key:String):Sound {
        key ??= path;

        var cachedSound:Sound = cache.getSound(key);
        if (cachedSound != null)
            return cachedSound;

        if (stream) {
            for (source in __assetSources) {
                var extension:String = AUDIO.findExtension(path, source);
                if (extension == null) continue;

                if (!(source is FsAssetSource)) {
                    // if the source is not an FsAssetSource, we can still use the compressed audio data directly to allocate less memory
                    return cache.loadSound(key, source.getBytes(path + extension), true);
                }

                // use a vorbis file from the local filesystem to save memory
                var vb:VorbisFile = VorbisFile.fromFile((cast source:FsAssetSource).root + path + extension);
                var buffer:AudioBuffer = AudioBuffer.fromVorbisFile(vb);

                if (buffer == null) {
                    // couldn't create vorbis file so just load (and eventually decompress) the full audio
                    return cache.loadSound(key, source.getBytes(path + extension));
                }

                var sound:Sound = Sound.fromAudioBuffer(buffer);
                cache.registerSound(key, sound);
                return sound;
            }

            Logging.warning('Couldn\'t find sound from path "${path}"!');
            return null;
        }

        var bytes:Bytes = getBytes(path, AUDIO);
        if (bytes == null) {
            Logging.warning('Couldn\'t find sound from path "${path}"!');
            return null;
        }

        return cache.loadSound(key, bytes);
    }

    /**
     * Retrieves a font from the cache, or load it if not existing yet.
     * @param font Path to the font file.
     * @param key Optional cache key for the font.
     * @return String
     */
    public static function getFont(path:String, ?key:String):String {
        key ??= path;

        var cachedFont:String = cache.getFont(key);
        if (cachedFont != null)
            return cachedFont;
		
		var bytes:Bytes = getBytes(path, FONT);
		if (bytes == null) {
            Logging.warning('Couldn\'t find font from path "${path}"!');
			return null;
		}

        return cache.loadFont(key, bytes);
    }

    /**
     * Returns the first asset source to detain a file or directory located at a specific path.
     * @param path File or directory to look for.
     * @param assetType Asset type.
     * @return IAssetSource
     */
    public static function getSourceFromPath(path:String, assetType:AssetType):IAssetSource {
        var extensions:Array<String> = assetType.getExtensions();

        for (source in __assetSources) {
            for (extension in extensions) {
                if (source.exists(path + extension))
                    return source;
            }
        }

        return null;
    }

    /**
     * Returns the bytes of a file from the first asset source detaining a location directing to the file's path.
     * @param path Path to look for.
     * @param assetType Asset type.
     * @return Bytes
     */
    public static function getBytes(path:String, assetType:AssetType):Bytes {
        var extensions:Array<String> = assetType.getExtensions();

        for (source in __assetSources) {
            for (extension in extensions) {
                if (source.exists(path + extension))
                    return source.getBytes(path + extension);
            }
        }

        return null;
    }

    /**
     * Returns the content of a file from the first asset source detaining a location directing to the file's path.
     * @param path Path to look for.
     * @param assetType Asset type.
     * @return String
     */
    public static function getContent(path:String, assetType:AssetType):String {
        var extensions:Array<String> = assetType.getExtensions();

        for (source in __assetSources) {
            for (extension in extensions) {
                if (source.exists(path + extension))
                    return source.getContent(path + extension);
            }
        }

        return null;
    }

    static inline function get_clearCache():Bool
        return cache.autoClear;

    static inline function set_clearCache(v:Bool):Bool
        return cache.autoClear = v;
}
