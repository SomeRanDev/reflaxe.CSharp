package cscompiler.components;

import cscompiler.ast.CSModifier;
import cscompiler.ast.CSStatement;
import cscompiler.ast.CSExpr;
import cscompiler.ast.CSFunction;
import cscompiler.ast.CSModifier;
import cscompiler.ast.CSTopLevel;
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
	public function compile(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<CSTopLevel> {
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

		return {
			nameSpace: csNameSpace,
			def: CSTopLevelClass({
				name: csClassName,
				fields: csFields
			})
		};

	}

	/**
		Compiles the class variable.
	**/
	function compileVariable(v: ClassVarData) {
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

		// TODO more exhaustive modifier conversion?
		final modifiers:Array<CSModifier> = [CSPublic];
		if (v.isStatic) {
			modifiers.push(CSStatic);
		}

		csFields.push({
			name: varName,
			modifiers: modifiers,
			kind: CSVar(
				varType,
				csExpr
			)
		});

	}

	/**
		Compiles the class function.
	**/
	function compileFunction(f: ClassFuncData, classType: ClassType) {
		final field = f.field;

		final isConstructor = (field.name == "new");

		// Compile name
		final name = isConstructor ? csClassName : compiler.compileVarName(field.name);

		// Compile modifiers
		final modifiers = compileFunctionModifiers(f, classType);

		// Compile metadata
		// TODO
		//final meta = compiler.compileMetadata(field.meta, MetadataTarget.ClassField) ?? "";

		// If a dynamic function, we want to compile as function variable.
		if(f.kind == MethDynamic) {
			// `field.expr()` gives an expression of as TypedExprDef.TFunction,
			// so we don't need to do anything special to compile it as a lambda.
			final e = field.expr();
			if(e != null) {
				csFields.push({
					name: name,
					modifiers: modifiers,
					kind: CSVar(
						compiler.compileType(field.type, field.pos),
						compiler.compileClassVarExpr(e)
					)
				});
			}
			else {
				// TODO Is this supposed to happen?
			}
		} else {

			final arguments = f.args.map(a -> {
				// For now we don't take advantage of C# overload.
				// let's just make it work, then we'll see what we do about it afterwards
				compiler.compileFunctionArgument(a.type, a.name, field.pos, a.opt, a.expr);
			});

			// Compile return type
			final ret = isConstructor ? null : compiler.compileType(f.ret, field.pos);

			// Compile expression
			final statement = f.expr != null ? compiler.compileClassFuncExpr(f.expr) : null;

			csFields.push({
				name: name,
				modifiers: modifiers,
				kind: CSMethod({
					ret: ret,
					args: arguments,
					statement: statement
				})
			});
		}

	}

	/**
		Returns a list of all the C# properties to be appened to a C# function.
	**/
	function compileFunctionModifiers(f: ClassFuncData, classType: ClassType): Array<CSModifier> {
		final field = f.field;

		final modifiers = [ CSPublic ]; // Always public

		if(f.isStatic) {
			modifiers.push(CSStatic);
		} else {
			// Add virtual if @:virtual meta OR has child override
			if(field.hasMeta(":virtual") || ClassHierarchyTracker.funcHasChildOverride(classType, field, false)) {
				modifiers.push(CSVirtual);
			} else if(field.hasMeta(":override") || ClassHierarchyTracker.getParentOverrideChain(f).length > 0) {
				modifiers.push(CSOverride);
			}
		}

		return modifiers;
	}
}

#end
