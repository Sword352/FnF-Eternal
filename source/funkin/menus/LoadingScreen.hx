package funkin.menus;

import funkin.ui.SpinningCircle;
import funkin.data.ChartFormat;
import funkin.data.NoteSkin;
import funkin.data.StageData;
import funkin.data.*;
import lime.app.Future;
import openfl.Lib;

/**
 * State which preloads assets before heading to gameplay.
 */
class LoadingScreen extends ScriptableState {
    #if debug
    /**
     * Time elapsed since the start of the program, used to determine how long the loading screen takes to load.
     */
    static var _loadTime:Float = -1;
    #end

    /**
     * Gameplay start time.
     */
    var startTime:Float = 0;

    #if debug
    /**
     * Traces how long the loading screen took to load.
     */
    public static function reportTime():Void {
        if (_loadTime == -1) return;

        trace('${PlayState.song.meta.name} (${PlayState.currentDifficulty}) - Took ${((Lib.getTimer() - _loadTime) / 1000)}s to load');
        _loadTime = -1;
    }
    #end

    /**
     * Creates a new `LoadingScreen`.
     * @param startTime Gameplay start time.
     */
    public function new(startTime:Float = 0):Void {
        this.startTime = startTime;
        super();
    }

    /**
     * Creation behaviour.
     */
    override function create():Void {
        #if debug
        _loadTime = Lib.getTimer();
        #end

        FlxG.autoPause = false;
        Transition.skip();

        var circle:SpinningCircle = new SpinningCircle();
        add(circle);

        // exclude the graphic since we only want to keep gameplay assets
        Assets.cache.excludeGraphic(circle.graphic);

        var tasks:Array<Void->Void> = getTasks();

        new Future(() -> {
            for (task in tasks)
                task();
            return 0;
        }, true)
        .onComplete((_) -> circle.fade(10, false, onComplete))
        .onError(onError);
    }

    /**
     * Update behaviour.
     */
    override function update(elapsed:Float):Void {
        if (FlxG.sound.music?.volume > 0.05) 
            FlxG.sound.music.volume -= elapsed * 2;

        super.update(elapsed);
    }

    /**
     * Returns the tasks to be executed by the `Future` object.
     */
    function getTasks():Array<Void->Void> {
        var tasks:Array<Void->Void> = [];
        var song:Chart = PlayState.song;

        var queuedCharacters:Array<String> = [];
        var queuedNoteSkins:Array<String> = [];
        var noteSkins:Array<String> = [];

        // prepare characters
        for (char in [song.gameplayInfo.player, song.gameplayInfo.opponent, song.gameplayInfo.spectator]) {
            if (char == null || queuedCharacters.contains(char))
                continue;

            queuedCharacters.push(char);

            var config:CharacterData = Paths.yaml("data/characters/" + char);
            if (config == null) continue;

            var isPlayer:Bool = (song.gameplayInfo.opponent == char || song.gameplayInfo.player == char);
            tasks.push(loadCharacter.bind(config, isPlayer));

            if (config.noteSkin != null && isPlayer && !noteSkins.contains(config.noteSkin))
                noteSkins.push(config.noteSkin);
        }

        // prepare noteskins
        for (i in 0...2) {
            var noteSkin:String = noteSkins[i] ?? song.getNoteskin(i);
            if (queuedNoteSkins.contains(noteSkin))
                continue;

            tasks.push(loadNoteskin.bind(noteSkin));
            queuedNoteSkins.push(noteSkin);
        }
        
        // prepare stage
        var stageName:String = song.gameplayInfo.stage;
        var uiStyle:String = "";

        if (stageName?.length > 0) {
            var stage:StageData = Paths.yaml('data/stages/${stageName}');

            if (stage?.uiStyle != null)
                uiStyle = stage.uiStyle;

            if (stage?.sprites != null)
                tasks.push(loadStageElements.bind(stage.sprites));
        }

        tasks.push(loadCommonAssets.bind(uiStyle));
        return tasks;
    }

    /**
     * Method called whenever the `Future` object is done executing it's task.
     */
    function onComplete():Void {
        Assets.clearCache = false;
        BGM.stopMusic();

        FlxG.signals.postStateSwitch.addOnce(() -> {
            // run the garbage collector once the transition completes to avoid lagspikes mid-game, since bitmaps needs to be freed from ram
            Transition.onComplete.add(openfl.system.System.gc);
            FlxG.autoPause = Options.autoPause;
        });
        FlxG.switchState(PlayState.new.bind(startTime));
    }

    /**
     * Method called whenever an error occurs while the `Future` object is executing it's task.
     */
    function onError(error:Any):Void {
        throw error;
    }

    /**
     * Method responsible of loading a character.
     */
    function loadCharacter(character:CharacterData, preloadIcon:Bool):Void {
        Paths.preloadAtlas(character.image);

        if (character.icon != null && preloadIcon)
            Paths.image('icons/${character.icon}');
    }

    /**
     * Method responsible of loading stage elements.
     */
    function loadStageElements(elements:Array<StageSprite>):Void {
        for (element in elements)
            if (element.rectGraphic == null)
                Paths.preloadAtlas(element.image);
    }

    /**
     * Method responsible of loading a noteskin.
     */
    function loadNoteskin(noteSkin:String):Void {
        var noteSheet:String = "game/notes";
        var splashSheet:String = "game/splashes";
        var receptorSheet:String = null; // gets cached with notes by default

        if (noteSkin != "default") {
            var data:NoteSkinConfig = NoteSkin.get(noteSkin);

            if (data.note != null)
                noteSheet = data.note.image;

            if (data.receptor != null)
                receptorSheet = data.receptor.image;

            if (data.splash != null)
                splashSheet = data.splash.image;

            // since it's softcoded, don't parse it again when going to playstate
            NoteSkin.clearData = false;
        }

        Paths.image(noteSheet);

        if (receptorSheet != null)
            Paths.image(receptorSheet);

        if (!Options.noNoteSplash)
            Paths.image(splashSheet);
    }

    /**
     * Method responsible of loading common assets.
     */
    function loadCommonAssets(uiStyle:String):Void {
        Paths.image('game/combo-numbers' + uiStyle);
        Paths.image('game/ratings' + uiStyle);
        Paths.image('game/healthBar');
        Paths.image("ui/alphabet");

        for (i in 1...4)
            Paths.sound('gameplay/missnote${i}');
    }
}
