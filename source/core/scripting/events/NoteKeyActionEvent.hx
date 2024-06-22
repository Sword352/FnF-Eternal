package core.scripting.events;

#if ENGINE_SCRIPTING
/**
 * Event dispatched whenever a note key is pressed or released in gameplay.
 */
class NoteKeyActionEvent extends ScriptEvent {
    /**
     * Target key.
     */
    @:eventConstructor public var key(default, null):Int;

    /**
     * Direction.
     */
    @:eventConstructor public var direction:Int;
}
#end
