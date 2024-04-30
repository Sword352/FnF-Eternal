package funkin.gameplay.notes;

import flixel.tweens.*;
import flixel.util.FlxAxes;
import flixel.util.FlxSignal;
import flixel.group.FlxGroup;

class StrumLine extends FlxGroup {
    public var x(default, set):Float = 0;
    public var y(default, set):Float = 0;
    public var receptorSpacing(default, set):Float = 112;

    public var receptors:FlxTypedGroup<Receptor>;
    public var splashes:FlxTypedGroup<Splash>;
    public var notes:FlxTypedGroup<Note>;

    public var downscroll(get, set):Bool;
    public var scrollSpeed:Float = 1;
    public var scrollMult:Float = 1;
    public var dirAngle:Float = 180;

    public var characters:Array<Character> = [];
    public var skin(default, set):String;

    public var holdKeys:Array<Bool> = [false, false, false, false];
    public var ghostTap:Bool = Settings.get("ghost tapping");
    public var cpu:Bool = false;

    public var onNoteHit:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
    public var onHold:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
    public var onMiss:FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

    var notesToRemove:Array<Note> = [];
    var lastStep:Int = 0; // used for base game behaviour

    public function new(x:Float = 0, y:Float = 0, cpu:Bool = false, skin:String = "default"):Void {
        super();

        this.x = x;
        this.y = y;

        this.cpu = cpu;
        this.skin = skin;

        receptors = new FlxTypedGroup<Receptor>();
        add(receptors);

        if (!Settings.get("disable note splashes") && !cpu)
            createSplashes();

        notes = new FlxTypedGroup<Note>();
        add(notes);

        for (i in 0...4) {
            var receptor:Receptor = new Receptor(i, skin);
            receptor.setPosition(x + (receptorSpacing * (i - 2)), y);
            receptors.add(receptor);
        }
    }

    override public function update(elapsed:Float):Void {
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

            if (note.killIfLate && (note.avoid || note.missed || note.isSustainNote)
                && Conductor.self.time > (note.time + note.length + ((400 / note.getScrollSpeed()) + note.lateKillOffset)))
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

            if (!note.noStrumFollow)
                note.follow(receptor);
        });

        super.update(elapsed);

        while (notesToRemove.length > 0)
            removeNote(notesToRemove.pop());

        // only clip the sustain here as super.update changes the sustains position
        notes.forEachAlive((note) -> {
            if (note.isSustainNote && (note.goodHit || note.missed) && note.autoClipSustain && (cpu || holdKeys[note.direction]))
                note.clipSustain(receptors.members[note.direction]);
        });

        if (cpu) {
            receptors.forEachAlive((receptor) -> {
                if (receptor.animation.curAnim.name.startsWith("confirm") && receptor.animation.curAnim.finished)
                    receptor.playAnimation("static", true);
            });
        }

        lastStep = Conductor.self.step;
    }

    override function draw():Void {
        notes.forEachExists((note) -> {
            if (note.isSustainNote && note.sustain.visible && note.holdBehindStrum)
                note.sustain.draw();
        });

        super.draw();
    }

    public function addNote(note:Note):Void {
        notes.add(note);
        if (notes.members.length > 1)
            notes.members.sort((a, b) -> Std.int(a.time - b.time));
    }

    public function removeNote(note:Note):Void {
        notes.remove(note, true);
        note.destroy();
    }

    public function hitNote(note:Note):Void {
        if (note.isSustainNote) {
            note.baseVisible = false;
            if (!cpu) resizeLength(note);
        } else
            notesToRemove.push(note);
    }

    public inline function keyHit(direction:Int):NoteHit {
        var receptor:Receptor = receptors.members[direction];
        for (character in characters) character.holding = true;
        holdKeys[direction] = true;

        var possibleNotes:Array<Note> = notes.members.filter((note) -> note.direction == direction && note.canBeHit);
        if (possibleNotes.length == 0) {
            receptor.playAnimation("press", true);
            return (!ghostTap) ? MISSED : null;
        }

        possibleNotes.sort((a, b) -> Std.int(a.time - b.time));

        var noteToHit:Note = possibleNotes[0];

        // Remove notes with a 0-1ms distance (TODO: think about this)
        if (possibleNotes.length > 1) {
            for (note in possibleNotes) {
                if (note == noteToHit) continue;
                if (Math.abs(note.time - noteToHit.time) < 1) removeNote(note);
                else break;
            }
        }

        return NOTE_HIT(noteToHit);
    }

    public inline function keyRelease(direction:Int):Void {
        holdKeys[direction] = false;
        receptors.members[direction].playAnimation("static", true);
        for (character in characters) character.holding = holdKeys.contains(true);
    }

    public function getDirFromKey(key:Int, release:Bool = false):Int {
        var controls:Controls = Controls.global;
        var actions:Array<String> = Note.directions;

        for (i in 0...actions.length) {
            for (k in controls.keybinds[actions[i]][0])
                if (key == k && (release || !holdKeys[i]))
                    return i;
        }

        return -1;
    }

    inline function miss(note:Note):Void {
        if (note.isSustainNote) {
            note.baseVisible = false;
            // resizeLength(note);
        } else
            note.alphaMult = note.lateAlpha;

        note.missed = true;
        onMiss.dispatch(note);
    }

    // incase the player hits the note early or late
    inline function resizeLength(note:Note):Void {
        if (note == null) return;

        note.length += (note.time - Conductor.self.time);
        if (note.length < 100) removeNote(note);
        note.time = Conductor.self.time;
    }

    public inline function setPosition(x:Float = 0, y:Float = 0):StrumLine {
        this.x = x;
        this.y = y;
        return this;
    }

    public inline function screenCenter(axes:FlxAxes = XY):StrumLine {
        if (axes.x) x = FlxG.width * 0.5;
        if (axes.y) y = FlxG.height * 0.5;
        return this;
    }

    public function singCharacters(note:Note):Void {
        if (note.noSingAnim) return;

        for (character in characters) {
            if (!note.isSustainNote || note.baseVisible || character.animation.name != character.singAnimations[note.direction] || !Settings.get("disable hold stutter"))
                character.sing(note.direction, note.animSuffix);
            else
                character.holdTime = 0;

            character.currentDance = 0;
        }
    }

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

    public inline function createSplashes(cache:Bool = true):Void {
        splashes = new FlxTypedGroup<Splash>();
        add(splashes);

        if (cache)
            cacheSplash();
    }

    public inline function cacheSplash():Void {
        var cachedSplash:Splash = new Splash(skin);
        splashes.add(cachedSplash);
        cachedSplash.kill();
    }

    public inline function popSplash(direction:Int):Void {
        var splash:Splash = splashes.recycle(Splash, () -> new Splash(skin));
        var receptor:Receptor = receptors.members[direction];
        splash.setPosition(receptor.x, receptor.y);
        splash.pop(direction);
    }

    inline function setReceptorsX(x:Float):Void
        receptors?.forEach((r) -> r.x = x + (receptorSpacing * (r.direction - 2)));

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

    function set_x(v:Float):Float {
        setReceptorsX(v);
        return x = v;
    }

    function set_y(v:Float):Float {
        receptors?.forEach((r) -> r.y = v);
        return y = v;
    }

    function set_skin(v:String):String {
        if (v != null) {
            receptors?.forEach((r) -> r.skin = v);
            receptorSpacing = ((v == "default") ? 112 : (funkin.globals.NoteSkin.get(v)?.receptor?.spacing ?? 112));
        }

        return skin = v;
    }

    function set_receptorSpacing(v:Float):Float {
        receptorSpacing = v;
        setReceptorsX(x);
        return v;
    }

    inline function set_downscroll(v:Bool):Bool {
        if ((v && scrollMult > 0) || (!v && scrollMult < 0))
            scrollMult = -scrollMult;
        return v;
    }

    inline function get_downscroll():Bool
        return scrollMult < 0;
}

enum NoteHit {
    NOTE_HIT(note:Note);
    MISSED;
}
