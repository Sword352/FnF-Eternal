package gameplay.events;

import gameplay.events.EventTypes.EventArgument;

/**
 * Temporary workaround to make default argument values still work with macros.
 */
class EventMacroFixer {
    public static function fixMacroValue(argument:EventArgument):Dynamic {
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
