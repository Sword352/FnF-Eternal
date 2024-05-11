package core.assets;

#if ENGINE_RUNTIME_ASSETS
import sys.FileSystem;
import sys.io.File;
import openfl.display.BitmapData;
import openfl.media.Sound;

class RuntimeAssetStructure extends AssetStructure {
    var root:String;

    public function new(root:String):Void {
        this.root = root + "/";
        super();
    }

    override function getPath(path:String, type:AssetType, ?library:String):String {
        return cycleExtensions(root + formatFile(path, library), type);
    }

    override function entryExists(path:String):Bool {
        return FileSystem.exists(path);
    }

    override function getAtlasData(path:String):String {
        return File.getContent(path);
    }

    override function getContent(path:String):String {
        return File.getContent(path);
    }

    override function createBitmapData(path:String):BitmapData {
        return BitmapData.fromFile(path);
    }

    override function createSound(path:String):Sound {
        return Sound.fromFile(path);
    }

    override function dispose():Void {
        root = null;
    }
}
#end
