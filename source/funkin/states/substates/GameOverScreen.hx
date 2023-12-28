package funkin.states.substates;

import flixel.FlxObject;
import flixel.math.FlxPoint;

import funkin.objects.Character;
import funkin.states.menus.StoryMenu;
import funkin.states.debug.ChartEditor;
import funkin.states.menus.FreeplayMenu;

class GameOverScreen extends MusicBeatSubState {
    var character:Character;
    var cameraObject:FlxObject;

    var characterStr:String;
    var data:GameOverProperties;

    var position:FlxPoint;

    var started:Bool = false;
    var allowInputs:Bool = true;

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
        data = formatProperties(character.data.gameOverProperties ?? PlayState.song.meta.gameOverProperties);
        add(character);

        cameraObject = new FlxObject(character.cameraDisplace.x, character.cameraDisplace.y, 1, 1);
        cameraObject.visible = false;
        add(cameraObject);

        character.playAnimation("firstDeath");
        FlxG.sound.play(Assets.sound(data.deathSound));

        Conductor.bpm = data.bpm;
        Conductor.music = FlxG.sound.music;

        Conductor.resetPosition();

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
                started = true;
                FlxG.sound.playMusic(Assets.music(data.music));
            }
        }

        if (controls.justPressed("back")) {
            Tools.stopMusic();

            PlayState.lossCounter = 0;
            TransitionSubState.skipNextTransIn = true;

            FlxG.switchState(switch (PlayState.gameMode) {
                case STORY: new StoryMenu();
                case DEBUG: new ChartEditor(PlayState.song, PlayState.currentDifficulty);
                default: new FreeplayMenu();
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

    private function accept():Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onAccept"))
            return;
        #end

        allowInputs = false;
        Assets.clearAssets = Settings.get("reload assets");

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

    public static function formatProperties(properties:GameOverProperties):GameOverProperties {
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