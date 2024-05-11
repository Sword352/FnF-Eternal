package core.assets;

import lime.media.vorbis.VorbisFile;
import lime.media.AudioBuffer;
import openfl.media.Sound;
import openfl.display.BitmapData;

class AssetStructure {
    public function new():Void {}

    public function getPath(path:String, type:AssetType, ?library:String):String {
        return null;
    }

    // TODO: allow the "library:path" format
    public function formatFile(file:String, ?library:String):String {
        return library == null ? file : '${library}/${file}';
    }

    public function entryExists(path:String):Bool {
        return false;
    }

    public function cycleExtensions(path:String, type:AssetType):String {
        for (ext in type.getExtensions()) {
            if (entryExists(path + ext))
                return path + ext;
        }

        return path;
    }

    public function getAtlasData(path:String):String {
        // flixel automatically read the file from path
        return path;
    }

    public function getContent(path:String):String {
        return null;
    }

    public function createBitmapData(path:String):BitmapData {
        return null;
    }

    public function createSound(path:String):Sound {
        return null;
    }

    // using fromBytes is broken for now...
    // TODO: do not use filesystem on other structures and move this to ModAssetStructure

    public function createSoundStream(path:String):Sound {
        var buffer:AudioBuffer = AudioBuffer.fromVorbisFile(VorbisFile.fromFile(path));
        return Sound.fromAudioBuffer(buffer);
    }

    public function dispose():Void {}
}
