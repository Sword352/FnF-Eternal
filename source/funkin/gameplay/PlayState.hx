package funkin.gameplay;

import flixel.*;
import flixel.util.*;
import flixel.tweens.*;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;

import funkin.gameplay.*;
import funkin.gameplay.notes.*;
import funkin.gameplay.stages.*;
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
    public static var current:PlayState;
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

    public var ratingSprites:FlxTypedSpriteGroup<RatingSprite>;
    public var comboSprites:FlxTypedSpriteGroup<ComboSprite>;
    public var countdownSprite:FlxSprite;
    public var hud:GameplayUI;

    public var score:Float = 0;
    public var misses:Int = 0;
    public var combo:Int = 0;
    public var health(default, set):Float = 1;
    public var accuracy(get, never):Float;

    public var accuracyDisplay(get, never):Float;
    public var accuracyMod:Float = 0;
    public var accuracyNotes:Int = 0;

    public var ratings:Array<Rating> = Rating.getDefaultList();
    public var rank(get, never):String;

    public var cameraSpeed:Float = 3;
    public var cameraZoom:Float = 1;
    public var hudZoom:Float = 1;

    public var gameBeatBump:Float = 0.03;
    public var hudBeatBump:Float = 0.05;
    public var camBumpInterval:Float = 4;

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
        current = this;

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

        var noteSkinExists:Bool = song.gameplayInfo.noteSkins != null;
        var plrNoteSkin:String = (noteSkinExists ? song.gameplayInfo.noteSkins[1] : "default") ?? "default";
        var oppNoteSkin:String = (noteSkinExists ? song.gameplayInfo.noteSkins[0] : "default") ?? "default";

        music = new SongPlayback(song.meta.folder);
        music.setupInstrumental(song.gameplayInfo.instrumental);
        music.onSongEnd.add(endSong);
        add(music);

        if (song.gameplayInfo.voices?.length > 0)
            for (voiceFile in song.gameplayInfo.voices)
                music.createVoice(voiceFile);

        conductor.beatsPerMeasure = (song.gameplayInfo.beatsPerMeasure ?? 4);
        camBumpInterval = conductor.beatsPerMeasure;

        conductor.stepsPerBeat = (song.gameplayInfo.stepsPerBeat ?? 4);
        conductor.bpm = song.gameplayInfo.bpm;

        stage = switch (song.gameplayInfo.stage.toLowerCase()) {
            default: new SoftcodedStage(song.gameplayInfo.stage);
        }
        add(stage);

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
            player = new Character(400, 0, song.gameplayInfo.player, PLAYER);
            add(player);

            if (player.noteSkin != null)
                plrNoteSkin = player.noteSkin;
        }

        strumLines = new FlxTypedGroup<StrumLine>();
        strumLines.cameras = [camHUD];

        opponentStrumline = new StrumLine(FlxG.width * 0.25, 50, true, oppNoteSkin);
        opponentStrumline.scrollSpeed = song.gameplayInfo.scrollSpeed;
        strumLines.add(opponentStrumline);

        playerStrumline = new StrumLine(FlxG.width * 0.75, 50, false, plrNoteSkin);
        playerStrumline.scrollSpeed = song.gameplayInfo.scrollSpeed;
        strumLines.add(playerStrumline);

        if (opponent != null) opponentStrumline.characters.push(opponent);
        if (player != null) playerStrumline.characters.push(player);

        noteSpawner = new NoteSpawner(strumLines.members, startTime);
        add(noteSpawner);
        add(strumLines);

        hud = new GameplayUI();
        hud.visible = !Options.hideUi;
        hud.cameras = [camHUD];
        add(hud);

        if (Options.downscroll) {
            playerStrumline.y = opponentStrumline.y = FlxG.height * 0.8;
        }
        if (Options.centeredStrumline) {
            playerStrumline.x = FlxG.width / 2;
            opponentStrumline.visible = false;
        }

        if (gameMode == FREEPLAY)
            strumLines.forEach((strumline) -> strumline.runStartTweens());

        ratingSprites = new FlxTypedSpriteGroup<RatingSprite>();
        comboSprites = new FlxTypedSpriteGroup<ComboSprite>();

        if (Options.uiJudgements) {
            var index:Int = members.indexOf(strumLines);
            ratingSprites.cameras = comboSprites.cameras = [camHUD];
            insert(index, ratingSprites);
            insert(index, comboSprites);
        } else {
            add(comboSprites);
            add(ratingSprites);
        }

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

        conductor.enableInterpolation = true;

        // cache some extra stuff that cannot be loaded in the loading screen
        // since they can be modified
        cacheExtra();

        #if DISCORD_RPC
        DiscordPresence.presence.details = 'Playing ${song.meta.name} (${Tools.capitalize(gameMode)})';
        #end

        // Calling the stage create post function here, in case it modifies some camera position values
        stage.createPost();

        add(events = new SongEventExecutor());

        if (startTime <= 0)
            startCountdown();
        else
            setTime(startTime);

        if (gameMode != DEBUG)
            trace('${song.meta.name} - Took ${((Lib.getTimer() - createTime) / 1000)}s to load');

        scripts.call("onCreatePost");
    }

    override public function update(elapsed:Float):Void {
        scripts.call("onUpdate", [elapsed]);
        super.update(elapsed);

        if (health <= 0 && subState == null)
            gameOver();

        camGame.zoom = Tools.lerp(camGame.zoom, cameraZoom, cameraSpeed);
        camHUD.zoom = Tools.lerp(camHUD.zoom, hudZoom, cameraSpeed);
        updateCamLerp();

        #if DISCORD_RPC
        if (music.playing && conductor.time >= 0 && conductor.time <= music.instrumental.length)
            DiscordPresence.presence.state = FlxStringUtil.formatTime((music.instrumental.length * 0.001) - (conductor.time * 0.001));
        #end

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

            if (controls.justPressed("autoplay")) {
                playerStrumline.cpu = !playerStrumline.cpu;
                hud.updateScoreText();
                validScore = false;
            }
        }

        stage.updatePost(elapsed);
        scripts.call("onUpdatePost", [elapsed]);
    }

    override function stepHit(step:Int):Void {
        super.stepHit(step);
        stage.stepHit(step);
        music.resync();
    }

    override function beatHit(beat:Int):Void {
        var event:BeatHitEvent = Events.get(BeatHitEvent).setup(conductor.step, beat, conductor.measure, beat != 0 && beat % camBumpInterval == 0);
        scripts.dispatchEvent("onBeatHit", event);
        if (event.cancelled) return;

        if (event.cameraBump) {
            camGame.zoom += gameBeatBump;
            camHUD.zoom += hudBeatBump;
        }

        if (event.allowDance)
            gameDance(beat);

        if (event.iconBops)
            hud.beatHit();
    }

    override function measureHit(measure:Int):Void {
        super.measureHit(measure);
        stage.measureHit(measure);
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

    // TODO: make a class for countdowns
    public function startCountdown():Void {
        var event:CountdownEvent = scripts.dispatchEvent("onCountdownStart", Events.get(CountdownEvent).setup(START, -1, "ui/gameplay/countdown" + stage.uiStyle));
        if (event.cancelled) return;

        // avoids division by 0 and invalid frames
        var frames:Int = (event.totalTicks > 1 ? event.totalTicks - 1 : event.totalTicks);
        var graphic = Assets.image(event.graphicAsset);

        countdownSprite = new FlxSprite();
        countdownSprite.loadGraphic(graphic, true, graphic.width, Math.floor(graphic.height / frames));
        countdownSprite.animation.add("countdown", [for (i in 0...frames) i], 0);
        countdownSprite.animation.play("countdown");
        countdownSprite.cameras = [camHUD];
        countdownSprite.alpha = 0;
        add(countdownSprite);

        // store a local ref so that the values won't reset since its pooled
        var totalTicks:Int = event.totalTicks;

        FlxTimer.loop(conductor.crochet / 1000, (elapsedLoops) -> countdownTick(elapsedLoops, totalTicks), totalTicks);
        conductor.beat = -totalTicks - 1;
    }

    inline function countdownTick(tick:Int, totalTicks:Int):Void {
        var suffix:String = (tick == totalTicks ? "Go" : Std.string(totalTicks - tick));
        var done:Bool = tick == totalTicks;

        var sound:String = 'gameplay/intro${suffix}' + stage.uiStyle;
        var event:CountdownEvent = scripts.dispatchEvent("onCountdownTick", Events.get(CountdownEvent).setup(TICK, tick, null, sound, tick - 2));
        if (event.cancelled) return;

        #if DISCORD_RPC
        if (event.changePresence)
            DiscordPresence.presence.state = suffix + (done ? '!' : '...');
        #end

        if (event.allowBeatEvents) {
            gameDance(tick - 1 + (totalTicks % 2));
            stage.onCountdownTick(tick);
        }

        if (event.spriteFrame != -1) countdownSprite.animation.frameIndex = event.spriteFrame;
        if (event.soundAsset != null) FlxG.sound.play(Assets.sound(event.soundAsset));

        countdownSprite.alpha = (event.spriteFrame == -1 ? 0 : 1);
        countdownSprite.screenCenter();

        if (event.allowTween && event.spriteFrame != -1) {
            countdownSprite.y -= 50;
            FlxTween.tween(countdownSprite, {y: countdownSprite.y + 100, alpha: 0}, conductor.crochet * 0.95 / 1000, {ease: FlxEase.smootherStepInOut});
        }

        if (done) {
            FlxTimer.wait(conductor.crochet / 1000, () -> {
                remove(countdownSprite, true);
                countdownSprite = FlxDestroyUtil.destroy(countdownSprite);
                startSong();
            });
        }
    }

    public function startSong(time:Float = 0):Void {
        if (scripts.quickEvent("onSongStart").cancelled)
            return;

        conductor.music = music.instrumental;
        music.play(time);

        stage.onSongStart();
        hud.onSongStart();
    }

    public function endSong():Void {
        var event:SongEndEvent = scripts.dispatchEvent("onSongEnd", Events.get(SongEndEvent).setup(weekToUnlock, validScore));
        if (event.cancelled) return;

        if (event.resetLossCount)
            lossCounter = 0;

        if (event.saveScore) {
            var song:String = '${song.meta.folder}-${currentDifficulty}';
            if (gameMode == STORY) song += "_story";

            HighScore.set(song, {
                score: score,
                misses: misses,
                accuracy: accuracyDisplay,
                rank: rank
            });
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
        stage.onSongEnd();
    }

    inline function gameDance(beat:Int):Void {
        player?.dance(beat);
        spectator?.dance(beat);

        if (opponent != null && opponent != spectator)
            opponent.dance(beat);

        stage.beatHit(beat);
    }

    public function onNoteHit(event:NoteHitEvent):Void {
        scripts.dispatchEvent("onNoteHit", event);
        if (event.cancelled) return;

        score += event.score;
        health += event.health;

        if (event.increaseAccuracy) {
            accuracyMod += event.accuracy;
            accuracyNotes++;
        }

        if (event.increaseCombo) combo++;
        if (event.increaseHits) event.rating.hits++;

        if (event.displayRating) displayRating(event.rating);
        if (event.displayCombo) displayCombo(combo);

        if (event.displaySplash)
            event.note.parentStrumline.popSplash(event.note);

        if (event.unmutePlayer)
            music.playerVolume = event.playerVolume;

        if (event.updateScoreText)
            hud.updateScoreText();
    }

    public function onNoteHold(event:NoteHoldEvent):Void {
        scripts.dispatchEvent("onNoteHold", event);
        if (event.cancelled) return;

        if (event.unmutePlayer)
            music.playerVolume = event.playerVolume;

        health += event.health;
    }

    public function onNoteHoldInvalidation(event:NoteHoldInvalidationEvent):Void {
        scripts.dispatchEvent("onNoteHoldInvalidation", event);
        if (event.cancelled) return;

        score -= event.scoreLoss * Math.floor(event.fraction);
        health -= event.healthLoss * Math.floor(event.fraction);

        if (event.decreaseAccuracy) accuracyNotes += Math.floor(event.fraction);
        if (event.increaseMisses) misses++;
        if (event.breakCombo) combo = 0;

        if (event.characterMiss) characterMisses(event.note, -1, event.spectatorSad);
        if (event.playSound) playMissSound(event.soundVolume, event.soundVolDiff);

        music.playerVolume = event.playerVolume;
        hud.updateScoreText();
    }

    public function onMiss(event:NoteMissEvent):Void {
        scripts.dispatchEvent("onMiss", event);
        if (event.cancelled) return;

        score -= event.scoreLoss;
        health -= event.healthLoss;

        if (event.breakCombo) combo = 0;
        if (event.decreaseAccuracy) accuracyNotes++;
        if (event.increaseMisses) misses++;

        if (event.playSound) playMissSound(event.soundVolume, event.soundVolDiff);
        if (event.characterMiss) characterMisses(event.note, -1, event.spectatorSad);

        music.playerVolume = event.playerVolume;
        hud.updateScoreText();
    }

    public function onGhostPress(event:GhostPressEvent):Void {
        scripts.dispatchEvent("onGhostPress", event);
        if (event.cancelled || event.ghostTapping) return;

        score -= event.scoreLoss;
        health -= event.healthLoss;

        if (event.breakCombo) combo = 0;
        if (event.decreaseAccuracy) accuracyNotes++;
        if (event.increaseMisses) misses++;

        if (event.characterMiss) characterMisses(null, event.direction, event.spectatorSad);
        if (event.playSound) playMissSound(event.soundVolume, event.soundVolDiff);

        music.playerVolume = event.playerVolume;
        hud.updateScoreText();
    }

    public function characterMisses(note:Note, direction:Int = -1, spectatorSad:Bool = true):Void {
        if (direction != -1 || (note != null && !note.noMissAnim)) {
            for (player in playerStrumline.characters) {
                player.sing(note?.direction ?? direction, "miss");
                player.animEndTime = (conductor.crochet / 1000);
                player.currentDance = 0;
            }
        }

        if (spectatorSad && spectator?.animation.exists("sad")) {
            spectator.playAnimation("sad", true);
            spectator.animEndTime = (conductor.crochet / 1000);
            spectator.currentDance = 0;
        }
    }

    public inline function playMissSound(volume:Float = 0.1, difference:Float = 0.1):Void {
        FlxG.sound.play(Assets.sound('gameplay/missnote${FlxG.random.int(1, 3)}'), FlxG.random.float(volume, volume + difference));
    }

    public function displayRating(rating:Rating):Void {
        if (rating.image == null) return;

        if (Options.noComboStack) {
            for (spr in ratingSprites)
                spr.kill();
        }

        var sprite:RatingSprite = ratingSprites.recycle(RatingSprite);
        sprite.loadGraphic(Assets.image('ui/gameplay/${rating.image}' + stage.uiStyle));
        sprite.scale.set(0.7, 0.7);
        sprite.updateHitbox();

        sprite.setPosition(ratingSprites.x, ratingSprites.y);
        if (Options.uiJudgements)
            sprite.screenCenter();

        // is sorting faster? will think of it later
        ratingSprites.remove(sprite, true);
        ratingSprites.insert(ratingSprites.length + 1, sprite);
    }

    public function displayCombo(combo:Int):Void {
        var separatedCombo:String = Std.string(combo);
        if (!Options.simplifyComboNum)
            while (separatedCombo.length < 3)
                separatedCombo = "0" + separatedCombo;

        if (Options.noComboStack) {
            for (spr in comboSprites)
                spr.kill();
        }

        for (i in 0...separatedCombo.length) {
            var sprite:ComboSprite = comboSprites.recycle(ComboSprite);
            sprite.loadGraphic(Assets.image('ui/gameplay/num${separatedCombo.charAt(i)}' + stage.uiStyle));
            sprite.scale.set(0.5, 0.5);
            sprite.updateHitbox();

            if (!Options.uiJudgements)
                sprite.setPosition(ratingSprites.x + 43 * (i + 3), ratingSprites.y + 140);
            else {
                sprite.screenCenter();
                sprite.x += 43 * (i + 1);
                sprite.y += 140;
            }   

            comboSprites.remove(sprite, true);
            comboSprites.insert(comboSprites.length + 1, sprite);
        }
    }

    // Overrides
    override function onSubStateOpen(subState:FlxSubState):Void {
        Tools.pauseEveryTween();
        Tools.pauseEveryTimer();
        music?.pause();

        if (subState is TransitionSubState && cast(subState, TransitionSubState).type == OUT)
            Transition.noPersistentUpdate = true;

        if (camSubState != null)
            subState.cameras = [camSubState];

        if (playerStrumline != null)
            playerStrumline.inactiveInputs = true;

        super.onSubStateOpen(subState);
    }

    override function onSubStateClose(subState:FlxSubState):Void {
        Tools.resumeEveryTween();
        Tools.resumeEveryTimer();
        music?.resume();

        playerStrumline.inactiveInputs = false;
        super.onSubStateClose(subState);
    }

    override function onFocusLost():Void {
        super.onFocusLost();

        if (subState == null) {
            if (!FlxG.autoPause)
                pause();

            #if DISCORD_RPC
            DiscordPresence.presence.state = "Paused";
            #end
        }
    }

    override function destroy():Void {
        current = null;

        #if DISCORD_RPC
        DiscordPresence.presence.state = "";
        #end

        while (ratings.length > 0)
            ratings.pop().destroy();
        ratings = null;

        camPos = FlxDestroyUtil.put(camPos);
        cameraFocus = null;

        super.destroy();
    }

    // Helper functions

    public inline function cacheExtra():Void {
        for (rating in ratings)
            if (rating.image != null)
                Assets.image('ui/gameplay/${rating.image}' + stage.uiStyle);

        for (i in 0...10)
            Assets.image('ui/gameplay/num${i}' + stage.uiStyle);
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
                var cameraPosition:FlxPoint = v.getCamDisplace();
                camPos.copyFrom(cameraPosition);
                cameraPosition.put();
            }
    
            stage.onCamFocusChange(v);
            cameraFocus = v;
        }

        return v;
    }

    inline function set_health(v:Float):Float
        return health = hud.healthDisplay = FlxMath.bound(v, 0, 2);

    inline function get_accuracy():Float {
        if (accuracyNotes == 0) return 0;
        return FlxMath.bound(accuracyMod / accuracyNotes, 0, 1);
    }

    inline function get_accuracyDisplay():Float
        return FlxMath.roundDecimal(accuracy * 100, 2);

    function get_rank():String {
        var rank:String = "";
        if (playerStrumline.cpu) return rank;

        for (rating in ratings) {
            if (rating.rank == null || rating.hits < 1) continue;
            if (misses < rating.missThreshold) rank = rating.rank;
        }

        if (rank.length < 1) {
            if (misses < 1) rank = "FC";
            else if (misses > 0 && misses < 10) rank = "SDCB";
        }

        return rank;
    }
}

enum abstract GameMode(String) from String to String {
    var STORY = "story";
    var FREEPLAY = "freeplay";
    var DEBUG = "debug";
}
