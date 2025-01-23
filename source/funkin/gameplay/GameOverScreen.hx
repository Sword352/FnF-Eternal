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

    public function new(x:Float = 0, y:Float = 0, character:String = "boyfriend-gameover"):Void {
        super();

        this.characterStr = character;
        position = FlxPoint.get(x, y);

        PlayState.lossCounter++;
    }

    override function create():Void {
        super.create();

        character = Character.create(0, 0, characterStr);
        character.setPosition(position.x, position.y);

        conductor = new Conductor();
        conductor.active = false;

        data = character.gameOverData ?? PlayState.song.gameplayInfo.gameOverData ?? {};
        conductor.bpm = data.bpm ?? 100;

        add(conductor);
        add(character);

        cameraObject = new FlxObject(0, 0, 1, 1);
        cameraObject.visible = false;
        add(cameraObject);

        var position:FlxPoint = character.getCameraDisplace();
        cameraObject.setPosition(position.x, position.y);
        position.put();

        FlxG.sound.play(Paths.sound(data.deathSound ?? "gameplay/fnf_loss_sfx"));
        character.playAnimation("firstDeath");
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (character.animation.curAnim.name == "firstDeath" && !started) {
            if (character.animation.curAnim.curFrame >= 12 && camera.target == null)
                camera.follow(cameraObject, LOCKON, 0.06);

            if (character.animation.curAnim.finished) {
                startMusic();
            }
        }

        if (controls.justPressed("back")) {
            BGM.stopMusic();

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
    }

    override function beatHit(beat:Int):Void {
        if (beat >= 0)
            character?.dance(beat, true);

        super.beatHit(beat);
    }

    function startMusic():Void {
        FlxG.sound.playMusic(Paths.music(data.music ?? "gameover/gameOver"));
        conductor.music = FlxG.sound.music;
        conductor.active = true;
        started = true;
    }

    function accept():Void {
        Assets.clearCache = Options.reloadAssets;
        allowInputs = false;

        conductor.active = false;
        BGM.stopMusic();

        FlxG.sound.play(Paths.sound(data.confirmSound ?? "gameplay/gameOverEnd"));
        character?.playAnimation("deathConfirm", true);

        FlxTimer.wait(0.7, () -> camera.fade(FlxColor.BLACK, 2, false, FlxG.resetState));
    }

    override function destroy():Void {
        position = FlxDestroyUtil.put(position);
        characterStr = null;
        data = null;

        super.destroy();
    }
}
