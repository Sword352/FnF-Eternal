package funkin.core.scripting.events;

import funkin.gameplay.notes.StrumLine;
import funkin.data.ChartFormat.ChartNote;

/**
 * Event dispatched when a note is about to be spawned in gameplay.
 */
class NoteIncomingEvent extends ScriptEvent {
    /**
     * Time for the incoming note.
     */
    public var time:Float = 0;

    /**
     * Direction for the incoming note.
     */
    public var direction:Int = 0;

    /**
     * Strumline ID for the incoming note.
     */
    public var strumlineId:Int = 0;

    /**
     * Hold length for the incoming note.
     */
    public var length:Float = 0;

    /**
     * Notetype for the incoming note.
     */
    public var type:String = null;

    /**
     * Parent strumline for the incoming note.
     */
    public var strumLine:StrumLine = null;

    /**
     * Noteskin for the incoming note.
     */
    public var skin:String = null;

    /**
     * Resets this event.
     * @param data Note data associated with this event.
     * @param strumLine Parent strumline for the incoming note.
     * @return NoteIncomingEvent
     */
    public function reset(data:ChartNote, strumLine:StrumLine):NoteIncomingEvent {
        this.strumLine = strumLine;

        time = data.time;
        direction = data.direction;
        strumlineId = data.strumline;
        length = data.length;
        type = data.type;
        skin = strumLine.skin;

        cancelled = false;
        return this;
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        strumLine = null;
    }
}
