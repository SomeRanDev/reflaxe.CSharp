package cscompiler.ast;

#if(macro || cs_runtime)
import cscompiler.ast.CSTypePath;

import haxe.macro.Expr;
import haxe.macro.Type;

/**
	Represents a C# (typed) expression.
**/
@:structInit
class CSExpr {
	public var def(default, null): CSExprDef;
	public var haxeExpr(default, null): Null<TypedExpr> = null;
	public var type(default, null): Null<CSType> = null;
	
	public function new(def: CSExprDef, haxeExpr: Null<TypedExpr> = null,
			type: Null<CSType> = null) {
		this.def = def;
		this.haxeExpr = haxeExpr;
		this.type = type;
	}
}
#end
