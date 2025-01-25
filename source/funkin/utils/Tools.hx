package funkin.utils;

import yaml.Yaml;
import yaml.Parser;

import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.util.FlxAxes;
import flixel.util.FlxSave;
import flixel.tweens.FlxTween;

import openfl.events.Event;
import openfl.net.FileReference;
import openfl.events.IOErrorEvent;

import funkin.objects.OffsetSprite;

typedef YAMLAnimation = {
    var name:String;

    var ?prefix:String;
    var ?indices:Array<Int>;
    var ?frames:Array<Int>;
    var ?offsets:Array<Float>;

    var ?speed:Float;
    var ?fps:Float;
    var ?loop:Bool;
}

class Tools {
    public static final savePath:String = "Sword352/FNF-Eternal";
    public static final githubURL:String = "https://github.com/Sword352/FnF-Eternal/";

    public static final devState:String = "ALPHA";

    public static var gameVersion(get, never):String;
    static inline function get_gameVersion():String
        return openfl.Lib.application.meta["version"];

    public static function camelCase(string:String):String {
        var output:String = string.toLowerCase();
        if (!output.contains(" ")) return output;

        var parts:Array<String> = output.split(" ");

        for (i in 1...parts.length)
            parts[i] = capitalize(parts[i]);

        return parts.join("");
    }

    public static function capitalize(value:String, lower:Bool = true):String {
        return value.split(" ").map((f) -> {
            var fragment:String = f.substring(1, f.length);
            return f.charAt(0).toUpperCase() + ((lower) ? fragment.toLowerCase() : fragment);
        }).join(" ");
    }

    public static inline function parseYAML(content:String):Dynamic
        return Yaml.parse(content, Parser.options().useObjects());

    // used to avoid a flixel warning
    public static function changeFramerateCap(newFramerate:Int):Void {
        if (newFramerate > FlxG.updateFramerate) {
            FlxG.updateFramerate = newFramerate;
            FlxG.drawFramerate = newFramerate;
        } else {
            FlxG.drawFramerate = newFramerate;
            FlxG.updateFramerate = newFramerate;
        }
    }

    public static function centerToObject(object:FlxObject, base:FlxObject, axes:FlxAxes = XY):FlxObject {
        if (object == null || base == null)
            return object;

        if (axes.x)
            object.x = base.x + (base.width - object.width) / 2;

        if (axes.y)
            object.y = base.y + (base.height - object.height) / 2;

        return object;
    }

    public static function makeRect(sprite:FlxSprite, width:Float = 100, height:Float = 100, col:FlxColor = FlxColor.WHITE, unique:Bool = true, ?key:String):FlxSprite {
        sprite.makeGraphic(1, 1, col, unique, key);
        sprite.scale.set(width, height);
        sprite.updateHitbox();
        return sprite;
    }

    public static function resizeText(text:FlxText, min:Float = 0):Void {
        while (text.height >= (FlxG.height - min) || text.width >= (FlxG.width - min))
            text.size--;
    }

    public static function invokeTempSave(funcToDo:FlxSave->Void, name:String, ?folder:String):Void {
        if (folder == null || folder.length < 1)
            folder = savePath;

        var tmpSav:FlxSave = new FlxSave();
        tmpSav.bind(name, folder);
        funcToDo(tmpSav);
        tmpSav.close();
    }

    public static function getColor(value:Dynamic):FlxColor {
        if (value == null)
            return FlxColor.WHITE;

        if (value is Int)
            return value;

        if (value is String) {
            var possibleColor:Null<FlxColor> = FlxColor.fromString(value);
            return possibleColor ?? Std.parseInt(value);
        }

        if (value is Array) {
            var arr:Array<Int> = cast value;
            return FlxColor.fromRGB(arr[0] ?? 0, arr[1] ?? 0, arr[2] ?? 0);
        }

        return FlxColor.WHITE;
    }

    public static function addYamlAnimations(sprite:FlxSprite, animations:Array<YAMLAnimation>):Void {
        if (sprite == null || animations == null || animations.length == 0)
            return;

        for (animation in animations) {
            var speed:Float = animation.speed ?? 1;
            var loop:Bool = animation.loop ?? false;
            var fps:Float = animation.fps ?? 24;

            try {
                if (animation.indices != null)
                    sprite.animation.addByIndices(animation.name, animation.prefix, animation.indices, "", fps, loop);
                else if (animation.prefix != null)
                    sprite.animation.addByPrefix(animation.name, animation.prefix, fps, loop);
                else
                    sprite.animation.add(animation.name, animation.frames, fps, loop);

                sprite.animation.getByName(animation.name).timeScale = speed;

                if (animation.offsets != null) {
                    if (Std.isOfType(sprite, OffsetSprite))
                        (cast sprite:OffsetSprite).offsets.add(animation.name, animation.offsets[0] ?? 0, animation.offsets[1] ?? 0);
                    else
                        sprite.frames.addFramesOffsetByPrefix(animation.prefix, animation.offsets[0] ?? 0, animation.offsets[1] ?? 0, false);
                }
            }
            catch (e) {}
        }

        sprite.animation.play(animations[0].name, true);
    }

    public static inline function lerp(start:Float, goal:Float, speed:Float = 1):Float {
        return goal + (start - goal) * lerpRatio(speed);
    }

    public static inline function colorLerp(from:Int, to:Int, speed:Float = 1):FlxColor
        return FlxColor.interpolate(to, from, lerpRatio(speed));

    public static inline function lerpRatio(speed:Float = 1):Float
        return Math.exp(-FlxG.elapsed * speed);

    public static inline function framerateMult(framerate:Int = 60)
        return framerate * FlxG.elapsed;

    public static inline function pauseEveryTween():Void
        FlxTween.globalManager.forEach(twn -> twn.active = false);

    public static inline function pauseEveryTimer():Void
        FlxTimer.globalManager.forEach(tmr -> tmr.active = false);

    public static inline function resumeEveryTween():Void
        FlxTween.globalManager.forEach(twn -> twn.active = true);

    public static inline function resumeEveryTimer():Void
        FlxTimer.globalManager.forEach(tmr -> tmr.active = true);

    // Mostly used in editors
    static var _fileRef:FileReference;

    public static function saveData(fileName:String, data:String):FileReference {
        if (data == null || data.length == 0) return null;

        _fileRef = new FileReference();
        _fileRef.addEventListener(Event.CANCEL, destroyFileRef);
        _fileRef.addEventListener(Event.COMPLETE, destroyFileRef);
        _fileRef.addEventListener(IOErrorEvent.IO_ERROR, onFileRefError);
        _fileRef.save(data.trim(), fileName);
        return _fileRef;
    }

    static function onFileRefError(_):Void {
        Logging.error('Error while saving file "${_fileRef.name}"!');
        destroyFileRef(null);
    }

    static function destroyFileRef(_):Void {
        _fileRef.removeEventListener(Event.CANCEL, destroyFileRef);
        _fileRef.removeEventListener(Event.COMPLETE, destroyFileRef);
        _fileRef.removeEventListener(IOErrorEvent.IO_ERROR, onFileRefError);
        _fileRef = null;
    }
}
