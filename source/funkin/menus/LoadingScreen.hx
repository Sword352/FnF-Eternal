package funkin.menus;

import flixel.FlxState;
import openfl.Lib;

import funkin.data.ChartFormat.Chart;
import funkin.data.NoteSkin;

#if sys
// import sys.thread.FixedThreadPool;
import sys.thread.Thread;
import sys.thread.Mutex;
#end

import funkin.data.StageData;
import funkin.data.CharacterData;

// you don't need to access this state in order to access PlayState. This just helps making the slow loading process faster.
// TODO: thread-safe loading code, and maybe make this a bit more faster
class LoadingScreen extends FlxState {
    public static var loadTime:Float = -1;

    var song(get, never):Chart;
    inline function get_song():Chart
        return PlayState.song;

    var rotationSpeed:Float = FlxG.random.float(45, 180);
    var startTime:Float = 0;

    var circle:FlxSprite;

    #if sys
    // var threads:FixedThreadPool;
    var mutex:Mutex;
    #end

    var tasks:Array<Void->Void>;
    var characters:Map<String, CharacterData> = [];
    var stage:StageData = null;

    var switching:Bool = false;
    var ranTask:Int = 0;

    var autoPause:Bool;

    public static inline function getLoadTime():Float {
        var time:Float = loadTime;
        if (time == -1) return Lib.getTimer();

        loadTime = -1;
        return time;
    }

    public function new(startTime:Float = 0):Void {
        this.startTime = startTime;
        super();
    }

    override function create():Void {
        loadTime = Lib.getTimer();
        // Tools.stopMusic();

        autoPause = FlxG.autoPause;
        FlxG.autoPause = false;

        addVisuals();
        prepareTasks();
        runTasks();
    }

    function addVisuals():Void {
        var graphic = Assets.createGraphic("images/menus/loading_circle");
        graphic.persist = false;

        circle = new FlxSprite(0, 0, graphic);
        circle.setPosition(FlxG.width - circle.width - 25, FlxG.height - circle.height - 25);
        circle.alpha = 0;
        add(circle);
    }

    function runTasks():Void {
        #if sys
        // threads = new FixedThreadPool(tasks.length);
        mutex = new Mutex();

        for (task in tasks) {
            Thread.create(() -> {
                // Sys.sleep(0.01);
                
                try
                    task()
                catch (e)
                    trace("Skipping a task due to error: " + e.message);

                mutex.acquire();
                ranTask++;
                mutex.release();
            });
        }
        #else
        // i kinda dont have the choice
        for (task in tasks) {
            task();
            ranTask++;
        }
        #end
    }

    function prepareTasks():Void {
        tasks = [loadCommon, loadNoteAssets];

        for (char in [song.gameplayInfo.player, song.gameplayInfo.opponent, song.gameplayInfo.spectator]) {
            if (char == null || characters.exists(char)) continue;

            var file:String = Assets.yaml("data/characters/" + char);
            if (!FileTools.exists(file)) continue;

            var config:CharacterData = Tools.parseYAML(FileTools.getContent(file));
            if (config == null) continue;

            characters.set(char, config);

            tasks.push(() -> {
                // preload frame texture
                Assets.image(config.image, config.library);

                // also preload health icon (if its not the spectator)
                if (config.icon != null && (song.gameplayInfo.opponent == char || song.gameplayInfo.player == char))
                    Assets.image('icons/${config.icon}');
            });
        }
        
        var stageName:String = song.gameplayInfo.stage;
        if (stageName?.length > 0) {
            var stagePath:String = Assets.yaml('data/stages/${stageName}');

            if (FileTools.exists(stagePath)) {
                stage = Tools.parseYAML(FileTools.getContent(stagePath));
                if (stage.sprites != null) tasks.push(loadStage);
            }
        }

        /*
        tasks.push(() -> Assets.image("notes/noteSplashes"));
        tasks.push(() -> Assets.image("notes/receptors"));
        tasks.push(() -> Assets.image("notes/notes"));
        */

        /*
        tasks.push(() -> Assets.songMusic(song.meta.rawName, song.meta.instFile));
        
        if (song.meta.voices != null)
            for (file in song.meta.voices)
                tasks.push(() -> Assets.songMusic(song.meta.rawName, file));
        */

        tasks.push(() -> {
            Assets.songMusic(song.meta.folder, song.gameplayInfo.instrumental);

            if (song.gameplayInfo.voices != null)
                for (file in song.gameplayInfo.voices)
                    Assets.songMusic(song.meta.folder, file);
        });
    }

    override function update(elapsed:Float):Void {
        if (FlxG.sound.music?.volume > 0.05) 
            FlxG.sound.music.volume = Math.max(FlxG.sound.music.volume - elapsed * 2, 0.05);

        if (circle.alpha < 1) circle.alpha += elapsed * 5;
        circle.angle += rotationSpeed * elapsed;

        if (switching || ranTask < tasks.length) return;

        Assets.clearAssets = false;
        // #if sys threads.shutdown(); #end

        FlxG.switchState(PlayState.new.bind(startTime));
        FlxG.signals.postStateSwitch.addOnce(() -> FlxG.autoPause = autoPause);
        switching = true;
    }

    function loadStage():Void {
        for (sprite in stage.sprites)
            if (sprite.type != "rect")
                Assets.image(sprite.image, sprite.library);
    }

    function loadNoteAssets():Void {
        var noteSkins:Array<String> = ["default", "default"];
        var preloaded:Array<String> = [];

        for (index => string in [song.gameplayInfo.opponent, song.gameplayInfo.player]) {
            var data = characters[string];
            if (string != null && data?.noteSkin != null) noteSkins[index] = data.noteSkin;
            else if (song.gameplayInfo.noteSkins != null && song.gameplayInfo.noteSkins[index] != null)
                noteSkins[index] = song.gameplayInfo.noteSkins[index];
        }

        for (skin in noteSkins) {
            if (preloaded.contains(skin)) continue;

            // path, library
            var note:Array<String> = ["notes/notes", null];
            var strum:Array<String> = ["notes/receptors", null];
            var splash:Array<String> = ["notes/noteSplashes", null];
            var covers:Array<String> = ["notes/holds", null];

            if (skin != "default") {
                var data:NoteSkinConfig = NoteSkin.get(skin);
                var refs:Map<Array<String>, GenericSkin> = [
                    note => data.note,
                    strum => data.receptor,
                    splash => data.splash,
                    covers => data.holdCover
                ];

                for (k => v in refs) {
                    if (v == null) continue;
                    k[0] = v.image;
                    k[1] = v.library;
                }

                // since it's softcoded, don't parse it when going to playstate
                NoteSkin.clearData = false;
            }

            var toPreload:Array<Array<String>> = [note, strum];

            if (!Options.noNoteSplash) {
                toPreload.push(splash);
                if (!Options.holdBehindStrums)
                    toPreload.push(covers);
            }

            for (data in toPreload)
                Assets.image(data[0], data[1]);

            preloaded.push(skin);
        }
    }

    function loadCommon():Void {
        var uiStyle:String = stage?.uiStyle ?? "";
        
        Assets.image('ui/gameplay/combo-numbers' + uiStyle);
        Assets.image('ui/gameplay/ratings' + uiStyle);

        Assets.image("ui/alphabet");
        Assets.music("breakfast");

        for (i in 1...4)
            Assets.sound('gameplay/missnote${i}');
    }

    override function destroy():Void {
        #if sys
        // threads = null;
        mutex = null;
        #end

        characters = null;
        stage = null;
        tasks = null;

        super.destroy();
    }
}