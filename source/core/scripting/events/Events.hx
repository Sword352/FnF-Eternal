package core.scripting.events;

#if ENGINE_SCRIPTING
/**
 * Event pooling singleton, used to store event instances so that we can re-use them later.
 */
class Events {
    /**
     * Internal pool to re-use instantiated events.
     */
    static var _pool:EventPool = new EventPool();

    /**
     * Inits the pooling API.
     */
    public static function init():Void {
        FlxG.signals.preStateSwitch.add(_pool.clear);
    }

    /**
     * Gets an event instance from the pool and returns it.
     * @param eventCls Class of the event.
     * @return An event of class `eventCls`
     */
    public static function get<T:ScriptEvent>(eventCls:Class<T>):T {
        return _pool.get(eventCls);
    }

    /**
     * Puts the passed event into the pool and returns null.
     * @param event Event to put.
     */
    public static function put<T:ScriptEvent>(event:T):T {
        _pool.put(event);
        return null;
    }
}

/**
 * We can't use a map of `Class<ScriptEvent> => Array<ScriptEvent>`, so we're making our own container for the event pool.
 */
private class EventPool {
    /**
     * An array containing all of the pools.
     */
    var _pools:PoolContainer = [];

    /**
     * This represents the index of each pools stored in `_pools`.
     */
    var _clsIndex:Array<Class<ScriptEvent>> = [];

    public function new():Void {}

    /**
     * Gets an event of class `eventCls` from the pool.
     */
    public function get<T:ScriptEvent>(eventCls:Class<T>):T {
        var cls:Class<ScriptEvent> = cast eventCls;

        var poolIndex:Int = _clsIndex.indexOf(cls);
        var pool:Array<ScriptEvent> = _pools[poolIndex];

        // no corresponding pool found, create a new one
        if (poolIndex == -1) {
            pool = [];
            _clsIndex.push(cls);
            _pools.push(pool);
        }

        // pool is empty, create a new instance
        if (pool.length == 0) {
            return Type.createInstance(eventCls, []);
        }

        var event:ScriptEvent = pool.pop();
        event.reset();
        return cast event;
    }

    /**
     * Registers the passed event into the pool.
     */
    public function put<T:ScriptEvent>(event:T):Void {
        var cls:Class<ScriptEvent> = cast Type.getClass(event);
        var poolIndex:Int = _clsIndex.indexOf(cls);

        // create a pool if none is found
        if (poolIndex == -1) {
            _clsIndex.push(cls);
            _pools.push([event]);
            return;
        }

        // otherwise, simply push it to the existing pool
        _pools[poolIndex].push(event);
    }

    /**
     * Clears the entirety of the pool and dispose any contained event instances.
     */
    public function clear():Void {
        for (pool in _pools) {
            while (pool.length > 0)
                pool.pop().destroy();
        }

        _clsIndex.splice(0, _clsIndex.length);
        _pools.splice(0, _pools.length);
    }
}

typedef PoolContainer = Array<Array<ScriptEvent>>;
#end
