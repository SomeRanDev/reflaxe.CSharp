package cscompiler.components;

#if (macro || cs_runtime)

import haxe.macro.Type;
import haxe.display.Display.MetadataTarget;

import reflaxe.BaseCompiler;
import reflaxe.data.ClassVarData;
import reflaxe.data.ClassFuncData;
import reflaxe.input.ClassHierarchyTracker;

using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;

/**
	The component responsible for compiling Haxe
	classes into C#.
**/
class CSClass extends CSBase {

	/**
		C# name of the class currently being compiled.
	**/
	var csClassName: String = "";

	/**
		C# namespace of the class  currently being compiled.
	**/
	var csNameSpace: String = "";

	/**
		Called at the start of a class' compilation to reset the variables.
	**/
	function init(classType: ClassType) {

		final className = classType.name;
		csClassName = compiler.compileClassName(classType);
		csNameSpace = compiler.typeComp.compileNameSpace(classType);
	}

	/**
		Implementation of `CSCompiler.compileClassImpl`.
	**/
	public function compile(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>) {

		// TODO: Set the output folder for the file this will be generated for
		// compiler.setOutputFileDir("src");

		// Stores all the variables and fields to put together later.
		init(classType);

		// Compile namespace
		write("namespace ");
		write(csNameSpace);
		write(" {");
		indent();
		line();

		// Compile metadata (built-in Reflaxe function)
		final clsMeta = compiler.compileMetadata(classType.meta, MetadataTarget.Class) ?? "";
		write(clsMeta);

		// Basic declaration
		write("class " + csClassName);
		if(classType.superClass != null) {
			write(": " + compiler.compileClassName(classType.superClass.t.get()));
		}
		write(" {");
		line();

		// Variables
		for(v in varFields) {
			compileVariable(v);
		}

		// Functions
		for(f in funcFields) {
			compileFunction(f, classType);
		}

		// End of class
		unindent();
		line("}");

		// End of namespace
		unindent();
		line("}");

		return printer;

	}

	/**
		Compiles the class variable.
	**/
	function compileVariable(v: ClassVarData) {
		final field = v.field;

		// Compile metadata
		final meta = compiler.compileMetadata(field.meta, MetadataTarget.ClassField);

		// Put it all together to make C# variable
		if (meta != null)
			write(meta);

		if (v.isStatic)
			write("static ");

		// Compile type
		write(compiler.compileType(field.type, field.pos) ?? "var");

		// Compile name
		final varName = compiler.compileVarName(field.name, null, field);
		write(" ");
		write(varName);

		// Compile expression
		final e = field.expr();
		if (e != null) {
			write(" = ");
			compiler.compileClassVarExpr(e);
		}

		write(";");
		line();

	}

	/**
		Compiles the class function.
	**/
	function compileFunction(f: ClassFuncData, classType: ClassType) {
		final field = f.field;

		final isConstructor = (field.name == "new");

		// Compile name
		final name = isConstructor ? csClassName : compiler.compileVarName(field.name);

		// Compile metadata
		final meta = compiler.compileMetadata(field.meta, MetadataTarget.ClassField);
		if (meta != null)
			write(meta);

		// If a dynamic function, we want to compile as function variable.
		if(f.kind == MethDynamic) {
			// `field.expr()` gives an expression of as TypedExprDef.TFunction,
			// so we don't need to do anything special to compile it as a lambda.
			final e = field.expr();
			if(e != null) {
				if (f.isStatic)
					write("static");

				write("var ");
				write(name);
				write(" = ");

				compiler.compileClassVarExpr(e);
			}
		} else {
			// Compile arguments
			final arguments = f.args.map(a -> {
				if (a.isFrontOptional())
					compiler.compileFunctionArgument(a.type, a.name, field.pos, false, null);
				else
					compiler.compileFunctionArgument(a.type, a.name, field.pos, a.opt, a.expr);
			});

			// Compile return type
			final ret = isConstructor ? null : compiler.compileType(f.ret, field.pos);

			for (modifier in getFunctionModifiers(f, classType)) {
				write(modifier);
				write(" ");
			}

			if (!isConstructor && ret != null) {
				write(ret);
				write(" ");
			}

			write(name);

			write("(");
			for (a in f.args) {
				if (a.isFrontOptional())
					compiler.compileFunctionArgument(a.type, a.name, field.pos, false, null);
				else
					compiler.compileFunctionArgument(a.type, a.name, field.pos, a.opt, a.expr);
			}
			write(")");


			// Compile expression - Use `data.expr` instead of `field.expr()`
			// since it provides the contents of the function.
			if(f.expr != null) {
				write("{");
				indent();
				line();

				compiler.compileClassFuncExpr(f.expr);

				unindent();
				line();
				write("}");

			} else {
				write(";");
			}
			line();

			// Resolve variations
			// For now, we skip that part, because variation based on overload won't cover all cases anyway (dynamic access...)
			// TODO: Will get back to this later

			// final variations = f.findAllArgumentVariations(true, true);
			// if(variations != null && variations.length > 1) {
			// 	for(v in variations) {
			// 		if (v.args.length < f.args.length) {
			// 			// Compile arguments
			// 			final vArguments = v.args.map(a -> compiler.compileFunctionArgument(a.type, a.name, field.pos, a.opt, a.expr));

			// 			// Compile internal call arguments
			// 			final vCallArgs = f.args.map(a -> {
			// 				var def = true;
			// 				for(arg in v.args) {
			// 					if(arg.name == a.name) {
			// 						def = false;
			// 						break;
			// 					}
			// 				}
			// 				def && a.expr != null ? compiler.compileExpression(a.expr) : a.name;
			// 			});

			// 			// Compile metadata
			// 			final meta = compiler.compileMetadata(field.meta, MetadataTarget.ClassField);
			// 			if (meta != null)
			// 				write(meta);

			// 			for (modifier in getFunctionModifiers(f, classType)) {
			// 				write(modifier);
			// 				write(" ");
			// 			}

			// 			// Compile expression
			// 			final csExpr = {
			// 				if(f.expr != null) {
			// 					final code = (ret != "void" ? "return " : "") + name + "(" + vCallArgs.join(", ") + ");";
			// 					"{\n" + code.tab() + "\n}";
			// 				} else {
			// 					";";
			// 				}
			// 			}

			// 			final func = meta + props + " " + ret + " " + name + "(" + vArguments.join(", ") + ") " + csExpr;

			// 			write(func);
			// 		}
			// 	}
			// }
		}
	}

	/**
		Get a list of all the C# modifiers to be prepended to a C# function.
	**/
	function getFunctionModifiers(f: ClassFuncData, classType: ClassType): Array<String> {
		final field = f.field;

		final props = [ "public" ]; // Always public

		if(f.isStatic) {
			props.push("static");
		} else {
			// Add virtual if @:virtual meta OR has child override
			if(field.hasMeta(":virtual") || ClassHierarchyTracker.funcHasChildOverride(classType, field, false)) {
				props.push("virtual");
			} else if(field.hasMeta(":override") || ClassHierarchyTracker.getParentOverrideChain(f).length > 0) {
				props.push("override");
			}
		}

		return props;
	}
}

#end
