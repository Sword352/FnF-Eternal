package tools;

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

import objects.OffsetSprite;

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
    public static final savePath:String = "Sword352/FNF-Eternal-Engine";
    public static final githubURL:String = "https://github.com/Sword352/FNF-EternalEngine";

    public static final devState:String = "ALPHA";

    public static var gameVersion(get, never):String;
    static inline function get_gameVersion():String
        return openfl.Lib.application.meta["version"];

    public static inline function capitalize(value:String, lower:Bool = true):String
        return value.split(" ").map((f) -> {
            var fragment:String = f.substring(1, f.length);
            return f.charAt(0).toUpperCase() + ((lower) ? fragment.toLowerCase() : fragment);
        }).join(" ");

    public static inline function parseYAML(content:String):Dynamic
        return Yaml.parse(content, Parser.options().useObjects());

    public static inline function convertLimeKey(key:Int):Int
        return @:privateAccess openfl.ui.Keyboard.__convertKeyCode(key);

    // used to avoid a flixel warning
    public static inline function changeFramerateCap(newFramerate:Int):Void {
        if (newFramerate > FlxG.updateFramerate) {
            FlxG.updateFramerate = newFramerate;
            FlxG.drawFramerate = newFramerate;
        } else {
            FlxG.drawFramerate = newFramerate;
            FlxG.updateFramerate = newFramerate;
        }
    }

    public static inline function centerToObject(object:FlxObject, base:FlxObject, axes:FlxAxes = XY):FlxObject {
        if (object == null || base == null) return object;

        if (axes.x) object.x = base.x + ((base.width - object.width) * 0.5);
        if (axes.y) object.y = base.y + ((base.height - object.height) * 0.5);
        return object;
    }

    public static inline function makeRect(sprite:FlxSprite, width:Float = 100, height:Float = 100, col:FlxColor = FlxColor.WHITE, unique:Bool = true,
            ?key:String):FlxSprite {
        sprite.makeGraphic(1, 1, col, unique, key);
        sprite.scale.set(width, height);
        sprite.updateHitbox();
        return sprite;
    }

    public static inline function resizeText(text:FlxText, min:Float = 0):Void {
        while (text.height >= (FlxG.height - min) || text.width >= (FlxG.width - min))
            text.size--;
    }

    public static inline function stopMusic():Void {
        if (FlxG.sound.music != null && FlxG.sound.music.playing)
            FlxG.sound.music.stop();
    }

    public static function stopAllSounds():Void {
        if (FlxG.sound.music != null) {
            FlxG.sound.music.destroy();
            FlxG.sound.music = null;
        }

        if (FlxG.sound.list != null)
            while (FlxG.sound.list.length > 0)
                FlxG.sound.list.remove(FlxG.sound.list.members[0], true).destroy();

        if (FlxG.sound.defaultMusicGroup != null) {
            // using a while loop makes the game crash??
            for (sound in FlxG.sound.defaultMusicGroup.sounds)
                sound.destroy();

            FlxG.sound.defaultMusicGroup.sounds = [];
        }

        if (FlxG.sound.defaultSoundGroup != null) {
            for (sound in FlxG.sound.defaultSoundGroup.sounds)
                sound.destroy();

            FlxG.sound.defaultSoundGroup.sounds = [];
        }
    }

    public static function playMusicCheck(file:String, ?library:String, loop:Bool = true):Void {
        if (FlxG.sound.music == null || !FlxG.sound.music.playing)
            FlxG.sound.playMusic(Assets.music(file, library), 1, loop);
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
            if (possibleColor != null)
                return possibleColor;
            return Std.parseInt(value);
        }

        if (value is Array) {
            var arr:Array<Float> = cast value;
            while (arr.length < 3)
                arr.push(0);
            return FlxColor.fromRGB(Std.int(arr[0]), Std.int(arr[1]), Std.int(arr[2]));
        }

        return FlxColor.WHITE;
    }

    public static inline function addYamlAnimations(sprite:FlxSprite, animations:Array<YAMLAnimation>):Void {
        if (sprite == null || animations == null || animations.length == 0) return;

        var offsetSprite:Bool = (sprite is OffsetSprite);

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
                    if (offsetSprite)
                        cast(sprite, OffsetSprite).addOffset(animation.name, animation.offsets[0] ?? 0, animation.offsets[1] ?? 0);
                    else
                        sprite.frames.setFramesOffsetByPrefix(animation.prefix, animation.offsets[0] ?? 0, animation.offsets[1] ?? 0, false);
                }
            }
            catch (e) {}
        }

        if (offsetSprite)
            cast(sprite, OffsetSprite).playAnimation(animations[0].name, true);
        else
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
        trace('Error while saving file "${_fileRef.name}"!');
        destroyFileRef(null);
    }

    static function destroyFileRef(_):Void {
        _fileRef.removeEventListener(Event.CANCEL, destroyFileRef);
        _fileRef.removeEventListener(Event.COMPLETE, destroyFileRef);
        _fileRef.removeEventListener(IOErrorEvent.IO_ERROR, onFileRefError);
        _fileRef = null;
    }
}
