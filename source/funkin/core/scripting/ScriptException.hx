package funkin.core.scripting;

/**
 * Object used for throwing script exceptions.
 */
@:noCustomClass
class ScriptException extends haxe.Exception {
    /**
     * Reason this exception was thrown.
     */
    public var reason(default, null):ScriptExceptionReason;

    /**
     * Creates a new `ScriptException`.
     * @param reason Reason this exception was thrown.
     */
    public function new(reason:ScriptExceptionReason):Void {
        this.reason = reason;

        var msg:String = switch (reason) {
            case PARSING_ERROR(error): "Parsing script content failed with error: " + error;
            default: "Script content is suspected to be malicious";
        }
        super(msg);
    }
}

/**
 * Exception object used when the script content is suspected to be malicious.
 */
@:noCustomClass
class MaliciousScriptException extends ScriptException {
    public inline function new():Void {
        super(MALICIOUS_CONTENT);
    }
}

/**
 * Exception object used when parsing the script content failed.
 */
@:noCustomClass
class ParsingScriptException extends ScriptException {
    public inline function new(error:String):Void {
        super(PARSING_ERROR(error));
    }
}

/**
 * Reasons for a script exception.
 */
enum ScriptExceptionReason {
    /**
     * Parsing script content failed with an error.
     */
    PARSING_ERROR(error:String);

    /**
     * Script content may be malicious.
     */
    MALICIOUS_CONTENT;
    // MALICIOUS_CONTENT(maliciousKeyword:String);
}
