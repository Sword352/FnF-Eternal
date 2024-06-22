package funkin.core.macros;

#if macro
import haxe.macro.Compiler;

/**
 * Macro used to compile unused classes for scripting flexibility.
 */
class IncludeMacro {
    public static function addAdditionalClasses():Void {
        #if !display
        Compiler.include("flixel", true, ["flixel.system.macros", "flixel.addons.nape", "flixel.addons.editors"]);
        Compiler.include("openfl.display", true);
        Compiler.include("openfl.filters", true);

        #if sys
        // some stuff can't compile on HL due to failing to load "ssl.hdll"
        Compiler.include("sys", true, [#if hl "sys.ssl", "sys.net", "sys.db", "sys.Http" #end]);
        #end

        #if hxvlc
        Compiler.include("hxvlc", true);
        #end

        Compiler.include("StringBuf");
        #end
    }
}
#end
