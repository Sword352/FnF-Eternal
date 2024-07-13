import funkin.gameplay.components.Character.AnimationState;

var nextBeat:Int = 8;
var thunder:FlxSound;

function onCreatePost():Void {
    // cache the sound effects
    Assets.sound("thunder_1");
    Assets.sound("thunder_2");
}

function onBeatHit(event):Void {
    if (event.beat <= nextBeat || !FlxG.random.bool(10)) return;

    background.animation.play("lighting", true);

    thunder = FlxG.sound.play(Assets.sound("thunder_" + FlxG.random.int(1, 2)));
    thunder.onComplete = () -> thunder = null;

    for (character in [player, spectator])
        if (character.animState != AnimationState.SINGING)
            character.playSpecialAnim("scared", Conductor.self.crochet);

    nextBeat = event.beat + FlxG.random.int(8, 24);
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
