package funkin.core.assets;

/**
 * Simple singleton for managing asset types and extensions that can be used within the `Assets` API.
 */
class Extensions {
    /**
     * Map containing each asset type and their underlying file extensions.
     */
    static var _extensions:Map<String, Array<String>>;

    static function __init__():Void {
        _extensions = new Map();

        // register default extensions
        register(IMAGE, [".png", ".jpg", ".jpeg"]);
        register(AUDIO, [".ogg", ".wav"]);
        register(FONT, [".ttf", ".otf"]);
        register(TXT, [".txt"]);
        register(XML, [".xml"]);
        register(JSON, [".json"]);
        register(YAML, [".yml", ".yaml"]);
        register(SCRIPT, [".hx", ".hxs"]);
        register(NONE, [""]);
    }

    /**
     * Registers an asset type and it's extensions.
     * @param assetType Asset type to register.
     * @param extensions Extensions of the asset type.
     */
    public static function register(assetType:AssetType, extensions:Array<String>):Void {
        if (assetType == null || extensions == null) return;
        _extensions.set(assetType, extensions);
    }

    /**
     * Removes an asset type from the registery.
     * @param assetType Asset type to remove.
     */
    public static inline function remove(assetType:AssetType):Void {
        _extensions.remove(assetType);
    }

    /**
     * Adds an extension to an existing asset type.
     * @param assetType Asset type in which the extension will be added to.
     * @param extension Extension to add.
     */
    public static function addExtensionTo(assetType:AssetType, extension:String):Void {
        if (extension == null) return;

        if (_extensions.exists(assetType))
            _extensions.get(assetType).push(extension);
    }

    /**
     * Removes an extension from an existing asset type.
     * @param assetType Asset type in which the extension will be removed from.
     * @param extension Extension to remove.
     */
    public static function removeExtensionFrom(assetType:AssetType, extension:String):Void {
        if (extension == null) return;

        if (_extensions.exists(assetType))
            _extensions.get(assetType).remove(extension);
    }

    /**
     * Returns the corresponding extensions for an asset type.
     * @param assetType Asset type in which to retrieve the extensions from.
     * @return Array<String>
     */
    public static inline function getExtensionsFor(assetType:AssetType):Array<String> {
        return _extensions.get(assetType);
    }
}

/**
 * List of common asset types.
 */
enum abstract AssetType(String) from String to String {
    /**
     * Asset type used for image files.
     */
    var IMAGE = "image";

    /**
     * Asset type used for audio files.
     */
    var AUDIO = "audio";

    /**
     * Asset type used for font files.
     */
    var FONT = "font";

    /**
     * Asset type used for the plain text (.txt) file format.
     */
    var TXT = "txt";

    /**
     * Asset type used for the XML file format.
     */
    var XML = "xml";

    /**
     * Asset type used for the JSON file format.
     */
    var JSON = "json";

    /**
     * Asset type used for the YAML file format.
     */
    var YAML = "yaml";

    /**
     * Asset type used for script files.
     */
    var SCRIPT = "script";

    /**
     * Asset type which represents no specific extensions, typically used for paths and directories.
     */
    var NONE = "none";

    /**
     * Returns the corresponding extensions for this asset type.
     * @return Array<String>
     */
    public inline function getExtensions():Array<String> {
        return Extensions.getExtensionsFor(this);
    }

    /**
     * Finds the corresponding extension of a path in an asset source.
     * @param path Path to look for.
     * @param source Asset source.
     * @return String
     */
    public function findExtension(path:String, source:IAssetSource):String {
        for (extension in getExtensions())
            if (source.exists(path + extension))
                return extension;

        return null;
    }

    /**
     * Returns whether a file path ends with an extension matching this asset type.
     * @param path File path to check.
     * @return Bool
     */
    public function hasExtension(path:String):Bool {
        var extension:String = path.substring(path.indexOf("."), path.length);
        return getExtensions().contains(extension);
    }
}
