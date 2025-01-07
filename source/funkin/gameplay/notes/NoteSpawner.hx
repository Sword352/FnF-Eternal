package funkin.gameplay.notes;

import funkin.gameplay.notes.Sustain;
import funkin.data.ChartFormat.ChartNote;
import flixel.group.FlxGroup.FlxTypedGroup;

/**
 * `NoteSpawner` object, which progressively spawns notes from a chart.
 * Notes and sustains made by the spawner are recycled (meaning they get re-used), to improve performance.
 * This object dispatches the following event(s):
 * - `GameEvents.NOTE_INCOMING`
 */
@:build(funkin.core.macros.ScriptMacros.buildEventDispatcher())
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
     * Cached note incoming script event object.
     */
    var _noteIncomingEvent:NoteIncomingEvent = new NoteIncomingEvent();

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
        PlayState.song.notes.sort((a, b) -> Std.int(a.time - b.time));

        // skip notes with a time value lower than the start time
        if (startTime != 0 && PlayState.song.notes.length > 0) {
            while (PlayState.song.notes[currentNote].time < startTime) {
                // avoids null object reference when skipping every notes
                if (++currentNote >= PlayState.song.notes.length)
                    break;
            }
        }

        // setup the pools
        notes = new FlxTypedGroup<Note>();
        sustains = new FlxTypedGroup<Sustain>();

        // cache a small amount of objects
        var noteAmount:Int = Math.floor(Math.min(PlayState.song.notes.length, 20));
        var sustainAmount:Int = Math.floor(Math.min(PlayState.song.notes.length, 8));

        for (i in 0...noteAmount) {
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
        while (currentNote < PlayState.song.notes.length) {
            var note:ChartNote = PlayState.song.notes[currentNote];
            var strumLine:StrumLine = strumLines[note.strumline];

            if ((note.time - Conductor.self.time) > (1800 / (strumLine.scrollSpeed / Conductor.self.rate)))
                break;

            // if this is a ghost note, just skip it.
            if (_lastNote != null && _lastNote.time == note.time && _lastNote.direction == note.direction && _lastNote.strumline == note.strumline) {
                currentNote++;
                continue;
            }

            dispatchEvent(GameEvents.NOTE_INCOMING, _noteIncomingEvent.reset(note, strumLine));
            if (_noteIncomingEvent.cancelled) {
                currentNote++;
                continue;
            }

            var newNote:Note = getNote(_noteIncomingEvent);
            newNote.strumLine.addNote(newNote);

            _lastNote = note;
            currentNote++;
        }

        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        _noteIncomingEvent = FlxDestroyUtil.destroy(_noteIncomingEvent);

        sustains = FlxDestroyUtil.destroy(sustains);
        notes = FlxDestroyUtil.destroy(notes);

        strumLines = null;
        _lastNote = null;

        super.destroy();
    }

    /**
     * Recycling behaviour.
     * @param event `NoteIncomingEvent` object.
     * @return A `Note` instance
     */
    function getNote(event:NoteIncomingEvent):Note {
        var note:Note = notes.recycle(Note, noteConstructor);
        note.setup(event.time, event.direction, event.length, event.type);
        note.strumLine = event.strumLine;

        // don't swap the noteskin if it's the same!
        if (note.skin != event.skin)
            note.skin = event.skin;

        if (note.isHoldable())
            note.sustain = sustains.recycle(Sustain);

        return note;
    }

    inline function noteConstructor():Note {
        return new Note(0, 0, null, strumLines[0].skin);
    }
}
