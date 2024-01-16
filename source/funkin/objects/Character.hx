package funkin.objects;

import flixel.math.FlxPoint;

import funkin.objects.sprites.DancingSprite;

import funkin.states.substates.GameOverScreen;
import funkin.states.substates.GameOverScreen.GameOverProperties;

#if ENGINE_SCRIPTING
import eternal.core.scripting.HScript;
import eternal.core.scripting.ScriptableState;
#end

typedef CharacterConfig = {
    var image:String;
    var animations:Array<YAMLAnimation>;

    var ?atlasType:String;
    var ?antialiasing:Bool;
    var ?flip:Array<Bool>;
    var ?scale:Array<Float>;

    var ?singAnimations:Array<String>;
    var ?singDuration:Float;

    var ?danceAnimations:Array<String>;
    var ?danceBeat:Float;

    var ?healthBarColor:Dynamic;
    var ?cameraOffsets:Array<Float>;

    var ?icon:String;
    var ?noteSkin:String;

    var ?gameOverCharacter:String;
    var ?gameOverProperties:GameOverProperties;

    var ?playerFlip:Bool;
    var ?extra:Dynamic;
}

enum abstract CharacterType(String) from String to String {
    var DEFAULT = "default";
    var PLAYER = "player";
    var GAMEOVER = "gameover";
    var DEBUG = "debug";
}

class Character extends DancingSprite {
    public static final defaultAnimations:Array<String> = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];

    public var character(default, set):String;
    public var data:CharacterConfig;
    public var type:CharacterType;

    public var singAnimations:Array<String> = defaultAnimations.copy();

    public var cameraDisplace:FlxPoint;
    public var holding:Bool = false;

    public var singDuration:Float = 4;
    public var animEndTime:Float = 0;
    public var holdTime:Float = 0;

    #if ENGINE_SCRIPTING
    private var lastScriptRef:HScript;
    #end

    private function set_character(v:String):String {
        character = v;

        if (!exists)
            return v;

        switch (v) {
            // case "name" to hardcode your characters
            default:
                var filePath:String = Assets.yaml('data/characters/${v}');

                if (FileTools.exists(filePath))
                    data = Tools.parseYAML(FileTools.getContent(filePath));
                else {
                    trace('Could not find character "${v}"!');
                    data = returnDefaultCharacter();
                }

                setup(data);

                #if ENGINE_SCRIPTING
                destroyScript();

                if (type != DEBUG && FlxG.state is ScriptableState) {
                    var scriptPath:String = Assets.getPath('data/characters/${v}', SCRIPT);
                    if (FileTools.exists(scriptPath)) {
                        var scr:HScript = new HScript(scriptPath, false);
                        cast(FlxG.state, ScriptableState).addScript(scr);
                        scr.set("this", this);
                        scr.call("onInit");

                        lastScriptRef = scr;
                    }
                }
                #end
        }

        animation.finish();
        currentDance = 0;

        return v;
    }

    public function new(x:Float = 0, y:Float = 0, character:String = "bf", type:CharacterType = DEFAULT):Void {
        super(x, y);

        cameraDisplace = FlxPoint.get();

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

        if (!holding && holdTime >= Conductor.stepCrochet * singDuration * 0.001) {
            holdTime = 0;
            forceDance();
        }
    }

    public function setup(config:CharacterConfig):Void {
        frames = switch ((config.atlasType ?? "").toLowerCase().trim()) {
            case "aseprite": Assets.getAseAtlas(config.image);
            case "packer": Assets.getPackerAtlas(config.image);
            default: Assets.getSparrowAtlas(config.image);
        }

        Tools.addYamlAnimations(this, config.animations);

        singAnimations = config.singAnimations ?? singAnimations;
        singDuration = config.singDuration ?? 4;

        danceAnimations = config.danceAnimations ?? ["idle"];
        beat = config.danceBeat ?? 2;

        if (config.icon == null && (type == PLAYER || type == DEFAULT))
            config.icon = funkin.objects.ui.HealthIcon.DEFAULT_ICON;

        if (config.healthBarColor == null && (type == PLAYER || type == DEFAULT))
            config.healthBarColor = (type == PLAYER) ? 0xFF66FF33 : 0xFFFF0000;

        if (config.gameOverCharacter == null && type == PLAYER)
            config.gameOverCharacter = "bf-dead";

        if (type == GAMEOVER && config.gameOverProperties != null)
            config.gameOverProperties = GameOverScreen.formatProperties(config.gameOverProperties);

        forceDance(true);

        if (config.antialiasing != null)
            antialiasing = config.antialiasing;

        if (config.flip != null) {
            while (config.flip.length < 2)
                config.flip.push(false);

            flipX = config.flip[0];
            flipY = config.flip[1];
        }

        if (config.scale != null) {
            while (config.scale.length < 2)
                config.scale.push(1);

            scale.set(config.scale[0], config.scale[1]);
            updateHitbox();

            // re-apply offsets
            playAnimation(danceAnimations[0], true);
        }

        if (type == PLAYER && data.playerFlip != null && data.playerFlip) {
            swapAnimations(singAnimations[0], singAnimations[3]);
            swapAnimations(singAnimations[0] + "miss", singAnimations[3] + "miss");
            flipX = !flipX;
        }

        if (config.cameraOffsets == null)
            config.cameraOffsets = [0, 0];
        while (config.cameraOffsets.length < 2)
            config.cameraOffsets.push(0);

        updateCamDisplace();
    }

    public function updateCamDisplace():Void {
        if (cameraDisplace == null)
            return;

        getMidpoint(cameraDisplace);
        cameraDisplace.x += data.cameraOffsets[0];
        cameraDisplace.y += data.cameraOffsets[1];
    }

    public function sing(direction:Int, suffix:String = "", forced:Bool = true):Void {
        if (suffix == null)
            suffix = "";
        playAnimation(singAnimations[direction] + suffix, forced);
    }

    public function swapAnimations(firstAnimation:String, secondAnimation:String):Void {
        if (!animation.exists(firstAnimation) || !animation.exists(secondAnimation))
            return;

        @:privateAccess {
            var secondAnim = animation._animations.get(secondAnimation);
            animation._animations.set(secondAnimation, animation._animations.get(firstAnimation));
            animation._animations.set(firstAnimation, secondAnim);
        }

        if (animationOffsets.exists(firstAnimation) && animationOffsets.exists(secondAnimation)) {
            var secondOffsets = animationOffsets.get(secondAnimation);
            animationOffsets.set(secondAnimation, animationOffsets.get(firstAnimation));
            animationOffsets.set(firstAnimation, secondOffsets);
        }
    }

    override public function dance(currentBeat:Int, forced:Bool = false):Void {
        if (danceAnimations.contains(animation.curAnim.name) || type == GAMEOVER)
            super.dance(currentBeat, forced);
    }

    override public function playAnimation(name:String, force:Bool = false, reversed:Bool = false, frame = 0):Void {
       super.playAnimation(name, force, reversed, frame);
        holdTime = 0;
    }

    #if ENGINE_SCRIPTING
    inline function destroyScript():Void {
        lastScriptRef?.destroy();
        lastScriptRef = null;
    }
    #end

    override function destroy():Void {
        #if ENGINE_SCRIPTING
        destroyScript();
        #end

        super.destroy();

        cameraDisplace = FlxDestroyUtil.put(cameraDisplace);
        
        singAnimations = null;
        character = null;
        data = null;
    }

    override function set_x(x:Float):Float {
        super.set_x(x);
        updateCamDisplace();
        return x;
    }

    override function set_y(y:Float):Float {
        super.set_y(y);
        updateCamDisplace();
        return y;
    }

    public static function returnDefaultCharacter():CharacterConfig {
        return {
            image: "characters/BOYFRIEND",
            icon: "bf",
            animations: [
            {
                name: "idle",
                prefix: "BF idle dance",
                fps: 24,
                loop: false
            },
            {
                name: "singLEFT",
                prefix: "BF NOTE LEFT0",
                fps: 24,
                loop: false
            },
            {
                name: "singDOWN",
                prefix: "BF NOTE DOWN0",
                fps: 24,
                loop: false
            },
            {
                name: "singUP",
                prefix: "BF NOTE UP0",
                fps: 24,
                loop: false
            },
            {
                name: "singRIGHT",
                prefix: "BF NOTE RIGHT0",
                fps: 24,
                loop: false
            }],
            healthBarColor: [49, 176, 209],
            cameraOffsets: [0, -150],
            flip: [true, false],
            playerFlip: true
        };
    }
}
