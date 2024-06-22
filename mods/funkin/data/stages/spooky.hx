var lastBeat:Int = 0;
var awaitBeat:Int = 8;
var thunder:FlxSound;

function onCreatePost():Void {
    // cache the sound effects
    Assets.sound("thunder_1");
    Assets.sound("thunder_2");
}

function onBeatHit(event):Void {
    if (!FlxG.random.bool(10) || event.beat <= (lastBeat + awaitBeat)) return;

    background.animation.play("lighting", true);

    thunder = FlxG.sound.play(Assets.sound("thunder_" + FlxG.random.int(1, 2)));
    thunder.onComplete = () -> thunder = null;

    for (character in [player, spectator]) {
        if (character.holdTime <= 0) {
            character.playAnimation("scared", true);
            character.animEndTime = Conductor.self.crochet * 0.001;
        }
    }

    lastBeat = event.beat;
    awaitBeat = FlxG.random.int(8, 24);
}

function onSubStateOpen(_):Void {
    thunder?.pause();
}

function onSubStateClose(_):Void {
    thunder?.resume();
}

function onGameOver():Void {
    thunder?.stop();
}
