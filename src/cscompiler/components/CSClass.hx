package cscompiler.components;

#if (macro || cs_runtime)

import haxe.macro.Type;
import haxe.display.Display.MetadataTarget;

import reflaxe.BaseCompiler;

using reflaxe.helpers.SyntaxHelper;

/**
	The component responsible for compiling Haxe
	classes into C#.
**/
class CSClass extends CSBase {
	/**
		Implementation of `CSCompiler.compileClassImpl`.
	**/
	public function compile(classType: ClassType, varFields: ClassFieldVars, funcFields: ClassFieldFuncs): Null<String> {
		// Stores all the variables and fields to put together later.
		final variables = [];
		final functions = [];

		final className = classType.name;
		final csClassName = compiler.compileClassName(classType);

		var declaration = "";

		// Compile metadata (built-in Reflaxe function)
		final clsMeta = compiler.compileMetadata(classType.meta, MetadataTarget.Class);
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

			// Compile expression
			final csExpr = if(field.expr() != null) {
				compiler.compileClassVarExpr(field.expr());
			} else {
				"";
			}

			// Compile metadata
			final meta = compiler.compileMetadata(field.meta, MetadataTarget.ClassField);

			// Put it all together to make C# variable
			final decl = meta + (v.isStatic ? "static " : "") + "var " + varName + (csExpr.length == 0 ? "" : (" = " + csExpr));
			variables.push(decl);
		}

		// Functions
		for(f in funcFields) {
			final field = f.field;
			final data = f.data;

			// Compile name
			final name = field.name == "new" ? csClassName : compiler.compileVarName(field.name);

			// Compile metadata
			final meta = compiler.compileMetadata(field.meta, MetadataTarget.ClassField);

			// If a dynamic function, we want to compile as function variable.
			if(f.kind == MethDynamic) {
				// `field.expr()` gives an expression of as TypedExprDef.TFunction,
				// so we don't need to do anything special to compile it as a lambda.
				final callable = compiler.compileClassVarExpr(field.expr());
				final decl = meta + (f.isStatic ? "static " : "") + "var " + name + " = " + callable;
				variables.push(decl);
			} else {
				// Compile arguments
				// I don't know why this requires two different versions, needs to be fixed in Reflaxe.
				final arguments = if(data.tfunc != null) {
					data.tfunc.args.map(a -> compiler.compileFunctionArgument(a.v.t, a.v.name, field.pos, a.value));
				} else {
					data.args.map(a -> compiler.compileFunctionArgument(a.t, a.name, field.pos, null));
				}

				// Compile return type
				final ret = compiler.compileType(data.ret, field.pos);

				// Compile expression - Use `data.expr` instead of `field.expr()`
				// since it gives us the contents of the function.
				final csExpr = compiler.compileClassFuncExpr(data.expr);
				
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
}

#end
