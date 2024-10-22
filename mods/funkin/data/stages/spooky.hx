import flixel.group.FlxTypedSpriteGroup;
import funkin.gameplay.components.Character;
import funkin.gameplay.components.Character.AnimationState;

var lightElements:FlxTypedSpriteGroup;
var lightFrame:Float = 1 / 24;
var lightTimer:Float = 0;

var thunder:FlxSound;
var nextBeat:Int = 8;

function onCreatePost():Void {
    // cache the sound effects
    Paths.sound("thunder_1");
    Paths.sound("thunder_2");

    lightElements = new FlxTypedSpriteGroup();
    lightElements.group.add(backgroundLight);
    lightElements.group.add(windowLight);
    lightElements.group.add(windowShadowLight);
    lightElements.group.add(stairsLight);
    lightElements.alpha = 0;
}

function onUpdate(elapsed:Float):Void {
    if (lightElements.alpha == 0)
        return;

    lightTimer += elapsed;
    if (lightTimer < lightFrame)
        return;

    lightElements.alpha -= lightTimer;
    lightTimer = 0;
}

function onBeatHit(event):Void {
    if (event.beat <= nextBeat || !FlxG.random.bool(10)) 
        return;

    thunder = FlxG.sound.play(Paths.sound("thunder_" + FlxG.random.int(1, 2)));
    thunder.onComplete = () -> thunder = null;

    scareCharacter(spectator);
    scareCharacter(player);            

    nextBeat = event.beat + FlxG.random.int(8, 24);
    lightElements.alpha = 1;
}

function scareCharacter(character:Character):Void {
    if (character.animState != AnimationState.SINGING)
        character.playSpecialAnim("scared", conductor.crotchet * 2);
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
