import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.group.FlxTypedSpriteGroup;
import funkin.gameplay.components.Character;
import funkin.gameplay.components.Character.AnimationState;
import funkin.gameplay.components.Stage;
import funkin.core.scripting.Events;

class SpookyStage extends Stage {
    public function new():Void {
        super();
        game.addEventListener(Events.CREATE_POST, onCreatePost);
        game.addEventListener(Events.SUBSTATE_OPEN, onSubStateOpen);
        game.addEventListener(Events.SUBSTATE_CLOSE, onSubStateClose);
        game.addEventListener(Events.BEAT_HIT, onBeatHit);
        game.addEventListener(Events.UPDATE, onUpdate);
    }

    /**
     * Group containing elements used for the thunder strike effect.
     */
    var lightElements:FlxTypedSpriteGroup;

    /**
     * Amount of seconds a frame lasts during the effect.
     */
    var lightFrame:Float = 1 / 24;

    /**
     * Keeps track of the elapsed time before passing to the next animation frame.
     */
    var lightTimer:Float = 0;

    var thunder:FlxSound;
    var nextBeat:Int = 8;

    function onCreatePost():Void {
        lightElements = new FlxTypedSpriteGroup();
        lightElements.group.add(backgroundLight);
        lightElements.group.add(windowLight);
        lightElements.group.add(windowShadowLight);
        lightElements.group.add(stairsLight);
        lightElements.alpha = 0;

        // cache the sound effects
        Paths.sound("thunder_1");
        Paths.sound("thunder_2");
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

    function onBeatHit(beat):Void {
        if (beat <= nextBeat || !FlxG.random.bool(10)) return;
    
        thunder = FlxG.sound.play(Paths.sound("thunder_" + FlxG.random.int(1, 2)));
        thunder.onComplete = onThunderSoundComplete;
    
        scareCharacter(game.spectator);
        scareCharacter(game.player);            
    
        nextBeat = beat + FlxG.random.int(8, 24);
        lightElements.alpha = 1;
    }

    function scareCharacter(character:Character):Void {
        if (character == null) return;
        if (character.animState != AnimationState.SINGING)
            character.playSpecialAnim("scared", game.conductor.crotchet * 2);
    }

    function onThunderSoundComplete():Void {
        thunder = null;
    }

    function onSubStateOpen():Void {
        thunder?.pause();
    }
    
    function onSubStateClose():Void {
        thunder?.resume();
    }
}
