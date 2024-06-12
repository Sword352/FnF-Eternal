package gameplay.events;

/**
 * Event metadata. Contain infos used for the chart editor.
 */
typedef EventMeta = {
    /**
     * Display name for this event.
     */
    var name:String;

    /**
     * Type which is tied to this event metadata.
     */
    var type:String;

    /**
     * Event description.
     */
    var ?description:String;

    /**
     * Event arguments.
     */
    var ?arguments:Array<EventArgument>;
}

/**
 * Event argument. Metadata for a value in the `arguments` array of a `ChartEvent`.
 */
typedef EventArgument = {
    /**
     * Display name for this argument.
     */
    var name:String;

    /**
     * The value type of this argument.
     */
    var type:EventArgumentType;

    /**
     * Default value for this argument.
     */
    var ?defaultValue:Dynamic;

    /**
     * Temporary workaround. Represents `defaultValue` as a string.
     */
    var ?tempValue:String;

    /**
     * List of possible values for this argument. Only matters if the type is a `List`.
     */
    var ?list:Array<Dynamic>;

    /**
     * Additional unit text to display in the chart editor.
     */
    var ?unit:String;

    /**
     * Step precision for the number stepper. Only matters if the type is an `Int` or `Float`.
     */
    var ?step:Float;

    /**
     * Minimum number value for this argument. Only matters if the type is an `Int` or `Float`.
     */
    var ?min:Float;

    /**
     * Maximum number value for this argument. Only matters if the type is an `Int` or `Float`.
     */
    var ?max:Float;
}

/**
 * Represents an argument value type.
 */
enum abstract EventArgumentType(String) from String to String {
    var FLOAT = "Float";
    var INT = "Int";
    var STRING = "String";
    var BOOL = "Bool";
    var LIST = "List";
    var COLOR = "Color";
}

// Can't use those with macros...

/*
@:structInit
class EventMeta {
    public var name:String;
    public var type:String;

    @:optional public var description:String;
    @:optional public var arguments:Array<EventArgument>;
}

@:structInit
class EventArgument {
    public var name:String;
    public var type:EventArgumentType;

    @:optional public var defaultValue:Dynamic;
    @:optional public var tempValue:String;

    @:optional public var step:Float;
    @:optional public var min:Float;
    @:optional public var max:Float;
    @:optional public var list:Array<String>;
}

enum abstract EventArgumentType(Int) from Int to Int {
    var FLOAT = 0;
    var INT = 1;
    var STRING = 2;
    var BOOL = 3;
    var LIST = 4;
    var COLOR = 5;

    @:from public static function fromString(v:String):EventArgumentType {
        return switch (v) {
            case "Float": FLOAT;
            case "Int": INT;
            case "Bool": BOOL;
            case "List": LIST;
            case "Color": COLOR;
            case _: STRING;
        }
    }
}
*/