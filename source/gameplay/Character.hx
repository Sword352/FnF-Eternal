package gameplay;

import flixel.math.FlxPoint;
import objects.HealthIcon;
import objects.DancingSprite;
import states.substates.GameOverScreen;
import states.substates.GameOverScreen.GameOverData;

#if ENGINE_SCRIPTING
import core.scripting.Script;
import core.scripting.ScriptableState;
#end

class Character extends DancingSprite {
    public static final defaultAnimations:Array<String> = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];

    public var character(default, set):String;
    public var type:CharacterType;

    public var singAnimations:Array<String> = defaultAnimations.copy();
    public var singDuration:Float = 4;

    public var animEndTime:Float = 0;
    public var holdTime:Float = 0;
    public var holding:Bool = false;

    public var cameraOffsets:FlxPoint = FlxPoint.get();
    public var globalOffsets:FlxPoint = FlxPoint.get();

    public var healthIcon:String = HealthIcon.DEFAULT_ICON;
    public var healthBarColor:FlxColor = FlxColor.GRAY;

    public var gameOverChar:String;
    public var gameOverData:GameOverData;

    public var noteSkin:String = "default";
    public var extra:Dynamic = null;

    #if ENGINE_SCRIPTING
    var script:Script;
    #end

    public function new(x:Float = 0, y:Float = 0, character:String = "bf", type:CharacterType = DEFAULT):Void {
        super(x, y);

        this.type = type;
        this.character = character;
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (animation.curAnim == null || type == DEBUG)
            return;

        if (animEndTime > 0) {
            animEndTime -= elapsed;
            if (animEndTime <= 0) {
                animEndTime = 0;
                forceDance(true);
            }
        }

        if (singAnimations.contains(animation.curAnim.name))
            holdTime += elapsed;

        if (!holding && holdTime >= Conductor.self.stepCrochet * singDuration * 0.001)
            forceDance();
    }

    public function setup(config:CharacterConfig):Void {
        frames = Assets.getFrames(config.image, config.atlasType, config.library);
        Tools.addYamlAnimations(this, config.animations);

        singAnimations = config.singAnimations ?? singAnimations;
        singDuration = config.singDuration ?? 4;

        danceSteps = config.danceSteps ?? ["idle"];
        beat = config.danceBeat ?? 2;

        cameraOffsets.set();
        globalOffsets.set();

        if (config.cameraOffsets != null)
            cameraOffsets.set(config.cameraOffsets[0] ?? 0, config.cameraOffsets[1] ?? 0);

        if (config.globalOffsets != null)
            globalOffsets.set(config.globalOffsets[0] ?? 0, config.globalOffsets[1] ?? 0);

        extra = config.extra;

        healthBarColor = (config.healthBarColor == null) ? ((type == PLAYER) ? 0xFF66FF33 : 0xFFFF0000) : Tools.getColor(config.healthBarColor);
        healthIcon = config.icon ?? HealthIcon.DEFAULT_ICON;

        gameOverChar = config.gameOverChar;
        noteSkin = config.noteSkin;

        if (type == GAMEOVER && config.gameOverData != null)
            gameOverData = GameOverScreen.formatData(config.gameOverData);

        forceDance(true);

        if (config.antialiasing != null)
            antialiasing = config.antialiasing;

        if (config.flip != null) {
            flipX = config.flip[0] ?? false;
            flipY = config.flip[1] ?? false;
        }

        if (config.scale != null) {
            scale.set(config.scale[0] ?? 1, config.scale[1] ?? 1);
            updateHitbox();
        }

        if (type == PLAYER && config.playerFlip) {
            // TODO: flipped offsets
            swapAnimations(singAnimations[0], singAnimations[3]);
            swapAnimations(singAnimations[0] + "miss", singAnimations[3] + "miss");
            flipX = !flipX;
        }
    }

    public inline function sing(direction:Int, suffix:String = "", forced:Bool = true):Void
        playAnimation(singAnimations[direction] + (suffix ?? ""), forced);

    function swapAnimations(firstAnimation:String, secondAnimation:String):Void {
        if (!animation.exists(firstAnimation) || !animation.exists(secondAnimation))
            return;

        @:privateAccess {
            var secondAnim = animation._animations.get(secondAnimation);
            animation._animations.set(secondAnimation, animation._animations.get(firstAnimation));
            animation._animations.set(firstAnimation, secondAnim);
        }

        if (offsets.exists(firstAnimation) && offsets.exists(secondAnimation)) {
            var secondOffsets = offsets.get(secondAnimation);
            offsets.addPoint(secondAnimation, offsets.get(firstAnimation));
            offsets.addPoint(firstAnimation, secondOffsets);
        }
    }

    override function dance(beat:Int, forced:Bool = false):Void {
        if (danceSteps.contains(animation.curAnim.name) || type == GAMEOVER)
            super.dance(beat, forced);
    }

    override function playAnimation(name:String, force:Bool = false, reversed:Bool = false, frame = 0):Void {
        super.playAnimation(name, force, reversed, frame);
        holdTime = 0;
    }

    override function setPosition(x:Float = 0, y:Float = 0):Void {
        super.setPosition(x - globalOffsets.x, y - globalOffsets.y);   
    }

    public function getCamDisplace():FlxPoint {
        return getMidpoint().subtractPoint(cameraOffsets);
    }

    #if ENGINE_SCRIPTING
    inline function destroyScript():Void {
        script?.destroy();
        script = null;
    }
    #end

    override function destroy():Void {
        #if ENGINE_SCRIPTING
        destroyScript();
        #end

        cameraOffsets = FlxDestroyUtil.put(cameraOffsets);
        globalOffsets = FlxDestroyUtil.put(globalOffsets);

        gameOverData = null;
        gameOverChar = null;

        healthIcon = null;
        noteSkin = null;

        singAnimations = null;
        character = null;

        extra = null;

        super.destroy();
    }

    function set_character(v:String):String {
        if (v != null) {
            switch (v) {
                // case "name" to hardcode your characters
                default:
                    var filePath:String = Assets.yaml('data/characters/${v}');

                    if (FileTools.exists(filePath))
                        setup(Tools.parseYAML(FileTools.getContent(filePath)));
                    else {
                        trace('Could not find character "${v}"!');
                        loadDefault();
                    }

                    #if ENGINE_SCRIPTING
                    destroyScript();

                    if (PlayState.current != null && type != DEBUG) {
                        var scriptPath:String = Assets.script('data/characters/${v}');
                        
                        if (FileTools.exists(scriptPath)) {
                            script = Script.load(scriptPath);
                            script.set("this", this);

                            PlayState.current.addScript(script);
                            script.call("onCharacterCreation");
                        }
                    }
                    #end
            }

            animation.finish();
            currentDance = 0;
        }

        return character = v;
    }

    inline function loadDefault():Void {
        var file:String = Assets.yaml("data/characters/boyfriend");
        var content:String = FileTools.getContent(file);
        setup(Tools.parseYAML(content));

        healthIcon = HealthIcon.DEFAULT_ICON;
        healthBarColor = FlxColor.GRAY;
    }
}

typedef CharacterConfig = {
    var image:String;
    var animations:Array<YAMLAnimation>;

    var ?atlasType:String;
    var ?library:String;

    var ?antialiasing:Bool;
    var ?flip:Array<Bool>;
    var ?scale:Array<Float>;

    var ?singAnimations:Array<String>;
    var ?singDuration:Float;

    var ?danceSteps:Array<String>;
    var ?danceBeat:Float;

    var ?cameraOffsets:Array<Float>;
    var ?globalOffsets:Array<Float>;

    var ?icon:String;
    var ?noteSkin:String;
    var ?healthBarColor:Dynamic;

    var ?gameOverChar:String;
    var ?gameOverData:GameOverData;

    var ?playerFlip:Bool;
    var ?extra:Dynamic;
}

enum abstract CharacterType(Int) from Int to Int {
    var DEFAULT;
    var PLAYER;
    var GAMEOVER;
    var DEBUG;
}
