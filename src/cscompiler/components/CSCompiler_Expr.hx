package cscompiler.components;

import cscompiler.ast.CSConstant;
import cscompiler.ast.CSExpr;
#if (macro || cs_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;

import reflaxe.compiler.EverythingIsExprSanitizer;
import reflaxe.helpers.OperatorHelper;

using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;

import cscompiler.ast.CSStatement;

/**
	The component responsible for compiling Haxe
	typed expressions into C#.
**/
class CSCompiler_Expr extends CSCompiler_Base {
	/**
		Calls `compiler.compileExpressionOrError`.
	**/
	function _compileExpression(e: TypedExpr): String {
		return compiler.compileExpressionOrError(e);
	}

	/**
		Implementation of `CSCompiler.compileExpressionToCSExpr`.
	**/
	public function compileToCSExpr(expr: TypedExpr, topLevel: Bool): Null<CSExpr> {

		return switch compile(expr, topLevel)?.def {
			case null: null;

			case CSExprStatement(expression):
				expression;

			case CSBlock(statements):
				null;

			case CSIf(condition, ifContent, elseContent):
				null;

			case CSWhile(condition, content, normalWhile):
				null;

			case CSVar(varData, expr):
				null;

		}

	}

	/**
		Implementation of `CSCompiler.compileExpressionImpl`.
	**/
	public function compile(expr: TypedExpr, topLevel: Bool): Null<CSStatement> {
		return switch(expr.expr) {
			case TConst(constant): {
				haxeExpr: expr,
				def: CSExprStatement({
					haxeExpr: expr,
					def: compileConstant(constant)
				})
			}
			case TLocal(v): {
				haxeExpr: expr,
				def: CSExprStatement({
					haxeExpr: expr,
					def: CSIdent(compiler.compileVarName(v.name, expr))
				})
			}
			case TIdent(s): {
				haxeExpr: expr,
				def: CSExprStatement({
					haxeExpr: expr,
					def: CSIdent(compiler.compileVarName(s, expr))
				})
			}
			case TArray(e1, e2): {
				result = _compileExpression(e1) + "[" + _compileExpression(e2) + "]";
			}
			case TBinop(op, e1, e2): {
				result = binopToCS(op, e1, e2);
			}
			case TField(e, fa): {
				result = fieldAccessToCS(e, fa);
			}
			case TTypeExpr(m): {
				result = compiler.compileModuleType(m);
			}
			case TParenthesis(e): {
				final csExpr = _compileExpression(e);
				result = if(!EverythingIsExprSanitizer.isBlocklikeExpr(e)) {
					"(" + csExpr + ")";
				} else {
					csExpr;
				}
			}
			case TObjectDecl(fields): {
				// TODO: Anonymous structure expression?
			}
			case TArrayDecl(el): {
				// TODO: Array expression?
				// result = "new type[] {" + el.map(e -> _compileExpression(e)).join(", ") + "}";
			}
			case TCall(e, el): {
				// Check for @:nativeFunctionCode (built-in Reflaxe feature)
				final nfc = compiler.compileNativeFunctionCodeMeta(e, el);
				result = if(nfc != null) {
					nfc;
				} else {
					final arguments = el.map(e -> _compileExpression(e)).join(", ");
					_compileExpression(e) + "(" + arguments + ")";
				}
			}
			case TNew(classTypeRef, _, el): {
				// Check for @:nativeFunctionCode (built-in Reflaxe feature)
				final nfc = compiler.compileNativeFunctionCodeMeta(expr, el);
				result = if(nfc != null) {
					nfc;
				} else {
					final args = el.map(e -> _compileExpression(e)).join(", ");
					final className = compiler.compileClassName(classTypeRef.get());
					"new " + className + "(" + args + ")";
				}
			}
			case TUnop(op, postFix, e): {
				result = unopToCS(op, e, postFix);
			}
			case TFunction(tfunc): {
				// TODO: Lambda?
			}
			case TVar(tvar, maybeExpr): {
				result = compiler.compileType(tvar.t, expr.pos) + " " + compiler.compileVarName(tvar.name, maybeExpr);

				// Not guaranteed to have expression, be careful!
				if(maybeExpr != null) {
					final e = _compileExpression(maybeExpr);
					result += " = " + e;
				}
			}
			case TBlock(expressionList): {
				// TODO: Should we still generate even if empty?
				if(expressionList.length > 0) {
					result = "{\n" + toIndentedScope(expr) + "\n}";
				}
			}
			case TFor(tvar, iterExpr, blockExpr): {
				// TODO: When is TFor even provided (usually converted to TWhile)?
				// Will C# foreach work?
				result = "foreach(var " + tvar.name + " in " + _compileExpression(iterExpr) + ") {\n";
				result += toIndentedScope(blockExpr);
				result += "\n}";
			}
			case TIf(condExpr, ifContentExpr, elseExpr): {
				result = compileIf(condExpr, ifContentExpr, elseExpr);
			}
			case TWhile(condExpr, blockExpr, normalWhile): {
				final csExpr = _compileExpression(condExpr);
				if(normalWhile) {
					result = "while(" + csExpr + ") {\n";
					result += toIndentedScope(blockExpr);
					result += "\n}";
				} else {
					result = "do {\n";
					result += toIndentedScope(blockExpr);
					result += "} while(" + csExpr + ");";
				}
			}
			case TSwitch(switchedExpr, cases, edef): {
				// Haxe only generates `TSwitch` for switch statements only using numbers (I think?).
				// So this should be safe to translate directly to C# switch.
				result = "switch(" + _compileExpression(switchedExpr) + ") {\n";
				for(c in cases) {
					result += "\n";
					for(v in c.values) {
						result += "\tcase" + _compileExpression(v) + ":\n";
					}
					result += toIndentedScope(c.expr).tab();
					result += "\t\tbreak;";
				}
				if(edef != null) {
					result += "\n";
					result += "\tdefault:\n";
					result += toIndentedScope(edef).tab();
					result += "\t\tbreak;";
				}
			}
			case TTry(e, catches): {
				result += "try {\n";
				result += toIndentedScope(e);
				result += "\n}";
				// TODO: Might need to guarantee Haxe exception type?
				// Use PlatformConfig
				for(c in catches) {
					result += "catch(" + compiler.compileFunctionArgument(c.v.t, c.v.name, expr.pos, false, null) + ") {\n";
					result += toIndentedScope(c.expr);
					result += "\n}";
				}
			}
			case TReturn(maybeExpr): {
				// Not guaranteed to have expression, be careful!
				if(maybeExpr != null) {
					result = "return " + _compileExpression(maybeExpr);
				} else {
					result = "return";
				}
			}
			case TBreak: {
				result = "break";
			}
			case TContinue: {
				result = "continue";
			}
			case TThrow(subExpr): {
				// Can C# throw anything?
				result = "throw " + _compileExpression(subExpr) + ";";
			}
			case TCast(subExpr, maybeModuleType): {
				result = _compileExpression(subExpr);

				// Not guaranteed to have module, be careful!
				if(maybeModuleType != null) {
					result = "(" + result + " as " + compiler.compileModuleType(maybeModuleType) + ")";
				}
			}
			case TMeta(metadataEntry, subExpr): {
				// TODO: Handle expression meta?
				// Only works if `-D retain-untyped-meta` is enabled.
				result = _compileExpression(subExpr);
			}
			case TEnumParameter(subExpr, enumField, index): {
				// TODO
				// Given an expression that is an instance of an enum,
				// generate the C# code to extract a value from this enum.
			}
			case TEnumIndex(subExpr): {
				// TODO
				// Given an expression that is an instance of an enum,
				// generate the C# code to extract its index.
			}
		}
		/* return */ result;
	}

	/**
		Generate a block scope from an expression.

		If the typed expression is `TypedExprDef.TBlock`, then each
		sub-expression is compiled on a new line.

		Otherwise, the expression is compiled normally.

		Each line of the output is preemptively tabbed.
	**/
	function toIndentedScope(e: TypedExpr): String {
		var el = switch(e.expr) {
			case TBlock(el): el;
			case _: [e];
		}

		return if(el.length == 0) {
			"";
		} else {
			compiler.compileExpressionsIntoLines(el).tab();
		}
	}

	/**
		Generate an expression given a `TConstant` (from `TypedExprDef.TConst`).
	**/
	function compileConstant(constant: TConstant): CSConstant {
		return switch(constant) {
			case TInt(i): CSInt(i);
			case TFloat(s): CSDouble(s); // Haxe Float is actually a C# double
			case TString(s): compileString(s);
			case TBool(b): CSBool(b);
			case TNull: CSNull;
			case TThis: CSThis;
			case TSuper: CSBase;
		}
	}

	/**
		Generate the String literal for C# given its contents.
	**/
	function compileString(stringContent: String): String {
		return "\"" + StringTools.replace(StringTools.replace(stringContent, "\\", "\\\\"), "\"", "\\\"") + "\"";
	}

	/**
		Generate an expression given a `Binop` and two typed expressions (from `TypedExprDef.TBinop`).
	**/
	function binopToCS(op: Binop, e1: TypedExpr, e2: TypedExpr): String {
		var csExpr1 = _compileExpression(e1);
		var csExpr2 = _compileExpression(e2);
		final operatorStr = OperatorHelper.binopToString(op);
		return csExpr1 + " " + operatorStr + " " + csExpr2;
	}

	/**
		Generate an expression given a `Unop` and typed expression (from `TypedExprDef.TUnop`).
	**/
	function unopToCS(op: Unop, e: TypedExpr, isPostfix: Bool): String {
		final csExpr = _compileExpression(e);
		final operatorStr = OperatorHelper.unopToString(op);
		return isPostfix ? (csExpr + operatorStr) : (operatorStr + csExpr);
	}

	/**
		Generate an expression given a `FieldAccess` and typed expression (from `TypedExprDef.TField`).
	**/
	function fieldAccessToCS(e: TypedExpr, fa: FieldAccess): String {
		final nameMeta: NameAndMeta = switch(fa) {
			case FInstance(_, _, classFieldRef): classFieldRef.get();
			case FStatic(_, classFieldRef): classFieldRef.get();
			case FAnon(classFieldRef): classFieldRef.get();
			case FClosure(_, classFieldRef): classFieldRef.get();
			case FEnum(_, enumField): enumField;
			case FDynamic(s): { name: s, meta: null };
		}

		return if(nameMeta.hasMeta(":native")) {
			nameMeta.getNameOrNative();
		} else {
			final name = compiler.compileVarName(nameMeta.getNameOrNativeName());

			// Check if a special field access and intercept.
			switch(fa) {
				case FStatic(clsRef, cfRef): {
					final cf = cfRef.get();
					final className = compiler.compileClassName(clsRef.get());
					// TODO: generate static access
					// return ...
				}
				case FEnum(_, enumField): {
					// TODO: generate enum access
					// return ...
				}
				case _:
			}

			final csExpr = _compileExpression(e);

			// Check if a special field access that requires the compiled expression.
			switch(fa) {
				case FAnon(classFieldRef): {
					// TODO: generate anon struct access
					// return ...
				}
				case _:
			}

			csExpr + "." + name;
		}
	}

	function compileIf(condExpr: TypedExpr, ifContentExpr: TypedExpr, elseExpr: Null<TypedExpr>) {
		var result = "if(" + _compileExpression(condExpr.unwrapParenthesis()) + ") {\n";
		result += toIndentedScope(ifContentExpr);
		if(elseExpr != null) {
			switch(elseExpr.expr) {
				case TIf(condExpr2, ifContentExpr2, elseExpr2): {
					result += "\n} else " + compileIf(condExpr2, ifContentExpr2, elseExpr2);
				}
				case _: {
					result += "\n} else {\n";
					result += toIndentedScope(elseExpr);
					result += "\n}";
				}
			}
		} else {
			result += "\n}";
		}
		return result;
	}
}
#end