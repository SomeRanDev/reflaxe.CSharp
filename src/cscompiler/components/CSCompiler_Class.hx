package cscompiler.components;

import cscompiler.ast.CSVar;
import cscompiler.ast.CSField;
#if (macro || cs_runtime)

import haxe.macro.Type;
import haxe.display.Display.MetadataTarget;

import cscompiler.ast.CSClass;
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
class CSCompiler_Class extends CSCompiler_Base {
	/**
		The list of fields compiled into C# accumulated while compiling the class.
	**/
	var csFields: Array<CSField> = [];

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
		csFields = [];

		final className = classType.name;
		csClassName = compiler.compileClassName(classType);
		csNameSpace = compiler.typeComp.getNameSpace(classType);
	}

	/**
		Implementation of `CSCompiler.compileClassImpl`.
	**/
	public function compile(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<CSClass> {
		// Temp fix for CSType return
		return null;

		// Stores all the variables and fields to put together later.
		init(classType);

		// TODO convert metadata to C# attributes
		//compiler.compileMetadata(classType.meta, MetadataTarget.Class);

		// Basic declaration
		if(classType.superClass != null) {
			// TODO superclass
		}

		// TODO when reflax will provide a field iterator, we'll use that
		// Instead of querying varFields and funcFields
		for(v in varFields) {
			compileVariable(v);
		}
		for(f in funcFields) {
			compileFunction(f, classType);
		}

		// TODO namespace here or in parent AST node?

		return {
			name: csClassName,
			fields: csFields
		};

	}

	/**
		Compiles the class variable.
	**/
	function compileVariable(v: ClassVarData):CSField {
		final field = v.field;

		// Compile name
		final varName = compiler.compileVarName(field.name, null, field);

		// Compile type
		final varType = compiler.compileType(field.type, field.pos);

		// Compile expression
		final e = field.expr();
		final csExpr = compiler.compileClassVarExpr(e);

		// TODO handle getters/setters

		// Compile metadata
		// TODO C# attributes from meta
		//final meta = compiler.compileMetadata(field.meta, MetadataTarget.ClassField) ?? "";

		return {
			name: varName,
			access: [CSPublic], // TODO
			kind: CSVar(
				varType,
				csExpr
			)
		}

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
			final arguments = f.args.map(a -> {
				if (a.isFrontOptional())
					compiler.compileFunctionArgument(a.type, a.name, field.pos, false, null);
				else
					compiler.compileFunctionArgument(a.type, a.name, field.pos, a.opt, a.expr);
			});

			// Compile return type
			final ret = isConstructor ? null : compiler.compileType(f.ret, field.pos);

			// Compile expression - Use `data.expr` instead of `field.expr()`
			// since it provides the contents of the function.
			final csExpr = {
				if(f.expr != null) {
					final code = compiler.compileClassFuncExpr(f.expr);
					"{\n" + code.tab() + "\n}";
				} else {
					";";
				}
			}

			// Put it all together to make the C# function
			final props = compileFunctionProperties(f, classType).join(" ");
			final func = meta + props + " " + (!isConstructor ? ret + " " : "") + name + "(" + arguments.join(", ") + ") " + csExpr;
			functions.push(func);

			// Resolve variations
			final variations = f.findAllArgumentVariations(true, true);
			if(variations != null && variations.length > 1) {
				for(v in variations) {
					if (v.args.length < f.args.length) {
						// Compile arguments
						final vArguments = v.args.map(a -> compiler.compileFunctionArgument(a.type, a.name, field.pos, a.opt, a.expr));

						// Compile internal call arguments
						final vCallArgs = f.args.map(a -> {
							var def = true;
							for(arg in v.args) {
								if(arg.name == a.name) {
									def = false;
									break;
								}
							}
							def && a.expr != null ? compiler.compileExpression(a.expr) : a.name;
						});

						// Compile expression
						final csExpr = {
							if(f.expr != null) {
								final code = (ret != "void" ? "return " : "") + name + "(" + vCallArgs.join(", ") + ");";
								"{\n" + code.tab() + "\n}";
							} else {
								";";
							}
						}

						// Put it all together to make the C# function
						final props = compileFunctionProperties(f, classType).join(" ");
						final func = meta + props + " " + ret + " " + name + "(" + vArguments.join(", ") + ") " + csExpr;
						functions.push(func);
					}
				}
			}
		}
	}

	/**
		Returns a list of all the C# properties to be appened to a C# function.
	**/
	function compileFunctionProperties(f: ClassFuncData, classType: ClassType): Array<String> {
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
