package funkin.core.scripting;

/**
 * An `Element` is a scriptable entity able to interact with the game.
 * Scripts can have classes extending this class, which are automatically instansiated by the engine when scripts are reloaded.
 * 
 * An `Element` object can be activated based on a validation condition.
 * When the game switches states, each `Element` gets enabled or disabled based on the output of it's `validate` method.
 * `Element`s can also be forcely enabled/disabled using the `enabled` property.
 */
class Element {
    /**
     * Identifier for this element.
     */
    public var id(default, null):String;

    /**
     * Flag determining whether this element is currently enabled.
     */
    public var enabled(default, set):Bool;

    /**
     * Creates a new `Element`.
     * @param id Identifier for this element.
     */
    public function new(id:String):Void {
        this.id = id;
    }

    /**
     * Returns whether this element should be enabled.
     * This method is called before each state switch, and the element gets enabled or disabled based on it's output.
     * @return Bool
     */
    public function validate():Bool {
        return true;
    }

    /**
     * Method called when this element has been enabled.
     */
    public function onActivation():Void {}

    /**
     * Method called when this element has been disabled.
     */
    public function onDeactivation():Void {}

    function set_enabled(v:Bool):Bool {
        if (enabled != v) {
            if (v)
                onActivation();
            else
                onDeactivation();
        }
        return enabled = v;
    }
}

/**
 * An `Element` that is enabled when the gameplay starts.
 */
class GameplayElement extends Element {
    /**
     * Creates a new `GameplayElement`.
     * @param id Identifier for this element.
     */
    public function new(id:String):Void {
        super(id);
    }
    
    /**
     * Method which holds the validation condition for gameplay elements.
     * @return Bool
     */
    override function validate():Bool {
        if (!(FlxG.state is PlayState)) return false;
        onGameplayStart();
        return true;
    }

    /**
     * Method called when the gameplay starts.
     * Only called if this element is enabled.
     */
    function onGameplayStart():Void {}

    // we can't override methods from the super class in scripted classes yet,
    // so we override these methods manually for now
    override function onActivation():Void {}
    override function onDeactivation():Void {}
}

/**
 * An `Element` extension that gets enabled when a specific song is being played.
 */
class SongElement extends GameplayElement {
    var _song:String;

    /**
     * Creates a new `SongElement`.
     * @param song Song in which this element gets enabled.
     */
    public function new(song:String):Void {
        super(song);
        _song = song;
    }

    /**
     * Method which holds the validation condition for song elements.
     * @return Bool
     */
    override function validate():Bool {
        if (!(FlxG.state is PlayState) || PlayState.song.meta.folder != _song) return false;
        onGameplayStart();
        return true;
    }

    override function onGameplayStart():Void {}
    override function onActivation():Void {}
    override function onDeactivation():Void {}
}

/**
 * An `Element` extension that gets enabled when a specific notetype is included in the gameplay song.
 */
class NoteTypeElement extends GameplayElement {
    var _type:String;

    /**
     * Creates a new `NoteTypeElement`.
     * @param type Notetype for this element.
     */
    public function new(type:String):Void {
        super(type);
        _type = type;
    }

    /**
     * Method which holds the validation condition for notetype elements.
     * @return Bool
     */
    override function validate():Bool {
        if (!(FlxG.state is PlayState)) return false;

        for (note in PlayState.song.notes) {
            if (note.type == _type) {
                onGameplayStart();
                return true;
            }
        }

        return false;
    }

    override function onGameplayStart():Void {}
    override function onActivation():Void {}
    override function onDeactivation():Void {}
}
