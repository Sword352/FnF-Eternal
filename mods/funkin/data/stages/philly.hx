import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.sound.FlxSound;
import flixel.addons.display.FlxRuntimeShader;
import funkin.gameplay.components.Stage;
import funkin.core.scripting.Events;
import funkin.music.Conductor;

class PhillyStage extends Stage {
    var lightColors:Array<FlxColor> = [0x30A2FC, 0x31FD8C, 0xFB32F4, 0xFD4430, 0xFAA733];
    var lightTiming:Float = 0;
    var lastLight:Int = -1;

    var trainEnabled:Bool = false;
    var trainMoving:Bool = false;
    var trainCooldown:Int = 0;
    var trainLoop:Int = 8;

    var trainFPS:Float = 1 / 24;
    var trainTimer:Float = 0;

    var trainSound:FlxSound;

    public function new():Void {
        super();
        game.addEventListener(Events.CREATE_POST, onCreatePost);
        game.addEventListener(Events.UPDATE_POST, onUpdatePost);
        game.addEventListener(Events.SUBSTATE_OPEN, onSubStateOpen);
        game.addEventListener(Events.SUBSTATE_CLOSE, onSubStateClose);
        game.addEventListener(Events.MEASURE_HIT, onMeasureHit);
        game.addEventListener(Events.BEAT_HIT, onBeatHit);
    }

    function onCreatePost():Void {
        light.shader = new FlxRuntimeShader("
        #pragma header
        uniform float fadeMod;

        float curve(float x) {
            // custom easing, the fade gets faster on higher mod
            return pow(x, 2. + 1.5 * x);
        }
        
        void main() {
            // gl_FragColor = clamp(flixel_texture2D(bitmap, openfl_TextureCoordv) - curve(fract(fadeMod)), 0.0, 1.0);
            gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv) - curve(fadeMod);
        }
        ");
        light.shader.setFloat("fadeMod", 1);

        // Load the train sound effect
        trainSound = FlxG.sound.load(Paths.sound("train_passes"));
    }

    function onUpdatePost(elapsed:Float):Void {
        if (!game.music.playing) return;

        light.shader.setFloat("fadeMod", ((game.conductor.time - lightTiming) / game.conductor.measureLength) * 1.25);

        // 24 fps movement
        if (trainEnabled) {
            trainTimer += elapsed;
            if (trainTimer >= trainFPS) {
                trainTimer -= trainFPS;
                updateTrain();
            }
        }
    }

    function onBeatHit(beat):Void {
        if (!trainEnabled && ++trainCooldown > 8 && beat % 8 == 4 && FlxG.random.bool(30)) {
            trainCooldown = FlxG.random.int(-4, 0);
            startTrain();
        }
        else if (game.spectator?.animation.name == "hairFall" && game.spectator?.animation.finished)
            game.spectator.forceDance(beat, true);
    }

    function onMeasureHit():Void {
        var color:Int = FlxG.random.int(0, lightColors.length - 1, [lastLight]);
        light.color = lightColors[color];
        lightTiming = game.conductor.time;
        lastLight = color;
    }

    function onSubStateOpen():Void {
        if (trainEnabled)
            trainSound.pause();
    }

    function onSubStateClose():Void {
        if (trainEnabled)
            trainSound.resume();
    }

    function startTrain():Void {
        trainEnabled = true;
        trainSound.play(true);
    }

    function updateTrain():Void {
        if (trainSound.time >= 4700 && !trainMoving) {
            game.spectator?.playSpecialAnim("hairBlow");
            trainMoving = true;
        }

        if (trainMoving) {
            var trainFinishing:Bool = (trainLoop <= 0);
            train.x -= 400;

            if (train.x < -2000 && !trainFinishing) {
                trainFinishing = (--trainLoop <= 0);
                train.x = -1150;
            }

            if (train.x < -4000 && trainFinishing)
                resetTrain();
        }
    }

    function resetTrain():Void {
        game.spectator?.playSpecialAnim("hairFall");
        trainEnabled = trainMoving = false;

        train.x = 2000;
        trainLoop = 8;
    }
}
