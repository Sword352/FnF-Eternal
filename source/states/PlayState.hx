package states;

import flixel.*;
import flixel.util.*;
import flixel.tweens.*;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;

import gameplay.*;
import gameplay.notes.*;
import gameplay.stages.*;
import music.SongPlayback;

import objects.Camera;
import gameplay.ComboPopup;

import states.menus.StoryMenu;
import states.menus.FreeplayMenu;
import states.editors.chart.ChartEditor;
import states.substates.*;

import globals.ChartLoader;
import globals.ChartFormat.Chart;
import globals.SongProgress;

import openfl.Lib;

class PlayState extends MusicBeatState {
    public static var current:PlayState;
    public static var song:Chart;

    public static var songPlaylist:Array<String>;
    public static var currentDifficulty:String;
    public static var weekToUnlock:String;

    public static var gameMode:GameMode = FREEPLAY;
    public static var lossCounter:Int = 0;

    public var eventManager:EventManager;
    public var music:SongPlayback;

    public var camGame:FlxCamera;
    public var camHUD:FlxCamera;
    public var camSubState:FlxCamera;

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
    public var hud:GameplayUI;

    public var countdownGraphics:Array<String> = [null, 'ui/gameplay/ready', 'ui/gameplay/set', 'ui/gameplay/go'];
    public var countdownSounds:Array<String> = ['gameplay/intro3', 'gameplay/intro2', 'gameplay/intro1', 'gameplay/introGo'];
    public var countdownSprite:FlxSprite;

    public var score:Float = 0;
    public var combo:Int = 0;
    public var ratings:Array<Rating> = Rating.getDefaultList();

    public var misses:Int = 0;
    public var missScoreLoss:Float = 10;

    public var accuracy(get, never):Float;
    public var accuracyDisplay(get, never):Float;
    public var accuracyMod:Float = 0;
    public var accuracyNotes:Int = 0;

    public var health(default, set):Float = 1;
    public var minHealth:Float = 0;
    public var maxHealth:Float = 2;
    public var healthIncrement:Float = 0.023;
    public var healthLoss:Float = 0.0475;

    public var rank(get, never):String;
    public var rankSDCB:String = "SDCB";
    public var rankFC:String = "FC";

    public var cameraSpeed:Float = 3;
    public var cameraZoom:Float = 1;
    public var hudZoom:Float = 1;

    public var camBeatZoom:Float = 0.03;
    public var hudBeatZoom:Float = 0.05;
    public var beatZoomInterval:Float = 4;

    public var camDisplace:FlxObject;
    public var camPos:FlxPoint;

    public var cameraTargets:Array<Character>;
    public var targetCharacter:Character;

    public var validScore:Bool = (gameMode != DEBUG);
    public var startTime:Float;

    // ======= Base game compatibility ==============
    public var boyfriend(get, set):Character;
    public var gf(get, set):Character;
    public var dad(get, set):Character;

    public var camFollow(get, set):FlxObject;
    public var camFollowPos(get, set):FlxPoint;
    public var defaultCamZoom(get, set):Float;

    inline function get_boyfriend():Character return player;
    inline function set_boyfriend(v:Character):Character return player = v;

    inline function get_gf():Character return spectator;
    inline function set_gf(v:Character):Character return spectator = v;

    inline function get_dad():Character return opponent;
    inline function set_dad(v:Character):Character return opponent = v;

    inline function get_defaultCamZoom():Float return cameraZoom;
    inline function set_defaultCamZoom(v:Float):Float return cameraZoom = v;

    inline function get_camFollow():FlxObject return camDisplace;
    inline function set_camFollow(v:FlxObject):FlxObject return camDisplace = v;

    inline function get_camFollowPos():FlxPoint return camPos;
    inline function set_camFollowPos(v:FlxPoint):FlxPoint return camPos = v;

    // ==============================================

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

        #if ENGINE_SCRIPTING
        loadScriptsFrom('songs/${song.meta.folder}/scripts');
        loadScriptsGlobally('scripts/gameplay');
        noSubstateCalls = true;
        #end

        camGame = new Camera();
        camGame.bgColor.alpha = 0;
        FlxG.cameras.reset(camGame);

        camHUD = new FlxCamera();
        camHUD.bgColor.alpha = 0;
        FlxG.cameras.add(camHUD, false);

        camSubState = new Camera();
        camSubState.bgColor.alpha = 0;
        FlxG.cameras.add(camSubState, false);

        camPos = FlxPoint.get();

        camDisplace = new FlxObject(0, 0, 1, 1);
        camGame.follow(camDisplace, LOCKON);
        camDisplace.visible = false;
        add(camDisplace);

        super.create();

        #if ENGINE_SCRIPTING
        hxsCall("onCreate");
        #end

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
        beatZoomInterval = conductor.beatsPerMeasure;

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

        cameraTargets = [opponent, spectator, player];

        strumLines = new FlxTypedGroup<StrumLine>();
        strumLines.cameras = [camHUD];

        opponentStrumline = new StrumLine(FlxG.width * 0.25, 50, true, oppNoteSkin);
        opponentStrumline.scrollSpeed = song.gameplayInfo.scrollSpeed;
        opponentStrumline.onNoteHit.add(onOpponentNoteHit);
        opponentStrumline.onHold.add(onOpponentHold);
        strumLines.add(opponentStrumline);

        playerStrumline = new StrumLine(FlxG.width * 0.75, 50, false, plrNoteSkin);
        playerStrumline.scrollSpeed = song.gameplayInfo.scrollSpeed;
        strumLines.add(playerStrumline);

        playerStrumline.onNoteHit.add(processPlayerNoteHit);
        playerStrumline.onHoldInvalidation.add(onHoldInvalidation);
        playerStrumline.onGhostPress.add(onGhostPress);
        playerStrumline.onMiss.add(onMiss);
        playerStrumline.onHold.add(onHold);

        if (opponent != null) opponentStrumline.characters.push(opponent);
        if (player != null) playerStrumline.characters.push(player);

        noteSpawner = new NoteSpawner(strumLines.members, startTime);
        add(noteSpawner);
        add(strumLines);

        eventManager = new EventManager();
        eventManager.loadEvents(song.events);
        add(eventManager);

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
        #if ENGINE_SCRIPTING
        var types:Array<String> = [];

        for (note in song.notes) {
            var type:String = note.type;
            if (type != null && !types.contains(type)) {
                if (!Note.defaultTypes.contains(type)) {
                    var path:String = Assets.script("scripts/notetypes/" + type);
                    if (FileTools.exists(path)) loadScript(path);
                }

                types.push(type);
            }
        }
        #end

        conductor.enableInterpolation = true;

        // cache some extra stuff that cannot be loaded in the loading screen
        // since they can be modified
        cacheExtra();

        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.details = 'Playing ${song.meta.name} (${gameMode.getHandle()})';
        #end

        // Calling the stage create post function here, in case it modifies some camera position values
        stage.createPost();

        // Run the first camera event, then snap the camera's position to it's intended position
        if (song.events.length > 0 && song.events[0].event.toLowerCase().trim() == "change camera target" && song.events[0].time <= 10)
            eventManager.runEvent(eventManager.events.shift());
        else
            camDisplace.setPosition(FlxG.width * 0.5, FlxG.height * 0.5);

        snapCamera();

        if (startTime <= 0) {
            #if ENGINE_SCRIPTING
            if (!cancellableCall("onCountdownStart"))
            #end
                startCountdown();
        } else
            setTime(startTime);

        if (gameMode != DEBUG)
            trace('${song.meta.name} - Took ${((Lib.getTimer() - createTime) / 1000)}s to load');

        #if ENGINE_SCRIPTING
        hxsCall("onCreatePost");
        #end
    }

    override public function update(elapsed:Float):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onUpdate", [elapsed]))
            return;
        #end

        super.update(elapsed);

        if (health <= minHealth && subState == null)
            gameOver();

        camGame.zoom = Tools.lerp(camGame.zoom, cameraZoom, cameraSpeed);
        camHUD.zoom = Tools.lerp(camHUD.zoom, hudZoom, cameraSpeed);

        updateCamPos();
        updateCamLerp();

        #if ENGINE_DISCORD_RPC
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

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    override function stepHit(step:Int):Void {
        #if ENGINE_SCRIPTING if (cancellableCall("onStepHit", [step])) return; #end

        stage.stepHit(step);
        music.resync();
    }

    override function beatHit(beat:Int):Void {
        #if ENGINE_SCRIPTING if (cancellableCall("onBeatHit", [beat])) return; #end

        if (beat != 0 && beat % beatZoomInterval == 0) {
            camGame.zoom += camBeatZoom;
            camHUD.zoom += hudBeatZoom;
        }

        gameDance(beat);
        hud.beatHit();
    }

    override function measureHit(measure:Int):Void {
        #if ENGINE_SCRIPTING if (cancellableCall("onMeasureHit", [measure])) return; #end
        stage.measureHit(measure);
    }

    public function pause():Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onPause"))
            return;
        #end

        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.state = "Paused";
        #end

        openSubState(new PauseScreen());

        #if ENGINE_SCRIPTING
        hxsCall("onPausePost");
        #end
    }

    public function gameOver():Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onGameOver"))
            return;
        #end

        music.stop();
        persistentDraw = false;

        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.state = "Game Over";
        #end

        camSubState.zoom = camGame.zoom;

        var playerPosition:FlxPoint = player?.getScreenCoords() ?? FlxPoint.get(camPos.x, camPos.y);
        openSubState(new GameOverScreen(playerPosition.x, playerPosition.y, player?.gameOverChar ?? player?.character ?? "boyfriend-dead"));
        playerPosition.put();

        #if ENGINE_SCRIPTING
        hxsCall("onGameOverPost");
        #end
    }

    inline public function openChartEditor():Void {
        Assets.clearAssets = Options.reloadAssets;
        FlxG.switchState(ChartEditor.new.bind(song, currentDifficulty, (FlxG.keys.pressed.SHIFT) ? Math.max(conductor.time, 0) : 0));
    }

    public function changeCamTarget(target:Int):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onCamTargetChange", [target]))
            return;
        #end

        targetCharacter = cameraTargets[target];
        stage.onCamFocusChange(target);

        #if ENGINE_SCRIPTING
        hxsCall("onCamTargetChangePost", [target]);
        #end
    }

    public inline function snapCamera():Void {
        updateCamPos();
        camDisplace.setPosition(camPos.x, camPos.y);
    }

    public inline function updateCamPos():Void {
        if (targetCharacter == null)
            return;

        var position:FlxPoint = targetCharacter.getCamDisplace();
        camPos.set(position.x, position.y);
        position.put();
    }

    public inline function updateCamLerp():Void {
        camDisplace.setPosition(Tools.lerp(camDisplace.x, camPos.x, cameraSpeed), Tools.lerp(camDisplace.y, camPos.y, cameraSpeed));
    }

    public function startCountdown(ticks:Int = 4, changeBeat:Bool = true):Void {
        if (changeBeat)
            conductor.beat = -(ticks + 1);

        countdownSprite = new FlxSprite();
        countdownSprite.cameras = [camHUD];
        countdownSprite.alpha = 0;
        add(countdownSprite);

        new FlxTimer().start(conductor.crochet * 0.001, (tmr) -> countdownTick(tmr.elapsedLoops - 1, ticks), ticks);
        // countdownTick(0, ticks);
    }

    inline function countdownTick(tick:Int, totalLoops:Int):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onCountdownTick", [tick]))
            return;
        #end

        var done:Bool = (tick == totalLoops - 1);

        stage.onCountdownTick(tick);
        gameDance(tick);

        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.state = (done ? 'Go' : Std.string(totalLoops - tick - 1)) + (done ? '!' : '...');
        #end

        var graphic:String = countdownGraphics[tick];
        var sound:String = countdownSounds[tick];

        if (graphic != null) countdownSprite.loadGraphic(Assets.image(graphic + stage.uiStyle));
        if (sound != null) FlxG.sound.play(Assets.sound(sound + stage.uiStyle));

        countdownSprite.alpha = (graphic == null ? 0 : 1);
        countdownSprite.screenCenter();

        FlxTween.cancelTweensOf(countdownSprite);
        FlxTween.tween(countdownSprite, {y: countdownSprite.y + 50 * (tick + 1), alpha: 0}, conductor.crochet * 0.001, {
            ease: FlxEase.smootherStepInOut,
            onComplete: (!done) ? null : (_) -> {
                remove(countdownSprite, true);
                countdownSprite = FlxDestroyUtil.destroy(countdownSprite);
                startSong();
            }
        });

        #if ENGINE_SCRIPTING
        hxsCall("onCountdownTickPost", [tick]);
        #end
    }

    public function startSong(time:Float = 0):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSongStart"))
            return;
        #end

        conductor.music = music.instrumental;
        music.play(time);

        stage.onSongStart();
        hud.onSongStart();
    }

    public function endSong():Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSongEnd"))
            return;
        #end

        conductor.music = null;
        stage.onSongEnd();
        lossCounter = 0;

        if (validScore) {
            var song:String = '${song.meta.folder}-${currentDifficulty}';
            if (gameMode == STORY) song += "_story";

            HighScore.set(song, {
                score: score,
                misses: misses,
                accuracy: accuracyDisplay,
                rank: rank
            });
        }

        switch (gameMode) {
            case STORY:
                if (songPlaylist.length > 0) {
                    Transition.onComplete.add(() -> load(songPlaylist.shift(), currentDifficulty));
                    FlxG.switchState(LoadingScreen.new.bind(0));
                }
                else {
                    if (weekToUnlock != null) {
                        SongProgress.unlock(weekToUnlock, true);
                        weekToUnlock = null;
                    }
                    
                    FlxG.switchState(StoryMenu.new);
                }
            case DEBUG:
                openChartEditor();
            default:
                FlxG.switchState(FreeplayMenu.new);
        }
    }

    inline function gameDance(beat:Int):Void {
        player?.dance(beat);
        spectator?.dance(beat);

        if (opponent != null && opponent != spectator)
            opponent.dance(beat);

        stage.beatHit(beat);
    }

    inline function processPlayerNoteHit(note:Note):Void {
        if (playerStrumline.cpu)
            onBotplayNoteHit(note);
        else
            onPlayerNoteHit(note);
    }

    public function onGhostPress(direction:Int):Void {
        playMissAnimation(direction);
        onMiss(null);
    }

    public function onPlayerNoteHit(note:Note):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onNoteHit", [note]))
            return;
        #end

        music.playerVolume = 1;
        health += healthIncrement;

        var rating:Rating = note.findRating(ratings);

        score += rating.scoreIncrement;
        accuracyMod += rating.accuracyMod;
        accuracyNotes++;

        rating.hits++;
        displayRating(rating);

        combo++;
        if (rating.displayCombo && combo >= 10)
            displayCombo(combo);

        if (rating.displayNoteSplash && !Options.noNoteSplash)
            playerStrumline.popSplash(note);

        hud.updateScoreText();

        #if ENGINE_SCRIPTING
        hxsCall("onNoteHitPost", [note]);
        #end
    }

    public function onOpponentNoteHit(note:Note):Void {
        #if ENGINE_SCRIPTING
        hxsCall("onOpponentNoteHit", [note]);
        #end

        if (music.voices.length == 1)
            music.playerVolume = 1;
    }

    public function onBotplayNoteHit(note:Note):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onBotplayNoteHit", [note]))
            return;
        #end

        health += healthIncrement;
        music.playerVolume = 1;
    }

    public function onHold(note:Note):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onNoteHold", [note]))
            return;
        #end

        health += healthIncrement;
        music.playerVolume = 1;
    }

    public function onHoldInvalidation(note:Note):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onNoteHoldInvalidation", [note]))
            return;
        #end

        var remainingLength:Float = note.length - (conductor.time - note.time);
        var fraction:Float = (remainingLength / (conductor.stepCrochet * 2)) + 1;

        health -= healthLoss * fraction;
        score -= missScoreLoss * Math.floor(fraction);
        accuracyNotes += Math.floor(fraction);
        misses++;

        hud.updateScoreText();
        characterMisses(note);
        playMissSound(0.4);

        music.playerVolume = 0;
        combo = 0;
    }

    public function onOpponentHold(note:Note):Void {
        #if ENGINE_SCRIPTING
        hxsCall("onOpponentNoteHold", [note]);
        #end

        if (music.voices.length == 1)
            music.playerVolume = 1;
    }

    public function onMiss(note:Note):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onMiss", [note]))
            return;
        #end

        combo = 0;
        music.playerVolume = 0;

        score -= missScoreLoss;
        health -= healthLoss;

        misses++;
        accuracyNotes++;
        hud.updateScoreText();

        characterMisses(note);
        playMissSound();

        #if ENGINE_SCRIPTING
        hxsCall("onMissPost", [note]);
        #end
    }

    public function characterMisses(note:Note):Void {
        if (note != null && !note.noMissAnim)
            playMissAnimation(note.direction);

        if (spectator != null && spectator.animation.exists("sad") && (note == null || spectator.animation.name != "sad" || spectator.animation.finished)) {
            spectator.playAnimation("sad", true);
            spectator.animEndTime = (conductor.crochet / 1000);
            spectator.currentDance = 0;
        }
    }

    public inline function playMissSound(volume:Float = 0.1):Void {
        FlxG.sound.play(Assets.sound('gameplay/missnote${FlxG.random.int(1, 3)}'), FlxG.random.float(volume, volume + 0.1));
    }

    public inline function playMissAnimation(direction:Int):Void {
        for (player in playerStrumline.characters) {
            player.sing(direction, "miss");
            player.animEndTime = (conductor.crochet / 1000);
            player.currentDance = 0;
        }
    }

    public function displayRating(rating:Rating):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onRatingDisplay", [rating]))
            return;
        #end

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
        #if ENGINE_SCRIPTING
        if (cancellableCall("onComboDisplay", [combo]))
            return;
        #end

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
    override function openSubState(subState:FlxSubState):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSubStateOpened", [subState]))
            return;
        #end

        Tools.pauseEveryTween();
        Tools.pauseEveryTimer();
        music?.pause();

        if (subState is TransitionSubState && cast(subState, TransitionSubState).type == OUT)
            Transition.noPersistentUpdate = true;

        if (camSubState != null)
            subState.cameras = [camSubState];

        if (playerStrumline != null)
            playerStrumline.inactiveInputs = true;
        
        super.openSubState(subState);
    }

    override function closeSubState():Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSubStateClosed"))
            return;
        #end

        Tools.resumeEveryTween();
        Tools.resumeEveryTimer();
        music?.resume();

        playerStrumline.inactiveInputs = false;
        super.closeSubState();
    }

    override function onFocusLost():Void {
        super.onFocusLost();

        if (subState == null) {
            if (!FlxG.autoPause)
                pause();

            #if ENGINE_DISCORD_RPC
            DiscordPresence.presence.state = "Paused";
            #end
        }
    }

    override function destroy():Void {
        current = null;

        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.state = "";
        #end

        while (ratings.length > 0)
            ratings.pop().destroy();
        ratings = null;

        countdownGraphics = null;
        countdownSounds = null;

        camPos = FlxDestroyUtil.put(camPos);
        targetCharacter = null;
        cameraTargets = null;

        rankSDCB = null;
        rankFC = null;

        super.destroy();
    }

    // Helper functions

    public inline function cacheExtra():Void {
        for (rating in ratings)
            if (rating.image != null)
                Assets.image('ui/gameplay/${rating.image}' + stage.uiStyle);

        for (i in 0...10)
            Assets.image('ui/gameplay/num${i}' + stage.uiStyle);

        for (sprite in countdownGraphics)
            if (sprite != null)
                Assets.image(sprite + stage.uiStyle);

        for (sound in countdownSounds)
            if (sound != null)
                Assets.sound(sound + stage.uiStyle);
    }

    inline public function setTime(time:Float):Void {
        conductor.time = time;
        startSong(time);
    }

    inline function set_health(v:Float):Float
        return health = hud.healthDisplay = FlxMath.bound(v, minHealth, maxHealth);

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
            if (misses < 1) rank = rankFC;
            else if (misses > 0 && misses < 10) rank = rankSDCB;
        }

        return rank;
    }
}

enum abstract GameMode(String) from String to String {
    var STORY = "story";
    var FREEPLAY = "freeplay";
    var DEBUG = "debug";

    public function getHandle():String {
        return switch (this:GameMode) {
            case STORY: "Story";
            case FREEPLAY: "Freeplay";
            case DEBUG: "Debug";
        }
    }
}
