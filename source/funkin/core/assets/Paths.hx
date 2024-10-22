package funkin.core.assets;

import yaml.Parser;
import yaml.Yaml;
import haxe.Json;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.typeLimit.OneOfTwo;
import flixel.graphics.FlxGraphic;
import openfl.media.Sound;

/**
 * Static singleton with commonly used path shortcuts.
 */
class Paths {
    /**
     * Returns an `FlxGraphic` from a file in the `images` folder.
     * @param path Image file name or path.
     * @param hardware Whether to dispose the image from ram, leaving it in GPU memory.
     * @return FlxGraphic
     */
    public static inline function image(path:String, hardware:Bool = true):FlxGraphic
        return Assets.getGraphic(formatPath(path, "images"), hardware);

	/**
	 * Returns a `Sound` from a file in the `sounds` folder.
	 * @param path Sound file name or path.
	 * @return Sound
	 */
	public static inline function sound(path:String):Sound
		return Assets.getSound(formatPath(path, "sounds"), false);

	/**
	 * Returns a `Sound` from a file in the `music` folder.
	 * @param path Music file name or path.
	 * @return Sound
	 */
	public static inline function music(path:String):Sound
		return Assets.getSound(formatPath(path, "music"), true);

	/**
	 * Returns the path to a font in the `fonts` folder.
	 * @param path Font name or path.
	 * @return String
	 */
	public static inline function font(path:String):String
		return Assets.getFont(formatPath(path, "fonts"));

	/**
	 * Returns a track from a song in the `songs` folder.
	 * @param song Song to look for.
	 * @param file Track to look for.
	 * @return Sound
	 */
	public static inline function songMusic(song:String, file:String):Sound
		return Assets.getSound('songs/${song}/music/${file}', true);

	/**
	 * Parses and returns the content of a json file located at `path`.
	 * @param path Path of the json file to look for.
	 * @return Dynamic
	 */
	public static function json(path:String):Dynamic {
		var content:String = Assets.getContent(path, JSON);

		if (content == null)
			return null;

		return Json.parse(content);
	}

	/**
	 * Parses and returns the content of a yaml file located at `path`.
	 * @param path Path of the yaml file to look for.
	 * @return Dynamic
	 */
	public static function yaml(path:String):Dynamic {
		var content:String = Assets.getContent(path, YAML);

		if (content == null)
			return null;

		return Yaml.parse(content, Parser.options().useObjects());
	}

	/**
	 * Returns the content of a script file.
	 * @param path Path to the script.
	 * @return String
	 */
	public static inline function script(path:String):String
		return Assets.getContent(path, SCRIPT);

	/**
	 * Parses and returns a sparrow atlas from files in the `images` folder.
	 * @param path Path to the atlas.
     * @param hardware Whether to dispose the image from ram, leaving it in GPU memory.
	 * @return String
	 */
	public static function atlas(path:String, hardware:Bool = true):FlxAtlasFrames {
		var graphic:FlxGraphic = image(path, hardware);

		if (graphic == null)
			return null;

		var atlas:FlxAtlasFrames = FlxAtlasFrames.findFrame(graphic);

		// no need to find and read data again
		if (atlas != null)
			return atlas;

		// search for sparrow atlas
		var sparrowXml:String = Assets.getContent(formatPath(path, "images"), XML);

		if (sparrowXml != null)
			return FlxAtlasFrames.fromSparrow(graphic, sparrowXml);

		// no atlas found, just return the static graphic
		var atlas:FlxAtlasFrames = new FlxAtlasFrames(graphic);
		atlas.pushFrame(graphic.imageFrame.frame);
		return atlas;
	}

	/**
	 * Builds a frame collection from a or multiple atlases.
	 * @param assets Atlas(es) to use.
	 * @param hardware Whether to dispose images from ram, leaving it in GPU memory.
	 * @return FlxAtlasFrames
	 */
	public static function buildAtlas(assets:AtlasAsset, hardware:Bool = true):FlxAtlasFrames {
		if (assets is String)
			return atlas(assets, hardware);

		if (assets is Array) {
			var atlases:Array<String> = cast assets;
			if (atlases.length == 0) {
				trace("Cannot construct frame collection from empty array!");
				return null;
			}

			var parent:FlxAtlasFrames = atlas(atlases[0], hardware);
			if (parent == null) {
				trace('Parent atlas "${atlases[0]}" could not be built!');
				return null;
			}
			
			if (atlases.length > 1) {
				for (i in 1...atlases.length) {
					var atlas:FlxAtlasFrames = atlas(atlases[i], hardware);
					if (atlas != null)
						parent.addAtlas(atlas);
					else
						trace('Atlas "${atlases[i]}" could not be built!');
				}
			}

			return parent;
		}

		trace("Invalid atlas data has been passed to buildAtlas()!");
		return null;
	}

	/**
	 * Preloads a or multiple atlases.
	 * @param assets Atlas(es) to preload.
	 * @param hardware Whether to dispose images from ram, leaving it in GPU memory.
	 */
	public static function preloadAtlas(assets:AtlasAsset, hardware:Bool = true):Void {
		if (assets is String)
			image(assets, hardware);
		else if (assets is Array) {
			for (atlas in (cast assets:Array<String>))
				image(atlas, hardware);
		}
	}

	/**
	 * Formats a path to properly redirect to it's parent asset library.
	 * @param path Path to format.
	 * @param rootPath Base path.
	 * @return String
	 */
	public static function formatPath(path:String, rootPath:String):String {
		if (path == null || rootPath == null)
			return null;

		if (!path.contains(":"))
			return rootPath + "/" + path;

        var librarySymbol:Int = path.indexOf(":");
		var library:String = path.substring(0, librarySymbol);
		var asset:String = path.substring(librarySymbol + 1, path.length);
		return library + "/" + rootPath + "/" + asset;
	}
}

typedef AtlasAsset = OneOfTwo<String, Array<String>>;
