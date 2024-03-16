var lastBeat:Int = 0;
var awaitBeat:Int = 8;
var thunder:FlxSound;

function onCreatePost():Void {
    // cache the sound effects
    Assets.sound("thunder_1");
    Assets.sound("thunder_2");
}

function onBeatHit(beat:Int):Void {
    if (!FlxG.random.bool(10) || beat <= (lastBeat + awaitBeat)) return;

    background.animation.play("lighting", true);

    thunder = FlxG.sound.play(Assets.sound("thunder_" + FlxG.random.int(1, 2)));
    thunder.onComplete = () -> thunder = null;

    for (character in [player, spectator]) {
        if (character.holdTime <= 0) {
            character.playAnimation("scared", true);
            character.animEndTime = Conductor.crochet * 0.001;
        }
    }

    lastBeat = beat;
    awaitBeat = FlxG.random.int(8, 24);
}

function onSubStateOpened():Void {
    thunder?.pause();
}

function onSubStateClosed():Void {
    thunder?.resume();
}

function onGameOver():Void {
    thunder?.stop();
}