package cscompiler.ast;

#if (macro || cs_runtime)

import haxe.macro.Type;

/**
	Represents a C# statement.
**/
class CSStatement {
	public var def(default, null): CSStatementDef;
	public var haxeExpr(default, null): Null<TypedExpr>;

	public function new(def: CSStatementDef, haxeExpr: Null<TypedExpr> = null) {
		this.def = def;
		this.haxeExpr = haxeExpr;
	}

}

enum CSStatementDef {
	CSExprStatement(expression: CSExpr);

	CSBlock(statements: Array<CSStatement>);

	/**
		TODO: else if
	**/
	CSIf(condition: CSExpr, ifContent: Array<CSStatement>, elseContent: Null<Array<CSStatement>>);

	CSWhile(condition: CSExpr, content: Array<CSStatement>, normalWhile: Bool);

	/**
		A variable declaration `var varData` or `var varData = expr`.
	**/
	CSVar(varData: CSVar, expr: Null<CSExpr>);
}

#end
