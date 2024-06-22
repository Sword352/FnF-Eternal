package funkin.core.scripting.events;

#if ENGINE_SCRIPTING
import funkin.gameplay.notes.StrumLine;
import funkin.data.ChartFormat.ChartNote;

/**
 * Event dispatched whenever a note is going to be spawned in gameplay.
 */
class NoteIncomingEvent extends ScriptEvent {
    /**
     * Chart note reference.
     */
    @:eventConstructor public var data:ChartNote;

    /**
     * Time for the incoming note.
     */
    @:eventConstructor public var time:Float = 0;

    /**
     * Direction for the incoming note.
     */
    @:eventConstructor public var direction:Int = 0;

    /**
     * Strumline index for the incoming note.
     */
    @:eventConstructor public var strumline:Int = 0;

    /**
     * Hold length for the incoming note.
     */
    @:eventConstructor public var length:Float = 0;

    /**
     * Notetype for the incoming note.
     */
    @:eventConstructor public var type:String = null;

    /**
     * Parent strumline for the incoming note.
     */
    @:eventConstructor public var strumLine:StrumLine = null;

    /**
     * Noteskin for the incoming note.
     */
    @:eventConstructor public var skin:String = null;

    override function destroy():Void {
        data = null;
        strumLine = null;
        skin = null;
    }
}
#end
