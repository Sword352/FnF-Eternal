package funkin.editors.chart;

import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.system.FlxAssets.FlxShader;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;

import funkin.gameplay.notes.Note;
import funkin.editors.SelectionHelper.SelectableSprite;
import funkin.data.ChartFormat.ChartNote;

class ChartNoteGroup extends FlxTypedGroup<DebugNote> {
    public var lastSelectedNote:ChartNote = null;
    // public var forceRegen:Bool = false;
    public var lastMeasure:Int = -1;

    var currentNotes:Array<ChartNote> = [];
    var aliveSprites:Array<DebugNote> = []; // less iterations for forEachAlive()
    var toKill:Array<DebugNote> = [];

    // temporary fix for sustains making a huge amount of draw items
    // var sustainGroup:FlxSpriteGroup;

    var parent:ChartEditor;

    public function new(parent:ChartEditor):Void {
        this.parent = parent;
        // sustainGroup = new FlxSpriteGroup();
        super();
    }

    public function clearNotes():Void {
        forEachAlive((note) -> note.kill());
        currentNotes.splice(0, currentNotes.length);
        aliveSprites.splice(0, aliveSprites.length);
        lastSelectedNote = null;
    }

    override public function forEachAlive(func:DebugNote->Void, recursive:Bool = false):Void {
        for (note in aliveSprites) func(note);
    }

    override function update(elapsed:Float):Void {
        if (Conductor.self.measure != lastMeasure) {
            lastMeasure = Conductor.self.measure;
            regenNotes();
        }

        forEachAlive((n) -> {
            if (parent.music.playing && !n.dragging)
                noteBehaviour(n);

            if (n.data.length != 0)
                n.alphaY = Math.max(parent.line.y - n.sustain.y, 0);
                            
            n.update(elapsed);
        });
    }

    override function draw():Void {
        // sustainGroup.draw();

        forEachAlive((n) -> {
            if (!n.selected)
                n.draw();
        });

        // TODO: think of a smarter way (and do that for events too)
        for (object in parent.selection.selection)
            if (object is DebugNote)
                object.draw();
    }

    inline function noteBehaviour(note:DebugNote):Void {
        var late:Bool = (note.data.time <= Conductor.self.time);
        var hit:Bool = (late && note.data.time > parent.lastTime);

        if (note.data.time == 0 && !hit)
            hit = Conductor.self.time > 0 && parent.lastTime <= 0;

        if (hit && parent.hitsoundVolume > 0)
            FlxG.sound.play(parent.hitsound, parent.hitsoundVolume);

        if (parent.receptors.visible && (hit || (late && note.data.length > 0 && note.data.time + note.data.length > Conductor.self.time
            && parent.lastStep != Conductor.self.step)))
            parent.receptors.members[note.data.direction + 4 * note.data.strumline].playAnimation("confirm", true);
    }

    override function add(note:DebugNote):DebugNote {
        note.cameras = cameras;
        return super.add(note);
    }

    /*
    override function set_cameras(v:Array<FlxCamera>):Array<FlxCamera> {
        if (sustainGroup != null) sustainGroup.cameras = v;
        return super.set_cameras(v);
    }
    */

    override function destroy():Void {
        currentNotes = null;
        aliveSprites = null;
        lastSelectedNote = null;
        toKill = null;
        parent = null;

        super.destroy();
    }

    // TODO:
    // - fix very long sustains not appearing (when playing backward) until they're 3 measures or less from it's parent note
    // - maybe remake the math for spawning iterations as it seems a bit overkill

    public function regenNotes(force:Bool = false):Void {
        var iterations:Int = Math.floor(3 * (16 / Math.min(Conductor.self.measureLength, 16)));
        var firstNoteIndex:Int = -1;

        killNotes(force, iterations - 1);

        if (parent.selectedNote != null && !parent.selectedNote.exists) {
            lastSelectedNote = parent.selectedNote.data;
            parent.selectedNote = null;
        }

        for (i in 0...iterations) {
            var measure:Int = Conductor.self.measure + (i - Math.floor(iterations / 2));
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
                while (currentNote != null && inBounds(currentNote, time, nextTime)) {
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
            var lateTime:Float = measureTime(Conductor.self.measure - iterations + 1);
            var earlyTime:Float = measureTime(Conductor.self.measure + iterations);

            forEachAlive((n) -> {
                if (!n.selected && (n.data.time + n.data.length <= lateTime || n.data.time + n.data.length >= earlyTime)
                    && (n.data.length == 0 || Conductor.self.time < n.data.time || Conductor.self.time >= n.data.time + n.data.length))
                    toKill.push(n);
            });
        }
        else forEachAlive((n) -> toKill.push(n));

        for (note in toKill) killNote(note);
        toKill.splice(0, toKill.length);
    }

    public function killNote(note:DebugNote):Void {
        // sustainGroup.remove(note.sustain, true);
        currentNotes.remove(note.data);
        aliveSprites.remove(note);
        note.kill();
    }

    public function pushNote(note:DebugNote):Void {
        // sustainGroup.add(note.sustain);
        currentNotes.push(note.data);
        aliveSprites.push(note);
    }

    public function addNote(data:ChartNote):DebugNote {
        var note:DebugNote = recycle(DebugNote);
        note.setPosition(parent.checkerboard.x + ChartEditor.checkerSize * (data.direction + 4 * data.strumline), ChartEditor.getYFromTime(data.time));
        note.x += ChartEditor.separatorWidth * data.strumline;
        note.data = data;
        pushNote(note);
        return note;
    }

    inline function measureTime(measure:Float):Float {
        return Conductor.self.beatOffset.time + Conductor.self.stepCrochet * ((measure * Conductor.self.measureLength) - Conductor.self.beatOffset.step);
    }

    inline function inBounds(note:ChartNote, measureTime:Float, nextTime:Float) {
        return FlxMath.inBounds(note.time, measureTime, nextTime);
    }
}

class DebugNote extends SelectableSprite {
    public static final sustainColors:Array<FlxColor> = [0xC24A98, 0x00FEFE, 0x13FB05, 0xF9383E];

    public var data(default, set):ChartNote = null;
    public var editing(default, set):Bool = false;

    public var alphaShader:SustainShader;
    public var alphaY:Float = 0;

    public var sustain:FlxSprite;
    public var text:FlxText;

    var undoTime:Float = 0;
    var undoDir:Int = 0;
    var undoStr:Int = 0;

    public function new():Void {
        super();

        frames = Assets.getSparrowAtlas("notes/notes");

        for (direction in Note.directions)
            animation.addByPrefix(direction, direction + "0", 0);

        setGraphicSize(ChartEditor.checkerSize, ChartEditor.checkerSize);
        updateHitbox();

        text = new FlxText(0, 0, ChartEditor.checkerSize);
        text.setFormat(Assets.font("vcr"), 14);
        text.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.35);
        text.fieldHeight = ChartEditor.checkerSize;

        sustain = new FlxSprite();
        sustain.makeRect(ChartEditor.checkerSize * 0.25, 1, FlxColor.WHITE, false, "charteditor_susrect");

        alphaShader = new SustainShader();
        sustain.shader = alphaShader;

        var editor:ChartEditor = cast FlxG.state;
        dragBound.set(editor.checkerboard.x, editor.checkerboard.x + editor.checkerboard.width - width);
    }

    override function update(elapsed:Float):Void {
        var editor:ChartEditor = cast FlxG.state;

        if (data.length != 0) {
            if (!FlxG.mouse.pressedRight || !FlxG.mouse.overlaps(sustain) || FlxG.mouse.y < sustain.y + height * 0.5) {
                sustain.scale.y = Math.max(ChartEditor.checkerSize, ChartEditor.checkerSize * ((data.length / Conductor.self.stepCrochet) - 0.5));
            }
            else {
                sustain.scale.y = FlxG.mouse.y - sustain.y + ChartEditor.checkerSize * 0.5;
                data.length = Conductor.self.stepCrochet * ((sustain.scale.y / ChartEditor.checkerSize) + 0.5);
            }

            sustain.updateHitbox();

            if (editor.lateAlphaOn) {
                var normalized:Float = (sustain.height - alphaY) / sustain.height;
                alphaShader.rectHeight.value[0] = normalized;
                alphaShader.rectY.value[0] = 1 - normalized;
            }
            else {
                alphaShader.rectHeight.value[0] = 1;
                alphaShader.rectY.value[0] = 0;
            }
        }

        alpha = (editor.lateAlphaOn && data.time < Conductor.self.time ? ChartEditor.lateAlpha : 1);

        #if FLX_DEBUG
		flixel.FlxBasic.activeCount++;
		#end
    }

    override function draw():Void {
        if (data.length != 0)
            sustain.draw();

        super.draw();

        if (data.type != null)
            text.draw();
    }

    public function changeText(noteType:Int):Void {
        var invalid:Bool = (noteType == -1);
        text.color = (invalid ? FlxColor.RED : FlxColor.WHITE);
        text.text = Std.string(invalid ? noteType : noteType + 1);
    }

    override function onDrag():Void {
        var editor:ChartEditor = cast FlxG.state;

        var displace:Int = Math.round((x - editor.checkerboard.x) / ChartEditor.checkerSize);
        y = FlxMath.bound(y, 0, editor.checkerboard.bottom - height);

        data.time = ChartEditor.getTimeFromY(y);
        data.strumline = Math.floor(displace / 4);
        data.direction = displace % 4;

        animation.play(Note.directions[data.direction]);
        sustain.color = sustainColors[data.direction];
    }

    override function onSelect():Void {
        // we're removing the note so we don't have to sort the array each frames
        // (required for note spawning handled by ChartNoteGroup)
        cast(FlxG.state, ChartEditor).chart.notes.remove(data);

        // store values for undos
        undoTime = data.time;
        undoDir = data.direction;
        undoStr = data.strumline;
    }

    override function onRelease():Void {
        var editor:ChartEditor = cast FlxG.state;
        x = editor.checkerboard.x + ChartEditor.checkerSize * (data.direction + 4 * data.strumline) + (ChartEditor.separatorWidth * data.strumline);

        if (!FlxG.keys.pressed.SHIFT) {
            y = ChartEditor.roundPos(y);
            data.time = ChartEditor.getTimeFromY(y);
        }

        editor.noteDrags.push({
            ref: data, time: data.time, dir: data.direction, str: data.strumline,
            oldTime: undoTime, oldDir: undoDir, oldStl: undoStr
        });

        editor.requestSortNotes = true;
        editor.chart.notes.push(data);
    }

    function set_editing(v:Bool):Bool {
        colorTransform.alphaOffset = (v ? -120 : 0);
        return editing = v;
    }

    override function set_x(v:Float):Float {
        // null check because the super call changes x an y to 0
        // we can be sure that the text isnt null if the sustain isnt however
        if (sustain != null) {
            sustain.x = v + (width - sustain.width) * 0.5;
            text.x = v;
        }

        return super.set_x(v);
    }

    override function set_y(v:Float):Float {
        if (sustain != null) {
            sustain.y = v + height * 0.5;
            text.y = v;
        }

        return super.set_y(v);
    }

    override function set_cameras(v:Array<FlxCamera>):Array<FlxCamera> {
        if (v != null) sustain.cameras = v;
        return super.set_cameras(v);
    }

    override function destroy():Void {
        sustain = FlxDestroyUtil.destroy(sustain);
        text = FlxDestroyUtil.destroy(text);
        alphaShader = null;
        data = null;

        super.destroy();
    }

    function set_data(v:ChartNote):ChartNote {
        if (v != null) {
            if (v.type != null) changeText(cast(FlxG.state, ChartEditor).noteTypes.indexOf(v.type));
            animation.play(Note.directions[v.direction]);
            sustain.color = sustainColors[v.direction];
        }

        return data = v;
    }
}

class SustainShader extends FlxShader {
    @:glFragmentSource('
    #pragma header

    uniform float rectY;
    uniform float rectHeight;
    
    float getAlpha(vec2 pixel) {
        if ((pixel.y > rectY && pixel.y < rectY + rectHeight))
            return 1.;
        return 0.6;
    }
    
    void main() {
        vec2 pixel = openfl_TextureCoordv.xy;
        vec4 color = flixel_texture2D(bitmap, pixel);

        float pixelAlpha = getAlpha(pixel);
        gl_FragColor = vec4(color.rgb * pixelAlpha, pixelAlpha);
    }')
    public function new():Void {
        super();
        rectY.value = [0];
        rectHeight.value = [0];
    }
}
