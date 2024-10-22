package funkin.core.assets;

import haxe.io.Bytes;
import sys.FileSystem;
import sys.io.File;

/**
 * An asset source implementation which retrieves everything from the user's local filesystem.
 */
class FsAssetSource implements IAssetSource {
    /**
     * Root of this asset source.
     */
    public var root:String;

    public function new(root:String):Void {
        this.root = root + "/";
    }

    public function getContent(path:String):String
        return File.getContent(root + path);

    public function getBytes(path:String):Bytes
        return File.getBytes(root + path);
 
    public function readDirectory(path:String):Array<String>
        return FileSystem.readDirectory(root + path);

    public function isDirectory(path:String):Bool 
        return FileSystem.isDirectory(root + path);
 
    public function exists(path:String):Bool
        return FileSystem.exists(root + path);
 
    public function dispose():Void {
        root = null;
    }
}
