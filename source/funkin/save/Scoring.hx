package funkin.save;

import funkin.gameplay.components.GameStats;

/**
 * TODO:
 * - implement special game sessions for story mode
 * - make a per-mod saving system (each mods having it's own score container in the save file, so that scores don't get confused)
 */

/**
 * Singleton which stores, manages, saves and loads game sessions.
 */
class Scoring {
    /**
     * Empty game session.
     */
    public static final emptySession:GameSession = new GameSession();

    /**
     * Global scoring instance.
     */
    public static final self:Scoring = new Scoring();

    /**
     * Internal game session container.
     */
    var _sessions:Map<String, GameSession>;

    function new():Void {}

    /**
     * Loads saved game sessions.
     */
    public function load():Void {
        if (FlxG.save.data.scores == null)
            FlxG.save.data.scores = new Map<String, GameSession>();

        _sessions = (cast FlxG.save.data.scores : Map<String, GameSession>).copy();
    }

    /**
     * Saves every stored game sessions.
     */
    public function save():Void {
        FlxG.save.data.scores = _sessions.copy();
        FlxG.save.flush();
    }

    /**
     * Registers a new game session based on the provided song's statistics if the provided stats score is greater than the current session's score, or if there's no session with the same name yet.
     * @param song The song's name.
     * @param stats An instance of `GameStats` containing the game's statistics.
     */
    public function registerGame(song:String, stats:GameStats):Void {
        var currentSession:GameSession = getSession(song);

        if (stats.score > currentSession.score) {
            addSession(song, new GameSession(Math.fround(stats.score), stats.misses, stats.accuracy, stats.getRankName()));
            save();
        }
    }

    /**
     * Registers a game session.
     * @param key Key for the session.
     * @param session `GameSession` instance.
     */
    public function addSession(key:String, session:GameSession):Void {
        _sessions.set(key, session);
    }

    /**
     * Returns the game session associated with the provided key. If no session is found, an empty session is returned.
     * @param key Session key.
     * @return `GameSession` instance.
     */
    public function getSession(key:String):GameSession {
        return _sessions.get(key) ?? emptySession;
    }

    /**
     * Removes a game session associated with the provided key.
     * @param key Session key.
     * @return `true` if the session exists and has been removed, `false` otherwise.
     */
    public function deleteSession(key:String):Bool {
        return _sessions.remove(key);
    }
}

/**
 * Game session object storing score informations.
 */
@:structInit
class GameSession {
    /**
     * Total game score.
     */
    public var score:Float = 0;

    /**
     * Total misses count.
     */
    public var misses:Int = 0;

    /**
     * Final accuracy amount.
     */
    public var accuracy:Float = 0;

    /**
     * Final rank.
     */
    public var rank:String = null;

    /**
     * Creates a new `GameSession` instance.
     * @param score Initial score.
     * @param misses Initial misses.
     * @param accuracy Initial accuracy.
     * @param rank Initial rank.
     */
    public function new(score:Float = 0, misses:Int = 0, accuracy:Float = 0, rank:String = null):Void {
        this.score = score;
        this.misses = misses;
        this.accuracy = accuracy;
        this.rank = rank;
    }
}
