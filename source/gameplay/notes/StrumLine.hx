package gameplay.notes;

import flixel.tweens.*;
import flixel.util.FlxSignal;
import flixel.group.FlxSpriteGroup;
import gameplay.notes.Sustain;
import globals.NoteSkin;

/**
 * Sprite group which manages notes, sustains, splashes and receptors, all into a single object.
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
     * Signal dispatched when a ghost key hit happens.
     */
    public var onGhostPress:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

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
     * Hits the passed note.
     * The note either gets removed, or hidden if it's a hold note.
     * @param note Note to hit.
     */
    public function hitNote(note:Note):Void {
        note.beenHit = true;

        if (!note.holdable)
            notesToRemove.push(note);
        else {
            if (!cpu) resizeLength(note);
            if (!Options.holdBehindStrums) spawnCover(note);
            note.visible = false;
        }

        playConfirm(note.direction);
        singCharacters(note);
    }

    inline function noteBehaviour(note:Note):Void {
        if (cpu && !note.avoid && note.canBeHit)
            cpuBehaviour(note);

        if (!cpu && !note.beenHit && !note.missed && note.late)
            lateNoteBehaviour(note);

        if ((note.missed || note.avoid || note.holdable) && Conductor.self.time > note.time + note.length + (400 / note.getScrollSpeed()))
            notesToRemove.push(note);

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

    inline function canHold(note:Note):Bool {
        // also returns true if the sustain has been held but was released a little bit earlier, to make inputs feel better and easier
        return !note.invalidatedHold && (cpu || heldKeys[note.direction] || (note.beenHit && Conductor.self.time >= note.time + note.length - releaseImmunityTime));
    }

    inline function cpuBehaviour(note:Note):Void {
        onNoteHit.dispatch(note);
        hitNote(note);
    }

    inline function lateNoteBehaviour(note:Note):Void {
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

    inline function heldSustainBehaviour(note:Note):Void {
        if (note.holdCover == null && !Options.holdBehindStrums && !splashDisabled)
            spawnCover(note);

        note.beenHit = true;
        note.missed = false;
        note.unheldTime = 0;

        playConfirm(note.direction);
        singCharacters(note);

        onHold.dispatch(note);
    }

    inline function unheldSustainBehaviour(note:Note):Void {
        if (note.holdCover != null) {
            note.holdCover.kill();
            note.holdCover = null;
        }

        note.beenHit = false;
        note.perfectHold = false;
        note.missed = true;

        onMiss.dispatch(note);
    }

    inline function finishHoldNote(note:Note):Void {
        if (note.beenHit)
            notesToRemove.push(note);

        note.finishedHold = true;
    }

    inline function invalidateHoldNote(note:Note):Void {
        onHoldInvalidation.dispatch(note);
    }

    /**
     * Method called when a key is pressed.
     */
    inline function onKeyDown(rawKey:Int, _):Void {
        var key:Int = Tools.convertLimeKey(rawKey);
        var dir:Int = getDirFromKey(key);

        if (dir == -1 || heldKeys[dir] || inactiveInputs) return;

        #if ENGINE_SCRIPTING
        if (PlayState.current?.cancellableCall("onKeyPress", [key, dir]))
            return;
        #end

        for (character in characters) character.holding = true;
        heldKeys[dir] = true;

        var possibleNotes:Array<Note> = notes.members.filter((note) -> note.direction == dir && note.canBeHit);
        var noteToHit:Note = possibleNotes[0];

        if (noteToHit != null) {
            onNoteHit.dispatch(noteToHit);
            hitNote(noteToHit);
        }
        else {
            if (!ghostTapping) onGhostPress.dispatch(dir);
            playPress(dir);
        }
    }

    /**
     * Method called when a key is released.
     */
    inline function onKeyUp(rawKey:Int, _):Void {
        var key:Int = Tools.convertLimeKey(rawKey);
        var dir:Int = getDirFromKey(key);

        if (dir == -1) return;

        #if ENGINE_SCRIPTING
        if (PlayState.current?.cancellableCall("onKeyRelease", [key, dir]))
            return;
        #end

        heldKeys[dir] = false;
        playStatic(dir);

        for (character in characters)
            character.holding = heldKeys.contains(true);
    }

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
        onGhostPress = cast FlxDestroyUtil.destroy(onGhostPress);
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
