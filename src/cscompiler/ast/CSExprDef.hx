package cscompiler.ast;

#if (macro || cs_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;

/**
	TODO: Give each case a better description.
**/
enum CSExprDef {
	/**
		A constant.
	**/
	CSConst(constant: CSConstant);

	/**
		Reference to a local variable `varData`.
	**/
	CSLocalVar(varData: CSVar);

	/**
		Array access `baseExpr[indexExpr]`.
	**/
	CSArray(baseExpr: CSExpr, indexExpr: CSExpr);

	/**
		Binary operator `leftExpr op rightExpr`.
	**/
	// TODO Binop to CSBinop (because some operators are not supported by C#)
	CSBinop(op: Binop, leftExpr: CSExpr, rightExpr: CSExpr);

	/**
		Field access on `e` of name `fieldName`.
	**/
	CSField(e: CSExpr, fieldAccess: CSFieldAccess);

	/**
		Reference to a C# type (class, enum...).
	**/
	CSTypeExpr(type: CSType);

	/**
		Parentheses `(e)`.
	**/
	CSParenthesis(e: CSExpr);

	/**
		An array declaration `{ expressions }`.
	**/
	CSArrayDecl(expressions: Array<CSExpr>);

	/**
		A call `baseExpr<typeParams>(arguments)`.
	**/
	CSCall(baseExpr: CSExpr, typeParams: Array<CSType>, arguments: Array<CSExpr>);

	/**
		A constructor call `new cls<typeParams>(arguments)`.
	**/
	CSNew(cls: CSTypePath, typeParams: Array<CSType>, arguments: Array<CSExpr>);

	/**
		An unary operator `op` on `baseExpr`.

		TODO:
		Is postfix necessary?
	**/
	CSUnop(op: Unop, postFix: Bool, baseExpr: CSExpr);

	/**
		A function declaration.
	**/
	CSFunctionExpr(tfunc: CSFunction);

	/**
		An unknown identifier.
	**/
	CSIdent(s: String);
}

#end
