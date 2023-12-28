package eternal.core.crash;

#if ENGINE_CRASH_HANDLER
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;

import haxe.CallStack;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

#if hl
import hl.UI;
import hl.Api;
import haxe.EnumFlags;
#end

class CrashHandler {
     #if sys
     public static final CRASHLOG_PATH:String = "crash/";
     #end

     public static var lastReport(default, null):CrashReport = {};

     public static final quotes:Array<String> = [
          // sword
          "i told you to use FlxGroup.recycle why don't you listen",
          "https://www.youtube.com/watch?v=4kEO7VjKRB8",
          "duh what did you do bro",
          "so true",
          "bruh",
                              
          #if ENGINE_DISCORD_RPC
          "#DISCORD Well, looks like ${user} crashed the game.",
          "#DISCORD ${user} should really take a break!",
          #end

          // leon brother
          "Looks like a pipe exploded",
          "Come back next Friday",
          "Haha someone's code isn't funkin'",
          "Looks like it's crashing time!",

          // plankdev
          "erm... what the blast",
          "you're did it !!!!",

          "your funkin ain't fridayin", // crazyb3ndy
          "Hi. I'm Eternal engine, and I'm a crashaholic.", // memehoovy
          "now what the heck happened here?", // eyedalehim
          "what the scallop", // meloomazy
          "a crash? aw man", // smb
          "um hi i'm the friendly crash quote" // glade
     ];

     public static inline function init():Void {
         Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, _onCriticalCrash);

         #if hl
         Api.setErrorHandler(_onCriticalCrash);
         #end
     }

     public static function processCrash(event:Dynamic):String {
          var fullStack:String = "";
          for (stackItem in CallStack.exceptionStack(true)) {
               switch (stackItem) {
                    case CFunction:
                         fullStack += 'Non-Haxe (C) Function\n';
                    case Module(m):
                         fullStack += 'Module ${m}\n';
                    case FilePos(_, file, line, _):
                         fullStack += '${file}:${line}\n';
                    case Method(className, method):
                         fullStack += '${className} - method ${method}\n';
                    case LocalFunction(func):
                         fullStack += 'Local Function ${func}\n';
               }
          }

          lastReport.exception = processError(event);
          lastReport.callstack = fullStack;

          var msg:String = 'Error: ${lastReport.exception}\n${lastReport.callstack}';
          trace("\n" + msg);
          msg += '\nPlease report this to the github page: ${Tools.githubURL}';

          if (FlxG.state != null && FlxG.state is ICrashListener)
               cast(FlxG.state, ICrashListener).onCrash();

          #if sys
          if (!FileSystem.exists(CRASHLOG_PATH))
              FileSystem.createDirectory(CRASHLOG_PATH);
 
          var path:String = '${CRASHLOG_PATH}FNF-EE_${DateTools.format(Date.now(), "%Y-%m-%d_%H'%M'%S")}.txt';
          File.saveContent(path, msg);
          trace('Saved crash log to "${path}"');

          lastReport.crashLog = path;
          #end

          return msg;
     }

     public static inline function processError(error:Dynamic):String {
          var exception:String = "Unknown";

          try {
               if (error is UncaughtErrorEvent)
                   exception = cast(error, UncaughtErrorEvent).error;
               else
                   exception = Std.string(error);
          }
          catch (e) {
               trace('Error retrieving crash data!');
               trace(e);
          }

          return exception;
     }

     public static inline function getNextQuote():String {
          FlxG.random.shuffle(quotes);

          #if ENGINE_DISCORD_RPC
          var output:String = FlxG.random.getObject(quotes);

          if (output.startsWith("#DISCORD "))
               output = output.replace("#DISCORD ", "").replace("${user}", DiscordPresence.username ?? "User");

          return output;
          #else
          return FlxG.random.getObject(quotes);
          #end
     }

     private static function _onCriticalCrash(event:Dynamic):Void {          
          var msg:String = processCrash(event);     

          #if hl
          var params:EnumFlags<DialogFlags> = new EnumFlags<DialogFlags>();
          params.set(IsError);
          UI.dialog("Friday Night Funkin': Eternal Engine - Exception Report", msg + '\n\nPress OK to close the game.', params);
          #else
          Lib.application.window.alert(msg + '\n\nPress OK to close the game.', "Friday Night Funkin': Eternal Engine - Exception Report");
          #end
     }
}

@:structInit class CrashReport {
     public var callstack:String;
     public var exception:String;
     #if sys public var crashLog:String; #end

     public function new():Void {}
}

interface ICrashListener {
     function onCrash():Void;
}
#end
