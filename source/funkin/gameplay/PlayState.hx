package funkin.gameplay;

import flixel.*;
import flixel.math.FlxPoint;

import funkin.gameplay.*;
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

/**
 * This object dispatches the following event(s):
 * - `GameEvents.COUNTDOWN_START`
 * - `GameEvents.GAME_OVER`
 * - `GameEvents.SONG_START`
 * - `GameEvents.SONG_END`
 */
class PlayState extends MusicBeatState {
    /**
     * Current `PlayState` instance.
     */
    public static var self(get, never):PlayState;
    static inline function get_self():PlayState
        return cast FlxG.state;
    
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
    public var bumpSpeed:Float = 4;

    public var cameraFocus(default, set):Character;
    public var camPos:FlxPoint = FlxPoint.get();
    public var camDisplace:FlxObject;

    public var validScore:Bool = (gameMode != DEBUG);
    public var startTime:Float;

    /**
     * Flag used to prevent the game over event from being repeatedly dispatched.
     */
    @:allow(funkin.gameplay.components.GameStats)
    var _checkGameOver:Bool = false;

    public function new(startTime:Float = 0):Void {
        this.startTime = startTime;
        super();
    }

    public inline static function load(song:String, diff:String = "normal"):Void {
        PlayState.song = ChartLoader.loadChart(song, diff);
        currentDifficulty = diff;
    }

    override function create():Void {
        ScriptManager.addVariable("game", this);
        super.create();

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

        music = new SongPlayback(song);
        music.onComplete.add(endSong);
        add(music);

        song.prepareConductor(conductor);

        if (song.gameplayInfo.stage?.length > 0) {
            stage = Stage.create(song.gameplayInfo.stage);
            add(stage);
        }

        if (song.gameplayInfo.spectator != null) {
            spectator = Character.create(400, 0, song.gameplayInfo.spectator);
            add(spectator);
        }

        if (song.gameplayInfo.opponent != null) {
            opponent = Character.create(200, 0, song.gameplayInfo.opponent);
            add(opponent);
        }

        if (song.gameplayInfo.player != null) {
            player = Character.create(400, 0, song.gameplayInfo.player);
            add(player);
        }

        stage?.postBuild();

        playField = new PlayField();
        playField.camera = camHUD;
        add(playField);

        events = new SongEventExecutor();
        add(events);

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
    }

    function startCountdown():Void {
        var event:CountdownStartEvent = dispatchEvent(GameEvents.COUNTDOWN_START, new CountdownStartEvent(stage?.uiStyle ?? ""));
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
        super.update(elapsed);

        if (_checkGameOver)
            _performGameOverCheck();

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
    }

    override function beatHit(beat:Int):Void {
        playField.iconBops();
        gameDance(beat);

        super.beatHit(beat);
    }

    override function measureHit(measure:Int):Void {
        camGame.zoom += gameBeatBump;
        camHUD.zoom += hudBeatBump;
        super.measureHit(measure);
    }

    public inline function pause():Void {
        openSubState(new PauseScreen());
    }

    public function gameOver():Void {
        var event:ScriptEvent = dispatchEvent(GameEvents.GAME_OVER, new ScriptEvent());
        if (event.cancelled) return;

        var character:String = player?.gameOverChar ?? player?.character ?? "boyfriend-gameover";
        var position:FlxPoint = player?.getScreenCoords() ?? FlxPoint.get(camPos.x, camPos.y);

        music.stop();

        #if DISCORD_RPC
        DiscordRPC.self.state = "Game Over";
        #end

        camSubState.zoom = camGame.zoom;
        persistentDraw = false;

        openSubState(new GameOverScreen(position.x, position.y, character));
        position.put();
    }

    function _performGameOverCheck():Void {
        if (stats.health <= 0)
            gameOver();
        _checkGameOver = false;
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
        var event:ScriptEvent = dispatchEvent(GameEvents.SONG_START, new ScriptEvent());
        if (event.cancelled) return;

        #if DISCORD_RPC
        DiscordRPC.self.timestamp.start = 1;
        #end

        conductor.interpolate = false;
        music.play(time);
    }

    public function endSong():Void {
        var event:ScriptEvent = dispatchEvent(GameEvents.SONG_END, new ScriptEvent());
        if (event.cancelled) return;

        conductor.music = null;
        lossCounter = 0;

        if (validScore) {
            Transition.onComplete.add(saveScore);
        }

        switch (gameMode) {
            case STORY:
                if (songPlaylist.length > 0) {
                    Transition.onComplete.add(() -> load(songPlaylist.shift(), currentDifficulty));
                    FlxG.switchState(LoadingScreen.new.bind(0));
                }
                else {
                    if (weekToUnlock != null)
                        SongProgress.unlock(weekToUnlock, true);
                        
                    weekToUnlock = null;
                    FlxG.switchState(StoryMenu.new);
                }
            case DEBUG:
                openChartEditor();
            default:
                FlxG.switchState(FreeplayMenu.new);
        }
    }

    function saveScore():Void {
        var song:String = '${song.meta.folder}-${currentDifficulty}';
        if (gameMode == STORY) song += "_story";
        Scoring.self.registerGame(song, stats);
    }

    public function gameDance(beat:Int):Void {
        player?.dance(beat);
        spectator?.dance(beat);
        opponent?.dance(beat);
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

        subState.camera = camSubState;
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
        #if DISCORD_RPC
        DiscordRPC.self.timestamp.reset();
        DiscordRPC.self.state = null;
        #end

        stats = FlxDestroyUtil.destroy(stats);
        camPos = FlxDestroyUtil.put(camPos);
        cameraFocus = null;

        super.destroy();

        // only remove the variable once Events.DESTROY has been dispatched
        ScriptManager.removeVariable("game");
    }

    public inline function setTime(time:Float):Void {
        conductor.time = time;
        startSong(time);
    }

    function set_cameraFocus(v:Character):Character {
        if (v != null) {
            var cameraPosition:FlxPoint = v.getCameraDisplace();
            camPos.copyFrom(cameraPosition);
            cameraPosition.put();
        }

        return cameraFocus = v;
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
