package funkin.utils;

#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.Assets;
#end

/**
 * Cross-platform file utility.
 * TODO: Deprecate this and make a better tool so that it relies on asset trees rather
 */
class FileTools {
    public static inline function getContent(path:String):String {
        #if sys
        return File.getContent(path);
        #else
        return Assets.getText(path);
        #end
    }

    public static inline function createDirectory(path:String):Void {
        #if sys
        FileSystem.createDirectory(path);
        #end
    }

    public static inline function readDirectory(path:String):Array<String> {
        #if sys
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

    public static inline function isDirectory(path:String):Bool {
        #if sys
        return FileSystem.isDirectory(path);
        #else
        return exists(path) && !path.contains(".");
        #end
    }

    public static inline function exists(path:String):Bool {
        #if sys
        return FileSystem.exists(path);
        #else
        return Assets.exists(path);
        #end
    }
}
