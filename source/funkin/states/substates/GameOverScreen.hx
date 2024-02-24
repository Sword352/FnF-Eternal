package funkin.states.substates;

import flixel.FlxObject;
import flixel.math.FlxPoint;

import funkin.objects.Character;
import funkin.states.menus.StoryMenu;
import funkin.states.debug.ChartEditor;
import funkin.states.menus.FreeplayMenu;

class GameOverScreen extends MusicBeatSubState {
    var cameraObject:FlxObject;
    var character:Character;

    var data:GameOverProperties;
    var characterStr:String;
    var position:FlxPoint;

    var allowInputs:Bool = true;
    var started:Bool = false;

    #if ENGINE_SCRIPTING
    var overrideCode:Bool = false;
    #end

    public function new(x:Float = 0, y:Float = 0, character:String = "bf-dead"):Void {
        super();

        this.characterStr = character;
        position = FlxPoint.get(x, y);

        PlayState.lossCounter++;
    }

    override function create():Void {
        super.create();

        #if ENGINE_SCRIPTING
        initStateScript();
        hxsCall("onCreate");

        if (overrideCode) {
            hxsCall("onCreatePost");
            return;
        }
        #end

        character = new Character(position.x, position.y, characterStr, GAMEOVER);
        data = formatProperties(character.gameOverProps ?? PlayState.song.meta.gameOverProperties);
        add(character);

        cameraObject = new FlxObject(0, 0, 1, 1);
        cameraObject.visible = false;
        add(cameraObject);

        var position:FlxPoint = character.getCamDisplace();
        cameraObject.setPosition(position.x, position.y);
        position.put();

        FlxG.sound.play(Assets.sound(data.deathSound));
        character.playAnimation("firstDeath");

        Conductor.bpm = data.bpm;
        Conductor.music = FlxG.sound.music;

        Conductor.resetTime();

        #if ENGINE_SCRIPTING
        hxsCall("onCreatePost");
        #end
    }

    override function update(elapsed:Float):Void {
        if (FlxG.sound.music?.playing)
            updateConductor(elapsed);

        #if ENGINE_SCRIPTING
        hxsCall("onUpdate", [elapsed]);
        super.update(elapsed);

        if (overrideCode) {
            hxsCall("onUpdatePost", [elapsed]);
            return;
        }
        #else
        super.update(elapsed);
        #end

        if (character.animation.curAnim.name == "firstDeath" && !started) {
            if (character.animation.curAnim.curFrame >= 12 && camera.target == null)
                camera.follow(cameraObject, LOCKON, data.cameraSpeed * 0.01);

            if (character.animation.curAnim.finished) {
                FlxG.sound.playMusic(Assets.music(data.music));
                started = true;
            }
        }

        if (controls.justPressed("back")) {
            Tools.stopMusic();

            PlayState.lossCounter = 0;
            TransitionSubState.skipNextTransIn = true;

            FlxG.switchState(switch (PlayState.gameMode) {
                case STORY: StoryMenu.new;
                case DEBUG: ChartEditor.new.bind(PlayState.song, PlayState.currentDifficulty, 0);
                default: FreeplayMenu.new;
            });
        }

        if (controls.justPressed("accept") && allowInputs)
            accept();

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    override function beatHit(currentBeat:Int):Void {
        if (character != null)
            character.dance(currentBeat, true);

        super.beatHit(currentBeat);
    }

    inline function accept():Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onAccept"))
            return;
        #end

        Assets.clearAssets = Settings.get("reload assets");
        allowInputs = false;

        Conductor.music = null;
        Tools.stopMusic();

        character?.playAnimation("deathConfirm", true);
        FlxG.sound.play(Assets.sound(data.confirmSound));

        new FlxTimer().start(0.7, (_) -> {
            camera.fade(Tools.getColor(data.fadeColor), data.fadeDuration, false, FlxG.resetState);
        });

        #if ENGINE_SCRIPTING
        hxsCall("onAcceptPost");
        #end
    }

    override function destroy():Void {
        position = FlxDestroyUtil.put(position);
        characterStr = null;
        data = null;

        super.destroy();
    }

    public static inline function formatProperties(properties:GameOverProperties):GameOverProperties {
        if (properties == null) {
            return {
                music: "gameover/gameOver",
                bpm: 100,
                confirmSound: "gameplay/gameOverEnd",
                deathSound: "gameplay/fnf_loss_sfx",
                fadeColor: "black",
                fadeDuration: 2,
                cameraSpeed: 6
            };
        }

        if (properties.music == null)
            properties.music = "gameover/gameOver";

        if (properties.bpm == null)
            properties.bpm = 100;

        if (properties.confirmSound == null)
            properties.confirmSound = "gameplay/gameOverEnd";

        if (properties.deathSound == null)
            properties.deathSound = "gameplay/fnf_loss_sfx";

        if (properties.fadeColor == null)
            properties.fadeColor = "black";

        if (properties.fadeDuration == null)
            properties.fadeDuration = 2;

        if (properties.cameraSpeed == null)
            properties.cameraSpeed = 6;

        return properties;
    }
}

typedef GameOverProperties = {
    var ?music:String;
    var ?bpm:Float;

    var ?confirmSound:String;
    var ?deathSound:String;

    var ?fadeColor:Dynamic;
    var ?fadeDuration:Float;

    var ?cameraSpeed:Float;
}