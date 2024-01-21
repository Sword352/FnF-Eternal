var lastBeat:Int = 0;
var awaitBeat:Int = 8;

function onCreatePost():Void {
    // cache the sound effects
    Assets.sound("thunder_1");
    Assets.sound("thunder_2");
}

function onBeatHit(beat:Int):Void {
    if (!FlxG.random.bool(10) || !music.playing || beat <= (lastBeat + awaitBeat))
        return;

    FlxG.sound.play(Assets.sound("thunder_" + FlxG.random.int(1, 2)));
    background.animation.play("lighting", true);

    for (character in [player, spectator]) {
        if (character.holdTime <= 0) {
            character.playAnimation("scared", true);
            character.animEndTime = Conductor.crochet * 0.001;
        }
    }

    lastBeat = beat;
    awaitBeat = FlxG.random.int(8, 24);
}