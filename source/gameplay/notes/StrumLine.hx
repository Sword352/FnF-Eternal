package gameplay.notes;

import flixel.tweens.*;
import flixel.util.FlxSignal;
import flixel.group.FlxSpriteGroup;
import gameplay.notes.Sustain;
import globals.NoteSkin;

/**
 * Sprite group which manages notes, sustains, splashes and receptors, all into a single object.
 * TODO: Find a solution to fix some script callbacks being repeatedly called after cancellation:
 * - `onHoldInvalidation` (`game_invalidateHoldNote`)
 * - `onMiss` when a hold note is not being held or is late (`game_lateNoteBehaviour` / `game_unheldSustainBehaviour`)
 * - `onNoteHit` when `cpu` is true (`game_noteHitBehaviour`)
 */
class StrumLine extends FlxSpriteGroup {
    /**
     * Notes contained in this strumline.
     */
    public var notes:FlxTypedSpriteGroup<Note>;

    /**
     * Sustains contained in this strumline.
     */
    public var sustains:FlxTypedSpriteGroup<Sustain>;

    /**
     * Receptors of this strumline.
     */
    public var receptors:FlxTypedSpriteGroup<Receptor>;

    /**
     * Splash group of this strumline.
     */
    public var splashes:FlxTypedSpriteGroup<Splash>;

    /**
     * Hold cover group of this strumline.
     */
    public var holdCovers:FlxTypedSpriteGroup<HoldCover>;

    /**
     * Spacing between each receptors of this strumline.
     */
    public var receptorSpacing(default, set):Float = 112;

    /**
     * Defines whether notes move from top to bottom, instead of bottom to top.
     */
    public var downscroll:Bool = Options.downscroll;

    /**
     * Defines the note movement speed.
     */
    public var scrollSpeed:Float = 1;

    /**
     * Characters tied to this strumline.
     */
    public var characters:Array<Character> = [];

    /**
     * Noteskin of this strumline.
     */
    public var skin(default, set):String;

    /**
     * Defined by the noteskin, this tells whether splashes are disabled.
     */
    public var splashDisabled:Bool = false;

    /**
     * Defines whether notes are automatically hit.
     */
    public var cpu(default, set):Bool = false;

    /**
     * Directions held by the player.
     */
    public var heldKeys:Array<Bool> = [false, false, false, false];

    /**
     * If false, the player misses if a key has been pressed while there's no notes on screen.
     */
    public var ghostTapping:Bool = Options.ghostTapping;

    /**
     * Set this to true if you wish to disable inputs.
     */
    public var inactiveInputs:Bool = false;

    /**
     * Map defining keys and it's directions for player inputs (`key => direction`).
     */
    public var keys:Map<Int, Int>;

    /**
     * Defines the time in milliseconds in which the player can release a hold note without missing it, just before it ends.
     */
    public var releaseImmunityTime:Float = 50;

    /**
     * Signal dispatched when a note has been hit.
     */
    public var onNoteHit:NoteSignal = new NoteSignal();

    /**
     * Signal dispatched each steps when a sustain is being held.
     */
    public var onHold:NoteSignal = new NoteSignal();

    /**
     * Signal dispatched when a hold note can no longer be hit.
     */
    public var onHoldInvalidation:NoteSignal = new NoteSignal();

    /**
     * Signal dispatched when a note is missed.
     */
    public var onMiss:NoteSignal = new NoteSignal();

    /**
     * Signal dispatched when a ghost miss happens.
     */
    public var onGhostMiss:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

    /**
     * Internal array containing notes to remove this frame.
     */
    var notesToRemove:Array<Note> = [];

    /**
     * Used for legacy base game behaviour.
     */
    var lastStep:Int = 0;

    /**
     * Creates a new `StrumLine`.
     * @param x Initial `x` position.
     * @param y Initial `y` position.
     * @param cpu Defines whether notes are automatically hit.
     * @param skin Initial noteskin.
     */
    public function new(x:Float = 0, y:Float = 0, cpu:Bool = false, skin:String = "default"):Void {
        super(x, y);

        this.cpu = cpu;
        this.skin = skin;

        receptors = new FlxTypedSpriteGroup<Receptor>();
        add(receptors);

        splashes = new FlxTypedSpriteGroup<Splash>();
        holdCovers = new FlxTypedSpriteGroup<HoldCover>();
        add(splashes);

        // cache note splashes
        if (!Options.noNoteSplash && !cpu) {
            splashes.add(new Splash(skin)).kill();

            // don't cache the hold cover if we can't see them anyways
            if (!Options.holdBehindStrums)
                holdCovers.add(new HoldCover(skin)).kill();
        }

        sustains = new FlxTypedSpriteGroup<Sustain>();
        sustains.active = false;

        if (Options.holdBehindStrums)
            insert(0, sustains);
        else
            add(sustains);

        add(holdCovers);

        notes = new FlxTypedSpriteGroup<Note>();
        notes.active = false;
        add(notes);

        for (i in 0...4) {
            var receptor:Receptor = new Receptor(i, skin);
            receptor.x = receptorSpacing * (i - 2);
            receptor.parentStrumline = this;
            receptors.add(receptor);
        }
    }

    /**
     * Updates this strumline.
     */
    override function update(elapsed:Float):Void {
        notes.forEachAlive(noteBehaviour);
        super.update(elapsed);

        while (notesToRemove.length > 0)
            removeNote(notesToRemove.pop());

        lastStep = Conductor.self.step;
    }

    /**
     * Adds a note to this strumline.
     * @param note Note to add.
     */
    public function addNote(note:Note):Void {
        notes.add(note);

        if (note.sustain != null) {
            sustains.add(note.sustain);

            /*
            if (sustains.members.length > 1)
                sustains.members.sort(sortSustains);
            */
        }

        // sorting is not required I believe?
        /*
        if (notes.members.length > 1)
            notes.members.sort(sortNotes);
        */
    }

    /**
     * Removes a note from this strumline and kills it.
     * @param note Note to remove.
     */
    public function removeNote(note:Note):Void {
        if (note.sustain != null)
            sustains.remove(note.sustain, true);

        notes.remove(note, true);
        note.kill();
    }

    /**
     * Registers a note to remove. Used so that no notes are skipped from the loop in the update method.
     * @param note Note to remove
     */
    public inline function queueNoteRemove(note:Note):Void {
        notesToRemove.push(note);
    }

    /**
     * Hits a note.
     * The note either gets removed, or hidden if it's a hold note.
     * @param note Note to hit.
     */
    public function hitNote(note:Note):Void {
        note.beenHit = true;

        if (!note.holdable)
            queueNoteRemove(note);
        else {
            if (!cpu) resizeLength(note);
            if (!Options.holdBehindStrums && !Options.noNoteSplash) spawnCover(note);
            note.visible = false;
        }

        playConfirm(note.direction);
        singCharacters(note);
    }

    function noteBehaviour(note:Note):Void {
        if (cpu && note.canBeHit)
            noteHitBehaviour(note);

        if (!cpu && !note.beenHit && !note.missed && note.late)
            lateNoteBehaviour(note);

        if (note.lateKill && Conductor.self.time > note.time + note.length + (400 / note.getScrollSpeed()))
            queueNoteRemove(note);

        if (note.holdable && !note.finishedHold && (note.beenHit || note.missed)) {
            if (canHold(note)) {
                if (lastStep != Conductor.self.step || !note.beenHit)
                    heldSustainBehaviour(note);
            }
            else if (!note.missed)
                unheldSustainBehaviour(note);

            if (note.missed && !note.invalidatedHold) {
                note.unheldTime += FlxG.elapsed;
                if (note.invalidatedHold)
                    invalidateHoldNote(note);
            }

            if (Conductor.self.time >= note.time + note.length)
                finishHoldNote(note);
        }

        note.follow(getReceptor(note.direction));
        note.update(FlxG.elapsed);

        if (note.holdable && note.beenHit)
            note.clipSustain(getReceptor(note.direction));
    }

    function canHold(note:Note):Bool {
        // also returns true if the sustain has been held but was released a little bit earlier, to make inputs feel better and easier
        return !note.invalidatedHold && (cpu || heldKeys[note.direction] || (note.beenHit && Conductor.self.time >= note.time + note.length - releaseImmunityTime));
    }

    function noteHitBehaviour(note:Note):Void {
        if (PlayState.current != null)
            game_noteHitBehaviour(note);
        else {
            onNoteHit.dispatch(note);
            hitNote(note);
        }
    }

    function lateNoteBehaviour(note:Note):Void {
        if (PlayState.current != null) {
            game_lateNoteBehaviour(note);
            return;
        }

        if (note.holdable) {
            note.perfectHold = false;
            note.visible = false;
            // resizeLength(note);
        } else {
            note.alphaMult = 0.3;
        }
    
        note.missed = true;
        onMiss.dispatch(note);
    }

    function heldSustainBehaviour(note:Note):Void {
        if (PlayState.current != null) {
            game_heldSustainBehaviour(note);
            return;
        }

        if (note.holdCover == null && !Options.holdBehindStrums && !Options.noNoteSplash && !splashDisabled)
            spawnCover(note);

        note.beenHit = true;
        note.missed = false;
        note.unheldTime = 0;

        playConfirm(note.direction);
        singCharacters(note);

        onHold.dispatch(note);
    }

    function unheldSustainBehaviour(note:Note):Void {
        if (PlayState.current != null) {
            game_unheldSustainBehaviour(note);
            return;
        }

        if (note.holdCover != null) {
            note.holdCover.kill();
            note.holdCover = null;
        }

        note.beenHit = false;
        note.perfectHold = false;
        note.missed = true;

        onMiss.dispatch(note);
    }

    function invalidateHoldNote(note:Note):Void {
        if (PlayState.current != null)
            game_invalidateHoldNote(note);
        else
            onHoldInvalidation.dispatch(note);
    }

    function finishHoldNote(note:Note):Void {
        if (note.beenHit)
            queueNoteRemove(note);

        note.finishedHold = true;
    }

    /**
     * Method called when a key is pressed.
     */
    inline function onKeyDown(rawKey:Int, _):Void {
        var key:Int = Tools.convertLimeKey(rawKey);
        var dir:Int = getDirFromKey(key);

        if (dir == -1 || heldKeys[dir] || inactiveInputs) return;

        #if ENGINE_SCRIPTING
        // TODO: fix weird heldKeys handling (some keys may be ignored if the direction gets changed from a script)
        if (PlayState.current != null) {
            var event:NoteKeyActionEvent = PlayState.current.scripts.dispatchEvent("onKeyPress", Events.get(NoteKeyActionEvent).setup(key, dir));
            if (event.cancelled || heldKeys[event.direction]) return;
            dir = event.direction;
        }
        #end

        for (character in characters) character.holding = true;
        heldKeys[dir] = true;

        var possibleNotes:Array<Note> = notes.members.filter((note) -> note.direction == dir && note.canBeHit);
        var targetNote:Note = possibleNotes[0];

        if (targetNote != null)
            noteHitBehaviour(targetNote);
        else
            ghostPress(dir);
    }

    /**
     * Method called when a key is released.
     */
    inline function onKeyUp(rawKey:Int, _):Void {
        var key:Int = Tools.convertLimeKey(rawKey);
        var dir:Int = getDirFromKey(key);

        if (dir == -1) return;

        #if ENGINE_SCRIPTING
        if (PlayState.current != null) {
            var event:NoteKeyActionEvent = PlayState.current.scripts.dispatchEvent("onKeyRelease", Events.get(NoteKeyActionEvent).setup(key, dir));
            if (event.cancelled) return;
            dir = event.direction;
        }
        #end

        heldKeys[dir] = false;
        playStatic(dir);

        for (character in characters)
            character.holding = heldKeys.contains(true);
    }

    inline function ghostPress(direction:Int):Void {
        if (PlayState.current != null)
            game_ghostPress(direction);
        else {
            if (!ghostTapping) onGhostMiss.dispatch(direction);
            playPress(direction);
        }
    }

    // PLAYSTATE SPECIFIC BEHAVIOURS
    function game_noteHitBehaviour(note:Note):Void {
        var rating:Rating = note.findRating(PlayState.current.ratings);

        // TODO: maybe don't reference the strumlines?
        var event:NoteHitEvent = Events.get(NoteHitEvent).setup(
            note,
            this == PlayState.current.opponentStrumline,
            cpu,
            rating,
            (!cpu ? rating.scoreIncrement : 0),
            (this != PlayState.current.opponentStrumline ? rating.healthIncrement : 0),
            (!cpu ? rating.accuracyMod : 0),
            (!cpu && rating.displayCombo && PlayState.current.combo >= 10),
            (!cpu && rating.displaySplash && !Options.noNoteSplash),
            (!Options.holdBehindStrums && !Options.noNoteSplash),
            !cpu,
            !cpu,
            !cpu,
            !cpu,
            this == PlayState.current.playerStrumline || PlayState.current.music.voices.length == 1,
            !cpu,
            !cpu
        );

        PlayState.current.onNoteHit(event);

        if (event.cancelled) {
            // TODO: smarter way to do this
            if (!cpu) game_ghostPress(note.direction);
            return;
        }

        note.beenHit = true;

        if (!note.holdable) {
            if (event.removeNote)
                queueNoteRemove(note);
        }
        else {
            if (event.resizeLength) resizeLength(note);
            if (event.spawnCover) spawnCover(note);
            note.visible = event.noteVisible;
        }

        if (event.playConfirm)
            playConfirm(note.direction);

        if (event.characterSing)
            singCharacters(note);

        onNoteHit.dispatch(note);
    }

    function game_lateNoteBehaviour(note:Note):Void {
        var event:NoteMissEvent = Events.get(NoteMissEvent).setup(note);
        PlayState.current.onMiss(event);

        if (event.cancelled)
            return;

        if (note.holdable) {
            note.perfectHold = !event.breakPerfectHold;
            note.visible = event.noteVisible;
        } else {
            note.alphaMult = event.noteAlpha;
        }

        note.missed = true;
        onMiss.dispatch(note);
    }

    function game_heldSustainBehaviour(note:Note):Void {
        var event:NoteHoldEvent = Events.get(NoteHoldEvent).setup(
            note,
            this == PlayState.current.opponentStrumline,
            cpu,
            (this != PlayState.current.opponentStrumline ? 0.023 : 0),
            this == PlayState.current.playerStrumline || PlayState.current.music.voices.length == 1,
            (note.holdCover == null && !Options.holdBehindStrums && !Options.noNoteSplash && !splashDisabled)
        );

        PlayState.current.onNoteHold(event);

        if (event.cancelled)
            return;

        note.beenHit = true;
        note.missed = false;
        note.unheldTime = 0;

        if (event.spawnCover)
            spawnCover(note);

        if (event.playConfirm)
            playConfirm(note.direction);

        if (event.characterSing)
            singCharacters(note);

        onHold.dispatch(note);
    }

    function game_unheldSustainBehaviour(note:Note):Void {
        var event:NoteMissEvent = Events.get(NoteMissEvent).setup(note, true);
        PlayState.current.onMiss(event);

        if (event.cancelled)
            return;

        if (event.killCover && note.holdCover != null) {
            note.holdCover.kill();
            note.holdCover = null;
        }

        note.beenHit = false;
        note.perfectHold = !event.breakPerfectHold;
        note.missed = true;

        onMiss.dispatch(note);
    }

    function game_invalidateHoldNote(note:Note):Void {
        var remainingLength:Float = note.length - (PlayState.current.conductor.time - note.time);
        var fraction:Float = (remainingLength / (PlayState.current.conductor.stepCrochet * 2)) + 1;

        var event:NoteHoldInvalidationEvent = Events.get(NoteHoldInvalidationEvent).setup(note, fraction);
        PlayState.current.onNoteHoldInvalidation(event);

        if (event.cancelled) {
            note.unheldTime = 0;
            return;
        }

        onHoldInvalidation.dispatch(note);
    }

    function game_ghostPress(direction:Int):Void {
        var event:GhostPressEvent = Events.get(GhostPressEvent).setup(direction, ghostTapping);
        PlayState.current.onGhostPress(event);

        if (event.cancelled)
            return;

        if (event.playPress)
            playPress(event.direction);

        if (!event.ghostTapping)
            onGhostMiss.dispatch(event.direction);
    }
    //

    /**
     * Finds the corresponding direction for the passed key.
     */
    inline function getDirFromKey(key:Int):Int {
        return keys[key] ?? -1;
    }

    /**
     * Resizes the hold length of the passed note if the player has hit the note earlier or later.
     * The note gets removed if the new length is 0.
     */
    inline function resizeLength(note:Note):Void {
        note.length += (note.time - Conductor.self.time);
        note.time = Conductor.self.time;

        if (note.length == 0)
            removeNote(note);
    }

    /**
     * Makes this strumline's `characters` sing.
     * @param note Parent note.
     */
    public function singCharacters(note:Note):Void {
        if (note.noSingAnim) return;

        for (character in characters) {
            if (!note.holdable || !Options.noHoldStutter || character.animation.name != character.singAnimations[note.direction])
                character.sing(note.direction, note.animSuffix);
            else
                character.holdTime = 0;

            character.currentDance = 0;
        }
    }

    /**
     * Runs the start tween on all receptors of this strumline.
     */
    public function runStartTweens():Void {
        for (receptor in receptors) {
            receptor.alpha = 0;
            receptor.y -= 10;
            FlxTween.tween(receptor, {y: receptor.y + 10, alpha: 1}, 1, {
                startDelay: 0.5 + (0.2 * receptor.direction),
                ease: FlxEase.circOut
            });
        }
    }

    /**
     * Adds a splash to this strumline.
     * @param note Parent note.
     */
    public function popSplash(note:Note):Void {
        if (splashDisabled) return;

        var splash:Splash = splashes.recycle(Splash, splashConstructor);
        var receptor:Receptor = getReceptor(note.direction);
        splash.setPosition(receptor.x, receptor.y);
        splash.pop(note.direction);
    }

    /**
     * Adds a hold cover to this strumline.
     * @param note Parent note.
     */
    public function spawnCover(note:Note):Void {
        if (splashDisabled) return;

        var cover:HoldCover = holdCovers.recycle(HoldCover, holdCoverConstructor);
        cover.start(note);

        cover.centerToObject(getReceptor(note.direction));
        note.holdCover = cover;
    }

    inline function splashConstructor():Splash {
        return new Splash(skin);
    }

    inline function holdCoverConstructor():HoldCover {
        return new HoldCover(skin);
    }

    /*
    inline function sortNotes(a:Note, b:Note):Int {
        return Std.int(a.time - b.time);
    }

    inline function sortSustains(a:Sustain, b:Sustain):Int {
        return sortNotes(a.parent, b.parent);
    }
    */

    /**
     * Plays the press animation on the specified receptor.
     * @param direction The receptor's direction.
     */
    public inline function playPress(direction:Int):Void {
        getReceptor(direction).playAnimation("press", true);
    }

    /**
     * Plays the confirm animation on the specified receptor.
     * @param direction The receptor's direction.
     */
    public inline function playConfirm(direction:Int):Void {
        getReceptor(direction).playAnimation("confirm", true);
    }

    /**
     * Plays the static animation on the specified receptor.
     * @param direction The receptor's direction.
     */
    public inline function playStatic(direction:Int):Void {
        getReceptor(direction).playAnimation("static", true);
    }

    /**
     * Returns the receptor matching the passed direction.
     * @param direction Direction to check.
     */
    public inline function getReceptor(direction:Int):Receptor {
        return receptors.members[direction];
    }

    inline function enableInputs():Void {
        // inputs are already enabled, don't add them again
        if (keys != null) return;

        // register key listeners
        FlxG.stage.application.window.onKeyDown.add(onKeyDown);
        FlxG.stage.application.window.onKeyUp.add(onKeyUp);

        // and map the keys
        keys = [
            for (i in 0...Note.directions.length)
                for (key in Controls.global.keybinds[Note.directions[i]][0])
                    key => i
        ];
    }

    inline function disableInputs():Void {
        // inputs are already disabled, don't remove them again
        if (keys == null) return;

        // remove the key listeners
        FlxG.stage.application.window.onKeyDown.remove(onKeyDown);
        FlxG.stage.application.window.onKeyUp.remove(onKeyUp);

        // and clear the keys
        keys = null;
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        onHoldInvalidation = cast FlxDestroyUtil.destroy(onHoldInvalidation);
        onHold = cast FlxDestroyUtil.destroy(onHold);

        onNoteHit = cast FlxDestroyUtil.destroy(onNoteHit);
        onGhostMiss = cast FlxDestroyUtil.destroy(onGhostMiss);
        onMiss = cast FlxDestroyUtil.destroy(onMiss);

        notesToRemove = null;
        characters = null;
        heldKeys = null;
        skin = null;

        disableInputs();
        super.destroy();
    }

    // Setter methods

    function set_cpu(v:Bool):Bool {
        if (!v)
            enableInputs();
        else
            disableInputs();

        return cpu = v;
    }

    function set_skin(v:String):String {
        if (v != null) {
            receptors?.forEach((r) -> r.skin = v);

            switch (v) {
                case "default":
                    receptorSpacing = 112;
                    splashDisabled = false;
                default:
                    var noteSkin:NoteSkinConfig = NoteSkin.get(v);
                    receptorSpacing = noteSkin?.receptor?.spacing ?? 112;
                    splashDisabled = noteSkin?.disableSplashes ?? false;
            }
        }

        return skin = v;
    }

    function set_receptorSpacing(v:Float):Float {
        receptors?.forEach((r) -> r.x = x + (v * (r.direction - 2)));
        return receptorSpacing = v;
    }
}

typedef NoteSignal = FlxTypedSignal<Note->Void>;
