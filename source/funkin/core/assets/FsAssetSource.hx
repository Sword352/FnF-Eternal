package funkin.core.assets;

import haxe.io.Bytes;
import sys.FileSystem;
import sys.io.File;

/**
 * An asset source implementation which retrieves everything from the user's local filesystem.
 */
@:noCustomClass
class FsAssetSource implements IAssetSource {
    /**
     * Root of this asset source.
     */
    // @:unreflective makes the root immutable and unaccessible by scripts to prevent users from bypassing the filesystem blacklist
    @:unreflective public var root:String;

    /**
     * Creates a new `FsAssetSource`.
     * @param root Root directory of the files this asset source can access.
     */
    public function new(root:String):Void {
        this.root = root + "/";
    }

    @:inheritDoc(funkin.core.assets.IAssetSource.getContent)
    public function getContent(path:String):String {
        if (!isPathSafe(path)) return null;
        return File.getContent(root + path);
    }

    @:inheritDoc(funkin.core.assets.IAssetSource.getBytes)
    public function getBytes(path:String):Bytes {
        if (!isPathSafe(path)) return null;
        return File.getBytes(root + path);
    }
 
    @:inheritDoc(funkin.core.assets.IAssetSource.readDirectory)
    public function readDirectory(path:String):Array<String> {
        if (!isPathSafe(path)) return null;
        return FileSystem.readDirectory(root + path);
    }

    @:inheritDoc(funkin.core.assets.IAssetSource.isDirectory)
    public function isDirectory(path:String):Bool {
        if (!isPathSafe(path)) return false;
        return FileSystem.isDirectory(root + path);
    }
 
    @:inheritDoc(funkin.core.assets.IAssetSource.exists)
    public function exists(path:String):Bool {
        if (!isPathSafe(path)) return false;
        return FileSystem.exists(root + path);
    }

    @:inheritDoc(funkin.core.assets.IAssetSource.dispose)
    public function dispose():Void {
        root = null;
    }

    inline function isPathSafe(path:String):Bool {
        return !path.contains("..");
    }
}
