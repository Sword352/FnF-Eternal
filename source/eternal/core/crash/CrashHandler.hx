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
     public static var lastCallstack(default, null):String;
     public static var lastException(default, null):String;

     #if sys
     public static final CRASHLOG_PATH:String = "crash/";
     public static var lastCrashLog(default, null):String;
     #end

     public static final quotes:Array<String> = [
          // leon brother
          "Looks like a pipe exploded",
          "Come back next Friday",
          "Haha someone's code isn't funkin'",
          "Looks like it's crashing time!",
          // crazyb3ndy
          "your funkin ain't fridayin",
          // plankdev
          "erm... what the blast",
          "you're did it !!!!",
          // "can you shur.up man??? uuggghhh *shakes butt*",
          // <a:bwomp:1148184617552187435>
          // memehoovy
          "Hi. I'm Eternal engine, and I'm a crashaholic.",
          // eyedalehim
          "now what the heck happened here?",
          // laztrix
          "what the scallop",
          // smb
          "a crash? aw man",
          // glade
          "um hi i'm the friendly crash quote",
          // sword
          "https://www.youtube.com/watch?v=4kEO7VjKRB8",

          // discord quotes
          #if ENGINE_DISCORD_RPC
          "#DISCORD Looks like ${user} crashed the game!",
          "#DISCORD ${user} should really take a break"
          #end
     ];

     public static function init():Void {
         Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

         #if hl
         Api.setErrorHandler(onCrash);
         /*
         #elseif cpp
         untyped __global__.__hxcpp_set_critical_error_handler((e) -> onCrash(e, true));
         */
         #end
     }

     private static function onCrash(event:Dynamic):Void {          
          var msg:String = processCrash(event);     

          #if hl
          var params:EnumFlags<DialogFlags> = new EnumFlags<DialogFlags>();
          params.set(IsError);
          UI.dialog("Friday Night Funkin': Eternal Engine - Exception Report", msg + '\n\nPress OK to close the game.', params);
          #else
          Lib.application.window.alert(msg + '\n\nPress OK to close the game.', "Friday Night Funkin': Eternal Engine - Exception Report");
          #end
     }

     @:allow(eternal.core.crash.FNFGame)
     private static function processCrash(event:Dynamic):String {
          var exception:String = processError(event);

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

          lastException = '<>Error:<> ${exception}';
          lastCallstack = fullStack;

          var msg:String = '${lastException.replace("<>", "")}\n${lastCallstack}';
          trace("\n" + msg);
          msg += '\nPlease report this to the github page: ${Tools.githubURL}';

          #if sys
          if (!FileSystem.exists(CRASHLOG_PATH))
              FileSystem.createDirectory(CRASHLOG_PATH);
 
          var path:String = '${CRASHLOG_PATH}FNF-EE_${DateTools.format(Date.now(), "%Y-%m-%d_%H'%M'%S")}.txt';
          File.saveContent(path, msg);
          trace('Saved crash log to "${path}"');

          lastCrashLog = path;
          #end

          return msg;
     }

     inline private static function processError(error:Dynamic):String {
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

     inline public static function getNextQuote():String {
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
}
#end
