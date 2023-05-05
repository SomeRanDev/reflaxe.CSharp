package cscompiler.components;

#if (macro || cs_runtime)

import haxe.macro.Type;
import haxe.display.Display.MetadataTarget;

import reflaxe.BaseCompiler;
import reflaxe.data.ClassVarData;
import reflaxe.data.ClassFuncData;

using reflaxe.helpers.SyntaxHelper;

/**
	The component responsible for compiling Haxe
	classes into C#.
**/
class CSClass extends CSBase {
	/**
		Implementation of `CSCompiler.compileClassImpl`.
	**/
	public function compile(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<String> {
		// Stores all the variables and fields to put together later.
		final variables = [];
		final functions = [];

		final className = classType.name;
		final csClassName = compiler.compileClassName(classType);

		final classPack = classType.pack;
		final csNameSpace = compiler.packToNameSpace(classPack);

		var declaration = "";

		// Compile metadata (built-in Reflaxe function)
		final clsMeta = compiler.compileMetadata(classType.meta, MetadataTarget.Class) ?? "";
		declaration += clsMeta;

		// Basic declaration
		declaration += "class " + csClassName;
		if(classType.superClass != null) {
			declaration += " extends " + compiler.compileClassName(classType.superClass.t.get());
		}

		// Variables
		for(v in varFields) {
			final field = v.field;

			// Compile name
			final varName = compiler.compileVarName(field.name, null, field);

			// Compile type
			final varType = compiler.compileType(field.type, field.pos);

			// Compile expression
			final e = field.expr();
			final csExpr = if(e != null) {
				compiler.compileClassVarExpr(e);
			} else {
				"";
			}

			// Compile metadata
			final meta = compiler.compileMetadata(field.meta, MetadataTarget.ClassField) ?? "";

			// Put it all together to make C# variable
			final decl = meta + (v.isStatic ? "static " : "") + (varType ?? "var") + " " + varName + (csExpr.length == 0 ? "" : (" = " + csExpr)) + ";";
			variables.push(decl);
		}

		// Functions
		for(f in funcFields) {
			final field = f.field;

			// Compile name
			final name = field.name == "new" ? csClassName : compiler.compileVarName(field.name);

			// Compile metadata
			final meta = compiler.compileMetadata(field.meta, MetadataTarget.ClassField) ?? "";

			// If a dynamic function, we want to compile as function variable.
			if(f.kind == MethDynamic) {
				// `field.expr()` gives an expression of as TypedExprDef.TFunction,
				// so we don't need to do anything special to compile it as a lambda.
				final e = field.expr();
				if(e != null) {
					final callable = compiler.compileClassVarExpr(e);
					final decl = meta + (f.isStatic ? "static " : "") + "var " + name + " = " + callable;
					variables.push(decl);
				}
			} else {
				// Compile arguments
				final arguments = f.args.map(a -> compiler.compileFunctionArgument(a.type, a.name, field.pos, a.opt, a.expr));

				// Compile return type
				final ret = compiler.compileType(f.ret, field.pos);

				// Compile expression - Use `data.expr` instead of `field.expr()`
				// since it gives us the contents of the function.
				final csExpr = {
					if(f.expr != null) {
						final code = compiler.compileClassFuncExpr(f.expr);
						"{\n" + code.tab() + "\n}";
					} else {
						";";
					}
				}

				// Put it all together to make the C# function
				final func = meta + "public " + (f.isStatic ? "static " : "virtual ") + ret + " " + name + "(" + arguments.join(", ") + ") " + csExpr;
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

			result = compiler.wrapNameSpace(csNameSpace, result);
			result = compiler.cleanWhiteSpaces(result);

			result;
		}
	}
}

#end
