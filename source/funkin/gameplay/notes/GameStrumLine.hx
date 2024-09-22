package funkin.gameplay.notes;

import funkin.gameplay.components.Rating;

/**
 * Special `StrumLine` which handles extra gameplay logic for `PlayState`.
 */
class GameStrumLine extends StrumLine {
    /**
     * Since the processed direction in `onKeyDown` and `onKeyUp` can be changed with an event, 
     * it messes with sustain holding since `heldKeys` is shared for both input checks and sustain holding.
     * This array allows us to handle these separatly.
     */
    var pressedKeys:Array<Bool> = [false, false, false, false];

    override function handleNoteHit(note:Note):Void {
        var rating:Rating = PlayState.self.stats.evaluateNote(note);

        var event:NoteHitEvent = Events.get(NoteHitEvent).setup(
            note,
            owner == OPPONENT,
            cpu,
            rating,
            (!cpu ? rating.score : 0),
            (owner == PLAYER ? rating.health : 0),
            (!cpu ? rating.accuracyMod : 0),
            (owner == PLAYER ? Math.max(rating.health * 10, 0) : 0),
            (!cpu && !rating.breakCombo && PlayState.self.stats.combo >= 10),
            (!cpu && rating.displaySplash && !Options.noNoteSplash),
            !cpu,
            !cpu,
            !cpu,
            (!cpu && rating.breakCombo),
            !cpu,
            owner == PLAYER || PlayState.self.music.voices?.length == 1,
            !cpu
        );

        note.state = BEEN_HIT;
        PlayState.self.scripts.dispatchEvent("onNoteHit", event);

        if (event.cancelled)
            return;

        PlayState.self.playField.incrementScore(event.score);
        PlayState.self.stats.health += event.health;

        if (event.breakCombo)
            PlayState.self.stats.combo = 0;
        else if (event.increaseCombo)
            PlayState.self.stats.combo++;

        if (event.increaseHits)
            event.rating.hits++;

        if (event.increaseAccuracy)
            PlayState.self.playField.incrementAccuracy(event.accuracy);

        if (event.displayRating)
            PlayState.self.playField.displayRating(event.rating);

        if (event.displayCombo)
            PlayState.self.playField.displayCombo(PlayState.self.stats.combo);

        if (event.displaySplash)
            popSplash(note);

        if (event.unmutePlayer)
            PlayState.self.music.playerVolume = event.playerVolume;

        if (note.isHoldable())
            note.visible = event.noteVisible;
        else if (event.removeNote)
            queueNoteRemoval(note);

        if (event.playConfirm)
            note.targetReceptor.playAnimation("confirm", true);

        if (event.characterSing)
            charactersSing(note);

        note.holdHealth = event.holdHealth;
        onNoteHit.dispatch(note);

        if (note.isHoldable() && event.resizeLength)
            resizeLength(note);
    }

    override function handleLateNote(note:Note):Void {
        var event:NoteMissEvent = Events.get(NoteMissEvent).setup(note);
        _onMiss(event);

        if (event.cancelled)
            return;

        if (note.isHoldable())
            note.visible = event.noteVisible;
        else
            note.alpha = event.noteAlpha;

        note.holdHealth = event.holdHealth;
        onMiss.dispatch(note);
    }

    override function handleSustainNote(note:Note):Void {
        var event:NoteHoldEvent = Events.get(NoteHoldEvent).setup(
            note,
            owner == OPPONENT,
            cpu,
            note.missed,
            owner == PLAYER || PlayState.self.music.voices?.length == 1
        );

        note.state = BEEN_HIT;
        PlayState.self.scripts.dispatchEvent("onNoteHold", event);
        
        if (event.cancelled)
            return;

        if (event.unmutePlayer)
            PlayState.self.music.playerVolume = event.playerVolume;

        if (event.characterSing)
            charactersSing(note);

        if (event.playConfirm)
            note.targetReceptor.playAnimation("confirm", true);

        note.unheldTime = 0;
        onHold.dispatch(note);
    }

    override function unholdSustainNote(note:Note):Void {
        var event:NoteMissEvent = Events.get(NoteMissEvent).setup(note, true);
        _onMiss(event);

        if (event.cancelled)
            return;

        note.holdHealth = event.holdHealth;
        onMiss.dispatch(note);
    }

    override function invalidateHoldNote(note:Note):Void {
        var remainingLength:Float = note.length - (PlayState.self.conductor.time - note.time);
        var fraction:Float = (remainingLength / (PlayState.self.conductor.semiQuaver * 2)) + 1;

        var event:NoteHoldInvalidationEvent = Events.get(NoteHoldInvalidationEvent).setup(note, fraction);
        PlayState.self.scripts.dispatchEvent("onNoteHoldInvalidation", event);
        
        if (event.cancelled)
            return;

        PlayState.self.playField.incrementScore(-Math.floor(event.scoreLoss * event.fraction));
        PlayState.self.stats.health -= event.healthLoss * event.fraction;

        if (event.breakCombo)
            PlayState.self.stats.combo = 0;

        if (event.characterMiss)
            charactersMiss(note.direction);

        if (event.spectatorSad)
            makeSpectatorSad();
        
        if (event.playSound)
            playMissSound(event.soundVolume, event.soundVolDiff);

        PlayState.self.music.playerVolume = event.playerVolume;

        note.sustain.alpha *= 0.5; // TODO: event prop
        onHoldInvalidation.dispatch(note);
    }

    override function ghostPress(direction:Int):Void {
        var event:GhostPressEvent = Events.get(GhostPressEvent).setup(direction, ghostTapping || notes.length == 0);
        PlayState.self.scripts.dispatchEvent("onGhostPress", event);

        if (event.cancelled)
            return;

        if (event.playPress)
            playPress(event.direction);

        if (event.ghostTapping)
            return;

        PlayState.self.playField.incrementScore(-event.scoreLoss);
        PlayState.self.stats.health -= event.healthLoss;

        if (event.breakCombo)
            PlayState.self.stats.combo = 0;

        if (event.characterMiss)
            charactersMiss(event.direction);

        if (event.spectatorSad)
            makeSpectatorSad();

        if (event.playSound)
            playMissSound(event.soundVolume, event.soundVolDiff);

        PlayState.self.music.playerVolume = event.playerVolume;
        onGhostMiss.dispatch(event.direction);         
    }

    override function holdSustainNote(note:Note):Void {
        if (owner == PLAYER)
            PlayState.self.stats.health += note.holdHealth * FlxG.elapsed;

        super.holdSustainNote(note);
    }

    override function onKeyDown(rawKey:Int, _):Void {
        var key:Int = Tools.convertLimeKey(rawKey);
        var dir:Int = getDirFromKey(key);

        if (dir == -1 || pressedKeys[dir] || inactiveInputs)
            return;

        var event:NoteKeyActionEvent = PlayState.self.scripts.dispatchEvent("onKeyPress", Events.get(NoteKeyActionEvent).setup(key, dir));
        if (event.cancelled)
            return;

        pressedKeys[dir] = true;
        dir = event.direction;
        heldKeys[dir] = true;

        var targetNote:Note = notes.group.getFirst((note) -> note.direction == dir && note.isHittable());

        if (targetNote != null)
            handleNoteHit(targetNote);
        else
            ghostPress(dir);
    }

    override function onKeyUp(rawKey:Int, _):Void {
        var key:Int = Tools.convertLimeKey(rawKey);
        var dir:Int = getDirFromKey(key);

        if (dir == -1)
            return;

        var event:NoteKeyActionEvent = PlayState.self.scripts.dispatchEvent("onKeyRelease", Events.get(NoteKeyActionEvent).setup(key, dir));
        if (event.cancelled)
            return;

        pressedKeys[dir] = false;
        dir = event.direction;
        heldKeys[dir] = false;
        playStatic(dir);

        if (!heldKeys.contains(true)) {
            for (character in characters)
                if (character.animState == HOLDING)
                    character.animState = SINGING;
        }
    }

    function _onMiss(event:NoteMissEvent):Void {
        event.note.state = MISSED;
        PlayState.self.scripts.dispatchEvent("onMiss", event);

        if (event.cancelled)
            return;

        PlayState.self.playField.incrementScore(-event.scoreLoss);
        PlayState.self.stats.health -= event.healthLoss;

        if (event.breakCombo) 
            PlayState.self.stats.combo = 0;

        if (event.increaseMisses) 
            PlayState.self.playField.incrementMisses();

        if (event.decreaseAccuracy)
            PlayState.self.playField.incrementAccuracy(0);

        if (event.playSound)
            playMissSound(event.soundVolume, event.soundVolDiff);

        if (event.characterMiss)
            charactersMiss(event.note.direction);

        if (event.spectatorSad)
            makeSpectatorSad();

        PlayState.self.music.playerVolume = event.playerVolume;
    }

    function makeSpectatorSad():Void {
        if (PlayState.self.spectator?.animation.exists("sad"))
            PlayState.self.spectator.playSpecialAnim("sad", Conductor.self.crotchet);
    }

    inline function playMissSound(volume:Float = 0.1, difference:Float = 0.1):Void {
        FlxG.sound.play(Assets.sound('gameplay/missnote${FlxG.random.int(1, 3)}'), FlxG.random.float(volume, volume + difference));
    }

    override function destroy():Void {
        pressedKeys = null;
        super.destroy();
    }
}
