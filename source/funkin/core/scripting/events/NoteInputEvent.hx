package funkin.core.scripting.events;

/**
 * Event dispatched when a note key has been pressed or released during gameplay.
 */
class NoteInputEvent extends ScriptEvent {
    /**
     * Pressed/released key.
     */
    public var key:Int;

    /**
     * Direction of the key.
     */
    public var direction:Int;

    /**
     * Resets this event.
     * @param key Pressed/released key.
     * @param direction Direction of the key.
     * @return NoteInputEvent
     */
    public function reset(key:Int, direction:Int):NoteInputEvent {
        this.key = key;
        this.direction = direction;
        cancelled = false;
        return this;
    }
}
