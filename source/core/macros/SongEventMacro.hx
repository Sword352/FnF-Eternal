package core.macros;

import gameplay.events.EventTypes;
import gameplay.events.EventMacroFixer;

import haxe.macro.Expr;
import haxe.macro.Expr.Field;
import haxe.macro.Context;
import haxe.macro.Compiler;

using haxe.macro.ExprTools;
using StringTools;

/**
 * Macro used for gameplay events, which allows to code them into seperated classes.
 * The role of this macro is to:
 * - Tie event classes into their corresponding event type
 * - Tie event metas into their corresponding event type
 * - Generate shortcuts to quickly access event arguments
 */
class SongEventMacro {
	#if macro
	/**
	 * Final event list. Stores event types with their parent classes, as a string.
	 */
	static var _list:Map<String, String> = [];

	/**
	 * Final meta list.
	 */
	static var _metas:Map<String, EventMeta> = [];
	
	/**
	 * Register the class and the passed meta to the global event list.
	 * @param event Event metadata
	 */
	public static function build(event:EventMeta):Array<Field> {
		final classData = Context.getLocalClass().get();

		// If the class exists in a sub-package, generate the prefix.
		final prefix = classData.pack.length > 0 ? (classData.pack.join(".") + ".") : "";

		if (event.arguments == null)
			event.arguments = [];

		_list.set(event.type, prefix + classData.name);
		_metas.set(event.type, event);

		var fields:Array<Field> = Context.getBuildFields();
		generateGetters(event, fields);
		return fields;
	}

	/**
	 * Method used so that DCE doesn't exclude event classes from the compilation process.
	 */
	public static function keepClasses():Void {
		Compiler.include("gameplay.events", true);
	}
	#end

	/**
	 * Returns the final event list.
	 */
	public static macro function getList():Expr {
		// Since this is a map, the "value expression" it becomes is an array declaration.
		final arrayDecl = macro $v{_list};

		return arrayDecl.map((inExpr) -> {
			switch (inExpr.expr) {
				// We have to resolve the class here!
				case EBinop(OpArrow, left, right):
					final newRight = macro Type.resolveClass($right);
					inExpr.expr = EBinop(OpArrow, left, newRight);
				case _:
			}

			return inExpr;
		});
	}

	/**
	 * Returns the final meta list.
	 */
	public static macro function getMetas():Expr {
		return macro $v{_metas};
	}

	#if macro
	/**
	 * Generate getters for the passed event.
	 */
	static function generateGetters(event:EventMeta, fields:Array<Field>):Void {
		for (argument in event.arguments) {
			var converted:String = validateName(argument.name);
			var argumentIndex:Int = event.arguments.indexOf(argument);
			var type:ComplexType = null;
			
			switch (argument.type) {
				case STRING | LIST:  type = macro: String;
				case INT | COLOR:    type = macro: Int;
				case FLOAT:          type = macro: Float;
				case _:              type = macro: Bool;
			}

			var defaultValue:Dynamic = EventMacroFixer.fixMacroValue(argument);

			fields.push({
				name: "get_" + converted,
				pos: Context.currentPos(),
				kind: FFun({
					expr: macro {
						return currentEvent.arguments[$v{argumentIndex}] ?? $v{defaultValue};
					},
					ret: type,
					args: [],
				}),
				meta: [{
					name: ":noCompletion",
					pos: Context.currentPos()
				}],
				access: [AInline]
			});

			fields.push({
				name: converted,
				pos: Context.currentPos(),
				doc: 'Quick access to the `${argument.name}` argument (automatically generated). Default value is `${defaultValue}`.',
				kind: FProp("get", "never", type, null)
			});
		}
	}

	/**
	 * Converts the passed name into a valid field string
	 * TODO: make it so an underscore is added if the name starts with a number
	 */
	static function validateName(string:String):String {
		var output:String = string.toLowerCase();

		// convert into camel case (can't use the method from Tools as it has undesirable imports)
		if (output.contains(" ")) {
			var parts:Array<String> = output.split(" ");

			for (i in 1...parts.length) {
				var part:String = parts[i];
				parts[i] = part.charAt(0).toUpperCase() + part.substring(1, part.length).toLowerCase();
			}

			output = parts.join("");
		}

		// filter the text to make the field name valid
		return ~/[^a-zA-Z0-9]*/g.replace(output, "");
	}
	#end
}
