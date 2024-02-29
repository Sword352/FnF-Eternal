package eternal.core.scripting;

#if macro
import haxe.macro.Compiler;

// Macro used to compile unused classes for HScript's flexibility
class HScriptInclude {
    /**
     * FORMAT: `"packageToImport" => [array of exclusions]`
     * The array of exclusions can be null if it does not require it
     */
    public static final imports:Map<String, Array<String>> = [
        // Packages
        "flixel" => ["flixel.system.macros", "flixel.addons.nape", "flixel.addons.editors"],
        #if sys "sys" => #if hl ["sys.ssl", "sys.net", "sys.db", "sys.Http"], #else null,
        #end #end // some stuff can't compile on HL due to failing to load "ssl.hdll"
        #if hxvlc "hxvlc.flixel" => null, #end
        "openfl.display" => null,
        
        // Classes
        "StringBuf" => null
    ];

    public static function addAdditionalClasses():Void {
        for (k => v in imports)
            Compiler.include(k, true, v);
    }
}
#end
