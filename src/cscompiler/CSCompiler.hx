package cscompiler;

#if (macro || cs_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import haxe.display.Display.MetadataTarget;

import reflaxe.BaseCompiler;
import reflaxe.PluginCompiler;
import reflaxe.compiler.EverythingIsExprSanitizer;
import reflaxe.helpers.OperatorHelper;

using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.ModuleTypeHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.NullableMetaAccessHelper;
using reflaxe.helpers.OperatorHelper;
using reflaxe.helpers.TypedExprHelper;
using reflaxe.helpers.TypeHelper;

/**
	The class that manages the generation of the C# code.

	Its "impl" functions are called from Reflaxe.
**/
class CSCompiler extends reflaxe.PluginCompiler<CSCompiler> {
	/**
		Called at the start of compilation.
	**/
	public override function onCompileStart() {
	}

	/**
		Required for adding semicolons at the end of each line. Overridden from Reflaxe.
	**/
	override function formatExpressionLine(expr: String): String {
		return expr + ";";
	}

	/**
		Get the name of the `ClassType` as it should appear in
		the C# output.
	**/
	function compileClassName(classType: ClassType): String {
		return classType.getNameOrNative();
	}

	/**
		Generate the C# output given the Haxe class information.
	**/
	public function compileClassImpl(classType: ClassType, varFields: ClassFieldVars, funcFields: ClassFieldFuncs): Null<String> {
		// Stores all the variables and fields to put together later.
		final variables = [];
		final functions = [];

		final className = classType.name;
		final csClassName = compileClassName(classType);

		var declaration = "";

		// Compile metadata (built-in Reflaxe function)
		final clsMeta = compileMetadata(classType.meta, MetadataTarget.Class);
		declaration += clsMeta;

		// Basic declaration
		declaration += "class " + csClassName;
		if(classType.superClass != null) {
			declaration += " extends " + compileClassName(classType.superClass.t.get());
		}

		// Variables
		for(v in varFields) {
			final field = v.field;

			// Compile name
			final varName = compileVarName(field.name, null, field);

			// Compile expression
			final csExpr = if(field.expr() != null) {
				compileClassVarExpr(field.expr());
			} else {
				"";
			}

			// Compile metadata
			final meta = compileMetadata(field.meta, MetadataTarget.ClassField);

			// Put it all together to make C# variable
			final decl = meta + (v.isStatic ? "static " : "") + "var " + varName + (csExpr.length == 0 ? "" : (" = " + csExpr));
			variables.push(decl);
		}

		// Functions
		for(f in funcFields) {
			final field = f.field;
			final data = f.data;

			// Compile name
			final name = field.name == "new" ? csClassName : compileVarName(field.name);

			// Compile metadata
			final meta = compileMetadata(field.meta, MetadataTarget.ClassField);

			// If a dynamic function, we want to compile as function variable.
			if(f.kind == MethDynamic) {
				// `field.expr()` gives an expression of as TypedExprDef.TFunction,
				// so we don't need to do anything special to compile it as a lambda.
				final callable = compileClassVarExpr(field.expr());
				final decl = meta + (f.isStatic ? "static " : "") + "var " + name + " = " + callable;
				variables.push(decl);
			} else {
				// Compile arguments
				// I don't know why this requires two different versions, needs to be fixed in Reflaxe.
				final arguments = if(data.tfunc != null) {
					data.tfunc.args.map(a -> compileFunctionArgument(a.v.t, a.v.name, field.pos, a.value));
				} else {
					data.args.map(a -> compileFunctionArgument(a.t, a.name, field.pos, null));
				}

				// Compile return type
				final ret = compileType(data.ret, field.pos);

				// Compile expression - Use `data.expr` instead of `field.expr()`
				// since it gives us the contents of the function.
				final csExpr = compileClassFuncExpr(data.expr);
				
				// Put it all together to make the C# function
				final func = meta + "public " + (f.isStatic ? "static " : "") + ret + " " + name + "(" + arguments.join(", ") + ") " + "{\n" + csExpr.tab() + "\n}";
				functions.push(func);
			}
		}

		// if there are no instance variables or functions,
		// we don't need to generate a class
		if(variables.length <= 0 && functions.length <= 0) {
			return null;
		}

		// Let's put everything together to make the C# class!
		return {
			final content = [];

			if(variables.length > 0) {
				content.push(variables.map(v -> v.tab()).join("\n\n"));
			}

			if(functions.length > 0) {
				content.push(functions.map(v -> v.tab()).join("\n\n"));
			}

			var result = declaration + " {\n";
			result += content.join("\n\n");
			result += "\n}\n";
			result;
		}
	}

	/**
		Generates the C# type from `haxe.macro.Type`.

		A `Position` is provided so compilation errors can be reported to it.
	**/
	function compileType(type: Type, pos: Position): String {
		return switch(type) {
			case TAbstract(_.get() => { name: "Void" }, []): {
				"void";
			}
			case TAbstract(_.get() => { name: "Int" }, []): {
				"int";
			}
			case _: {
				"UNKNOWN_TYPE";
			}
		}
	}

	/**
		Generate the C# output for a function argument.
	**/
	function compileFunctionArgument(t: Type, name: String, pos: Position, expr: Null<TypedExpr> = null) {
		var result = compileType(t, pos) + " " + compileVarName(name);
		if(expr != null) {
			result += " = " + compileExpression(expr);
		}
		return result;
	}

	/**
		Generate the C# output given the Haxe enum information.

		TODO: Later cause I'm lazy.
	**/
	public function compileEnumImpl(enumType: EnumType, options: EnumOptions): Null<String> {
		return null;
	}
  
	/**
		Generate the C# output given the Haxe typed expression (`TypedExpr`).
	**/
	public function compileExpressionImpl(expr: TypedExpr): Null<String> {
		var result = "";
		switch(expr.expr) {
			case TConst(constant): {
				result = constantToCS(constant);
			}
			case TLocal(v): {
				result = compileVarName(v.name, expr);
				if(v.meta.maybeHas(":arrayWrap")) {
					result = result + "[0]";	
				}
			}
			case TIdent(s): {
				result = compileVarName(s, expr);
			}
			case TArray(e1, e2): {
				result = compileExpression(e1) + "[" + compileExpression(e2) + "]";
			}
			case TBinop(op, e1, e2): {
				result = binopToCS(op, e1, e2);
			}
			case TField(e, fa): {
				result = fieldAccessToCS(e, fa);
			}
			case TTypeExpr(m): {
				result = moduleNameToCS(m);
			}
			case TParenthesis(e): {
				final csExpr = compileExpression(e);
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
				// result = "new type[] {" + el.map(e -> compileExpression(e)).join(", ") + "}";
			}
			case TCall(e, el): {
				// Check for @:nativeFunctionCode (built-in Reflaxe feature)
				final nfc = this.compileNativeFunctionCodeMeta(e, el);
				result = if(nfc != null) {
					nfc;
				} else {
					final arguments = el.map(e -> compileExpression(e)).join(", ");
					compileExpression(e) + "(" + arguments + ")";
				}
			}
			case TNew(classTypeRef, _, el): {
				// Check for @:nativeFunctionCode (built-in Reflaxe feature)
				final nfc = this.compileNativeFunctionCodeMeta(expr, el);
				result = if(nfc != null) {
					nfc;
				} else {
					final args = el.map(e -> compileExpression(e)).join(", ");
					final className = compileClassName(classTypeRef.get());
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
				result = compileType(tvar.t, expr.pos) + " " + compileVarName(tvar.name, maybeExpr);

				// Not guaranteed to have expression, be careful!
				if(maybeExpr != null) {
					final e = compileExpression(maybeExpr);
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
				result = "foreach(var " + tvar.name + " in " + compileExpression(iterExpr) + ") {\n";
				result += toIndentedScope(blockExpr);
				result += "\n}";
			}
			case TIf(condExpr, ifContentExpr, elseExpr): {
				result = compileIfToCs(condExpr, ifContentExpr, elseExpr);
			}
			case TWhile(condExpr, blockExpr, normalWhile): {
				final csExpr = compileExpression(condExpr);
				if(normalWhile) {
					result = "while " + csExpr + "{\n";
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
				result = "switch(" + compileExpression(switchedExpr) + ") {\n";
				for(c in cases) {
					result += "\n";
					for(v in c.values) {
						result += "\tcase" + compileExpression(v) + ":\n";
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
					result += "catch(" + compileFunctionArgument(c.v.t, c.v.name, expr.pos, null) + ") {\n";
					result += toIndentedScope(c.expr);
					result += "\n}";
				}
			}
			case TReturn(maybeExpr): {
				// Not guaranteed to have expression, be careful!
				if(maybeExpr != null) {
					result = "return " + compileExpression(maybeExpr);
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
				result = "throw " + compileExpression(subExpr) + ";";
			}
			case TCast(subExpr, maybeModuleType): {
				result = compileExpression(subExpr);

				// Not guaranteed to have module, be careful!
				if(maybeModuleType != null) {
					result = "(" + result + " as " + moduleNameToCS(maybeModuleType) + ")";
				}
			}
			case TMeta(metadataEntry, subExpr): {
				// TODO: Handle expression meta?
				// Only works if `-D retain-untyped-meta` is enabled.
				result = compileExpression(subExpr);
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
		return result;
	}

	/**
		Generate a block scope from an expression.

		If the typed expression is `TypedExprDef.TBlock`, then each
		sub-expression is compiled on a new line.

		Otherwise, the expression is compiled normally.

		Each line of the output is preemptively tabbed.
	**/
	function toIndentedScope(e: TypedExpr): String {
		final comExpr = e -> {
			final cs = compileExpression(e);
			return cs == null ? null : (cs.tab() + ";");
		};

		return switch(e.expr) {
			case TBlock(expressionList): {
				expressionList.map(comExpr).join("\n");
			}
			case _: {
				comExpr(e);
			}
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
		var csExpr1 = compileExpression(e1);
		var csExpr2 = compileExpression(e2);
		final operatorStr = OperatorHelper.binopToString(op);
		return csExpr1 + " " + operatorStr + " " + csExpr2;
	}

	/**
		Generate an expression given a `Unop` and typed expression (from `TypedExprDef.TUnop`).
	**/
	function unopToCS(op: Unop, e: TypedExpr, isPostfix: Bool): String {
		final csExpr = compileExpression(e);
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
			final name = compileVarName(nameMeta.getNameOrNativeName());

			// Check if a special field access and intercept.
			switch(fa) {
				case FStatic(clsRef, cfRef): {
					final cf = cfRef.get();
					final className = compileClassName(clsRef.get());
					// TODO: generate static access
					// return ...
				}
				case FEnum(_, enumField): {
					// TODO: generate enum access
					// return ...
				}
				case _:
			}

			final csExpr = compileExpression(e);

			// Check if a special field access that requires the compiled expression.
			switch(fa) {
				case FAnon(classFieldRef): {
					// TODO: generate anon struct access
					// return ...
				}
				case _:
			}

			return csExpr + "." + name;
		}
	}

	function compileIfToCs(condExpr: TypedExpr, ifContentExpr: TypedExpr, elseExpr: TypedExpr) {
		var result = "if(" + compileExpression(condExpr.unwrapParenthesis()) + ") {\n";
		result += toIndentedScope(ifContentExpr);
		if(elseExpr != null) {
			switch(elseExpr.expr) {
				case TIf(condExpr2, ifContentExpr2, elseExpr2): {
					result += "\n} else " + compileIfToCs(condExpr2, ifContentExpr2, elseExpr2);
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

	/**
		Generate C# output for `ModuleType` used in an expression (i.e. for cast).
	**/
	function moduleNameToCS(m: ModuleType): String {
		switch(m) {
			case TClassDecl(clsRef): compileClassName(clsRef.get());
			case _:
		}
		return m.getNameOrNative();
	}
}

#end