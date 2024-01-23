package eternal;

class NoteSkin {
    static var skins:Map<String, NoteSkinConfig> = [];
    static var _warnings:Array<String> = [];

    public static function get(skin:String):NoteSkinConfig {
        if (!skins.exists(skin))
            load(skin);

        return skins.get(skin);
    }

    public static function load(skin:String):Void {
        var path:String = Assets.yaml('data/noteskins/${skin}');
        if (!FileTools.exists(path)) {
            if (!_warnings.contains(skin)) {
                trace('Could not find noteskin "${skin}"!');
                _warnings.push(skin);
            }

            return;
        }

        skins.set(skin, Tools.parseYAML(FileTools.getContent(path)));
    }

    public static inline function clear():Void {
        _warnings.splice(0, _warnings.length);
        skins.clear();
    }

    public static inline function applyGenericSkin(sprite:OffsetSprite, skin:GenericSkin, mainAnim:String, ?direction:String):Void {
        if (skin.frameRect != null)
            sprite.loadGraphic(Assets.image(skin.image, skin.library), true, skin.frameRect[0], skin.frameRect[1]);
        else
            sprite.frames = Assets.getFrames(skin.image, skin.atlasType, skin.library);

        var animations:Array<YAMLAnimation> = skin.animations;
        if (direction != null) {
            // string interpolation, shoutout to swordcube for the idea
            var lower:String = direction.toLowerCase();
            var upper:String = direction.toUpperCase();

            // copy the animations to not mess with the original ones
            animations = [
                for (animation in skin.animations) {
                    name: animation.name.replace("${dir}", lower).replace("${DIR}", upper),
                    prefix: animation.prefix?.replace("${dir}", lower).replace("${DIR}", upper),
                    indices: animation.indices,
                    frames: animation.frames,
                    offsets: animation.offsets,
                    speed: animation.speed,
                    fps: animation.fps,
                    loop: animation.loop
                }
            ];
        }

        Tools.addYamlAnimations(sprite, animations);
        sprite.playAnimation(mainAnim, true);

        if (skin.scale != null) {
            sprite.scale.set(skin.scale[0] ?? 1, skin.scale[1] ?? 1);
            sprite.updateHitbox();
        }

        if (skin.flip != null) {
            sprite.flipX = skin.flip[0] ?? false;
            sprite.flipY = skin.flip[1] ?? false;
        }

        if (skin.antialiasing != null)
            sprite.antialiasing = skin.antialiasing;

        if (skin.centeredOffsets) {
            sprite.centerOrigin();
            sprite.centerOffsets();
        }
    }
}

typedef NoteSkinConfig = {
    var note:NoteConfig;
    var receptor:ReceptorConfig;
    var splash:SplashConfig;
}

typedef NoteConfig = GenericSkin;
typedef ReceptorConfig = GenericSkin & {
    var ?spacing:Float;
}
typedef SplashConfig = GenericSkin & {
    var ?speedVariation:Array<Float>;
    var ?maxVariation:Int;
    var ?alpha:Float;
}

private typedef GenericSkin = {
    var image:String;
    var animations:Array<YAMLAnimation>;

    var ?library:String;
    var ?atlasType:String;
    
    var ?frameRect:Array<Int>;
    var ?centeredOffsets:Bool;

    var ?antialiasing:Bool;
    var ?scale:Array<Float>;
    var ?flip:Array<Bool>;
}