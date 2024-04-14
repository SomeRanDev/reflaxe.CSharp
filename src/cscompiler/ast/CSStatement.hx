package cscompiler.ast;

#if (macro || cs_runtime)

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

enum CSStatementDef {
	CSExprStatement(expression: CSExpr);

	CSBlock(statements: Array<CSStatement>);

	/**
		TODO: else if
	**/
	CSIf(condition: CSExpr, ifContent: Array<CSStatement>, elseContent: Null<Array<CSStatement>>);

	CSWhile(condition: CSExpr, content: Array<CSStatement>, normalWhile: Bool);

	/**
	 	Used for TFor, although in practice it's not really happening as all
		TFor are converted to while
	**/
	CSForeach(varData: CSVar, iterExpr: CSExpr, content: Array<CSStatement>);

	/**
	 	C# Switch
	**/
	CSSwitch(subject: CSExpr, cases:Array<{value: CSExpr, content: Null<Array<CSStatement>>}>, edef: Null<Array<CSStatement>>);

	CSBreak;

	CSContinue;

	/**
		A variable declaration `var varData` or `var varData = expr`.
	**/
	CSVar(varData: CSVar, expr: Null<CSExpr>);
}

#end
