package funkin.core.assets;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import lime.media.vorbis.VorbisFile;
import lime.media.AudioBuffer;
import haxe.io.Bytes;

/**
 * Object which stores and manages image, audio and font assets.
 */
@:access(openfl.text.Font)
class AssetCache {
    /**
     * Determines whether to automatically clear the cache on state switch.
     */
    public var autoClear:Bool = true;

    /**
     * Internal graphic storage.
     */
    var _graphics:Map<String, FlxGraphic> = [];

    /**
     * Internal sound storage.
     */
    var _sounds:Map<String, Sound> = [];

    /**
     * Internal font storage.
     */
    var _fonts:Map<String, Font> = [];

    /**
     * Internal, stores graphics to exclude from cache clearing.
     */
    var _graphicExclusions:Array<FlxGraphic> = [];

    /**
     * Internal, stores sounds to exclude from cache clearing.
     */
    var _soundExclusions:Array<Sound> = [];

    /**
     * Internal, stores fonts to exclude from cache clearing.
     */
    var _fontExclusions:Array<Font> = [];

    /**
     * Map which stores bytes for vorbis audio.
     * This is used as a workaround so that the garbage collector doesn't clear the bytes during playback.
     */
    var _vorbisBytes:Map<Sound, Bytes> = [];

    /**
     * Creates a new `AssetCache`.
     */
    public function new():Void {
        FlxG.signals.preStateSwitch.add(onPreStateSwitch);
        FlxG.signals.preStateCreate.add((_) -> openfl.system.System.gc());
    }

    /**
     * Returns an `FlxGraphic` from the cache which matches the passed cache key.
     * @param key Cache key of the graphic.
     * @return FlxGraphic
     */
    public inline function getGraphic(key:String):FlxGraphic {
        return _graphics.get(key);
    }

    /**
     * Returns a `Sound` from the cache which matches the passed cache key.
     * @param key Cache key of the sound.
     * @return Sound
     */
    public inline function getSound(key:String):Sound {
        return _sounds.get(key);
    }

    /**
     * Returns a font key from a cached font.
     * @param key Cache key of the font.
     * @return String
     */
    public inline function getFont(key:String):String {
        // return null if the font doesn't exist to be consistent with other methods like getGraphic()
        return _fonts.exists(key) ? key : null;
    }

    /**
     * Loads an `FlxGraphic` and registers it to the cache.
     * @param key Cache key of the graphic.
     * @param bytes Raw image bytes.
     * @param hardware Whether to dispose the image from ram, leaving it in GPU memory.
     * NOTE: Hardware graphics are readonly, meaning they cannot be edited (with methods such as `setPixel()`)!
     * @return FlxGraphic
     */
    public function loadGraphic(key:String, bytes:Bytes, hardware:Bool = true):FlxGraphic {
        if (key == null || bytes == null)
            return null;

        var bitmap:BitmapData = BitmapData.fromBytes(bytes);

        if (bitmap == null) {
            trace('Couldn\'t load graphic with key "${key}"!');
            return null;
        }

        #if !hl
        if (hardware)
            bitmap.disposeImage();
        #end

        var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
        registerGraphic(key, graphic);
        return graphic;
    }

    /**
     * Loads a `Sound` and registers it to the cache.
     * @param key Cache key of the sound.
     * @param bytes Compressed or raw audio bytes.
     * @param asVorbis Whether to use `VorbisFile` to save memory.
     * NOTE: it's not ideal to set `asVorbis` to true for any kind of sfx or sound effects!
     * @return Sound
     */
    public function loadSound(key:String, bytes:Bytes, asVorbis:Bool = false):Sound {
        if (key == null || bytes == null)
            return null;

        var buffer:AudioBuffer = null;

        if (!asVorbis)
            buffer = AudioBuffer.fromBytes(bytes);
        else {
            var vb:VorbisFile = VorbisFile.fromBytes(bytes);

            // not every audio files are vorbis, so just use a normal audio buffer if it failed making the vorbis file
            if (vb != null)
                buffer = AudioBuffer.fromVorbisFile(vb);
            else {
                buffer = AudioBuffer.fromBytes(bytes);
                asVorbis = false;
            }
        }

        if (buffer == null) {
            trace('Couldn\'t load sound with key "${key}"!');
            return null;
        }

        var sound:Sound = Sound.fromAudioBuffer(buffer);
        registerSound(key, sound);

        if (asVorbis)
            _vorbisBytes.set(sound, bytes);

        return sound;
    }

    /**
     * Loads a `Font` and registers it to the cache.
     * @param key Cache key of the font.
     * @param bytes Raw font bytes.
     * @return String
     */
    public function loadFont(key:String, bytes:Bytes):String {
        if (key == null || bytes == null)
            return null;

        var font:Font = Font.fromBytes(bytes);
        if (font == null) {
            trace('Couldn\'t load font with key "${key}"!');
            return null;
        }

        registerFont(key, font);
        return key;
    }

    /**
     * Registers a graphic to the cache.
     * @param key Graphic cache key.
     * @param graphic `FlxGraphic` object.
     */
    public function registerGraphic(key:String, graphic:FlxGraphic):Void {
        if (key == null || graphic == null)
            return;

        graphic.persist = true;
        _graphics.set(key, graphic);
    }

    /**
     * Registers a sound to the cache.
     * @param key Sound cache key.
     * @param sound `Sound` object.
     */
    public function registerSound(key:String, sound:Sound):Void {
        if (key == null || sound == null)
            return;

        _sounds.set(key, sound);
    }

    /**
     * Registers a font to the cache.
     * @param key Font cache key.
     * @param font `Font` object.
     */
    public function registerFont(key:String, font:Font):Void {
        if (key == null || font == null)
            return;

        font.fontName = key;
        Font.registerFont(font);
        _fonts.set(key, font);
    }

    /**
     * Unregisters a graphic from the cache.
     * @param key Corresponding cache key.
     */
    public function unregisterGraphic(key:String):Void {
        var graphic:FlxGraphic = _graphics.get(key);
        if (graphic == null)
            return;

        graphic.persist = false;
        _graphics.remove(key);
    }

    /**
     * Unregisters a sound from the cache.
     * @param key Corresponding cache key.
     */
    public function unregisterSound(key:String):Void {
        _vorbisBytes.remove(_sounds[key]);
        _sounds.remove(key);
    }

    /**
     * Unregisters a font from the cache.
     * @param key Corresponding cache key.
     */
    public function unregisterFont(key:String):Void {
        _fonts.remove(key);
    }

    /**
     * Excludes a graphic from being disposed during cache clearing.
     * @param graphic `FlxGraphic` object.
     */
    public function excludeGraphic(graphic:FlxGraphic):Void {
        if (graphic == null || _graphicExclusions.contains(graphic))
            return;

        _graphicExclusions.push(graphic);
    }

    /**
     * Excludes a sound from being disposed during cache clearing.
     * @param sound `Sound` object.
     */
    public function excludeSound(sound:Sound):Void {
        if (sound == null || _soundExclusions.contains(sound))
            return;

        _soundExclusions.push(sound);
    }

    /**
     * Excludes a font from being disposed during cache clearing.
     * @param font `Font` object.
     */
    public function excludeFont(font:Font):Void {
        if (font == null || _fontExclusions.contains(font))
            return;

        _fontExclusions.push(font);
    }

    /**
     * Removes a graphic from being excluded during cache clearing.
     * @param graphic `FlxGraphic` object.
     */
    public function unexcludeGraphic(graphic:FlxGraphic):Void {
        _graphicExclusions.remove(graphic);
    }

    /**
     * Removes a sound from being excluded during cache clearing.
     * @param sound `Sound` object.
     */
    public function unexcludeSound(sound:Sound):Void {
        _soundExclusions.remove(sound);
    }

    /**
     * Removes a font from being excluded during cache clearing.
     * @param font `Font` object.
     */
    public function unexcludeFont(font:Font):Void {
        _fontExclusions.remove(font);
    }

    /**
     * Clears the content from this cache and frees the memory allocated by the stored entries.
     */
    public function clear():Void {
        clearGraphics();
        clearSounds();
        clearFonts();
    }

    /**
     * Clears graphics registered in the cache.
     * NOTE: excluded graphics are kept.
     */
    public function clearGraphics():Void {
        for (key in _graphics.keys()) {
            var graphic:FlxGraphic = _graphics.get(key);

            if (_graphicExclusions.contains(graphic))
                continue;

            _removeGraphic(key, graphic);
        }
    }

    /**
     * Clears sounds registred in the cache.
     * NOTE: excluded sounds are kept.
     */
    public function clearSounds():Void {
        for (key in _sounds.keys()) {
            var sound:Sound = _sounds.get(key);

            if (_soundExclusions.contains(sound))
                continue;

            _removeSound(key, sound);
        }
    }

    /**
     * Clears fonts registered in the cache.
     * NOTE: excluded fonts are kept.
     */
    public function clearFonts():Void {
        for (key in _fonts.keys()) {
            var font:Font = _fonts.get(key);

            if (_fontExclusions.contains(font))
                continue;

            _removeFont(key, font);
        }
    }

    /**
     * Same as `clear`, but clears excluded entries instead.
     */
    function _clearExclusions():Void {
        for (key in _graphics.keys()) {
            var graphic:FlxGraphic = _graphics.get(key);

            if (!_graphicExclusions.contains(graphic))
                continue;

            _graphicExclusions.remove(graphic);
            _removeGraphic(key, graphic);
        }

        for (key in _sounds.keys()) {
            var sound:Sound = _sounds.get(key);

            if (!_soundExclusions.contains(sound))
                continue;

            _soundExclusions.remove(sound);
            _removeSound(key, sound);
        }

        for (key in _fonts.keys()) {
            var font:Font = _fonts.get(key);

            if (!_fontExclusions.contains(font))
                continue;

            _fontExclusions.remove(font);
            _removeFont(key, font);
        }
    }

    function _removeGraphic(key:String, graphic:FlxGraphic):Void {
        // set persist to false and let flixel automatically dispose the graphic
        graphic.persist = false;
        
        // remove graphic from cache
        _graphics.remove(key);
    }

    function _removeSound(key:String, sound:Sound):Void {
        // remove the vorbis bytes to allow the gc to clear it
        _vorbisBytes.remove(sound);

        // clear sound from memory
        sound.close();

        // remove sound from cache
        _sounds.remove(key);
    }

    function _removeFont(key:String, font:Font):Void {
        // remove font from openfl cache
        Font.__fontByName.remove(key);
        Font.__registeredFonts.remove(font);

        // remove font from cache
        _fonts.remove(key);
    }

    function onPreStateSwitch():Void {
        if (autoClear)
            this.clear();
        else {
            // to clarify, `autoClear` basically reverses the clearing behaviour
            // when `autoClear` is true, every entries but excluded ones are disposed
            // when `autoClear` is false, excluded entries are disposed and everything else is kept
            _clearExclusions();
            autoClear = true;
        }
    }
}
