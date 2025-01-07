package funkin.core.scripting.events;

/**
 * Event dispatched before a state switch.
 */
class StateSwitchEvent extends ScriptEvent {
    /**
     * Function responsible of switching state.
     * Can be called immediatly, after a transition, etc.
     */
    public var onOutroComplete:Void->Void;

    /**
     * Creates a new `StateSwitchEvent`.
     * @param onOutroComplete Function responsible of switching state.
     */
    public function new(onOutroComplete:Void->Void):Void {
        this.onOutroComplete = onOutroComplete;
        super();
    }
}
