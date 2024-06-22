package funkin.gameplay;

import flixel.FlxObject;
import flixel.math.FlxPoint;

import funkin.gameplay.components.Character;
import funkin.data.GameOverData;

import funkin.menus.StoryMenu;
import funkin.menus.FreeplayMenu;
import funkin.editors.chart.ChartEditor;

class GameOverScreen extends MusicBeatSubState {
    var cameraObject:FlxObject;
    var character:Character;

    var data:GameOverData;
    var characterStr:String;
    var position:FlxPoint;

    var allowInputs:Bool = true;
    var started:Bool = false;

    public function new(x:Float = 0, y:Float = 0, character:String = "boyfriend-dead"):Void {
        super();

        this.characterStr = character;
        position = FlxPoint.get(x, y);

        PlayState.lossCounter++;
    }

    override function create():Void {
        super.create();

        initStateScripts();
        scripts.call("onCreate");

        character = new Character(position.x, position.y, characterStr, GAMEOVER);
        data = formatData(character.gameOverData ?? PlayState.song.gameplayInfo.gameOverData);
        add(character);

        cameraObject = new FlxObject(0, 0, 1, 1);
        cameraObject.visible = false;
        add(cameraObject);

        var position:FlxPoint = character.getCamDisplace();
        cameraObject.setPosition(position.x, position.y);
        position.put();

        FlxG.sound.play(Assets.sound(data.deathSound));
        character.playAnimation("firstDeath");

        conductor.bpm = data.bpm;
        conductor.enableInterpolation = false;
        conductor.music = FlxG.sound.music;
        conductor.resetTime();

        scripts.call("onCreatePost");
    }

    override function update(elapsed:Float):Void {
        scripts.call("onUpdate", [elapsed]);
        super.update(elapsed);

        if (character.animation.curAnim.name == "firstDeath" && !started) {
            if (character.animation.curAnim.curFrame >= 12 && camera.target == null)
                camera.follow(cameraObject, LOCKON, data.cameraSpeed * 0.01);

            if (character.animation.curAnim.finished) {
                FlxG.sound.playMusic(Assets.music(data.music));
                conductor.active = true;
                started = true;
            }
        }

        if (controls.justPressed("back")) {
            Tools.stopMusic();

            Transition.skipNextTransOut = true;
            PlayState.lossCounter = 0;

            FlxG.switchState(switch (PlayState.gameMode) {
                case STORY: StoryMenu.new;
                case DEBUG: ChartEditor.new.bind(PlayState.song, PlayState.currentDifficulty, 0);
                default: FreeplayMenu.new;
            });
        }

        if (controls.justPressed("accept") && allowInputs)
            accept();

        scripts.call("onUpdatePost", [elapsed]);
    }

    override function beatHit(beat:Int):Void {
        if (character != null)
            character.dance(beat, true);

        super.beatHit(beat);
    }

    function accept():Void {
        if (scripts.quickEvent("onAccept").cancelled) return;

        Assets.clearAssets = Options.reloadAssets;
        allowInputs = false;

        conductor.music = null;
        Tools.stopMusic();

        character?.playAnimation("deathConfirm", true);
        FlxG.sound.play(Assets.sound(data.confirmSound));

        new FlxTimer().start(0.7, (_) -> {
            camera.fade(Tools.getColor(data.fadeColor), data.fadeDuration, false, FlxG.resetState);
        });
    }

    override function destroy():Void {
        position = FlxDestroyUtil.put(position);
        characterStr = null;
        data = null;

        super.destroy();
    }

    public static inline function formatData(data:GameOverData):GameOverData {
        if (data == null) {
            return {
                music: "gameover/gameOver",
                confirmSound: "gameplay/gameOverEnd",
                deathSound: "gameplay/fnf_loss_sfx",
                fadeColor: "black",
                fadeDuration: 2,
                cameraSpeed: 6,
                bpm: 100
            };
        }

        if (data.music == null) data.music = "gameover/gameOver";
        if (data.confirmSound == null) data.confirmSound = "gameplay/gameOverEnd";
        if (data.deathSound == null) data.deathSound = "gameplay/fnf_loss_sfx";
        if (data.bpm == null) data.bpm = 100;

        if (data.fadeDuration == null) data.fadeDuration = 2;
        if (data.fadeColor == null) data.fadeColor = "black";
        if (data.cameraSpeed == null) data.cameraSpeed = 6;

        return data;
    }
}
