package funkin.gameplay.notes;

/**
 * Special `StrumLine` which handles extra gameplay logic for `PlayState`.
 * This object dispatches the following event(s):
 * - `GameEvents.NOTE_HIT`
 * - `GameEvents.NOTE_HOLD`
 * - `GameEvents.NOTE_HOLD_INVALIDATION`
 * - `GameEvents.GHOST_PRESS`
 * - `GameEvents.NOTE_KEY_PRESS`
 * - `GameEvents.NOTE_KEY_RELEASE`
 * - `GameEvents.NOTE_MISS`
 */
@:build(funkin.core.macros.ScriptMacros.buildEventDispatcher())
class GameStrumLine extends StrumLine {
    /**
     * Since the processed direction in `onKeyDown` and `onKeyUp` can be changed with an event, 
     * it messes with sustain holding since `heldKeys` is shared for both input checks and sustain holding.
     * This array allows us to handle these separatly.
     */
    var pressedKeys:Array<Bool> = [false, false, false, false];

    /**
     * Cached note hit event object.
     */
    var _noteHitEvent:NoteHitEvent = new NoteHitEvent();

    /**
     * Cached note miss event object.
     */
    var _noteMissEvent:NoteMissEvent = new NoteMissEvent();

    /**
     * Cached note hold invalidation event object.
     */
    var _noteHoldMissEvent:NoteHoldInvalidationEvent = new NoteHoldInvalidationEvent();

    /**
     * Cached note hold event object.
     */
    var _noteHoldEvent:NoteHoldEvent = new NoteHoldEvent();

    /**
     * Cached ghost press event object.
     */
    var _ghostPressEvent:GhostPressEvent = new GhostPressEvent();

    /**
     * Cached note input event object.
     */
    var _inputEvent:NoteInputEvent = new NoteInputEvent();

    override function handleNoteHit(note:Note):Void {
        note.state = BEEN_HIT;

        var game:PlayState = PlayState.self;
        var prevCombo:Int = game.stats.combo;

        dispatchEvent(GameEvents.NOTE_HIT, _noteHitEvent.reset(note, game.stats.combo));
        if (_noteHitEvent.cancelled) return;

        note.holdHealth = _noteHitEvent.holdHealth;
        game.playField.incrementScore(_noteHitEvent.score);
        game.stats.health += _noteHitEvent.health;
        game.stats.combo = _noteHitEvent.combo;

        if (_noteHitEvent.rating != null) {
            _noteHitEvent.rating.hits++;
            game.playField.displayJudgement(_noteHitEvent.rating);
        }

        if (_noteHitEvent.accuracy != null)
            game.playField.incrementAccuracy(_noteHitEvent.accuracy);

        if (game.stats.combo > prevCombo)
            game.playField.displayCombo(game.stats.combo);

        if (_noteHitEvent.displaySplash)
            popSplash(note);

        if (_noteHitEvent.unmutePlayer)
            game.music.playerVolume = 1;

        if (note.isHoldable())
            note.visible = _noteHitEvent.noteVisible;
        else if (_noteHitEvent.removeNote)
            queueNoteRemoval(note);

        if (_noteHitEvent.playConfirm)
            note.targetReceptor.playAnimation("confirm", true);

        if (_noteHitEvent.characterSing)
            charactersSing(note);

        onNoteHit.dispatch(note);

        if (note.isHoldable() && !cpu)
            resizeLength(note);
    }

    override function handleLateNote(note:Note):Void {
        _onMiss(_noteMissEvent.reset(note, false));
        if (_noteMissEvent.cancelled) return;

        if (note.isHoldable())
            note.visible = _noteMissEvent.noteVisible;
        else
            note.alpha = _noteMissEvent.noteAlpha;

        onMiss.dispatch(note);
    }

    override function handleSustainNote(note:Note):Void {
        dispatchEvent(GameEvents.NOTE_HOLD, _noteHoldEvent.reset(note));
        note.state = BEEN_HIT;

        if (_noteHoldEvent.cancelled) return;

        if (_noteHoldEvent.unmutePlayer)
            PlayState.self.music.playerVolume = 1;

        if (_noteHoldEvent.characterSing)
            charactersSing(note);

        if (_noteHoldEvent.playConfirm)
            note.targetReceptor.playAnimation("confirm", true);

        note.unheldTime = 0;
        onHold.dispatch(note);
    }

    override function unholdSustainNote(note:Note):Void {
        _onMiss(_noteMissEvent.reset(note, true));
        if (_noteMissEvent.cancelled) return;
        onMiss.dispatch(note);
    }

    override function invalidateHoldNote(note:Note):Void {
        dispatchEvent(GameEvents.NOTE_HOLD_INVALIDATION, _noteHoldMissEvent.reset(note));
        if (_noteHoldMissEvent.cancelled) return;

        var game:PlayState = PlayState.self;
        game.playField.incrementScore(-Math.floor(_noteHoldMissEvent.scoreLoss * _noteHoldMissEvent.fraction));
        game.stats.health -= _noteHoldMissEvent.healthLoss * _noteHoldMissEvent.fraction;

        if (_noteHoldMissEvent.breakCombo)
            game.stats.combo = 0;

        if (_noteHoldMissEvent.characterMiss)
            charactersMiss(note.direction);

        if (_noteHoldMissEvent.spectatorSad)
            makeSpectatorSad();
        
        if (_noteHoldMissEvent.playSound)
            playMissSound();

        if (_noteHoldMissEvent.mutePlayer)
            game.music.playerVolume = 0;

        note.sustain.alpha *= _noteHoldMissEvent.alphaMultiplier;
        onHoldInvalidation.dispatch(note);
    }

    override function ghostPress(direction:Int):Void {
        dispatchEvent(GameEvents.GHOST_PRESS, _ghostPressEvent.reset(direction, ghostTapping || notes.length == 0));
        if (_ghostPressEvent.cancelled) return;

        if (_ghostPressEvent.playPress) playPress(_ghostPressEvent.direction);
        if (_ghostPressEvent.ghostTapping) return;

        var game:PlayState = PlayState.self;

        game.playField.incrementScore(-_ghostPressEvent.scoreLoss);
        game.stats.health -= _ghostPressEvent.healthLoss;

        if (_ghostPressEvent.breakCombo)
            game.stats.combo = 0;

        if (_ghostPressEvent.characterMiss)
            charactersMiss(_ghostPressEvent.direction);

        if (_ghostPressEvent.spectatorSad)
            makeSpectatorSad();

        if (_ghostPressEvent.playSound)
            playMissSound();

        if (_ghostPressEvent.mutePlayer)
            game.music.playerVolume = 0;

        onGhostMiss.dispatch(_ghostPressEvent.direction);         
    }

    override function holdSustainNote(note:Note):Void {
        PlayState.self.stats.health += note.holdHealth * FlxG.elapsed;
        super.holdSustainNote(note);
    }

    override function onKeyDown(rawKey:Int, _):Void {
        var key:Int = Tools.convertLimeKey(rawKey);
        var dir:Int = getDirFromKey(key);

        if (dir == -1 || pressedKeys[dir] || inactiveInputs) return;

        dispatchEvent(GameEvents.NOTE_KEY_PRESS, _inputEvent.reset(key, dir));
        if (_inputEvent.cancelled) return;

        pressedKeys[dir] = true;
        dir = _inputEvent.direction;
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
        if (dir == -1) return;

        dispatchEvent(GameEvents.NOTE_KEY_RELEASE, _inputEvent.reset(key, dir));
        if (_inputEvent.cancelled) return;

        pressedKeys[dir] = false;
        dir = _inputEvent.direction;
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
        dispatchEvent(GameEvents.NOTE_MISS, event);
        if (event.cancelled) return;

        var game:PlayState = PlayState.self;
        game.playField.incrementScore(-event.scoreLoss);
        game.playField.incrementMisses();
        game.stats.health -= event.healthLoss;
        game.stats.combo = 0;

        if (event.decreaseAccuracy)
            game.playField.incrementAccuracy(0);

        if (event.playSound)
            playMissSound();

        if (event.characterMiss)
            charactersMiss(event.note.direction);

        if (event.spectatorSad)
            makeSpectatorSad();

        if (event.mutePlayer)
            game.music.playerVolume = 0;

        event.note.holdHealth = event.holdHealth;
    }

    function makeSpectatorSad():Void {
        if (PlayState.self.spectator?.animation.exists("sad"))
            PlayState.self.spectator.playSpecialAnim("sad", Conductor.self.beatLength);
    }

    inline function playMissSound():Void {
        FlxG.sound.play(Paths.sound('gameplay/missnote${FlxG.random.int(1, 3)}'), FlxG.random.float(0.1, 0.2));
    }

    override function destroy():Void {
        _noteHitEvent = FlxDestroyUtil.destroy(_noteHitEvent);
        _noteMissEvent = FlxDestroyUtil.destroy(_noteMissEvent);
        _noteHoldEvent = FlxDestroyUtil.destroy(_noteHoldEvent);
        _noteHoldMissEvent = FlxDestroyUtil.destroy(_noteHoldMissEvent);
        _ghostPressEvent = FlxDestroyUtil.destroy(_ghostPressEvent);
        _inputEvent = FlxDestroyUtil.destroy(_inputEvent);

        pressedKeys = null;
        super.destroy();
    }
}
