package funkin.core.scripting;

import haxe.iterators.ArrayIterator;
import haxe.iterators.ArrayKeyValueIterator;

/**
 * Simple object for storing script objects.
 */
class ScriptContainer implements IFlxDestroyable {
    /**
     * Internal array containing all of the scripts.
     */
    var _scripts:Array<Script> = [];

    /**
     * Creates a new `ScriptContainer`.
     */
    public function new():Void {}

    /**
     * Appends an array of script into this script container.
     * @param scripts Array of `Script` instances.
     */
    public function append(scripts:Array<Script>):Void {
        if (scripts == null) return;
        for (script in scripts) add(script);
    }

    /**
     * Adds a script to this script container and returns it.
     * @param script Script to add.
     */
    public function add(script:Script):Script {
        if (script == null) return null;
        _scripts.push(script);
        return script;
    }

    /**
     * Removes a script from this container.
     * @param script Script to remove.
     * @return `true` if the script was contained and removed, `false` otherwise.
     */
    public inline function remove(script:Script):Bool {
        return _scripts.remove(script);
    }

    /**
     * Destroys and removes all of the scripts this script container contains.
     */
    public function clear():Void {
        while (_scripts.length > 0)
            _scripts.pop().destroy();
    }

    /**
     * Returns an iterator looping through each script of this container.
     * @return ArrayIterator<Script>
     */
    public inline function iterator():ArrayIterator<Script> {
        return _scripts.iterator();
    }

    /**
     * Returns a key value iterator looping through each script of this container.
     * @return ArrayKeyValueIterator<Script>
     */
    public inline function keyValueIterator():ArrayKeyValueIterator<Script> {
        return _scripts.keyValueIterator();
    }

    /**
     * Clean up memory.
     */
    public function destroy():Void {
        this.clear();
        _scripts = null;
    }
}
