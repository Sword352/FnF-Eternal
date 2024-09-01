package funkin.core.macros;

import haxe.macro.Compiler;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;
import haxe.macro.Context;

/**
 * Macro which builds `reset` and `setup` methods to (re)set properties on scripting events, so that they can be re-used.
 * - By declaring a variable with the `@:eventConstructor` metadata, it's going to be an argument to pass in the `setup` method.
 * - By declaring a variable with the `@:eventValue` metadata, it will be reset whenever the `reset` method is called.
 */
class ScriptEventMacro {
    #if macro
    /**
     * Builds `reset` and `setup` methods.
     */
    public static function build():Array<Field> {
        var fields:Array<Field> = Context.getBuildFields();
        if (Context.defined("display")) return fields;

        var resetValues:Map<String, Expr> = [];
        var resetOrder:Array<String> = [];

        var setupValues:Map<String, SetupData> = [];
        var setupOrder:Array<String> = [];

        var invalidFields:Array<String> = ["reset", "setup"];
        var duplicates:Array<String> = [];

        for (field in fields) {
            for (meta in field.meta) {
                switch (meta.name) {
                    case ":eventValue":
                        switch (field.kind) {
                            case FVar(_, expr) | FProp(_, _, _, expr):
                                resetValues.set(field.name, expr);
                                resetOrder.push(field.name);
                            case _:
                                Context.warning('@:eventValue cannot be used with field "${field.name}"! (Invalid field kind)', Context.currentPos());
                                continue;
                        }
                    case ":eventConstructor":
                        switch (field.kind) {
                            case FVar(type, expr) | FProp(_, _, type, expr):
                                setupValues.set(field.name, {expr: expr, type: type, doc: field.doc});
                                setupOrder.push(field.name);
                            case _:
                                Context.warning('@:eventConstructor cannot be used with field "${field.name}"! (Invalid field kind)', Context.currentPos());
                                continue;
                        }
                }
            }

            if (invalidFields.contains(field.name)) {
                duplicates.push(field.name);
            }
        }

        if (resetOrder.length == 0 && setupOrder.length == 0) {
            return fields;
        }

        if (resetOrder.length > 0) {
            if (duplicates.contains("reset")) {
                Context.error("reset cannot be overridden!", Context.currentPos());
            }

            var resetExpr:Array<Expr> = [];

            for (value in resetOrder) {
                var val:Expr = resetValues.get(value);
                resetExpr.push(macro $i{value} = ${val});
            }
    
            resetExpr.push(macro super.reset());
    
            fields.push({
                name: "reset",
                pos: Context.currentPos(),
                doc: "Reset properties for this event so that it can be re-used.",
                access: [AOverride, APublic],
                kind: FFun({
                    expr: macro $b{resetExpr},
                    args: []
                })
            });
        }

        if (setupOrder.length > 0) {
            if (duplicates.contains("setup")) {
                Context.error("Cannot declare field setup!", Context.currentPos());
            }

            var setupExpr:Array<Expr> = [];
            var setupArgs:Array<FunctionArg> = [];
            var documentation:Array<String> = ["Setup this event."];

            for (value in setupOrder) {
                var data:SetupData = setupValues.get(value);
                var doc:String = "@param " + value;

                if (data.doc != null)
                    doc += " " + data.doc;
                
                documentation.push(doc);

                setupArgs.push({
                    name: value,
                    type: data.type,
                    value: data.expr,
                    opt: data.expr != null
                });

                setupExpr.push({
                    pos: Context.currentPos(),
                    expr: EBinop(OpAssign, macro this.$value, {
                        pos: Context.currentPos(),
                        expr: EConst(CIdent(value))
                    })
                });
            }

            setupExpr.push(macro return this);

            fields.push({
                name: "setup",
                pos: Context.currentPos(),
                doc: documentation.join("\n"),
                access: [APublic],
                kind: FFun({
                    expr: macro $b{setupExpr},
                    args: setupArgs
                })
            });
        }

        return fields;
    }
    #end
}

#if macro
typedef SetupData = {
    var expr:Expr;
    var type:ComplexType;
    var doc:String;
}
#end
