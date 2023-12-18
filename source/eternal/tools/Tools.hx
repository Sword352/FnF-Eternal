package eternal.tools;

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

    inline public static function formatSong(song:String):String
        return song.toLowerCase().replace(" ", "-");

    inline public static function capitalize(value:String, lower:Bool = true):String
        return value.split(" ").map((f) -> {
            var fragment:String = f.substring(1, f.length);
            return f.charAt(0).toUpperCase() + ((lower) ? fragment.toLowerCase() : fragment);
        }).join(" ");

    inline public static function parseYAML(content:String):Dynamic
        return Yaml.parse(content, Parser.options().useObjects());


    // used to avoid a flixel warning
    inline public static function changeFramerateCap(newFramerate:Int):Void {
		if (newFramerate > FlxG.updateFramerate) {
			FlxG.updateFramerate = newFramerate;
			FlxG.drawFramerate = newFramerate;
		}
		else {
			FlxG.drawFramerate = newFramerate;
			FlxG.updateFramerate = newFramerate;
		}
	}

    inline public static function centerToObject(object:FlxObject, base:FlxObject, axes:FlxAxes = XY):FlxObject {
        if (object == null || base == null)
            return object;

        if (axes.x)
            object.x = base.x + (base.width / 2) - (object.width / 2);
        if (axes.y)
            object.y = base.y + (base.height / 2) - (object.height / 2);
        return object;
    }

    inline public static function makeRect(sprite:FlxSprite, width:Float = 100, height:Float = 100, col:FlxColor = FlxColor.WHITE,
        unique:Bool = true, ?key:String):FlxSprite {
        sprite.makeGraphic(1, 1, col, unique, key);
        sprite.scale.set(width, height);
        sprite.updateHitbox();
        return sprite;
    }

    inline public static function resizeText(text:FlxText):Void {
        while (text.height >= FlxG.height || text.width >= FlxG.width)
            text.size--;
    }

    inline public static function stopMusic():Void {
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
            FlxG.sound.playMusic(AssetHelper.music(file, library), 1, loop);
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

    public static function addYamlAnimations(sprite:FlxSprite, animations:Array<YAMLAnimation>):Void {
        if (sprite == null || animations == null || animations.length < 1)
            return;

        var offsetSprite:Bool = (sprite is OffsetSprite);
        
        for (animation in animations) {
            var speed:Float = animation.speed ?? 1;
            var loop:Bool = animation.loop ?? false;
            var fps:Float = animation.fps ?? 24;
            
            if (animation.indices != null)
                sprite.animation.addByIndices(animation.name, animation.prefix, animation.indices, "", fps, loop);
            else if (animation.prefix != null)
                sprite.animation.addByPrefix(animation.name, animation.prefix, fps, loop);
            else
                sprite.animation.add(animation.name, animation.frames, fps, loop);

            sprite.animation.getByName(animation.name).timeScale = speed;

            if (animation.offsets != null) {
                while (animation.offsets.length < 2)
                    animation.offsets.push(0);

                if (offsetSprite)
                    cast(sprite, OffsetSprite).addOffset(animation.name, animation.offsets[0], animation.offsets[1]);
                else
                    sprite.frames.setFramesOffsetByPrefix(animation.prefix, animation.offsets[0], animation.offsets[1], false);
            }
                
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

	public static function saveData(fileName:String, data:String):Void {
        if (data == null || data.length < 1)
            return;

        _fileRef = new FileReference();
        _fileRef.addEventListener(Event.CANCEL, destroyFileRef);
		_fileRef.addEventListener(Event.COMPLETE, destroyFileRef);
		_fileRef.addEventListener(IOErrorEvent.IO_ERROR, onFileRefError);
		_fileRef.save(data.trim(), fileName);
	}

    static function onFileRefError(_):Void {
        trace("Error while saving file: " + _fileRef.name);
        destroyFileRef(null);
    }

	static function destroyFileRef(_):Void {
        _fileRef.removeEventListener(Event.CANCEL, destroyFileRef);
		_fileRef.removeEventListener(Event.COMPLETE, destroyFileRef);
		_fileRef.removeEventListener(IOErrorEvent.IO_ERROR, onFileRefError);
		_fileRef = null;
	}
}
