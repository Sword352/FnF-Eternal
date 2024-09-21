package funkin.gameplay.components;

import flixel.text.FlxText;

/**
 * Object which allows for the creation of ratings.
 */
@:structInit
class Rating implements IFlxDestroyable {
    /**
     * Name for this rating.
     */
    public var name:String;

    /**
     * Score amount the player gains from hitting this rating.
     */
    @:optional public var score:Float = 300;

    /**
     * Health amount the player gains from hitting this rating.
     */
    @:optional public var health:Float = 0.01;

    /**
     * Accuracy this rating gives, ranging from 0 to 1.
     */
    @:optional public var accuracyMod:Float = 1;

    /**
     * Hit window not to exceed in order to obtain this rating.
     */
    @:optional public var hitWindow:Float = 45;

    /**
     * Rank the game chooses if you don't exceed this rating's `missThreshold`.
     */
    @:optional public var rank:Rank = null;

    /**
     * Miss amount not to exceed in order to get this rating's `rank`.
     */
    @:optional public var missThreshold:Int = 1;

    /**
     * Whether to invalidate ranks if this rating gets 1 hit or more.
     */
    @:optional public var invalidateRank:Bool = false;

    /**
     * Total hits this rating got, used to determinate the rank.
     */
    @:optional public var hits:Int = 0;

    /**
     * Whether this rating pops a splash.
     */
    @:optional public var displaySplash:Bool = true;

    /**
     * Whether this rating breaks the combo.
     */
    @:optional public var breakCombo:Bool = false;

    /**
     * Returns a string representation of this rating.
     */
    public function toString():String {
        return this.name;
    }

    /**
     * Clean up memory.
     */
    public function destroy():Void {
        rank = FlxDestroyUtil.destroy(rank);
        name = null;
    }

    /**
     * Returns the default rating list as an `Array`.
     */
    public static function getDefault():Array<Rating> {
        return [
            {name: "mad",   rank: new Rank("MFC", FlxColor.PINK), score: 450, health: 0.02, hitWindow: 22.5},
            {name: "sick",  rank: new Rank("SFC", FlxColor.CYAN)},
            {name: "good",  rank: new Rank("GFC", FlxColor.LIME), score: 150, accuracyMod: 0.85, hitWindow: 90,  displaySplash: false},
            {name: "bad",   score: 50,  health: 0.005,   accuracyMod: 0.3, hitWindow: 135, invalidateRank: true, displaySplash: false},
            {name: "awful", score: -25, health: -0.0075, accuracyMod: 0,   hitWindow: 175, invalidateRank: true, displaySplash: false, breakCombo: true}
        ];
    }
}

/**
 * Object which allows for the creation of ranks.
 */
@:structInit
class Rank implements IFlxDestroyable {
    /**
     * Name for this rank.
     */
    public var name:String;

    /**
     * Color for this rank.
     */
    public var color(default, set):FlxColor;

    /**
     * Text format for this rank.
     */
    public var format(get, never):FlxTextFormat;

    /**
     * Actual format.
     */
    var _format:FlxTextFormat;

    function set_color(v:FlxColor):FlxColor {
        // no need to regenerate a text format
        if (_format != null) {
            @:privateAccess
            _format.format.color = v;
        }

        return color = v;
    }

    function get_format():FlxTextFormat {        
        if (_format == null)
            _format = new FlxTextFormat(color);

        return _format;
    }

    /**
     * Creates a new `Rank` instance.
     * @param name Name for this rank.
     * @param color Color for this rank.
     */
    public function new(name:String, color:FlxColor):Void {
        this.name = name;
        this.color = color;
    }

    /**
     * Returns a string representation of this rank.
     */
    public function toString():String {
        return this.name;
    }

    /**
     * Clean up memory.
     */
    public function destroy():Void {
        name = null;
        _format = null;
    }
}
