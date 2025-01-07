package funkin.gameplay.notes;

import flixel.util.FlxSignal;
import flixel.group.FlxSpriteGroup;
import funkin.gameplay.notes.Sustain;
import funkin.gameplay.components.Character;
import funkin.data.NoteSkin;

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
     * Determines whether notes are automatically processed.
     */
    public var cpu(default, set):Bool = false;
    
    /**
     * Defines the owner of this strumline.
     */
    public var owner:StrumLineOwner = OPPONENT;

    /**
     * Directions held by the player.
     */
    public var heldKeys:Array<Bool> = [false, false, false, false];

    /**
     * If false, the player misses if a key has been pressed while all notes present on screen aren't hittable yet.
     */
    public var ghostTapping:Bool = Options.ghostTapping;

    /**
     * Flag determining whether inputs should be ignored.
     * Useful to pause inputs for substates and such.
     */
    public var inactiveInputs:Bool = false;

    /**
     * Map defining keys and their corresponding directions for player inputs (`key => direction`).
     */
    public var keys:Map<Int, Int>;

    /**
     * Determines the time in milliseconds in which the player can release a hold note without missing it, just before it ends.
     */
    public var releaseImmunityTime:Float = 50;

    /**
     * Determines whether notes moves from top to bottom, instead of bottom to top.
     */
    public var downscroll:Bool = Options.downscroll;

    /**
     * Determines the note movement speed.
     */
    public var scrollSpeed(default, set):Float = 1;

    /**
     * Characters singing according to the notes of this strumline.
     */
    public var characters:Array<Character> = [];

    /**
     * Noteskin of this strumline.
     */
    public var skin(default, set):String;

    /**
     * Spacing between each receptors of this strumline.
     */
    public var receptorSpacing(default, set):Float = 112;
 
    /**
     * Defined by the noteskin, flag defining whether splashes are disabled.
     */
    public var splashDisabled:Bool = false;

    /**
     * Signal dispatched when a note has been hit.
     */
    public var onNoteHit:NoteSignal = new NoteSignal();

    /**
     * Signal dispatched when a note has been missed.
     */
    public var onMiss:NoteSignal = new NoteSignal();

    /**
     * Signal dispatched when a hold note is being held.
     */
    public var onHold:NoteSignal = new NoteSignal();

    /**
     * Signal dispatched when a hold note is no longer valid to be held.
     */
    public var onHoldInvalidation:NoteSignal = new NoteSignal();

    /**
     * Signal dispatched when a ghost miss happens.
     */
    public var onGhostMiss:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

    /**
     * Internal array containing notes to remove this frame.
     */
    var _notesToRemove:Array<Note> = [];

    /**
     * Stores the last step for sustain holding behaviour.
     */
    var _lastStep:Int = 0;

    /**
     * Creates a new `StrumLine`.
     * @param x Initial `x` position.
     * @param y Initial `y` position.
     * @param cpu Determines whether notes are automatically processed.
     * @param owner Defines this strumline's owner.
     * @param skin Initial noteskin.
     */
    public function new(x:Float = 0, y:Float = 0, cpu:Bool = false, skin:String = "default"):Void {
        super(x, y);

        this.cpu = cpu;
        this.skin = skin;

        sustains = new FlxTypedSpriteGroup<Sustain>();
        sustains.active = false;
        group.add(sustains);

        receptors = new FlxTypedSpriteGroup<Receptor>();
        add(receptors);

        notes = new FlxTypedSpriteGroup<Note>();
        notes.active = false;
        group.add(notes);

        splashes = new FlxTypedSpriteGroup<Splash>();
        group.add(splashes);

        // prepare the note splash pool
        if (!Options.noNoteSplash && !cpu)
            splashes.add(new Splash(skin)).kill();

        for (i in 0...4) {
            var receptor:Receptor = new Receptor(i, skin);
            receptor.x = receptorSpacing * (i - 2);
            receptor.strumLine = this;
            receptors.add(receptor);
        }
    }

    /**
     * Updates this strumline.
     */
    override function update(elapsed:Float):Void {
        notes.forEachAlive(updateNote);
        group.update(elapsed);

        while (_notesToRemove.length > 0)
            removeNote(_notesToRemove.pop());

        _lastStep = Conductor.self.step;
    }

    /**
     * Adds a note to this strumline.
     * @param note Note to add.
     */
    public function addNote(note:Note):Void {
        notes.group.add(note);

        if (note.sustain != null)
            sustains.group.add(note.sustain);
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
     * Registers a note to remove.
     * @param note Note to remove.
     */
    public inline function queueNoteRemoval(note:Note):Void {
        _notesToRemove.push(note);
    }

    /**
     * Adds a character to this strumline.
     * @param character Character to add.
     */
    public inline function addCharacter(character:Character):Void {
        if (character != null)
            characters.push(character);
    }

    /**
     * Removes a character from this strumline.
     * @param character Character to remove.
     */
    public inline function removeCharacter(character:Character):Void {
        characters.remove(character);
    }

    /**
     * Handles the gameplay note logic.
     */
    function updateNote(note:Note):Void {
        if (cpu && note.isHittable())
            handleNoteHit(note);

        if (!cpu && note.state == NONE && note.isLate())
            handleLateNote(note);

        // the note has to be late in order to kill it, else it won't be considered a miss
        if (note.lateKill && note.isLate() && Conductor.self.time > note.time + note.length + (400 / (scrollSpeed / Conductor.self.rate)))
            queueNoteRemoval(note);

        if (note.isHoldable() && note.state != NONE && !note.finishedHold) {
            if (canHold(note))
                holdSustainNote(note);
            else if (!note.missed)
                unholdSustainNote(note);

            if (note.missed && !note.isHoldWindowLate()) {
                note.unheldTime += FlxG.elapsed;
                if (note.isHoldWindowLate())
                    invalidateHoldNote(note);
            }

            if (Conductor.self.time >= note.time + note.length)
                finishHoldNote(note);
        }

        if (note.active)
            note.update(FlxG.elapsed);
    }

    /**
     * Method called to handle note behaviour.
     */
    function handleNoteHit(note:Note):Void {
        note.state = BEEN_HIT;

        if (!note.isHoldable())
            queueNoteRemoval(note);
        else
            note.visible = false;

        note.targetReceptor.playAnimation("confirm", true);
        charactersSing(note);

        onNoteHit.dispatch(note);

        // only resize the length here as it changes the note's time and length
        if (note.isHoldable() && !cpu)
            resizeLength(note);
    }

    /**
     * Method called to handle late note behaviour.
     */
    function handleLateNote(note:Note):Void {
        if (note.isHoldable())
            note.visible = false;
        else
            note.alpha = 0.3;

        note.state = MISSED;
        charactersMiss(note.direction);
        onMiss.dispatch(note);
    }

    /**
     * Method called to handle sustain note holding behaviour.
     */
    function holdSustainNote(note:Note):Void {
        if (_lastStep != Conductor.self.step || !note.beenHit)
            handleSustainNote(note);
    }

    function handleSustainNote(note:Note):Void {
        if (note.missed)
            charactersSing(note);

        note.state = BEEN_HIT;
        note.unheldTime = 0;

        note.targetReceptor.playAnimation("confirm", true);
        onHold.dispatch(note);
    }

    /**
     * Method called to handle sustain unholding beaviour.
     */
    function unholdSustainNote(note:Note):Void {
        note.state = MISSED;
        charactersMiss(note.direction);
        onMiss.dispatch(note);
    }

    /**
     * Method called to handle ghost presses.
     */
    function ghostPress(direction:Int):Void {
        playPress(direction);

        if (!ghostTapping && notes.length > 0) {
            charactersMiss(direction);
            onGhostMiss.dispatch(direction);
        }
    }

    /**
     * Method called to handle sustain note invalidation behaviour.
     */
    function invalidateHoldNote(note:Note):Void {
        note.sustain.alpha *= 0.5;
        charactersMiss(note.direction);
        onHoldInvalidation.dispatch(note);
    }

    /**
     * Declares a hold note as finished, meaning it can't be held anymore.
     */
    function finishHoldNote(note:Note):Void {
        if (note.beenHit)
            queueNoteRemoval(note);

        note.finishedHold = true;
    }

    /**
     * Returns whether we can hold a sustain note.
     * @param note Target note.
     * @return Bool
     */
    inline function canHold(note:Note):Bool {
        // this also allows to release the sustain note a bit earlier to make inputs easier
        return !note.isHoldWindowLate() && (cpu || heldKeys[note.direction] || (note.beenHit && Conductor.self.time >= note.time + note.length - releaseImmunityTime));
    }

    /**
     * Method called when a key is pressed.
     */
    function onKeyDown(rawKey:Int, _):Void {
        var key:Int = Tools.convertLimeKey(rawKey);
        var dir:Int = getDirFromKey(key);

        if (dir == -1 || heldKeys[dir] || inactiveInputs) 
            return;

        heldKeys[dir] = true;

        var targetNote:Note = notes.group.getFirst((note) -> note.direction == dir && note.isHittable());

        if (targetNote != null)
            handleNoteHit(targetNote);
        else
            ghostPress(dir);
    }

    /**
     * Method called when a key is released.
     */
    function onKeyUp(rawKey:Int, _):Void {
        var key:Int = Tools.convertLimeKey(rawKey);
        var dir:Int = getDirFromKey(key);

        if (dir == -1) 
            return;

        heldKeys[dir] = false;
        playStatic(dir);

        if (!heldKeys.contains(true)) {
            for (character in characters)
                if (character.animState == HOLDING)
                    character.animState = SINGING;
        }
    }

    /**
     * Finds the corresponding direction for the passed key.
     */
    inline function getDirFromKey(key:Int):Int {
        return keys[key] ?? -1;
    }

    /**
     * Resizes the hold length of the passed note if the player has hit the note earlier or later.
     */
    function resizeLength(note:Note):Void {
        note.length += (note.time - Conductor.self.time);
        note.time = Conductor.self.time;
    }

    /**
     * Makes all of this strumline's characters play a sing animation.
     * @param note Parent note.
     */
    function charactersSing(note:Note):Void {
        for (character in characters) {
            character.playSingAnim(note.direction);

            if (!cpu)
                character.animState = HOLDING;

            if (note.isHoldable())
                character.animDuration = note.length - Math.max(Conductor.self.time - note.time, 0) + Conductor.self.crotchet;
        }
    }

    /**
     * Makes all of this strumline's characters play a miss animation.
     * @param direction Direction.
     */
    function charactersMiss(direction:Int):Void {
        for (character in characters)
            character.playMissAnim(direction);
    }

    /**
     * Adds a splash to this strumline.
     * @param note Parent note.
     */
    public function popSplash(note:Note):Void {
        if (splashDisabled) return;

        var splash:Splash = splashes.recycle(Splash, splashConstructor);
        var receptor:Receptor = note.targetReceptor;
        splash.setPosition(receptor.x, receptor.y);
        splash.pop(note.direction);
    }

    inline function splashConstructor():Splash {
        return new Splash(skin);
    }

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

    function enableInputs():Void {
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

    function disableInputs():Void {
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

        _notesToRemove = null;
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

    function set_scrollSpeed(v:Float):Float {
        scrollSpeed = Math.abs(v);
        return v;
    }
}

/**
 * Determines the owner of a strumline.
 */
enum abstract StrumLineOwner(Int) from Int to Int {
    var OPPONENT = 0;
    var PLAYER = 1;
}

private typedef NoteSignal = FlxTypedSignal<Note->Void>;
