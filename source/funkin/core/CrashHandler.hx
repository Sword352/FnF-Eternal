package funkin.core;

#if CRASH_HANDLER
import openfl.Lib;
import openfl.system.System;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.Exception;
import sys.FileSystem;
import sys.io.Process;
import sys.io.File;

/**
 * Singleton which catches runtime errors and displays an error dialog to the user.
 */
@:noCustomClass
class CrashHandler {
    /**
     * Initializes the crash handler.
     */
    public static function init():Void {
        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onErrorOFL);

        #if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onCriticalError);
		#end
    }

    #if cpp
    /**
     * Method called whenever a critical error is caught.
     * Only applies to the C++ target.
     * @param error The caught error.
     */
    static function onCriticalError(error:String):Void {
        // the CallStack API is only updated once the critical error handler has been called.
        // here we're basically forcing it to update before doing anything, and next hxcpp update is going to fix this issue
        // but this is probably going to stay for a while since hxcpp doesn't update regularly.
        // TODO: remove this whenever hxcpp updates
        untyped __cpp__('hx::StackContext *ctx = hx::StackContext::getCurrent();');
        untyped __cpp__('ctx->beginCatch(true);');
        //
    
        onError(error);
    }
    #end

    /**
     * Method called whenever an error is caught in the OpenFL lifecycle.
     * @param event `UncaughtErrorEvent` instance containing details about the error.
     */
    static function onErrorOFL(event:UncaughtErrorEvent):Void {
        event.preventDefault();
        onError(event.error);
    }

    /**
     * Saves a file containing the crash dump and opens an error dialog.
     * @param error The uncaught error.
     */
    static function onError(error:String):Void {
        var logPath:String = "logs/crashdump__" + DateTools.format(Date.now(), "%Y-%m-%d__%H'%M'%S") + ".log";
        var dump:String = CallStack.toString(CallStack.exceptionStack(true)).trim() + '\nUncaught Error: ${error}\nVersion: ${Tools.gameVersion}';

        if (!FileSystem.exists("logs/"))
            FileSystem.createDirectory("logs/");
        File.saveContent(logPath, dump);

        Sys.println(dump);
        Sys.println("Program must terminate."); // famous last words

        var dialog:String = "CrashDialog" #if windows + ".exe" #elseif mac + ".app" #end;

        if (FileSystem.exists(dialog)) {
            try {
                new Process(dialog, [dump, logPath]);
            }
            catch (e:Exception) {
                trace("Failed opening crash dialog! [" + e + "]");
                fallback(dump, logPath);
            }
        }
        else {
            trace("Couldn't find crash dialog!");
            fallback(dump, logPath);
        }

        System.exit(1);
    }

    /**
     * Opens a fallback window in case the crash dialog program cannot be accessed.
     * @param dump Crash dump.
     * @param log Path to the crash dump log.
     */
    static function fallback(dump:String, log:String):Void {
        FlxG.stage.window.alert('${dump}\n\nCrash dump saved at "${log}"\nPlease report this on GitHub if you believe this crash was caused by the engine!\n${Tools.githubURL}', "Error");
    }
}
#end
