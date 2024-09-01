package funkin.gameplay;

import flixel.*;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;

import funkin.gameplay.*;
import funkin.gameplay.notes.*;
import funkin.gameplay.components.*;
import funkin.gameplay.components.ComboPopup;
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

    public var strumLines:FlxTypedGroup<StrumLine>;
    public var noteSpawner:NoteSpawner;

    public var opponentStrumline:StrumLine;
    public var playerStrumline:StrumLine;

    public var stats:GameStats = new GameStats();
    public var hud:GameplayUI;

    public var comboPopup:ComboPopup;
    public var countdown:Countdown;

    public var score(get, set):Float;
    public var misses(get, set):Int;
    public var accuracyNotes(get, set):Int;
    public var botplay(get, set):Bool;

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

    override public function create():Void {
        var createTime:Float = LoadingScreen.getLoadTime();

        Tools.stopMusic();
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

        var oppNoteSkin:String = song.getNoteskin(OPPONENT);
        var plrNoteSkin:String = song.getNoteskin(PLAYER);

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

            if (opponent.noteSkin != null)
                oppNoteSkin = opponent.noteSkin;
        }

        if (song.gameplayInfo.player != null) {
            player = new Character(400, 0, song.gameplayInfo.player);
            add(player);

            if (player.noteSkin != null)
                plrNoteSkin = player.noteSkin;
        }

        stage?.postBuild();

        comboPopup = new ComboPopup(stats.ratings.length, stage?.uiStyle);
        comboPopup.camera = camHUD;
        add(comboPopup);

        hud = new GameplayUI();
        hud.camera = camHUD;
        add(hud);

        strumLines = new FlxTypedGroup<StrumLine>();
        strumLines.camera = camHUD;

        opponentStrumline = new StrumLine(FlxG.width * 0.25, 50, true, OPPONENT, oppNoteSkin);
        opponentStrumline.scrollSpeed = song.gameplayInfo.scrollSpeed;
        strumLines.add(opponentStrumline);

        playerStrumline = new StrumLine(FlxG.width * 0.75, 50, false, PLAYER, plrNoteSkin);
        playerStrumline.scrollSpeed = song.gameplayInfo.scrollSpeed;
        strumLines.add(playerStrumline);

        if (Options.downscroll)
            playerStrumline.y = opponentStrumline.y = FlxG.height * 0.8;

        if (Options.centeredStrumline) {
            playerStrumline.x = FlxG.width / 2;
            opponentStrumline.visible = false;
        }

        if (opponent != null)
            opponentStrumline.characters.push(opponent);

        if (player != null)
            playerStrumline.characters.push(player);

        noteSpawner = new NoteSpawner(strumLines.members, startTime);
        add(noteSpawner);

        // important to add strumlines *after* the note spawner!
        add(strumLines);

        // look for notetype scripts
        var types:Array<String> = [];

        for (note in song.notes) {
            var type:String = note.type;
            if (type != null && !types.contains(type)) {
                if (!Note.defaultTypes.contains(type)) {
                    var path:String = Assets.script("scripts/notetypes/" + type);
                    if (FileTools.exists(path)) scripts.load(path);
                }

                types.push(type);
            }
        }

        #if DISCORD_RPC
        DiscordPresence.presence.details = 'Playing ${song.meta.name} (${gameMode.toString()})';
        DiscordPresence.presence.state = "";
        #end

        conductor.enableInterpolation = true;

        events = new SongEventExecutor();
        add(events);

        if (startTime <= 0)
            startCountdown();
        else
            setTime(startTime);

        if (gameMode != DEBUG)
            trace('${song.meta.name} - Took ${((Lib.getTimer() - createTime) / 1000)}s to load');

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

        countdown.onFinish = startSong.bind(0);
        conductor.beat = -event.totalTicks - 1;
        countdown.start();
    }

    override public function update(elapsed:Float):Void {
        scripts.call("onUpdate", elapsed);
        super.update(elapsed);

        if (stats.health <= 0 && subState == null)
            gameOver();

        camGame.zoom = Tools.lerp(camGame.zoom, cameraZoom, bumpSpeed);
        camHUD.zoom = Tools.lerp(camHUD.zoom, hudZoom, bumpSpeed);
        updateCamLerp();

        if (subState == null && controls.justPressed("accept"))
            pause();

        if (gameMode != STORY) {
            if (Options.editorAccess && controls.justPressed("debug")) {
                if (gameMode != DEBUG) {
                    gameMode = DEBUG;
                    validScore = false;
                }

                openChartEditor();
            }

            if (controls.justPressed("autoplay"))
                botplay = !botplay;
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
            hud.iconBops();
    }

    public function pause():Void {
        if (scripts.quickEvent("onPause").cancelled)
            return;

        #if DISCORD_RPC
        DiscordPresence.presence.state = "Paused";
        #end

        openSubState(new PauseScreen());
    }

    public function gameOver():Void {
        var character:String = player?.gameOverChar ?? player?.character ?? "boyfriend-dead";
        var position:FlxPoint = player?.getScreenCoords() ?? FlxPoint.get(camPos.x, camPos.y);

        var event:GameOverEvent = scripts.dispatchEvent("onGameOver", Events.get(GameOverEvent).setup(character, position, camGame.zoom));
        if (event.cancelled) return;

        if (event.stopMusic)
            music.stop();

        #if DISCORD_RPC
        if (event.changePresence)
            DiscordPresence.presence.state = "Game Over";
        #end

        persistentDraw = event.persistentDraw;
        camSubState.zoom = event.zoom;

        openSubState(new GameOverScreen(event.position.x, event.position.y, event.character));
        event.position.put();
    }

    inline public function openChartEditor():Void {
        Assets.clearAssets = Options.reloadAssets;
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
        DiscordPresence.presence.state = "";
        #end

        conductor.music = music.instrumental;
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

    public function onNoteHit(event:NoteHitEvent):Void {
        scripts.dispatchEvent("onNoteHit", event);
        if (event.cancelled) return;

        score += event.score;
        stats.health += event.health;

        if (event.increaseCombo) stats.combo++;
        if (event.increaseHits) event.rating.hits++;
        if (event.breakCombo) stats.combo = 0;

        if (event.increaseAccuracy) {
            stats.accuracyMod += event.accuracy;
            accuracyNotes++;
        }

        if (event.displayRating) comboPopup.displayRating(event.rating);
        if (event.displayCombo) comboPopup.displayCombo(stats.combo);

        if (event.displaySplash)
            event.note.parentStrumline.popSplash(event.note);

        if (event.unmutePlayer)
            music.playerVolume = event.playerVolume;
    }

    public function onNoteHold(event:NoteHoldEvent):Void {
        scripts.dispatchEvent("onNoteHold", event);
        if (event.cancelled) return;

        if (event.unmutePlayer)
            music.playerVolume = event.playerVolume;
    }

    public function onNoteHoldInvalidation(event:NoteHoldInvalidationEvent):Void {
        scripts.dispatchEvent("onNoteHoldInvalidation", event);
        if (event.cancelled) return;

        score -= event.scoreLoss * Math.floor(event.fraction);
        stats.health -= event.healthLoss * Math.floor(event.fraction);

        if (event.decreaseAccuracy)
            accuracyNotes += Math.floor(event.fraction);

        if (event.breakCombo)
            stats.combo = 0;

        if (event.characterMiss)
            characterMisses(event.note, -1, event.spectatorSad);
        
        if (event.playSound)
            playMissSound(event.soundVolume, event.soundVolDiff);

        music.playerVolume = event.playerVolume;
    }

    public function onMiss(event:NoteMissEvent):Void {
        scripts.dispatchEvent("onMiss", event);
        if (event.cancelled) return;

        score -= event.scoreLoss;
        stats.health -= event.healthLoss;

        if (event.breakCombo) stats.combo = 0;
        if (event.increaseMisses) misses++;
        if (event.decreaseAccuracy) accuracyNotes++;

        if (event.playSound) playMissSound(event.soundVolume, event.soundVolDiff);
        if (event.characterMiss) characterMisses(event.note, -1, event.spectatorSad);

        music.playerVolume = event.playerVolume;
    }

    public function onGhostPress(event:GhostPressEvent):Void {
        scripts.dispatchEvent("onGhostPress", event);
        if (event.cancelled || event.ghostTapping) return;

        score -= event.scoreLoss;
        stats.health -= event.healthLoss;

        if (event.breakCombo) stats.combo = 0;

        if (event.characterMiss) characterMisses(null, event.direction, event.spectatorSad);
        if (event.playSound) playMissSound(event.soundVolume, event.soundVolDiff);

        music.playerVolume = event.playerVolume;
    }

    public function characterMisses(note:Note, direction:Int = -1, spectatorSad:Bool = true):Void {
        if (direction != -1 || !note?.noMissAnim)
            for (player in playerStrumline.characters)
                player.playMissAnim(note?.direction ?? direction);

        if (spectatorSad && spectator?.animation.exists("sad"))
            spectator.playSpecialAnim("sad", Conductor.self.crochet);
    }

    public inline function playMissSound(volume:Float = 0.1, difference:Float = 0.1):Void {
        FlxG.sound.play(Assets.sound('gameplay/missnote${FlxG.random.int(1, 3)}'), FlxG.random.float(volume, volume + difference));
    }

    // Overrides
    override function onSubStateOpen(subState:FlxSubState):Void {
        Tools.pauseEveryTween();
        Tools.pauseEveryTimer();
        music?.pause();

        if (subState is TransitionSubState && (cast subState:TransitionSubState).type == OUT)
            Transition.noPersistentUpdate = true;

        if (camSubState != null)
            subState.camera = camSubState;

        if (playerStrumline != null)
            playerStrumline.inactiveInputs = true;

        super.onSubStateOpen(subState);
    }

    override function onSubStateClose(subState:FlxSubState):Void {
        Tools.resumeEveryTween();
        Tools.resumeEveryTimer();
        music?.resume();

        #if DISCORD_RPC
        DiscordPresence.presence.state = "";
        #end

        playerStrumline.inactiveInputs = false;
        super.onSubStateClose(subState);
    }

    override function onFocusLost():Void {
        super.onFocusLost();

        if (subState == null) {
            if (!FlxG.autoPause)
                pause();
            else {
                #if DISCORD_RPC
                DiscordPresence.presence.state = "Paused";
                #end
            }
        }
    }

    override function onFocus():Void {
        super.onFocus();

        if (subState == null) {
            #if DISCORD_RPC
            DiscordPresence.presence.state = "";
            #end
        }
    }

    override function destroy():Void {
        self = null;

        #if DISCORD_RPC
        DiscordPresence.presence.state = "";
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

    function set_score(v:Float):Float {
        stats.score = v;
        hud.updateScore();
        return v;
    }

    function set_misses(v:Int):Int {
        stats.misses = v;
        hud.updateMisses();
        return v;
    }

    function set_accuracyNotes(v:Int):Int {
        stats.accuracyNotes = v;
        hud.updateAccuracy();
        return v;
    }

    function set_botplay(v:Bool):Bool {
        if (v)
            validScore = false;

        playerStrumline.cpu = v;
        hud.updateAccuracy();
        return v;
    }

    function get_score():Float {
        return stats.score;
    }

    function get_misses():Int {
        return stats.misses;
    }

    function get_accuracyNotes():Int {
        return stats.accuracyNotes;
    }

    function get_botplay():Bool {
        return playerStrumline?.cpu;
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
