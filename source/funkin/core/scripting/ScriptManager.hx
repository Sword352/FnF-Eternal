package funkin.core.scripting;

import flixel.FlxState;
import haxe.io.Path;

/**
 * Static singleton for managing scripts.
 */
class ScriptManager {
    /**
     * Script container which contains all of the loaded scripts.
     */
    static final _scripts:ScriptContainer = new ScriptContainer();

    /**
     * List of variables each script can access through their global scope.
     */
    @:allow(funkin.core.scripting.HScript)
    static final _sharedVariables:Map<String, Any> = [];

    /**
     * List of variables pre-imported in every script.
     */
    @:allow(funkin.core.scripting.Script)
    static final _presets:Map<String, Any> = [
        "Std" => Std,
        "Math" => Math,
        "StringTools" => StringTools,
        "StringBuf" => StringBuf,
        "EReg" => EReg,
        "Lambda" => Lambda,
        "Paths" => Paths,
        "Assets" => Assets
    ];

    /**
     * Lookup table for finding scripts using their corresponding file names.
     */
    static final _scriptLookup:Map<String, Script> = [];

    /**
     * Cache containing all of the instansiated script elements.
     */
    static final _elements:Map<String, Element> = [];

    /**
     * Initializes the script manager.
     */
    public static function init():Void {
        FlxG.signals.preStateCreate.add(_onCreate);
        FlxG.signals.postStateSwitch.add(_onCreatePost);
    }

    /**
     * Resets the script manager.
     * @param scripts Optional, scripts to register afterwards.
     * @param updateElements Whether to validate each element afterwards.
     */
    public static function reset(?scripts:Array<Script>, updateElements:Bool = false):Void {
        for (element in _elements) {
            // calls onDeactivation() if the element was enabled
            element.enabled = false;
        }
        
        _elements.clear();
        _scriptLookup.clear();
        _scripts.clear();
        _sharedVariables.clear();

        register(scripts, updateElements);
    }

    /**
     * Registers scripts into the script manager.
     * @param scripts Scripts to register.
     * @param updateElements Whether to validate each element afterwards.
     */
    public static function register(scripts:Array<Script>, updateElements:Bool = false):Void {
        if (scripts == null) return;

        for (script in scripts) {
            var elements:Array<Element> = script.buildClasses(Element);
            if (elements != null) {
                for (element in elements) {
                    if (element.id == null) {
                        Logging.error('Cannot register element with a null identifier (from script "${script.name}").');
                        continue;
                    }
                    if (_elements.exists(element.id)) {
                        Logging.warning('Duplicate element "${element.id}" was found! The current element will be overwritten.');
                    }
                    _elements.set(element.id, element);
                }
            }
            _scriptLookup.set(Path.withoutExtension(script.name), script);
            _scripts.add(script);
        }

        if (updateElements) {
            _validateElements();
        }
    }

    /**
     * Forces an element to be enabled.
     * @param name Name of the element.
     */
    public static function enableElement(name:String):Void {
        var element:Element = getElement(name);
        if (element == null) return;

        element.enabled = true;
    }

    /**
     * Forces an element to be disabled.
     * @param name Name of the element.
     */
    public static function disableElement(name:String):Void {
        var element:Element = getElement(name);
        if (element == null) return;

        element.enabled = false;
    }

    /**
     * Adds a variable to the global scope of each script.
     * @param name Variable name.
     * @param value Variable value.
     */
    public static inline function addVariable(name:String, value:Any):Void {
        _sharedVariables.set(name, value);
    }

    /**
     * Removes a variable from the global scope of each script.
     * @param name Variable name.
     */
    public static inline function removeVariable(name:String):Void {
        _sharedVariables.remove(name);
    }

    /**
     * Adds a preset variable which will be added to the global scope of every script.
     * NOTE: preset variables are only applied when reloading scripts.
     * To add a variable to already loaded scripts, use `addVariable` instead.
     * @param name Variable name.
     * @param value Variable value.
     */
    public static inline function addPreset(name:String, value:Any):Void {
        _presets.set(name, value);
    }

    /**
     * Removes a preset variable from being added to the global scope of every script.
     * NOTE: this only takes effect when reloading scripts.
     * To remove a shared variable from already loaded scripts, use `removeVariable` instead.
     * @param name Variable name.
     */
    public static inline function removePreset(name:String):Void {
        _presets.remove(name);
    }

    /**
     * Finds and returns a script by it's name, or null if not found.
     * @param name Name of the script to find.
     * @return Script
     */
    public static inline function getScript(name:String):Script {
        return _scriptLookup.get(name);
    }

    /**
     * Finds and returns an element by it's name, or null if not found.
     * @param name Name of the element to find.
     * @return Element
     */
    public static inline function getElement(name:String):Element {
        return _elements.get(name);
    }

    /**
     * Internal method which re-validates the current elements and dispatches the create event on the current state.
     * @param state Current game state.
     */
    static function _onCreate(state:FlxState):Void {
        _validateElements();

        if (state is ScriptableState) {
            (cast state:ScriptableState).dispatchEvent(Events.CREATE);
        }
    }

    /**
     * Internal method which dispatches the create post event on the current state.
     */
    static function _onCreatePost():Void {
        if (!(FlxG.state is ScriptableState)) return;
        (cast FlxG.state:ScriptableState).dispatchEvent(Events.CREATE_POST);
    }

    /**
     * Internal method which re-validates every elements.
     */
    static function _validateElements():Void {
        for (element in _elements)
            element.enabled = element.validate();
    }
}
