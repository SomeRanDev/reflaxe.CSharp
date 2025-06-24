package cscompiler.ast;

#if(macro || cs_runtime)
import cscompiler.ast.CSExpr;

import haxe.macro.Type;

/**
	Represents a C# statement.
**/
@:structInit
class CSStatement {
	public var def(default, null): CSStatementDef;
	
	public function new(def: CSStatementDef, haxeExpr: Null<TypedExpr> = null) {
		this.def = def;
	}
}
#end
