package cscompiler.ast;

#if (macro || cs_runtime)

import cscompiler.ast.CSExpr;
import haxe.macro.Type;

/**
	Represents a C# statement.
**/
@:structInit
class CSStatement {
	public var def(default, null): CSStatementDef;
	public var haxeExpr(default, null): Null<TypedExpr> = null;

	public function new(def: CSStatementDef, haxeExpr: Null<TypedExpr> = null) {
		this.def = def;
		this.haxeExpr = haxeExpr;
	}

}

#end
