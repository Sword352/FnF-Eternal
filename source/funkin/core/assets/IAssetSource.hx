package funkin.core.assets;

import haxe.io.Bytes;

/**
 * Base structure for asset sources implementations.
 * An asset source is an object that works similarly to the `FileSystem` API, exposing methods to help with file paths, retrieving bytes and such.
 * They are used for fetching assets from any kind of source (such as local filesystem, zip files...).
 */
interface IAssetSource {
    /**
     * Reads and returns the content of a file, as a string.
     * @param path Path locating to the file.
     * @return String
     */
    public function getContent(path:String):String;

    /**
     * Retrieves and returns the raw bytes of a file.
     * @param path Path locating to the file.
     * @return Bytes
     */
    public function getBytes(path:String):Bytes;

    /**
     * Scans a directory from this asset source and returns each scanned file or directory in an array of strings.
     * @param path Location of the directory to scan.
     * @return Array<String>
     */
    public function readDirectory(path:String):Array<String>;

    /**
     * Returns whether a file entry in this asset source is a directory.
     * @param path Path of the entry to look for.
     * @return Bool
     */
    public function isDirectory(path:String):Bool;

    /**
     * Returns whether a file or directory exists.
     * @param path Path of the directory or the file.
     * @return Bool
     */
    public function exists(path:String):Bool;

    /**
     * Closes this asset source and clean up memory, making it no longer usable.
     */
    public function dispose():Void;
}
