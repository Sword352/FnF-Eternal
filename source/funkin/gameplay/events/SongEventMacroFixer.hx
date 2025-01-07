package funkin.gameplay.events;

import funkin.gameplay.events.SongEventTypes.SongEventArgument;

/**
 * Temporary workaround to make default argument values still work with macros.
 */
class SongEventMacroFixer {
    public static function fixMacroValue(argument:SongEventArgument):Dynamic {
        var output:Dynamic = argument.defaultValue;

        if (output == null && argument.tempValue != null) {
			output = switch (argument.type) {
				case FLOAT:        Std.parseFloat(argument.tempValue);
				case INT | COLOR:  Std.parseInt(argument.tempValue);
				case BOOL:         argument.tempValue == "true";
				case _:            argument.tempValue;
			}
        }

        return output;
    } 
}
