package gameplay.notes;

import flixel.tweens.*;
import flixel.util.FlxSignal;
import flixel.group.FlxSpriteGroup;
import gameplay.notes.Note.Sustain;
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
     * Splash pool of this strumline.
     */
    public var splashes:FlxTypedSpriteGroup<Splash>;

    /**
     * Spacing between each receptors of this strumline.
     */
    public var receptorSpacing(default, set):Float = 112;

    /**
     * Defines whether the notes go from top to bottom, instead of bottom to top.
     */
    public var downscroll:Bool = Options.downscroll;

    /**
     * Defines how fast the notes moves.
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
     * Directions held by the player. Only matters if `cpu` is equal to false.
     */
    public var holdKeys:Array<Bool> = [false, false, false, false];

    /**
     * If false, the player misses if a key has been pressed while there's no notes on screen.
     */
    public var ghostTap:Bool = Options.ghostTapping;

    /**
     * Defines whether notes are automatically hit.
     */
    public var cpu:Bool = false;

    /**
     * Signal dispatched when a note has been hit. Only matters if `cpu` is equal to true.
     */
    public var onNoteHit:NoteSignal = new NoteSignal();

    /**
     * Signal dispatched each steps when a sustain is being held.
     */
    public var onHold:NoteSignal = new NoteSignal();

    /**
     * Signal dispatched when a note is missed. Only matters if `cpu` is equal to false.
     */
    public var onMiss:NoteSignal = new NoteSignal();

    /**
     * Internal array containing notes to remove this frame.
     */
    var notesToRemove:Array<Note> = [];

    /**
     * Used for legacy base game behaviour.
     */
    var lastStep:Int = 0;

    /**
     * Creates a new `StrumLine`
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
        add(splashes);

        // cache note splashes
        if (!Options.noNoteSplash && !cpu) {
            var cache:Splash = new Splash(skin);
            splashes.add(cache);
            cache.kill();
        }

        sustains = new FlxTypedSpriteGroup<Sustain>();
        sustains.active = false;

        if (Options.holdBehindStrums)
            insert(0, sustains);
        else
            add(sustains);

        notes = new FlxTypedSpriteGroup<Note>();
        notes.active = false;
        add(notes);

        for (i in 0...4) {
            var receptor:Receptor = new Receptor(i, skin);
            receptor.x = receptorSpacing * (i - 2);
            receptors.add(receptor);
        }
    }

    /**
     * Updates this strumline.
     */
    override function update(elapsed:Float):Void {
        notes.forEachAlive((note) -> {
            var receptor:Receptor = receptors.members[note.direction];

            if (cpu && note.canBeHit && !note.avoid) {
                note.goodHit = true;
                onNoteHit.dispatch(note);

                receptor.playAnimation("confirm", true);
                singCharacters(note);

                hitNote(note);
            }

            if (!cpu && note.late && !note.missed && !note.goodHit)
                miss(note);

            if ((note.avoid || note.missed || note.isSustainNote) && Conductor.self.time > note.time + note.length + (400 / note.getScrollSpeed()))
                notesToRemove.push(note);

            if (note.isSustainNote && (note.goodHit || note.missed)) {
                if (lastStep != Conductor.self.step) {
                    if (cpu || holdKeys[note.direction]) {
                        receptor.playAnimation("confirm", true);
                        singCharacters(note);
                        onHold.dispatch(note);
                    } else
                        onMiss.dispatch(note);
                }

                if (Conductor.self.time >= note.time + note.length && (cpu || holdKeys[note.direction]))
                    notesToRemove.push(note);
            }

            note.follow(receptor);
            note.update(elapsed);

            if (note.isSustainNote && (note.goodHit || note.missed) && (cpu || holdKeys[note.direction]))
                note.clipSustain(receptors.members[note.direction]);
        });

        super.update(elapsed);

        while (notesToRemove.length > 0)
            removeNote(notesToRemove.pop());

        if (cpu) {
            receptors.forEachAlive((receptor) -> {
                if (receptor.animation.curAnim.name.startsWith("confirm") && receptor.animation.curAnim.finished)
                    receptor.playAnimation("static", true);
            });
        }

        lastStep = Conductor.self.step;
    }

    /**
     * Adds a note to this strumline and sorts the note order afterwards.
     * @param note The note to add
     */
    public function addNote(note:Note):Void {
        notes.add(note);

        if (note.sustain != null) {
            sustains.add(note.sustain);

            if (sustains.members.length > 1)
                sustains.members.sort((a, b) -> Std.int(a.parent.time - b.parent.time));
        }

        if (notes.members.length > 1)
            notes.members.sort((a, b) -> Std.int(a.time - b.time));
    }

    /**
     * Removes a note from this strumline and kills it.
     * @param note The note to remove
     */
    public function removeNote(note:Note):Void {
        if (note.sustain != null)
            sustains.remove(note.sustain, true);

        notes.remove(note, true);
        note.kill();
    }

    /**
     * Method which hits the passed note.
     * The note either gets removed, or hidden if it's a hold note.
     * @param note The note to hit
     */
    public function hitNote(note:Note):Void {
        if (note.isSustainNote) {
            note.visible = false;
            if (!cpu) resizeLength(note);
        } else
            notesToRemove.push(note);
    }

    /**
     * Key hit behaviour.
     * @param direction The pressed direction
     * @return The result, as a `NoteHit` enum instance
     */
    public inline function keyHit(direction:Int):NoteHit {
        var receptor:Receptor = receptors.members[direction];
        for (character in characters) character.holding = true;
        holdKeys[direction] = true;

        var possibleNotes:Array<Note> = notes.members.filter((note) -> note.direction == direction && note.canBeHit);
        var noteToHit:Note = possibleNotes[0];

        // TODO: is it really worth it sorting, considering notes are already sorted?
        // possibleNotes.sort((a, b) -> Std.int(a.time - b.time));

        if (noteToHit != null)
            return NOTE_HIT(noteToHit);

        receptor.playAnimation("press", true);
        return (!ghostTap) ? MISSED : null;
    }

    /**
     * Key release behaviour.
     * @param direction The released direction
     */
    public inline function keyRelease(direction:Int):Void {
        holdKeys[direction] = false;
        receptors.members[direction].playAnimation("static", true);
        for (character in characters) character.holding = holdKeys.contains(true);
    }

    // TODO: move this somewhere else
    /**
     * Converts a key to note direction.
     * @param key The key to convert
     * @param release Whether this check is done on key up
     * @return The found direction, or -1 if no direction has been found
     */
    public inline function getDirFromKey(key:Int, release:Bool = false):Int {
        var controls:Controls = Controls.global;
        var actions:Array<String> = Note.directions;
        var output:Int = -1;

        for (i in 0...actions.length) {
            for (k in controls.keybinds[actions[i]][0]) {
                if (key == k && (release || !holdKeys[i])) {
                    output = i;
                    break;
                }
            }

            if (output != -1)
                break;
        }

        return output;
    }

    /**
     * Internal method which runs on miss.
     * @param note The missed note
     */
    inline function miss(note:Note):Void {
        if (note.isSustainNote) {
            note.visible = false;
            // resizeLength(note);
        } else
            note.alphaMult = 0.3;

        note.missed = true;
        onMiss.dispatch(note);
    }

    /**
     * Internal method which resize the hold note length of the passed note if the player has hit the note earlier or later.
     * If the length becomes less than 100 ms, the note gets removed.
     * @param note 
     */
    inline function resizeLength(note:Note):Void {
        if (note == null) return;

        note.length += (note.time - Conductor.self.time);
        if (note.length < 100) removeNote(note);
        note.time = Conductor.self.time;
    }

    /**
     * Makes this strumline's `characters` sing.
     * @param note The note used to make the character sings
     */
    public function singCharacters(note:Note):Void {
        if (note.noSingAnim) return;

        for (character in characters) {
            if (!note.isSustainNote || note.visible || character.animation.name != character.singAnimations[note.direction] || !Options.noHoldStutter)
                character.sing(note.direction, note.animSuffix);
            else
                character.holdTime = 0;

            character.currentDance = 0;
        }
    }

    /**
     * Runs a quick tween on all receptors of this strumline.
     * @param delay The time to wait before the tween starts
     * @param dirDelay The extra wait time per receptor.
     */
    public function tweenReceptors(delay:Float = 0.5, dirDelay:Float = 0.2):Void {
        for (receptor in receptors) {
            receptor.alpha = 0;
            receptor.y -= 10;
            FlxTween.tween(receptor, {y: receptor.y + 10, alpha: 1}, 1, {
                startDelay: delay + (dirDelay * receptor.direction),
                ease: FlxEase.circOut
            });
        }
    }

    /**
     * Pops a splash on this strumline.
     * @param note The note used to make the splash
     */
    public function popSplash(note:Note):Void {
        var skin:String = note.splashSkin ?? this.skin;
        var splash:Splash = splashes.recycle(Splash, () -> new Splash(skin));

        if (splash.skin != skin)
            splash.skin = skin;

        var receptor:Receptor = receptors.members[note.direction];
        splash.setPosition(receptor.x, receptor.y);
        splash.pop(note.direction);
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        onNoteHit = cast FlxDestroyUtil.destroy(onNoteHit);
        onMiss = cast FlxDestroyUtil.destroy(onMiss);
        onHold = cast FlxDestroyUtil.destroy(onHold);

        notesToRemove = null;
        characters = null;
        holdKeys = null;
        skin = null;

        super.destroy();
    }

    // Setter methods

    function set_skin(v:String):String {
        if (v != null) {
            receptors?.forEach((r) -> r.skin = v);
            receptorSpacing = ((v == "default") ? 112 : (NoteSkin.get(v)?.receptor?.spacing ?? 112));
        }

        return skin = v;
    }

    function set_receptorSpacing(v:Float):Float {
        receptors?.forEach((r) -> r.x = x + (v * (r.direction - 2)));
        return receptorSpacing = v;
    }
}

// TODO: do not use an enum

/**
 * Represent a `keyHit` result.
 */
enum NoteHit {
    /**
     * Value holding the note to hit.
     */
    NOTE_HIT(note:Note);

    /**
     * Value returned when the player misses.
     */
    MISSED;
}

typedef NoteSignal = FlxTypedSignal<Note->Void>;
