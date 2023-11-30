package eternal.tools;

#if ENGINE_RUNTIME_ASSETS
import sys.io.File;
import sys.FileSystem;
#else
import openfl.Assets;
#end

// Used for compatibility with ENGINE_RUNTIME_ASSETS and non-sys targets
class FileTools {
    inline public static function getContent(path:String):String {
        #if ENGINE_RUNTIME_ASSETS
        return File.getContent(path);
        #else
        return Assets.getText(path);
        #end
    }

    inline public static function createDirectory(path:String):Void {
        #if sys
        FileSystem.createDirectory(path);
        #else
        trace("Cannot create a directory on a non-sys target!");
        #end
    }

    inline public static function readDirectory(path:String):Array<String> {
        #if ENGINE_RUNTIME_ASSETS
        return FileSystem.readDirectory(path);
        #else
        // original by @MAJigsaw77
        var files:Array<String> = [];

        for (possibleFile in Assets.list().filter((f) -> f.contains(path))) {
            var file:String = possibleFile.replace('${path}/', "");
            if (file.contains("/"))
               file = file.replace(file.substring(file.indexOf("/"), file.length), "");

            if (!files.contains(file))
               files.push(file);
        }
  
        files.sort((a, b) -> {
            a = a.toUpperCase();
            b = b.toUpperCase();
            return (a < b) ? -1 : (a > b) ? 1 : 0;
        });

        return files;
        #end
    }

    inline public static function isDirectory(path:String):Bool {
        #if ENGINE_RUNTIME_ASSETS
        return FileSystem.isDirectory(path);
        #else
        return exists(path) && !path.contains(".");
        #end
    }

    inline public static function exists(path:String):Bool {
        #if ENGINE_RUNTIME_ASSETS
        return FileSystem.exists(path);
        #else
        return Assets.exists(path);
        #end
    }
}