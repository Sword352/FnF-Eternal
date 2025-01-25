package funkin.gameplay.components;

import flixel.text.FlxText;

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
