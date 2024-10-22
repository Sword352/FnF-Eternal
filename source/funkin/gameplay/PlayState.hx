package funkin.gameplay;

import flixel.*;
import flixel.math.FlxPoint;

import funkin.gameplay.*;
import funkin.gameplay.notes.*;
import funkin.gameplay.components.*;
import funkin.gameplay.events.SongEventExecutor;
import funkin.objects.Camera;

import funkin.menus.StoryMenu;
import funkin.menus.FreeplayMenu;
import funkin.menus.LoadingScreen;
import funkin.editors.chart.ChartEditor;

import funkin.data.ChartLoader;
import funkin.data.ChartFormat.Chart;
import funkin.save.SongProgress;

import openfl.Lib;

class PlayState extends MusicBeatState {
    public static var self:PlayState;
    public static var song:Chart;

    public static var songPlaylist:Array<String>;
    public static var currentDifficulty:String;
    public static var weekToUnlock:String;

    public static var gameMode:GameMode = FREEPLAY;
    public static var lossCounter:Int = 0;

    public var camGame:FlxCamera;
    public var camHUD:FlxCamera;
    public var camSubState:FlxCamera;

    public var events:SongEventExecutor;
    public var music:SongPlayback;

    public var spectator:Character;
    public var opponent:Character;
    public var player:Character;
    public var stage:Stage;

    public var stats:GameStats = new GameStats();
    public var playField:PlayField;
    public var countdown:Countdown;

    public var cameraSpeed:Float = 3;
    public var cameraZoom:Float = 1;
    public var hudZoom:Float = 1;

    public var gameBeatBump:Float = 0.03;
    public var hudBeatBump:Float = 0.025;
    public var camBumpInterval:Float = 4;
    public var bumpSpeed:Float = 4;

    public var cameraFocus(default, set):Character;
    public var camPos:FlxPoint = FlxPoint.get();
    public var camDisplace:FlxObject;

    public var validScore:Bool = (gameMode != DEBUG);
    public var startTime:Float;

    public function new(startTime:Float = 0):Void {
        this.startTime = startTime;
        super();
    }

    public inline static function load(song:String, diff:String = "normal"):Void {
        PlayState.song = ChartLoader.loadChart(song, diff);
        currentDifficulty = diff;
    }

    override function create():Void {
        self = this;

        scripts.loadScripts('songs/${song.meta.folder}/scripts');
        scripts.loadScripts('scripts/gameplay', true);

        camGame = new Camera();
        camGame.bgColor.alpha = 0;
        FlxG.cameras.reset(camGame);

        camHUD = new FlxCamera();
        camHUD.bgColor.alpha = 0;
        FlxG.cameras.add(camHUD, false);

        camSubState = new Camera();
        camSubState.bgColor.alpha = 0;
        FlxG.cameras.add(camSubState, false);

        camDisplace = new FlxObject(FlxG.width * 0.5, FlxG.height * 0.5, 1, 1);
        camDisplace.visible = camDisplace.active = false;
        camGame.follow(camDisplace, LOCKON);
        add(camDisplace);

        super.create();
        scripts.call("onCreate");

        music = new SongPlayback(song);
        music.onComplete.add(endSong);
        add(music);

        song.prepareConductor(conductor);
        camBumpInterval = conductor.beatsPerMeasure;

        if (song.gameplayInfo.stage?.length > 0) {
            stage = new Stage(song.gameplayInfo.stage);
            add(stage);
        }

        if (song.gameplayInfo.spectator != null) {
            spectator = new Character(400, 0, song.gameplayInfo.spectator);
            add(spectator);

            // make the spectator behave as the opponent
            if (song.gameplayInfo.opponent != null && song.gameplayInfo.opponent == song.gameplayInfo.spectator)
                opponent = spectator;
        }

        if (song.gameplayInfo.opponent != null && song.gameplayInfo.spectator != song.gameplayInfo.opponent) {
            opponent = new Character(200, 0, song.gameplayInfo.opponent);
            add(opponent);
        }

        if (song.gameplayInfo.player != null) {
            player = new Character(400, 0, song.gameplayInfo.player);
            add(player);
        }

        stage?.postBuild();

        playField = new PlayField();
        playField.camera = camHUD;
        add(playField);

        events = new SongEventExecutor();
        add(events);

        // look for notetype scripts
        var types:Array<String> = [];

        for (note in song.notes) {
            var type:String = note.type;
            if (type != null && !types.contains(type)) {
                if (!Note.defaultTypes.contains(type))
                    scripts.load("scripts/notetypes/" + type);

                types.push(type);
            }
        }

        #if DISCORD_RPC
        DiscordRPC.self.details = song.meta.name;
        updatePresenceState();
        #end

        conductor.music = music.instrumental;
        conductor.interpolate = true;

        if (startTime <= 0)
            startCountdown();
        else
            setTime(startTime);

        #if debug
        LoadingScreen.reportTime();
        #end

        scripts.call("onCreatePost");
    }

    function startCountdown():Void {
        var event:CountdownEvent = scripts.dispatchEvent("onCountdownStart", Events.get(CountdownEvent).setup(START, -1, "game/countdown" + (stage?.uiStyle ?? "")));
        if (event.cancelled) return;

        countdown = new Countdown();
        countdown.totalTicks = event.totalTicks;
        countdown.asset = event.graphicAsset;
        countdown.camera = camHUD;
        add(countdown);

        countdown.onFinish.add(startSong.bind(0));
        conductor.beat = -event.totalTicks - 1;
        countdown.start();
    }

    override function update(elapsed:Float):Void {
        scripts.call("onUpdate", elapsed);
        super.update(elapsed);

        if (stats.health <= 0 && subState == null)
            gameOver();

        camGame.zoom = Tools.lerp(camGame.zoom, cameraZoom, bumpSpeed);
        camHUD.zoom = Tools.lerp(camHUD.zoom, hudZoom, bumpSpeed);
        updateCamLerp();

        if (subState == null && controls.justPressed("accept"))
            pause();

        #if DISCORD_RPC
        if (music.playing)
            updatePresenceTimestamp();
        #end

        if (gameMode != STORY) {
            if (Options.editorAccess && controls.justPressed("debug")) {
                gameMode = DEBUG;
                validScore = false;
                openChartEditor();
            }

            if (controls.justPressed("autoplay"))
                playField.botplay = !playField.botplay;
        }
        
        scripts.call("onUpdatePost", elapsed);
    }

    override function beatHit(beat:Int):Void {
        var event:BeatHitEvent = Events.get(BeatHitEvent).setup(conductor.step, beat, conductor.measure, beat % camBumpInterval == 0);
        scripts.dispatchEvent("onBeatHit", event);
        if (event.cancelled) return;

        if (event.cameraBump) {
            camGame.zoom += gameBeatBump;
            camHUD.zoom += hudBeatBump;
        }

        if (event.allowDance)
            gameDance(beat);

        if (event.iconBops)
            playField.iconBops();
    }

    public function pause():Void {
        if (scripts.quickEvent("onPause").cancelled)
            return;

        openSubState(new PauseScreen());
    }

    public function gameOver():Void {
        var character:String = player?.gameOverChar ?? player?.character ?? "boyfriend-gameover";
        var position:FlxPoint = player?.getScreenCoords() ?? FlxPoint.get(camPos.x, camPos.y);

        var event:GameOverEvent = scripts.dispatchEvent("onGameOver", Events.get(GameOverEvent).setup(character, position, camGame.zoom));
        if (event.cancelled) return;

        if (event.stopMusic)
            music.stop();

        #if DISCORD_RPC
        if (event.changePresence)
            DiscordRPC.self.state = "Game Over";
        #end

        persistentDraw = event.persistentDraw;
        camSubState.zoom = event.zoom;

        openSubState(new GameOverScreen(event.position.x, event.position.y, event.character));
        event.position.put();
    }

    inline public function openChartEditor():Void {
        Assets.clearCache = Options.reloadAssets;
        FlxG.switchState(ChartEditor.new.bind(song, currentDifficulty, (FlxG.keys.pressed.SHIFT) ? Math.max(conductor.time, 0) : 0));
    }

    public inline function snapCamera():Void {
        camDisplace.setPosition(camPos.x, camPos.y);
    }

    public inline function updateCamLerp():Void {
        camDisplace.setPosition(Tools.lerp(camDisplace.x, camPos.x, cameraSpeed), Tools.lerp(camDisplace.y, camPos.y, cameraSpeed));
    }

    public function startSong(time:Float = 0):Void {
        if (scripts.quickEvent("onSongStart").cancelled)
            return;

        #if DISCORD_RPC
        DiscordRPC.self.timestamp.start = 1;
        #end

        conductor.interpolate = false;
        music.play(time);
    }

    public function endSong():Void {
        var event:SongEndEvent = scripts.dispatchEvent("onSongEnd", Events.get(SongEndEvent).setup(weekToUnlock, validScore));
        if (event.cancelled) return;

        if (event.resetLossCount)
            lossCounter = 0;

        if (event.saveScore) {
            var song:String = '${song.meta.folder}-${currentDifficulty}';
            if (gameMode == STORY) song += "_story";

            Scoring.self.registerGame(song, stats);
        }

        if (event.leaveState) {
            switch (gameMode) {
                case STORY:
                    if (songPlaylist.length > 0) {
                        Transition.onComplete.add(() -> load(songPlaylist.shift(), currentDifficulty));
                        FlxG.switchState(LoadingScreen.new.bind(0));
                    }
                    else {
                        if (event.unlockedWeek != null)
                            SongProgress.unlock(event.unlockedWeek, true);
                        
                        weekToUnlock = null;
                        FlxG.switchState(StoryMenu.new);
                    }
                case DEBUG:
                    openChartEditor();
                default:
                    FlxG.switchState(FreeplayMenu.new);
            }
        }

        conductor.music = null;
    }

    public function gameDance(beat:Int):Void {
        player?.dance(beat);
        spectator?.dance(beat);

        if (opponent != null && opponent != spectator)
            opponent.dance(beat);

        stage?.dance(beat);
    }

    #if DISCORD_RPC
    function updatePresenceTimestamp():Void {
        DiscordRPC.self.timestamp.end = 1 + Math.floor((music.instrumental.length - music.instrumental.time) * 0.001);
    }

    public function updatePresenceState(paused:Bool = false):Void {
        var state:String = currentDifficulty + " - " + gameMode.toString();

        if (paused)
            state += " (Paused)";

        DiscordRPC.self.state = state;
    }
    #end

    // Overrides
    override function onSubStateOpen(subState:FlxSubState):Void {
        Tools.pauseEveryTween();
        Tools.pauseEveryTimer();
        music?.pause();

        if (subState is TransitionSubState && (cast subState:TransitionSubState).type == OUT)
            Transition.noPersistentUpdate = true;

        if (camSubState != null)
            subState.camera = camSubState;

        if (playField != null)
            playField.inactiveInputs = true;

        super.onSubStateOpen(subState);
    }

    override function onSubStateClose(subState:FlxSubState):Void {
        Tools.resumeEveryTween();
        Tools.resumeEveryTimer();
        music?.resume();

        playField.inactiveInputs = false;
        super.onSubStateClose(subState);
    }

    override function onFocusLost():Void {
        super.onFocusLost();

        // don't update the presence or pause if a substate is already opened
        if (subState == null) {
            if (FlxG.autoPause) {
                #if DISCORD_RPC
                updatePresenceState(true);
                #end
            }
            else
                pause();                
        }
    }

    override function onFocus():Void {
        super.onFocus();

        if (subState == null && FlxG.autoPause) {
            #if DISCORD_RPC
            updatePresenceState();
            #end
        }
    }

    override function destroy():Void {
        self = null;

        #if DISCORD_RPC
        DiscordRPC.self.timestamp.reset();
        DiscordRPC.self.state = null;
        #end

        stats = FlxDestroyUtil.destroy(stats);
        camPos = FlxDestroyUtil.put(camPos);
        cameraFocus = null;

        super.destroy();
    }

    public inline function setTime(time:Float):Void {
        conductor.time = time;
        startSong(time);
    }

    function set_cameraFocus(v:Character):Character {
        if (v != null) {
            var event:CameraFocusEvent = scripts.dispatchEvent("onCameraFocus", Events.get(CameraFocusEvent).setup(v));
            if (event.cancelled) return cameraFocus;

            v = event.character;

            if (v != null) {
                var cameraPosition:FlxPoint = v.getCameraDisplace();
                camPos.copyFrom(cameraPosition);
                cameraPosition.put();
            }
    
            cameraFocus = v;
        }

        return v;
    }
}

/**
 * Defines the current game mode.
 */
enum abstract GameMode(Int) from Int to Int {
    var STORY;
    var FREEPLAY;
    var DEBUG;

    public function toString():String {
        return switch (this:GameMode) {
            case STORY: "Story";
            case FREEPLAY: "Freeplay";
            case DEBUG: "Debug";
        }
    }
}
