package funkin.core.assets;

import openfl.media.Sound;
import openfl.Assets as OpenFLAssets;
import openfl.display.BitmapData;

#if (ENGINE_RUNTIME_ASSETS && !ENGINE_MODDING)
class DefaultAssetStructure extends RuntimeAssetStructure {
    public function new():Void {
        super("assets");
    }
}
#else
class DefaultAssetStructure extends AssetStructure {
    public function new():Void {
        super();
    }

    override function getPath(path:String, type:AssetType, ?library:String):String {
        return cycleExtensions("assets/" + formatFile(path, library), type);
    }

    override function entryExists(path:String):Bool {
        return OpenFLAssets.exists(path);
    }

    override function getContent(path:String):String {
        return OpenFLAssets.getText(path);
    }

    override function createBitmapData(path:String):BitmapData {
        return OpenFLAssets.getBitmapData(path);
    }

    override function createSound(path:String):Sound {
        return OpenFLAssets.getSound(path);
    }
}
#end
