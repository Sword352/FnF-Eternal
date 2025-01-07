package funkin.core.macros;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.Compiler;

using haxe.macro.TypeTools;

/**
 * Class containing scripting-related macro utilities.
 */
class ScriptMacros {
    /**
     * Appends an `EventDispatcher` object to the parent class, along with few shortcuts.
     * @return Array<Field>
     */
    public static macro function buildEventDispatcher():Array<Field> {
        var fields:Array<Field> = Context.getBuildFields();

        // List of fields to append
        var fieldsToAdd:Map<String, String> = [
            // original name => new name
            "addListener" => "addEventListener",
            "removeListener" => "removeEventListener",
            "hasListener" => "hasEventListener",
            "stopPropagation" => "stopEventPropagation",
            "dispatch" => "dispatchEvent"
        ];

        var clsType:Type = Context.getType("funkin.core.scripting.EventDispatcher");
        var asClass:ClassType = clsType.getClass();

        fields.push({
            name: "_eventDispatcher",
            pos: Context.currentPos(),
            kind: FVar(clsType.toComplexType(), {
                pos: Context.currentPos(),
                expr: ENew({
                    pack: asClass.pack,
                    name: asClass.name
                }, [])
            }),
            meta: [{
                name: ":noCompletion",
                pos: Context.currentPos()
            }],
            access: [APrivate]
        });

        for (field in asClass.fields.get()) {
            if (fieldsToAdd.exists(field.name)) {
                var newName:String = fieldsToAdd.get(field.name);

                // assuming the expr is a TFunction
                var tfunc:TFunc = Type.enumParameters(field.expr().expr)[0];
                var args:Array<FunctionArg> = [for (arg in tfunc.args) {
                    name: arg.v.name,
                    type: arg.v.t.toComplexType(),
                    value: arg.value != null ? Context.getTypedExpr(arg.value) : null,
                    opt: arg.value != null
                }];
                var ret:ComplexType = tfunc.t.toComplexType();

                fields.push({
                    name: newName,
                    pos: Context.currentPos(),
                    access: [APublic, AInline],
                    kind: FFun({
                        ret: ret,
                        args: args,
                        expr: {
                            pos: Context.currentPos(),
                            expr: EReturn({
                                pos: Context.currentPos(),
                                expr: ECall({
                                    pos: Context.currentPos(),
                                    expr: EField(macro _eventDispatcher, field.name)
                                }, [for (arg in args) {
                                    pos: Context.currentPos(),
                                    expr: EConst(CIdent(arg.name))
                                }])
                            })
                        }
                    }),
                    doc: field.doc
                });
            }
        }

        // Find destroy method
        for (field in fields) {
            if (field.name == "destroy") {
                switch (field.kind) {
                    case FFun(func):
                        func.expr = macro $b{[func.expr].concat([macro _eventDispatcher = FlxDestroyUtil.destroy(_eventDispatcher)])};
                    case _:
                }
                break;
            }
        }

        return fields;
    }

    /**
     * Builds a regex for malicious script detection.
     * @param keywords Keywords to blacklist.
     * @return Expr
     */
    public static macro function buildSafetyRegex(keywords:Array<String>):Expr {
        for (i in 0...keywords.length)
            keywords[i] = "\\b" + StringTools.replace(keywords[i], ".", "\\.") + "\\b";
    
        var expression:String = keywords.join("|");
        return macro new EReg($v{expression}, "g");
    }

    /**
     * Compiles unused classes for scripting flexibility.
     */
    public static macro function addAdditionalClasses():Void {
        #if !display
        Compiler.include("flixel", true, ["flixel.system.macros", "flixel.addons.nape", "flixel.addons.editors"]);
        Compiler.include("openfl.display", true);
        Compiler.include("openfl.filters", true);
        #end
    }
}
