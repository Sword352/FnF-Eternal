package funkin.utils;

import haxe.Log;
import haxe.PosInfos;

// import flixel.system.debug.log.LogStyle as FlxLogStyle;

/**
 * Utility class for tracing fancy strings into the console.
 */
class Logging {
    /**
     * Internal map storing all of the log styles.
     */
    static var _logStyles:Map<String, LogStyle>;

    #if !debug
    /**
     * Internal flag which determines whether we should trace to the console on release builds.
     * Can be enabled by launching the program using a command prompt with the `--logging` argument.
     */
    static var _loggingEnabled:Bool;
    #end

    /**
     * Initializes the logging system.
     */
    public static function init():Void {
        _logStyles = new Map();
        addLogStyle(new LogStyle(INFO,    "i | ", CYAN));
        addLogStyle(new LogStyle(WARNING, "! | ", YELLOW));
        addLogStyle(new LogStyle(ERROR,   "X | ", RED));

        // FlxLogStyle.WARNING.callback = flixelWarning;
        // FlxLogStyle.ERROR.callback = flixelError;

        // override the default trace behavior
        Log.trace = haxeTrace;

        #if !debug
        // check for cli argument
        var args:Array<String> = Sys.args();
        _loggingEnabled = (args.length > 0 && args.contains("--logging"));

        if (_loggingEnabled) {
            // make a new line, otherwise the first line to be traced will be right after the current directory
            Sys.println("");
        }
        #end
    }

    /**
     * Registers a log style into the logging system.
     * @param style Log style to register.
     */
    public static function addLogStyle(style:LogStyle):Void {
        if (style == null) return;
        _logStyles.set(style.name, style);
    }

    /**
     * Removes a log style by it's name.
     * @param style Log style to remove.
     */
    public static inline function removeLogStyle(style:String):Void {
        _logStyles.remove(style);
    }

    /**
     * Traces a value into the console.
     * @param v Value to trace.
     * @param style Log style to use.
     * @param infos Optional file infos to trace. If blank, the haxe compiler will fill this argument with infos from where this method was called.
     */
    public static function trace(v:Any, ?style:String, ?infos:PosInfos):Void {
        #if !debug
        if (!_loggingEnabled) return;
        #end

        #if debug
        v = Log.formatOutput(v, infos);
        #else
        // no need for extra infos on release builds
        v = formatClassName(infos.className) + ": " + Std.string(v) + formatExtraParams(infos.customParams);
        #end

        traceString(v, style);
    }

    /**
     * Traces a string into the console without any position informations.
     * @param message Message to trace.
     * @param style Log style to use.
     */
    public static function traceString(message:String, ?style:String):Void {
        #if !debug
        if (!_loggingEnabled) return;
        #end

        var logStyle:LogStyle = _logStyles.get(style) ?? _logStyles.get(INFO);
        _trace(message, logStyle);
    }

    /**
     * Shortcut to trace an information into the console.
     * @param message Message to trace.
     * @param infos Automatically filled by the compiler.
     */
    public static inline function info(message:String, ?infos:PosInfos):Void {
        Logging.trace(message, INFO, infos);
    }

    /**
     * Shortcut to trace a warning into the console.
     * @param message Message to trace.
     * @param infos Automatically filled by the compiler.
     */
    public static inline function warning(message:String, ?infos:PosInfos):Void {
        Logging.trace(message, WARNING, infos);
    }

    /**
     * Shortcut to trace an error into the console.
     * @param message Message to trace.
     * @param infos Automatically filled by the compiler.
     */
    public static inline function error(message:String, ?infos:PosInfos):Void {
        Logging.trace(message, ERROR, infos);
    }

    /**
     * Internal method used to override the default trace behavior (`trace` method).
     */
    static inline function haxeTrace(v:Any, ?infos:PosInfos):Void {
        Logging.trace(v, INFO, infos);
    }

    /*
    static inline function flixelWarning(v:Any):Void {
        traceString('Flixel: ${v}', WARNING);
    }

    static inline function flixelError(v:Any):Void {
        traceString('Flixel: ${v}', ERROR);
    }
    */

    static inline function _trace(v:String, logStyle:LogStyle):Void {
        Sys.println(logStyle.color.toAnsi() + logStyle.header + v + "\u001b[0m");
    }

    #if !debug
    /**
     * Formats the custom parameters of a `PosInfos` object into a readable string.
     * @param params Params to format.
     * @return String
     */
    static function formatExtraParams(params:Array<Any>):String {
        if (params == null) return "";
        return ", " + params.join(", ");
    }

    /**
     * Extracts the class name from a class path.
     * @param path Class path.
     * @return String
     */
    static inline function formatClassName(path:String):String {
        return path.substring(path.lastIndexOf(".") + 1, path.length);
    }
    #end
}

/**
 * Class used to define log style properties.
 */
@:structInit
@:noCustomClass
class LogStyle {
    /**
     * Name of this log style.
     */
    public var name:String;

    /**
     * Trace header for this log style.
     */
    public var header:String;

    /**
     * Trace color for this log style.
     */
    public var color:AnsiColor;

    /**
     * Creates a new `LogStyle`.
     * @param name Name of this log style.
     * @param header Trace header for this log style.
     * @param color Trace color for this log style.
     */
    public function new(name:String, header:String, color:AnsiColor):Void {
        this.name = name;
        this.header = header;
        this.color = color;
    }
}

/**
 * List of default log styles.
 */
enum abstract DefaultLogStyle(String) from String to String {
    var INFO;
    var WARNING;
    var ERROR;
}

/**
 * List of default ansi colors.
 */
enum abstract AnsiColor(Int) from Int to Int {
    var RED = 31;
    var GREEN = 32;
    var YELLOW = 33;
    var BLUE = 34;
    var CYAN = 36;
    var WHITE = 37;

    /**
     * Converts this integer into an ansi sequence.
     * @return String
     */
    public inline function toAnsi():String {
        return '\033[${this}m';
    }
}
