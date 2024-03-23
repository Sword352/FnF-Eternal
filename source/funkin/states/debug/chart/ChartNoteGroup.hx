package funkin.states.debug.chart;

import flixel.group.FlxGroup;
import funkin.gameplay.notes.Note;
import funkin.globals.ChartFormat.ChartNote;

class ChartNoteGroup extends FlxTypedGroup<DebugNote> {
    public var lastSelectedNote:ChartNote = null;
    public var lastMeasure:Int = -1;

    var currentNotes:Array<ChartNote> = [];
    var aliveSprites:Array<DebugNote> = []; // less iterations for forEachAlive()
    var toKill:Array<DebugNote> = [];

    var parent:ChartEditor;

    public function new(parent:ChartEditor):Void {
        this.parent = parent;
        super();
    }

    override public function forEachAlive(func:DebugNote->Void, recursive:Bool = false):Void {
        for (note in aliveSprites) func(note);
    }

    override function update(elapsed:Float):Void {
        if (Conductor.currentMeasure != lastMeasure) {
            lastMeasure = Conductor.currentMeasure;
            regenNotes();
        }

        forEachAlive((n) -> {
            if (parent.music.playing)
                noteBehaviour(n);
                
            n.update(elapsed);
        });
    }

    override function draw():Void {
        forEachAlive((n) -> n.draw());
    }

    inline function noteBehaviour(note:DebugNote):Void {
        var late:Bool = (note.data.time <= Conductor.time);
        var hit:Bool = (late && note.data.time > parent.lastTime);

        if (hit && parent.hitsoundVolume > 0)
            FlxG.sound.play(parent.hitsound, parent.hitsoundVolume);

        if (parent.receptors.visible && (hit || (late && note.data.length > 0 && note.data.time + note.data.length > Conductor.time
            && parent.lastStep != Conductor.currentStep)))
            parent.receptors.members[note.data.direction + 4 * note.data.strumline].playAnimation("confirm", true);
    }

    override function add(note:DebugNote):DebugNote {
        note.cameras = cameras;
        return super.add(note);
    }

    override function destroy():Void {
        currentNotes = null;
        aliveSprites = null;
        lastSelectedNote = null;
        toKill = null;
        parent = null;

        super.destroy();
    }

    // TODO: fix those natural issues
    // - Some sustains that are in 2 measures can be seen disapearing when reaching a third measure
    // - Very long sustains not appearing (when playing backward) until they're 3 measures or less from it's parent note

    public function regenNotes(force:Bool = false):Void {
        var iterations:Int = Math.floor(3 * (16 / Math.min(Conductor.measureLength, 16)));
        var firstNoteIndex:Int = -1;

        killNotes(force, iterations - 1);

        if (parent.selectedNote != null && !parent.selectedNote.exists) {
            lastSelectedNote = parent.selectedNote.data;
            parent.selectedNote = null;
        }

        for (i in 0...iterations) {
            var measure:Int = Conductor.currentMeasure + (i - Math.floor(iterations / 2));
            if (measure < 0) continue;

            var time:Float = measureTime(measure);
            var nextTime:Float = measureTime(measure + 1);

            if (firstNoteIndex == -1) {
                for (i in 0...parent.chart.notes.length) {
                    if (parent.chart.notes[i].time >= time) {
                        firstNoteIndex = i;
                        break;
                    }
                }
            }

            if (firstNoteIndex != -1) {
                var currentNote:ChartNote = parent.chart.notes[firstNoteIndex];
                while (currentNote != null && FlxMath.inBounds(currentNote.time, time, nextTime)) {
                    if (!currentNotes.contains(currentNote)) {
                        var sprite:DebugNote = addNote(currentNote);
                        if (lastSelectedNote == currentNote) {
                            parent.selectedNote = sprite;
                            lastSelectedNote = null;
                        }
                    }

                    currentNote = parent.chart.notes[++firstNoteIndex];
                }
            }
        }
    }

    inline function killNotes(force:Bool, iterations:Int):Void {
        if (!force) {
            var lateTime:Float = measureTime(Conductor.currentMeasure - iterations + 1);
            var earlyTime:Float = measureTime(Conductor.currentMeasure + iterations);

            forEachAlive((n) -> {
                if ((n.data.time <= lateTime || n.data.time >= earlyTime)
                    && (n.data.length == 0 || Conductor.time < n.data.time || Conductor.time >= n.data.time + n.data.length))
                    toKill.push(n);
            });
        }
        else forEachAlive((n) -> toKill.push(n));

        for (note in toKill) killNote(note);
        toKill.splice(0, toKill.length);
    }

    public inline function killNote(note:DebugNote):Void {
        currentNotes.remove(note.data);
        aliveSprites.remove(note);
        note.kill();
    }

    public inline function pushNote(note:DebugNote):Void {
        currentNotes.push(note.data);
        aliveSprites.push(note);
    }

    inline function addNote(data:ChartNote):DebugNote {
        var note:DebugNote = recycle(DebugNote);
        note.setPosition(parent.checkerboard.x + ChartEditor.checkerSize * (data.direction + 4 * data.strumline), ChartEditor.getYFromTime(data.time));
        note.x += ChartEditor.separatorWidth * data.strumline;
        note.data = data;
        pushNote(note);
        return note;
    }

    inline function measureTime(measure:Float):Float {
        return Conductor.beatOffset.time + Conductor.stepCrochet * ((measure * Conductor.measureLength) - Conductor.beatOffset.step);
    }
}

class DebugNote extends FlxSprite {
    static final sustainColors:Array<FlxColor> = [0xC24A98, 0x00FEFE, 0x13FB05, 0xF9383E];

    public var data:ChartNote = null;
    public var sustain:FlxSprite;

    public function new():Void {
        super();

        frames = Assets.getSparrowAtlas("notes/notes");

        for (direction in Note.directions)
            animation.addByPrefix(direction, direction + "0", 0);

        setGraphicSize(ChartEditor.checkerSize, ChartEditor.checkerSize);
        updateHitbox();

        sustain = new FlxSprite();
        sustain.makeRect(ChartEditor.checkerSize * 0.25, 1, FlxColor.WHITE, false, "charteditor_susrect");
    }

    override function update(elapsed:Float):Void {
        if (data.length > 0) {
            sustain.scale.y = Math.max(ChartEditor.checkerSize, ChartEditor.checkerSize * ((data.length / Conductor.stepCrochet) - 0.5));
            sustain.updateHitbox();
        }

        alpha = (data.time < Conductor.time && Settings.get("CHART_lateAlpha")) ? ChartEditor.lateAlpha : 1;

        #if FLX_DEBUG
		flixel.FlxBasic.activeCount++;
		#end
    }

    override function draw():Void {
        if (data.length > 0) {
            sustain.x = x + (width - sustain.width) * 0.5;
            sustain.y = y + height * 0.5;

            sustain.color = sustainColors[data.direction];
            sustain.alpha = alpha;
            sustain.draw();
        }

        animation.play(Note.directions[data.direction]);
        super.draw();
    }

    override function destroy():Void {
        sustain = FlxDestroyUtil.destroy(sustain);
        data = null;

        super.destroy();
    }
}