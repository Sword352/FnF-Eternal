package eternal.core.crash;

#if ENGINE_CRASH_HANDLER
import flixel.FlxState;
import haxe.CallStack;

import openfl.Lib;
import openfl.events.UncaughtErrorEvent;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

class CrashHandler {
     public static final quotes:Array<String> = [
          "“i told you to use FlxGroup.recycle” - Sword",
          "“https://www.youtube.com/watch?v=4kEO7VjKRB8” - Sword",
          "“duh what did you do bro” - Sword",
          "“so true” - Sword",
          "“bruh” - Sword",
                              
          #if ENGINE_DISCORD_RPC
          "#DISCORD “Well, looks like ${user} crashed the game.” - Sword",
          "#DISCORD “${user} should really take a break!” - Sword",
          #end

          "“Looks like a pipe exploded” - LeonBrother",
          "“Come back next Friday” - LeonBrother",
          "“Haha someone's code isn't funkin'” - LeonBrother",
          "“Looks like it's crashing time!” - LeonBrother",

          "“erm... what the blast” - PlankDev",
          "“you're did it !!!!” - PlankDev",

          "“Hi. I'm Eternal engine, and I'm a crashaholic.” - Moxie",
          "“um hi i'm the friendly crash quote” - Glade",
          "“your funkin ain't fridayin” - Crazyb3ndy",
          "“now what happened here?” - EyeDaleHim",
          "“what the scallop” - Meloomazy",
          "“a crash? aw man” - SMB",
     ];

     #if sys
     public static final CRASHLOG_PATH:String = "crash/";
     #end

     public static var lastReport(default, null):CrashReport = {};

     public static inline function init():Void {
         Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
     }

     public static function processCrash(event:UncaughtErrorEvent):String {
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

          lastReport.exception = (event.error ?? "Unknown");
          lastReport.callstack = fullStack;

          var msg:String = '${lastReport.callstack}\nError: ${lastReport.exception}';
          msg += "\nIf you feel like this shouldn't happen, please report this to the github page! (" + Tools.githubURL + ")";
          Sys.println(msg);

          if (FlxG.state != null && FlxG.state is ICrashListener)
               cast(FlxG.state, ICrashListener).onCrash();

          #if sys
          if (!FileSystem.exists(CRASHLOG_PATH))
              FileSystem.createDirectory(CRASHLOG_PATH);
 
          var path:String = '${CRASHLOG_PATH}FNF-EE_${DateTools.format(Date.now(), "%Y-%m-%d_%H'%M'%S")}.txt';
          File.saveContent(path, msg);

          Sys.println('Saved crash log to "${path}"');
          lastReport.crashLog = path;
          #end

          return msg;
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

     static function onCrash(event:UncaughtErrorEvent):Void {
          // make sure it doesn't close the game
          event.preventDefault();

          TransitionSubState.skipNextTransIn = true;
          TransitionSubState.onComplete.removeAll();

          Assets.clearAssets = true;
          Tools.stopAllSounds();
          
          processCrash(event);

          if (FlxG.state == null)
              FlxG.switchState(FlxState.new);

          // TODO: fix infinite crash happening on PlayState
          // (The crash would happen infinetly and the substate would never open)
          FlxG.state.persistentUpdate = false;
          FlxG.state.openSubState(new CrashScreen());

          // on critical crashes (either an FlxGame crash OR 3 crashes in a row)
          // Lib.application.window.alert(msg + '\n\nPress OK to close the game.', "Friday Night Funkin': Eternal Engine - Exception Report");
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