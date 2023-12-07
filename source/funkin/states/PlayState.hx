package funkin.states;

import flixel.*;
import flixel.util.*;
import flixel.tweens.*;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

import funkin.music.MusicPlayback;
import funkin.music.EventManager;

import eternal.ChartLoader;
import eternal.ChartFormat.Chart;
import eternal.ChartFormat.ChartEvent;

import funkin.states.substates.*;

import funkin.objects.Rating;
import funkin.objects.notes.*;
import funkin.objects.stages.*;
import funkin.objects.Character;
import funkin.objects.ui.GameplayUI;

import funkin.states.menus.StoryMenu;
import funkin.states.debug.ChartEditor;
import funkin.states.menus.FreeplayMenu;

import openfl.Lib;

class PlayState extends MusicBeatState {
   public static var current:PlayState;

   public static var gameMode:GameMode = FREEPLAY;
   public static var lossCounter:Int = 0;

   public static var currentDifficulty:String;
   public static var songPlaylist:Array<String>;
   public static var song:Chart;

   public var eventManager:EventManager;
   public var music:MusicPlayback;

   public var camGame:FlxCamera;
   public var camHUD:FlxCamera;
   public var camSubState:FlxCamera;

   public var spectator:Character;
   public var opponent:Character;
   public var player:Character;
   public var stage:BaseStage;

   public var strumLines:FlxTypedGroup<StrumLine>;
   public var opponentStrumline:StrumLine;
   public var playerStrumline:StrumLine;

   public var ratingSprites:FlxTypedSpriteGroup<FlxSprite>;
   public var comboSprites:FlxTypedSpriteGroup<FlxSprite>;
   public var hud:GameplayUI;

   public var countdownSprites:Array<String> = [null, 'ui/gameplay/ready', 'ui/gameplay/set', 'ui/gameplay/go'];
   public var countdownSounds:Array<String> = ['gameplay/intro3', 'gameplay/intro2', 'gameplay/intro1', 'gameplay/introGo'];
   public var countdownSprite:FlxSprite;
   public var countdownTween:FlxTween;

   public var score:Float = 0;
   public var combo:Int = 0;
   public var ratings:Array<Rating> = Rating.getDefaultList();

   public var misses:Int = 0;
   public var missScoreLoss:Float = 10;

   public var accuracy:Float = 0;
   public var accuracyMod:Float = 0;
   public var accuracyNotes:Int = 0;
   public var accuracyDisplay:Float = 0;

   public var health(default, set):Float = 1;
   public var minHealth:Float = 0;
   public var maxHealth:Float = 2;
   public var healthIncrement:Float = 0.023;
   public var healthLoss:Float = 0.0475;

   public var rankFC:String = "FC";
   public var rankSDCB:String = "SDCB";

   public var cameraZoomIntensity:Float = 1;
   public var cameraZoomBeat:Float = 4;
   public var cameraSpeed:Float = 3;
   public var cameraZoom:Float = 1;
   public var hudZoom:Float = 1;

   public var cameraObject:FlxObject;
   public var cameraPoint:FlxPoint;

   public var cameraTargets:Array<Character>;
   public var targetCharacter:Character;

   public var notes:Array<Note> = [];
   public var noteSpawnTime:Float;

   public var validScore:Bool = gameMode != DEBUG;

   var startTime:Float;

   // ======= Base game compatibility ==============
   public var boyfriend(get, set):Character;
   public var gf(get, set):Character;
   public var dad(get, set):Character;

   public var camFollow(get, set):FlxPoint;
   public var camFollowPos(get, set):FlxObject;
   public var defaultCamZoom(get, set):Float;

   public var unspawnNotes(get, set):Array<Note>;

   inline function get_boyfriend():Character return player;
   inline function set_boyfriend(v:Character):Character return player = v;

   inline function get_gf():Character return spectator;
   inline function set_gf(v:Character):Character return spectator = v;

   inline function get_dad():Character return opponent;
   inline function set_dad(v:Character):Character return opponent = v;

   inline function get_defaultCamZoom():Float return cameraZoom;
   inline function set_defaultCamZoom(v:Float):Float return cameraZoom = v;

   inline function get_camFollow():FlxPoint return cameraPoint;
   inline function set_camFollow(v:FlxPoint):FlxPoint return cameraPoint = v;
   
   inline function get_camFollowPos():FlxObject return cameraObject;
   inline function set_camFollowPos(v:FlxObject):FlxObject return cameraObject = v;

   inline function get_unspawnNotes():Array<Note> return notes;
   inline function set_unspawnNotes(v:Array<Note>):Array<Note> return notes = v;
   // ==============================================

   public function new(startTime:Float = 0):Void {
      super();
      this.startTime = startTime;
   }

   inline public static function load(song:String, diff:String = "normal"):Void {
      currentDifficulty = diff;
      PlayState.song = ChartLoader.loadChart(song, diff);
   }

   override public function create():Void {
      Tools.stopMusic();
      current = this;

      var timeToLoad:Float = Lib.getTimer();

      #if ENGINE_SCRIPTING
      avoidCallbacks.push("onOpenSubState");
      avoidCallbacks.push("onCloseSubState");

      loadScriptsFrom('songs/${song.meta.rawName}/scripts');
      loadScriptsFrom('data/scripts');
      #end

      camGame = FlxG.camera;
      camGame.bgColor.alpha = 0;

      camHUD = new FlxCamera();
      camHUD.bgColor.alpha = 0;
      FlxG.cameras.add(camHUD, false);

      camSubState = new FlxCamera();
      camSubState.bgColor.alpha = 0;
      FlxG.cameras.add(camSubState, false);

      cameraPoint = FlxPoint.get();

      cameraObject = new FlxObject(0, 0, 1, 1);
      cameraObject.visible = false;
      camGame.follow(cameraObject, LOCKON, 1);
      add(cameraObject);

      super.create();

      #if ENGINE_SCRIPTING
      hxsCall("onCreate");
      #end

      music = new MusicPlayback(song.meta.rawName);
      music.setupInstrumental(song.meta.instFile);

      if (song.meta.voiceFiles.length > 0)
         for (voiceFile in song.meta.voiceFiles)
            music.createVoice(voiceFile);
      
      music.onSongEnd.add(endSong);
      add(music);

      Conductor.stepsPerBeat = song.meta.stepsPerBeat ?? 4;
      Conductor.beatsPerMeasure = song.meta.beatsPerMeasure ?? 4;
      Conductor.bpm = song.bpm;
      
      notes = ChartLoader.generateNotes(song);

      cameraZoomBeat = Conductor.beatsPerMeasure;
      
      eventManager = new EventManager(this);
      add(eventManager);

      strumLines = new FlxTypedGroup<StrumLine>();
      strumLines.cameras = [camHUD];
      add(strumLines);

      opponentStrumline = new StrumLine(FlxG.width * 0.25, FlxG.height * 0.085, true);
      opponentStrumline.scrollSpeed = song.speed;
      opponentStrumline.onNoteHit.add(opponentNoteHit);
      opponentStrumline.onHold.add(onOpponentHold);
      strumLines.add(opponentStrumline);

      playerStrumline = new StrumLine(FlxG.width * 0.75, FlxG.height * 0.085);
      playerStrumline.scrollSpeed = song.speed;
      playerStrumline.onNoteHit.add(botplayNoteHit);
      playerStrumline.onHold.add(onHold);
      playerStrumline.onMiss.add(miss);
      strumLines.add(playerStrumline);

      stage = switch (song.meta.stage.toLowerCase()) {
         default: new SoftcodedStage(this, song.meta.stage);
      }
      add(stage);

      eventManager.loadEvents(song.events);

      if (song.meta.spectator != null) {
         spectator = new Character(400, 0, song.meta.spectator);
         add(spectator);
      }

      if (song.meta.opponent != null) {
         opponent = new Character(200, 0, song.meta.opponent);
         opponentStrumline.characters.push(opponent);
         add(opponent);
      }

      if (song.meta.player != null) {
         player = new Character(400, 0, song.meta.player, PLAYER);
         playerStrumline.characters.push(player);
         add(player);
      }

      cameraTargets = [opponent, spectator, player];

      hud = new GameplayUI();
      hud.cameras = [camHUD];
      hud.visible = !Settings.get("hide user interface");
      add(hud);

      if (Settings.get("downscroll")) {
         playerStrumline.y = opponentStrumline.y = FlxG.height * 0.8;
         playerStrumline.downscroll = opponentStrumline.downscroll = true;
      }
      if (Settings.get("centered strumline")) {
         opponentStrumline.visible = false;
         playerStrumline.screenCenter(X);
      }

      if (gameMode == FREEPLAY)
         strumLines.forEach((strumline) -> strumline.tweenReceptors());

      comboSprites = new FlxTypedSpriteGroup<FlxSprite>();
      add(comboSprites);

      ratingSprites = new FlxTypedSpriteGroup<FlxSprite>();
      add(ratingSprites);

      if (Settings.get("judgements on user interface")) {
         ratingSprites.cameras = comboSprites.cameras = [camHUD];
         ratingSprites.setPosition(FlxG.width * 0.5 - 100, FlxG.height * 0.5 - 100);
         comboSprites.setPosition(ratingSprites.x + 60, ratingSprites.y + 140);

         for (group in [ratingSprites, comboSprites]) {
            remove(group, true);
            insert(members.indexOf(strumLines), group);
         }
      }

      cache();

      Controls.globalControls.onKeyJustPressed.add(onKeyDown);
      Controls.globalControls.onKeyJustReleased.add(onKeyUp);
      noteSpawnTime = 1800 / song.speed;

      #if ENGINE_DISCORD_RPC
      DiscordPresence.presence.details = 'Playing ${song.meta.name} (${gameMode.getHandle()})';
      #end

      // Calling the stage create post function here, in case it modifies some camera position values
      stage.createPost();

      // Run the first camera event, then snap the camera's position to it's intended position
      var cameraEvent:ChartEvent = null;
      if (song.events.length > 0 && song.events[0].event == "change camera target")
         cameraEvent = eventManager.loadedEvents.shift();
      else
         cameraEvent = { time: 0, event: "change camera target", arguments: [0] };

      eventManager.runEvent(cameraEvent);
      snapCamera();

      if (startTime <= 0) {
         #if ENGINE_SCRIPTING
         if (!cancellableCall("onStartCountdown"))
         #end
            startCountdown();
      }
      else
         setTime(startTime);

      persistentUpdate = true;

      if (gameMode != DEBUG)
         trace('${song.meta.name} - Took ${((Lib.getTimer() - timeToLoad) / 1000)}s to load');

      #if ENGINE_SCRIPTING
      hxsCall("onCreatePost");
      #end
   }

   override public function update(elapsed:Float):Void {
      #if ENGINE_SCRIPTING
      hxsCall("onUpdate", [elapsed]);
      #end

      super.update(elapsed);

      if (health <= minHealth)
         gameOver();

      var ratio:Float = FlxMath.bound(elapsed * cameraSpeed, 0, 1);
      camGame.zoom = FlxMath.lerp(camGame.zoom, cameraZoom, ratio);
      camHUD.zoom = FlxMath.lerp(camHUD.zoom, hudZoom, ratio);

      repositionCameraPoint();
      cameraObject.setPosition(FlxMath.lerp(cameraObject.x, cameraPoint.x, ratio), FlxMath.lerp(cameraObject.y, cameraPoint.y, ratio));

      #if ENGINE_DISCORD_RPC
      if (music.playing && Conductor.position >= 0 && Conductor.position <= music.instrumental.length)
         DiscordPresence.presence.state = '${FlxStringUtil.formatTime((music.instrumental.length * 0.001) - (Conductor.position * 0.001))}';
      #end

      #if ENGINE_SCRIPTING
      while (notes.length > 0 && notes[0].time - Conductor.position < (noteSpawnTime + notes[0].spawnTimeOffset)) {
         var note:Note = notes.shift();
         hxsCall("onNoteSpawn", [note]);
         strumLines.members[note.strumline].addNote(note);
         hxsCall("onNoteSpawnPost", [note]);
      }
      #else
      while (notes.length > 0 && notes[0].time - Conductor.position < (noteSpawnTime + notes[0].spawnTimeOffset))
         strumLines.members[notes[0].strumline].addNote(notes.shift());
      #end
      
      if (controls.justPressed("accept"))
         pause();

      if (gameMode != STORY) {
         if (controls.justPressed("debug") && Settings.get("editor access")) {
            if (gameMode != DEBUG) {
               gameMode = DEBUG;
               validScore = false;
            }

            openChartEditor();
         }

         if (controls.justPressed("autoplay")) {
            validScore = false;
            playerStrumline.cpu = !playerStrumline.cpu;
            hud.showBotplayMark(playerStrumline.cpu);
            hud.updateScoreText();
         }
      }

      stage.updatePost(elapsed);

      #if ENGINE_SCRIPTING
      hxsCall("onUpdatePost", [elapsed]);
      #end
   }

   override function stepHit(currentStep:Int):Void {
      music.resyncCheck();
      stage.stepHit(currentStep);
      super.stepHit(currentStep);
   }

   override function beatHit(currentBeat:Int):Void {
      for (character in [player, spectator, opponent])
         if (character != null)
            character.dance(currentBeat);

      stage.beatHit(currentBeat);

      if (!Settings.get("reduced movements") && Conductor.currentBeat > -1) {
         hud.beatHit();

         if (currentBeat != 0 && currentBeat % cameraZoomBeat == 0) {
            if (camGame.zoom < 1.35)
               camGame.zoom += 0.05 * cameraZoomIntensity;
            camHUD.zoom += 0.05 * cameraZoomIntensity;
         }
      }

      super.beatHit(currentBeat);
   }

   override function measureHit(currentMeasure:Int):Void {
      stage.measureHit(currentMeasure);
      super.measureHit(currentMeasure);
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

      var playerPosition:FlxPoint = player?.getScreenPosition() ?? FlxPoint.get(cameraPoint.x, cameraPoint.y);
      openSubState(new GameOverScreen(playerPosition.x, playerPosition.y, player?.data.gameOverCharacter ?? "bf-dead"));
      playerPosition.put();

      #if ENGINE_SCRIPTING
      hxsCall("onGameOverPost");
      #end
   }

   inline public function openChartEditor():Void {
      AssetHelper.clearAssets = Settings.get("reload assets");
      FlxG.switchState(new ChartEditor(song, currentDifficulty, (FlxG.keys.pressed.SHIFT) ? Math.max(Conductor.position, 0) : 0));
   }

   public function changeCameraTarget(target:Int):Void {
      #if ENGINE_SCRIPTING
      if (cancellableCall("onCameraMove"))
         return;
      #end

      targetCharacter = cameraTargets[target];

      #if ENGINE_SCRIPTING
      hxsCall("onCameraMovePost");
      #end
   }

   public function snapCamera():Void {
      repositionCameraPoint();
      cameraObject.setPosition(cameraPoint.x, cameraPoint.y);
   }

   inline public function repositionCameraPoint():Void {
      if (targetCharacter != null)
         cameraPoint.set(targetCharacter.cameraDisplace.x, targetCharacter.cameraDisplace.y);
      else
         cameraPoint.set(FlxG.width * 0.5, FlxG.height * 0.5);
   }

   public function startCountdown(loops:Int = 4, changeConductorPos:Bool = true):Void { 
      if (loops <= 0 || Math.isNaN(loops) || loops == Math.POSITIVE_INFINITY || loops == Math.NEGATIVE_INFINITY)
         loops = 4; // why would you try to loop it eternally?

      // Caching
      for (sprite in countdownSprites)
         if (sprite != null)
            AssetHelper.image(sprite);

      for (sound in countdownSounds)
         if (sound != null)
            AssetHelper.sound(sound);

      // Change the conductor position (mostly to fit the notes position during the start countdown)
      if (changeConductorPos)
         Conductor.position = -(Conductor.crochet * (loops + 1));

      // Setup some countdown elements and data
      countdownSprite = new FlxSprite();
      countdownSprite.cameras = [camHUD];
      countdownSprite.alpha = 0;
      add(countdownSprite);

      var countSpriteY:Float = 0;
      var timing:Float = Conductor.crochet / 1000;

      // Actually starts the countdown
      new FlxTimer().start(timing, tmr -> {
         var currentLoop:Int = tmr.elapsedLoops - 1;
         var isDone:Bool = (tmr.loopsLeft == 0);

         stage.onCountdownTick(currentLoop);
         beatHit(currentLoop);

         #if ENGINE_SCRIPTING
         hxsCall("onCountdownTick", [currentLoop]);
         #end

         #if ENGINE_DISCORD_RPC
         DiscordPresence.presence.state = (isDone ? 'Go' : Std.string(tmr.loopsLeft)) + (isDone ? '!' : '...');
         #end

         if (countdownSprites[currentLoop] != null) {
            countdownSprite.loadGraphic(AssetHelper.image(countdownSprites[currentLoop]));
            countdownSprite.alpha = 1;
         }
         else
            countdownSprite.alpha = 0;
         countdownSprite.screenCenter();

         if (countdownSounds[currentLoop] != null)
            FlxG.sound.play(AssetHelper.sound(countdownSounds[currentLoop]));

         if (!Settings.get("reduced movements"))
            countSpriteY += 100;
         else
            countSpriteY = countdownSprite.y;

         if (countdownTween != null) {
            countdownTween.cancel();
            countdownTween.destroy();
            countdownTween = null;
         }

         countdownTween = FlxTween.tween(countdownSprite, {y: countSpriteY, alpha: 0}, timing, {
            ease: FlxEase.cubeInOut,
            onComplete: (_) -> {
               if (isDone) {
                  remove(countdownSprite, true);
                  countdownSprite.destroy();
                  countdownSprite = null;
                  countdownTween = null;
                  startSong();
               }
            }
         });

         #if ENGINE_SCRIPTING
         hxsCall("onCountdownTickPost", [currentLoop]);
         #end
      }, loops);
   }

   public function startSong(time:Float = 0):Void {
      #if ENGINE_SCRIPTING
      hxsCall("onSongStart");
      #end

      music.play(time);
      stage.onSongStart();

      if (hud.timer.visible)
         hud.tweenTimer();

      #if ENGINE_SCRIPTING
      hxsCall("onSongStartPost");
      #end
   }

   public function endSong():Void {
      #if ENGINE_SCRIPTING
      if (cancellableCall("onSongEnd"))
         return;
      #end

      stage.onSongEnd();

      if (validScore) {
         var song:String = '${song.meta.rawName}-${currentDifficulty}';
         if (gameMode == STORY)
            song += "_story";

         HighScore.set(song, {score: score, misses: misses, accuracy: accuracyDisplay, rank: getRank(this)});
      }

      lossCounter = 0;

      switch (gameMode) {
         case STORY:
            if (songPlaylist.length > 0) {
               TransitionSubState.onComplete.add(() -> load(songPlaylist.shift(), currentDifficulty));
               FlxG.switchState(new PlayState());
            }
            else
               FlxG.switchState(new StoryMenu());
         case DEBUG:
            openChartEditor();
         default:
            FlxG.switchState(new FreeplayMenu());
      }
   }

   private inline function onKeyDown(rawID:Int, action:String) {
      #if ENGINE_SCRIPTING
      hxsCall("onKeyPressUnsafe", [rawID, action]);
      #end

      if (playerStrumline.cpu || action == null || !Note.directions.contains(action) || !persistentUpdate)
         return;

      #if ENGINE_SCRIPTING
      hxsCall("onKeyPress", [rawID, action]);
      #end

      var index:Int = Note.directions.indexOf(action);
      var receptor:Receptor = playerStrumline.receptors.members[index];

      playerStrumline.holdKeys[index] = true;

      for (player in playerStrumline.characters)
         player.holding = true;

      var possibleNotes:Array<Note> = playerStrumline.notes.members.filter((note) -> note.direction == index && note.canBeHit);

      if (possibleNotes.length > 0) {
         possibleNotes.sort(sortHitNotes);

         var noteToHit:Note = possibleNotes[0];
         
         // Delete stacked notes
         if (possibleNotes.length > 1) {
            for (i => note in possibleNotes) {
               if (i == 0) continue;
   
               if (note.direction == noteToHit.direction && Math.abs(note.time - noteToHit.time) <= 10)
                  playerStrumline.removeNote(note);
               else break;
            }
         }

         goodNoteHit(noteToHit);
      }
      else {
         receptor.playAnimation("press", true);

         if (!Settings.get("ghost tapping")) {
            playMissAnimation(index);
            miss(null);
         }
      }

      #if ENGINE_SCRIPTING
      hxsCall("onKeyPressPost", [rawID, action]);
      #end
   }

   private inline function onKeyUp(rawID:Int, action:String) {
      #if ENGINE_SCRIPTING
      hxsCall("onKeyReleaseUnsafe", [rawID, action]);
      #end

      if (action == null || !Note.directions.contains(action))
         return;

      #if ENGINE_SCRIPTING
      hxsCall("onKeyRelease", [rawID, action]);
      #end

      var index:Int = Note.directions.indexOf(action);
      playerStrumline.holdKeys[index] = false;

      for (player in playerStrumline.characters)
         player.holding = playerStrumline.holdKeys[FlxMath.wrap(player.singAnimations.indexOf(player.animation.curAnim.name), 0, 3)];

      playerStrumline.receptors.members[index].playAnimation("static", true);

      #if ENGINE_SCRIPTING
      hxsCall("onKeyReleasePost", [rawID, action]);
      #end
   }

   public function goodNoteHit(note:Note):Void {
      if (note == null || note.goodHit || note.missed)
         return;

      #if ENGINE_SCRIPTING
      hxsCall("onNoteHit", [note]);
      #end

      playerStrumline.receptors.members[note.direction].playAnimation("confirm", true);
      playerStrumline.singCharacters(note);

      note.goodHit = true;
      note.missed = false; // just in case
      
      music.vocalsVolume = 1;
      health += healthIncrement;

      // Calculate the rating
      var noteDiff:Float = Math.abs(music.instrumental.time - note.time);
      var rating:Rating = ratings[0];

      for (possibleRating in ratings)
         if (noteDiff > Note.safeZoneOffset * possibleRating.hitWindowMult)
            rating = possibleRating;

      score += rating.scoreIncrement;
      accuracyMod += rating.accuracyMod;
      accuracyNotes++;
      recalculateAccuracy();

      rating.hits++;
      displayRating(rating);

      combo++;
      if (rating.displayCombo && combo > 0)
         displayCombo();

      if (rating.displayNoteSplash && !Settings.get("disable note splashes"))
         playerStrumline.popSplash(note.direction);

      if (rating.causesMiss)
         miss(note);

      hud.updateScoreText();
      playerStrumline.hitNote(note);

      #if ENGINE_SCRIPTING
      hxsCall("onNoteHitPost", [note]);
      #end
   }

   public function opponentNoteHit(note:Note):Void {
      #if ENGINE_SCRIPTING
      hxsCall("onOpponentNoteHit", [note]);
      #end
      
      checkVocalsVolume();
   }

   public function botplayNoteHit(note:Note):Void {
      #if ENGINE_SCRIPTING
      hxsCall("onBotplayNoteHit", [note]);
      #end

      checkVocalsVolume();
      health += healthIncrement;
   }

   public function onHold(note:Note):Void {
      #if ENGINE_SCRIPTING
      hxsCall("onNoteHold", [note]);
      #end

      checkVocalsVolume();
      health += healthIncrement;
   }

   public function onOpponentHold(note:Note):Void {
      #if ENGINE_SCRIPTING
      hxsCall("onOpponentNoteHold", [note]);
      #end

      checkVocalsVolume();
   }

   public function miss(note:Note):Void {
      #if ENGINE_SCRIPTING
      hxsCall("onMiss", [note]);
      #end

      combo = 0;
      music.vocalsVolume = 0;
      
      score -= missScoreLoss;
      health -= healthLoss;

      misses++;
      accuracyNotes++;

      recalculateAccuracy();
      hud.updateScoreText();

      if (note != null)
         playMissAnimation(note.direction, note.isSustainNote && !note.baseVisible);

      if (spectator != null && spectator.animation.exists("sad")
         && (note == null || spectator.animation.name != "sad" || spectator.animation.finished)) {
         spectator.playAnimation("sad", true);
         spectator.animEndTime = Conductor.crochet / 1000;
      }
      
      FlxG.sound.play(AssetHelper.sound('gameplay/missnote${FlxG.random.int(1, 3)}'), FlxG.random.float(0.1, 0.2));

      #if ENGINE_SCRIPTING
      hxsCall("onMissPost", [note]);
      #end
   }

   public inline function playMissAnimation(direction:Int, hold:Bool = false):Void {
      for (player in playerStrumline.characters) {
         if (!hold || !Settings.get("disable hold stutter") || player.animation.name != (player.singAnimations[direction] + "miss"))
            player.sing(direction, "miss");
         else
            player.holdTime = 0;

         player.currentDance = 0;
         player.animEndTime = Conductor.crochet / 1000;
      }
   }

   public inline function checkVocalsVolume():Void {
      if (music.playing && music.vocalsVolume <= 0)
         music.vocalsVolume = 1;
   }

   public function recalculateAccuracy():Void {
      if (accuracyNotes != 0 && accuracyMod != 0)
         accuracy = FlxMath.bound(accuracyMod / accuracyNotes, 0, 1);
      accuracyDisplay = FlxMath.roundDecimal(accuracy * 100, 2);
   }

   public function displayRating(rating:Rating):Void {
      #if ENGINE_SCRIPTING
      if (cancellableCall("onRatingDisplay", [rating]))
         return;
      #end

      if (rating == null || rating.ratingGraphic == null)
         return;

      if (Settings.get("disable combo stacking")) {
         for (spr in ratingSprites) {
            FlxTween.cancelTweensOf(spr);
            spr.kill();
         }
      }
      
      var sprite:FlxSprite = ratingSprites.recycle(FlxSprite, null, true, false);
      if (!sprite.exists) { // check if the sprite is a recycled one to reset its properties
         sprite.revive();
         sprite.acceleration.set();
         sprite.velocity.set();
         sprite.alpha = 1;
      }

      sprite.loadGraphic(AssetHelper.image('ui/gameplay/${rating.ratingGraphic}'));
      sprite.scale.set(0.7, 0.7);
      sprite.updateHitbox();
      sprite.setPosition(ratingSprites.x, ratingSprites.y); 

      sprite.acceleration.y = 550;
      sprite.velocity.set(-FlxG.random.float(0, 10), -FlxG.random.float(140, 175));
      if (Settings.get("reduced movements")) {
         sprite.acceleration.y *= 0.4;
         sprite.velocity.y *= 0.4;
      }

      ratingSprites.remove(sprite, true);
      ratingSprites.insert(ratingSprites.length + 1, sprite);

      FlxTween.tween(sprite, {alpha: 0}, 0.2, {
         startDelay: Conductor.crochet * 0.001,
         onComplete: (_) -> sprite.kill()
      });
   }

   public function displayCombo():Void {
      #if ENGINE_SCRIPTING
      if (cancellableCall("onComboDisplay"))
         return;
      #end

      if (Settings.get("disable combo stacking")) {
         for (spr in comboSprites) {
            FlxTween.cancelTweensOf(spr);
            spr.kill();
         }
      }

      var separatedCombo:String = Std.string(combo);

      if (!Settings.get("simplify combo number"))
         while (separatedCombo.length < 3)
            separatedCombo = "0" + separatedCombo;

      for (i in 0...separatedCombo.length) {
         var sprite:FlxSprite = comboSprites.recycle(FlxSprite, null, true, false);
         if (!sprite.exists) { // check if the sprite is a recycled one to reset its properties
            sprite.revive();
            sprite.acceleration.set();
            sprite.velocity.set();
            sprite.alpha = 1;
         }

         sprite.loadGraphic(AssetHelper.image('ui/gameplay/num${separatedCombo.charAt(i)}'));
         sprite.scale.set(0.5, 0.5);
         sprite.updateHitbox();
         sprite.setPosition(comboSprites.x + 43 * i, comboSprites.y);

         sprite.acceleration.y = FlxG.random.int(200, 300);
         sprite.velocity.set(FlxG.random.float(-5, 5), -FlxG.random.int(140, 160));
         if (Settings.get("reduced movements")) {
            sprite.acceleration.y *= 0.4;
            sprite.velocity.y *= 0.4;
         }

         comboSprites.remove(sprite, true);
         comboSprites.insert(comboSprites.length + 1, sprite);
         
         FlxTween.tween(sprite, {alpha: 0}, 0.2, {
            startDelay: Conductor.crochet * 0.002,
            onComplete: (_) -> sprite.kill()
         });
      }
   }

   // Overrides
   override function openSubState(subState:FlxSubState):Void {
      #if ENGINE_SCRIPTING
      if (cancellableCall("onOpenSubState", [subState]))
         return;
      #end

      Tools.pauseEveryTween();
      Tools.pauseEveryTimer();

      if (music != null)
         music.pause();

      if (camSubState != null)
         subState.cameras = [camSubState];
      
      persistentUpdate = false;
      super.openSubState(subState);
   }

   override function closeSubState():Void {
      #if ENGINE_SCRIPTING
      if (cancellableCall("onCloseSubState"))
         return;
      #end

      Tools.resumeEveryTween();
      Tools.resumeEveryTimer();

      if (music != null)
         music.resume();
      
      persistentUpdate = true;
      super.closeSubState();
   }

   override function onFocusLost():Void {
      super.onFocusLost();

      if (!FlxG.autoPause && subState == null)
         pause();

      #if ENGINE_DISCORD_RPC
      DiscordPresence.presence.state = "Paused";
      #end
   }

   override function destroy():Void {
      current = null;

      Controls.globalControls.onKeyJustPressed.remove(onKeyDown);
      Controls.globalControls.onKeyJustReleased.remove(onKeyUp);

      // Destroy remaining notes
      while (notes.length > 0)
         notes.shift().destroy();
      notes = null;

      while (ratings.length > 0)
         ratings.shift().destroy();
      ratings = null;

      cameraTargets = null;
      countdownSprites = null;
      countdownSounds = null;

      countdownSprite = null;
      countdownTween = null;

      cameraPoint.put();
      cameraPoint = null;

      targetCharacter = null;

      rankFC = null;
      rankSDCB = null;

      super.destroy();
   }
   
   // Helper functions
   var cacheList:Map<String, AssetType> = [];

   public function cache():Void {
      // Cache gameover
      /*
      var gameOverCache:Character = new Character(0, 0, player.data.gameOverCharacter, GAMEOVER);
      var gameOverData:GameOverProperties = gameOverCache.data.gameOverProperties;

      AssetHelper.sound(gameOverData.confirmSound);
      AssetHelper.sound(gameOverData.deathSound);
      AssetHelper.music(gameOverData.music);

      gameOverCache.destroy();
      */

      // Cache commonly used graphics and sounds
      AssetHelper.getSparrowAtlas("ui/alphabet");

      for (i in 1...4)
         AssetHelper.sound('gameplay/missnote${i}');

      for (i in 0...10)
         AssetHelper.image('ui/gameplay/num${i}');

      for (rating in ratings)
         if (rating.ratingGraphic != null)
            AssetHelper.image('ui/gameplay/${rating.ratingGraphic}');

      // Cache pause music
      AssetHelper.music("breakfast");

      // Misc cache, for scripting
      for (k => v in cacheList) {
         if (v != IMAGE && v != SOUND)
            continue;

         switch (v) {
            case IMAGE: AssetHelper.image(k);
            case SOUND: AssetHelper.sound(k);
            default:
         }
      }

      cacheList.clear();
      cacheList = null;
   }

   inline public function setTime(time:Float):Void {
      clearNotesBefore(time);
      Conductor.position = time;
      startSong(time);
   }

   public function clearNotesBefore(time:Float):Void {
      var invalidNotes:Array<Note> = [];

      for (note in notes) {
         if (note.time >= time)
            break;
         
         invalidNotes.push(note);
      }

      for (note in invalidNotes) {
         notes.remove(note);
         note.destroy();
      }
   }

   public static function getRank(game:PlayState):String {
      if (game.playerStrumline.cpu)
         return "";

      var rank:String = "";

      for (rating in game.ratings) {
         if (rating.rank == null || rating.hits < 1)
            continue;

         if ((rating.missThreshold != null && game.misses < rating.missThreshold)
            || (rating.missExceed != null && game.misses > rating.missExceed))
            rank = rating.rank;
      }

      if (rank.length < 1) {
         if (game.misses < 1)
            rank = game.rankFC;
         else if (game.misses > 0 && game.misses < 10)
            rank = game.rankSDCB;
      }

      return rank;
   }

   public static function sortHitNotes(a:Note, b:Note):Int
      return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);

   inline function set_health(v:Float):Float
      return health = hud.healthDisplay = FlxMath.bound(v, minHealth, maxHealth);
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