package funkin.core.scripting;

/**
 * List of common script events.
 */
enum abstract Events(String) from String to String {
    /**
     * Event dispatched at the start of the state creation process.
     */
    var CREATE = "create";

    /**
     * Event dispatched after the state creation process.
     */
    var CREATE_POST = "createPost";

    /**
     * Event dispatched each frame before the state's update.
     * This event dispatches the elapsed time in seconds between the last and current frame.
     */
    var UPDATE = "update";

    /**
     * Event dispatched each frame once the state has been updated.
     * This event dispatches the elapsed time in seconds between the last and current frame.
     */
    var UPDATE_POST = "updatePost";

    /**
     * Event dispatched when the state is about to be destroyed.
     */
    var DESTROY = "destroy";

    /**
     * Event dispatched when the current song beat changes.
     * This event dispatches the current beat in the song.
     */
    var BEAT_HIT = "beatHit";

    /**
     * Event dispatched when the current song measure changes.
     * This event dispatches the current measure in the song.
     */
    var MEASURE_HIT = "measureHit";

    /**
     * Event dispatched when a substate opens.
     * This event can be cancelled and dispatches an object holding the pending substate.
     */
    var SUBSTATE_OPEN = "substateOpen";

    /**
     * Event dispatched when a substate closes.
     * This event can be cancelled and dispatches an object holding the pending substate.
     */
    var SUBSTATE_CLOSE = "substateClose";

    /**
     * Event dispatched before a state switch occurs.
     * This event can be cancelled and dispatches an object holding a function that handles the state switch procedure.
     */
    var STATE_SWITCH = "stateSwitch";
}

/**
 * List of events typically dispatched in gameplay.
 */
enum abstract GameEvents(String) from String to String {
    /**
     * Event dispatched when a `StrumLine` hits a note in gameplay.
     * This event can be cancelled and dispatches an object holding informations about the note hit.
     */
    var NOTE_HIT = "noteHit";

    /**
     * Event dispatched when a `StrumLine` misses a note in gameplay.
     * This event can be cancelled and dispatches an object holding informations about the note miss.
     */
    var NOTE_MISS = "noteMiss";

    /**
     * Event dispatched each quarter beats when a sustain note is being held by a `StrumLine` in gameplay.
     * This event can be cancelled and dispatches an object holding informations about the note hold.
     */
    var NOTE_HOLD = "noteHold";

    /**
     * Event dispatched when a sustain note gets invalidated in gameplay.
     * This event can be cancelled and dispatches an object holding informations about the note invalidation.
     */
    var NOTE_HOLD_INVALIDATION = "noteHoldInvalidation";

    /**
     * Event dispatched when a note is about to spawn in gameplay.
     * This event can be cancelled and dispatches an object holding informations about the upcoming note.
     */
    var NOTE_INCOMING = "noteIncoming";

    /**
     * Event dispatched when the player presses a note key.
     * This event can be cancelled and dispatches an object holding informations about the key press.
     */
    var NOTE_KEY_PRESS = "noteKeyPress";

    /**
     * Event dispatched when the player releases a note key.
     * This event can be cancelled and dispatches an object holding informations about the key release.
     */
    var NOTE_KEY_RELEASE  = "noteKeyRelease";

    /**
     * Event dispatched when the player presses a key while there was no notes on screen during gameplay.
     * This event can be cancelled and dispatches an object holding informations about the ghost press.
     */
    var GHOST_PRESS = "ghostPress";

    /**
     * Event dispatched before the game over starts.
     * This event can be cancelled.
     */
    var GAME_OVER = "gameOver";

    /**
     * Event dispatched when a song event is being executed in gameplay.
     * This event can be cancelled and dispatches an object holding informations about the song event.
     */
    var EVENT_EXECUTION = "eventExecution";

    /**
     * Event dispatched when a song event is being preloaded in gameplay.
     * This event can be cancelled and dispatches an object holding informations about the song event.
     */
    var EVENT_PRELOAD = "eventPreload";

    /**
     * Event dispatched before the countdown starts.
     * This event can be cancelled and dispatches an object holding countdown properties.
     */
    var COUNTDOWN_START = "countdownStart";

    /**
     * Event dispatched before a countdown tick.
     * This event can be cancelled and dispatches an object holding properties for the countdown tick.
     */
    var COUNTDOWN_TICK = "countdownTick";

    /**
     * Event dispatched when the song starts.
     * This event can be cancelled.
     */
    var SONG_START = "songStart";

    /**
     * Event dispatched before the song ends.
     * This event can be cancelled.
     */
    var SONG_END = "songEnd";
}
