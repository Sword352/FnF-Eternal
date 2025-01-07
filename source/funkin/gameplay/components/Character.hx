package funkin.gameplay.components;

import flixel.math.FlxPoint;
import funkin.ui.HealthIcon;
import funkin.objects.Bopper;
import funkin.data.GameOverData;
import funkin.data.CharacterData;

/**
 * Object which allows for the creation of characters.
 * Characters can be made by providing data in YAML files in the `data/characters` folder.
 * Character-specific logic can also be implemented by creating a script under the same path and file name.
 */
class Character extends Bopper {
    /**
     * Sing animations for every characters, ordered by direction.
     */
    public static final singAnimations:Array<String> = ["singLeft", "singDown", "singUp", "singRight"];

    /**
     * Miss animations for every characters, ordered by direction.
     */
    public static final missAnimations:Array<String> = ["missLeft", "missDown", "missUp", "missRight"];

    /**
     * Character this instance represents.
     */
    public var character(default, set):String;

    /**
     * Current animation state.
     */
    public var animState:AnimationState = NONE;

    /**
     * Time in milliseconds to wait before the current animation stops.
     * Ignored if equal to `-1`, only applies when the current animation state is `SINGING` or `DANCING`.
     */
    public var animDuration:Float = -1;

    /**
     * Represents the current position in the song when an animation is played.
     * Only applies when the current animation state is `SINGING` or `DANCING`.
     */
    public var animTime:Float = 0;

    /**
     * Time in steps to wait before any sing animation stops.
     */
    public var singDuration:Float = 4;

    /**
     * Defines the pixel offsets to adjust the camera's scroll when focusing on this character.
     */
    public var cameraOffsets:FlxPoint = FlxPoint.get();

    /**
     * Defines the pixel offsets to adjust this character's position.
     */
    public var globalOffsets:FlxPoint = FlxPoint.get();

    /**
     * Defines the UI health icon for this character.
     */
    public var healthIcon:String = HealthIcon.DEFAULT_ICON;

    /**
     * Defines the color for this character's health bar side.
     */
    public var healthBarColor:Null<FlxColor> = FlxColor.GRAY;

    /**
     * Optional game over character to use when using this character.
     */
    public var gameOverChar:String;

    /**
     * Optional game over data to apply when using this character.
     */
    public var gameOverData:GameOverData;

    /**
     * Optional note skin for this character's strumline.
     */
    public var noteSkin:String = "default";

    /**
     * Creates a new `Character`.
     * Unlike the constructor, this method takes account for scripted characters.
     * @param x Initial `x` position.
     * @param y Initial `y` position.
     * @param character Character this instance represents.
     * @return Character
     */
    public static function create(x:Float = 0, y:Float = 0, character:String = "boyfriend"):Character {
        var script:Script = ScriptManager.getScript(character);
        if (script == null) return new Character(x, y, character);

        var output:Character = script.buildClass(Character, [x, y, character]);
        return output ?? new Character(x, y, character);
    }

    /**
     * Creates a new `Character`.
     * NOTE: constructor doesn't take account for scripted characters! Use `Character.create` instead unless you know what you're doing.
     * @param x Initial `x` position.
     * @param y Initial `y` position.
     * @param character Character this instance represents.
     */
    public function new(x:Float = 0, y:Float = 0, character:String = "boyfriend"):Void {
        super(x, y);
        this.character = character;
    }

    /**
     * Update behaviour.
     */
    override function update(elapsed:Float):Void {
        switch (animState) {
            case SINGING | SPECIAL:
                if (animDuration != -1 && (Conductor.self.time - animTime) >= animDuration)
                    stopAnim();
            
            case _:
        }

        animation.update(elapsed);

        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end
    }

    /**
     * Plays a sing animation.
     * @param direction Direction in which to play the animation.
     * @param suffix Optional suffix to append to the animation's name.
     */
    public function playSingAnim(direction:Int, suffix:String = ""):Void {
        playAnimation(singAnimations[direction] + (suffix ?? ""), true);
        animTime = Conductor.self.time;
        animState = SINGING;

        // since hold notes have longer durations, we have to make sure they aren't overwritten (in case of double notes and such)
        animDuration = Math.max(animDuration, Conductor.self.semiQuaver * singDuration);
    }

    /**
     * Plays a miss animation.
     * @param direction Direction in which to play the animation.
     */
    public function playMissAnim(direction:Int):Void {
        playAnimation(missAnimations[direction], true);
        animDuration = Conductor.self.crotchet;
        animTime = Conductor.self.time;
        animState = SPECIAL;
    }

    /**
     * Plays a special animation.
     * @param animation Animation to play.
     * @param duration Time in milliseconds to wait before the animation stops. Ignored if equal to `-1`.
     */
    public function playSpecialAnim(animation:String, duration:Float = -1):Void {
        playAnimation(animation, true);
        animTime = Conductor.self.time;
        animDuration = duration;
        animState = SPECIAL;
    }

    /**
     * Plays an animation.
     * @param animation Animation to play.
     * @param type Animation type.
     * @param startTime Current position in the song.
     * @param duration Duration of the animation. Ignored if equal to `-1`.
     */
    public function playAnim(animation:String, type:AnimationState = NONE, startTime:Float = -1, duration:Float = -1):Void {
        playAnimation(animation, true);
        animDuration = duration;
        animTime = startTime;
        animState = type;
    }

    /**
     * Stops the current singing or special animation and makes this character dance.
     */
    public function stopAnim():Void {
        forceDance(Conductor.self.beat, true);
        animDuration = animTime = -1;
    }

    /**
     * Forces this character to dance.
     * @param beat Current beat in the song.
     * @param forced Whether to force the animation to be played.
     */
    public function forceDance(beat:Float, forced:Bool = false):Void {
        animState = DANCING;
        dance(beat, forced);
    }

    /**
     * Makes this character dance.
     * @param beat Current beat in the song.
     * @param forced Whether to force the animation to be played.
     */
    override function dance(beat:Float, forced:Bool = false):Void {
        if (animState == DANCING)
            super.dance(beat, forced);
    }

    /**
     * Sets this character's position and account for global offsets.
     * @param x `x` position.
     * @param y `y` position.
     */
    override function setPosition(x:Float = 0, y:Float = 0):Void {
        super.setPosition(x - globalOffsets.x, y - globalOffsets.y);
    }

    /**
     * Returns the camera position to focus on this character.
     * @return `FlxPoint`
     */
    public function getCameraDisplace():FlxPoint {
        return getMidpoint().subtractPoint(cameraOffsets);
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        cameraOffsets = FlxDestroyUtil.put(cameraOffsets);
        globalOffsets = FlxDestroyUtil.put(globalOffsets);

        gameOverData = null;
        gameOverChar = null;

        healthIcon = null;
        noteSkin = null;

        character = null;
        super.destroy();
    }

    function set_character(v:String):String {
        character = v;

        if (v != null) {
            var data:CharacterData = Paths.yaml('data/characters/${v}');
            if (data == null) {
                // TODO: have an hardcoded fallback character rather than looking for boyfriend's file
                Logging.warning('Could not find character "${v}"!');
                data = Paths.yaml("data/characters/boyfriend");
            }

            frames = Paths.buildAtlas(data.image);
            Tools.addYamlAnimations(this, data.animations);
    
            singDuration = data.singDuration ?? 4;
            danceSteps = data.danceSteps ?? ["idle"];
            danceInterval = data.danceBeat ?? 2;
    
            if (data.cameraOffsets != null)
                cameraOffsets.set(data.cameraOffsets[0] ?? 0, data.cameraOffsets[1] ?? 0);
    
            if (data.globalOffsets != null)
                globalOffsets.set(data.globalOffsets[0] ?? 0, data.globalOffsets[1] ?? 0);

            healthBarColor = (data.healthBarColor == null ? null : Tools.getColor(data.healthBarColor));
            healthIcon = data.icon ?? HealthIcon.DEFAULT_ICON;
    
            gameOverData = data.gameOverData;
            gameOverChar = data.gameOverChar;
            noteSkin = data.noteSkin;
    
            if (data.antialiasing != null)
                antialiasing = data.antialiasing;
    
            if (data.flip != null) {
                flipX = data.flip[0] ?? false;
                flipY = data.flip[1] ?? false;
            }

            // TODO: maybe implement static animations?
            // playAnimation(animation.exists("static") ? "static" : danceSteps[0], true);

            resetDance();
            animState = DANCING;
            animation.stop();
    
            if (data.scale != null) {
                scale.set(data.scale[0] ?? 1, data.scale[1] ?? 1);
                updateHitbox();
            }
    
            // TODO: reimplement this back?
            /*
            if (type == PLAYER && data.playerFlip) {
                swapAnimations(singAnimations[0], singAnimations[3]);
                swapAnimations(singAnimations[0] + "miss", singAnimations[3] + "miss");
                flipX = !flipX;
            }
            */
        }

        return v;
    }
}

/**
 * Represents a character's animation state.
 */
enum abstract AnimationState(Int) from Int to Int {
    var NONE = -1;
    var SINGING;
    var HOLDING;
    var DANCING;
    var SPECIAL;
}
