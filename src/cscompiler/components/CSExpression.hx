package cscompiler.components;

#if (macro || cs_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;

import reflaxe.compiler.EverythingIsExprSanitizer;
import reflaxe.helpers.OperatorHelper;

using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;

/**
	The component responsible for compiling Haxe
	typed expressions into C#.
**/
class CSExpression extends CSBase {
	/**
		Calls `compiler.compileExpressionOrError`.
	**/
	function _compileExpression(e: TypedExpr): Null<CSPrinter> {
		return compiler.compileExpressionOrError(e);
	}

	/**
		Implementation of `CSCompiler.compileExpressionImpl`.
	**/
	public function compile(expr: TypedExpr, topLevel: Bool): Null<CSPrinter> {
		return switch(expr.expr) {
			case TConst(constant): {
				write(constantToCS(constant));
			}
			case TLocal(v): {
				write(compiler.compileVarName(v.name, expr));
			}
			case TIdent(s): {
				write(compiler.compileVarName(s, expr));
			}
			case TArray(e1, e2): {
				_compileExpression(e1);
				write("[");
				_compileExpression(e2);
				write("]");
			}
			case TBinop(op, e1, e2): {
				write(binopToCS(op, e1, e2));
			}
			case TField(e, fa): {
				compileFieldAccess(e, fa);
			}
			case TTypeExpr(m): {
				write(compiler.compileModuleType(m));
			}
			case TParenthesis(e): {
				if(!EverythingIsExprSanitizer.isBlocklikeExpr(e)) {
					write("(");
					_compileExpression(e);
					write(")");
				} else {
					_compileExpression(e);
				}
			}
			case TObjectDecl(fields): {
				// TODO: Anonymous structure expression?
				write("/*TObjectDecl(...)*/null");
			}
			case TArrayDecl(el): {
				// TODO: Array expression?
				// result = "new type[] {" + el.map(e -> _compileExpression(e)).join(", ") + "}";
				null;
			}
			case TCall(e, el): {
				// Check for @:nativeFunctionCode (built-in Reflaxe feature)
				final nfc = compiler.compileNativeFunctionCodeMeta(e, el);
				if(nfc != null) {
					write(nfc);
				} else {
					_compileExpression(e);
					write("(");
					for (i in 0...el.length) {
						_compileExpression(el[i]);
						if (i > 0)
							write(", ");
					}
					write(")");
				}
			}
			case TNew(classTypeRef, _, el): {
				// Check for @:nativeFunctionCode (built-in Reflaxe feature)
				final nfc = compiler.compileNativeFunctionCodeMeta(expr, el);
				if(nfc != null) {
					write(nfc);
				} else {
					write("new ");
					write(compiler.compileClassName(classTypeRef.get()));
					write("(");
					for (i in 0...el.length) {
						_compileExpression(el[i]);
						if (i > 0)
							write(", ");
					}
					write(")");
				}
			}
			case TUnop(op, postFix, e): {
				write(unopToCS(op, e, postFix));
			}
			case TFunction(tfunc): {
				// TODO: Lambda?
				null;
			}
			case TVar(tvar, maybeExpr): {
				write(compiler.compileType(tvar.t, expr.pos) ?? "var");
				write(" ");
				write(compiler.compileVarName(tvar.name, maybeExpr));

				// Not guaranteed to have expression, be careful!
				if(maybeExpr != null) {
					write(" = ");
					_compileExpression(maybeExpr);
				}
				printer;
			}
			case TBlock(expressionList): {
				// TODO: Should we still generate even if empty?
				if(expressionList.length > 0) {
					beginBlock("{");
					compileBlockScope(expr);
					endBlock("}");
				}
				printer;
			}
			case TFor(tvar, iterExpr, blockExpr): {
				// TODO: When is TFor even provided (usually converted to TWhile)?
				// Will C# foreach work?
				write("foreach (var ");
				write(tvar.name);
				write(" in ");
				_compileExpression(iterExpr);
				write(") ");
				beginBlock("{");
				compileBlockScope(blockExpr);
				endBlock("}");
			}
			case TIf(condExpr, ifContentExpr, elseExpr): {
				compileIf(condExpr, ifContentExpr, elseExpr);
			}
			case TWhile(condExpr, blockExpr, normalWhile): {
				if(normalWhile) {
					write("while (");
					_compileExpression(condExpr);
					write(") ");
					beginBlock("{");
					compileBlockScope(blockExpr);
					endBlock("}");
				} else {
					write("do ");
					beginBlock("{");
					compileBlockScope(blockExpr);
					endBlock("}");
					write(" while (");
					_compileExpression(condExpr);
					write(");");
				}
			}
			case TSwitch(switchedExpr, cases, edef): {
				// Haxe only generates `TSwitch` for switch statements only using numbers (I think?).
				// So this should be safe to translate directly to C# switch.
				write("switch (");
				_compileExpression(switchedExpr);
				write(") ");
				beginBlock("{");
				for(c in cases) {
					for(v in c.values) {
						write("case ");
						_compileExpression(v);
						writeln(":");
					}
					indent();
					compileBlockScope(c.expr);
					line("break");
					unindent();
				}
				if(edef != null) {
					line("default:");
					indent();
					compileBlockScope(edef);
					line("break");
					unindent();
				}
				endBlock("}");
			}
			case TTry(e, catches): {
				write("trye ");
				beginBlock("{");
				compileBlockScope(e);
				endBlock("}");
				// TODO: Might need to guarantee Haxe exception type?
				// Use PlatformConfig
				for(c in catches) {
					write(" catch (");
					compiler.compileFunctionArgument(c.v.t, c.v.name, expr.pos, false, null);
					write(") ");
					beginBlock("{");
					compileBlockScope(c.expr);
					endBlock("}");
				}
				printer;
			}
			case TReturn(maybeExpr): {
				// Not guaranteed to have expression, be careful!
				if(maybeExpr != null) {
					write("return ");
					_compileExpression(maybeExpr);
				} else {
					write("return");
				}
			}
			case TBreak: {
				write("break");
			}
			case TContinue: {
				write("continue");
			}
			case TThrow(subExpr): {
				// Can C# throw anything?
				write("throw ");
				_compileExpression(subExpr);
				write(";");
			}
			case TCast(subExpr, maybeModuleType): {

				// Not guaranteed to have module, be careful!
				if(maybeModuleType != null) {
					write("(");
					_compileExpression(subExpr);
					write(" as ");
					compiler.compileModuleType(maybeModuleType);
					write(")");
				}
				else {
					_compileExpression(subExpr);
				}
			}
			case TMeta(metadataEntry, subExpr): {
				// TODO: Handle expression meta?
				// Only works if `-D retain-untyped-meta` is enabled.
				_compileExpression(subExpr);
			}
			case TEnumParameter(subExpr, enumField, index): {
				// TODO
				// Given an expression that is an instance of an enum,
				// generate the C# code to extract a value from this enum.
				null;
			}
			case TEnumIndex(subExpr): {
				// TODO
				// Given an expression that is an instance of an enum,
				// generate the C# code to extract its index.
				null;
			}
		}
	}

	/**
		Generate a block scope from an expression.

		If the typed expression is `TypedExprDef.TBlock`, then each
		sub-expression is compiled on a new line.

		Otherwise, the expression is compiled normally.

		Each line of the output is preemptively tabbed.
	**/
	function compileBlockScope(e: TypedExpr) {
		var el = switch(e.expr) {
			case TBlock(el): el;
			case _: [e];
		}

		if(el.length > 0) {
			compiler.compileExpressionsIntoLines(el);
		}
	}

	/**
		Generate an expression given a `TConstant` (from `TypedExprDef.TConst`).
	**/
	function constantToCS(constant: TConstant): String {
		return switch(constant) {
			case TInt(i): Std.string(i);
			case TFloat(s): s;
			case TString(s): compileString(s);
			case TBool(b): b ? "true" : "false";
			case TNull: "null";
			case TThis: "this";
			case TSuper: "super";
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
	function compileFieldAccess(e: TypedExpr, fa: FieldAccess) {
		final nameMeta: NameAndMeta = switch(fa) {
			case FInstance(_, _, classFieldRef): classFieldRef.get();
			case FStatic(_, classFieldRef): classFieldRef.get();
			case FAnon(classFieldRef): classFieldRef.get();
			case FClosure(_, classFieldRef): classFieldRef.get();
			case FEnum(_, enumField): enumField;
			case FDynamic(s): { name: s, meta: null };
		}

		return if (nameMeta.hasMeta(":native")) {
			write(nameMeta.getNameOrNative());
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

			_compileExpression(e);

			// Check if a special field access that requires the compiled expression.
			switch(fa) {
				case FAnon(classFieldRef): {
					// TODO: generate anon struct access
					// return ...
				}
				case _:
			}

			write(".");
			write(name);
		}
	}

	function compileIf(condExpr: TypedExpr, ifContentExpr: TypedExpr, elseExpr: Null<TypedExpr>) {
		write("if (");
		_compileExpression(condExpr.unwrapParenthesis());
		write(") {");
		indent();
		line();

		compileBlockScope(ifContentExpr);

		if(elseExpr != null) {
			switch(elseExpr.expr) {
				case TIf(condExpr2, ifContentExpr2, elseExpr2): {
					unindent();
					line();
					write("} else ");
					compileIf(condExpr2, ifContentExpr2, elseExpr2);
				}
				case _: {
					unindent();
					line();
					write("} else {");
					indent();
					line();

					compileBlockScope(elseExpr);

					unindent();
					line();
					write("}");
				}
			}
		} else {
			unindent();
			line();
			write("}");
		}
		return printer;
	}
}
#end