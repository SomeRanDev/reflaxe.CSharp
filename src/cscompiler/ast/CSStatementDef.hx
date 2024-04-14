package cscompiler.ast;

#if (macro || cs_runtime)

import cscompiler.ast.CSExpr;
import haxe.macro.Type;

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

	/**
	 	C# Try/Catch
	**/
	CSTry(content: Array<CSStatement>, catches: Array<{name: String, type: CSType, content: Array<CSStatement>}>);

	CSBreak;

	CSContinue;

	CSReturn(maybeExpr: Null<CSExpr>);

	CSThrow(expr: CSExpr);

	/**
		A C# cast. Either by using `(T) V` (direct casting) or `V as T` (reference type/nullable cast)
	**/
	CSCast(expr: CSExpr, type: CSType, directCasting:Bool);

	/**
		A variable declaration `var varData` or `var varData = expr`.
	**/
	CSVar(varData: CSVar, expr: Null<CSExpr>);
}

#end