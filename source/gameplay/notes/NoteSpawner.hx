package gameplay.notes;

import flixel.FlxBasic;
import gameplay.notes.Sustain;
import globals.ChartFormat.Chart;
import globals.ChartFormat.ChartNote;
import flixel.group.FlxGroup.FlxTypedGroup;

/**
 * `NoteSpawner` object, which progressively spawns notes from a chart.
 * Notes and sustains made by the spawner are recycled (meaning they get re-used), to improve performance.
 */
class NoteSpawner extends FlxBasic {
    /**
     * The note pool.
     */
    public var notes:FlxTypedGroup<Note>;

    /**
     * The sustain pool.
     */
    public var sustains:FlxTypedGroup<Sustain>;

    /**
     * The strumlines in which notes are going to be spawned into.
     */
    public var strumLines:Array<StrumLine>;

    /**
     * Counter which tracks the next note to spawn.
     */
    public var currentNote:Int = 0;

    /**
     * Internal reference to the last spawned note, used to eliminate ghost notes.
     */
    var _lastNote:ChartNote;

    /**
     * Creates a new `NoteSpawner`
     * @param strumLines The strumlines in which notes are going to be spawned into.
     * @param startTime Start time, where we start spawning notes at.
     */
    public function new(strumLines:Array<StrumLine>, startTime:Float = 0):Void {
        super();
        this.strumLines = strumLines;
        visible = false;

        // make sure notes are sorted
        Chart.current.notes.sort((a, b) -> Std.int(a.time - b.time));

        // skip notes with a time value lower than the start time
        if (startTime != 0)
            while (Chart.current.notes[currentNote].time < startTime)
                currentNote++;

        // setup the pools
        notes = new FlxTypedGroup<Note>();
        sustains = new FlxTypedGroup<Sustain>();

        // cache a small amount of objects
        var noteAmount:Int = Math.floor(Math.min(Chart.current.notes.length, 20));
        var sustainAmount:Int = Math.floor(Math.min(Chart.current.notes.length, 8));

        for (i in 0...noteAmount) {
            // by the way, this also cache sustain graphics
            notes.add(new Note(0, i % 4, null, strumLines[Math.floor(i / 4) % strumLines.length].skin)).kill();
        }

        for (i in 0...sustainAmount) {
            sustains.add(new Sustain(notes.members[i])).kill();
        }
    }

    /**
     * Updates this `NoteSpawner`.
     */
    override function update(elapsed:Float):Void {
        while (currentNote < Chart.current.notes.length) {
            var note:ChartNote = Chart.current.notes[currentNote];
            var strumLine:StrumLine = strumLines[note.strumline];

            if ((note.time - Conductor.self.time) > (1800 / strumLine.scrollSpeed))
                break;

            // if this is a ghost note, just skip it.
            if (_lastNote != null && _lastNote.time == note.time && _lastNote.direction == note.direction && _lastNote.strumline == note.strumline) {
                currentNote++;
                continue;
            }

            var newNote:Note = getNote(note);

            #if ENGINE_SCRIPTING
            // The spawn callback is handled here.
            if (PlayState.current != null)
                PlayState.current.hxsCall("onNoteSpawn", [newNote]);
            #end

            strumLine.addNote(newNote);
            currentNote++;

            _lastNote = note;
        }
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        sustains = FlxDestroyUtil.destroy(sustains);
        notes = FlxDestroyUtil.destroy(notes);

        strumLines = null;
        _lastNote = null;

        super.destroy();
    }

    /**
     * Recycling behaviour.
     * @param chartNote The note data
     * @return A `Note` instance
     */
    inline function getNote(chartNote:ChartNote):Note {
        var parent:StrumLine = strumLines[chartNote.strumline];

        var note:Note = notes.recycle(Note, noteConstructor).setup(chartNote);
        note.parentStrumline = parent;

        // don't swap the noteskin if it's the same!
        if (note.skin != parent.skin)
            note.skin = parent.skin;

        if (note.length != 0)
            note.sustain = sustains.recycle(Sustain);

        return note;
    }

    inline function noteConstructor():Note {
        return new Note(0, 0, null, strumLines[0].skin);
    }
}
