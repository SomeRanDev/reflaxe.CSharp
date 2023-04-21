package cscompiler;

#if (macro || cs_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

// ---

import reflaxe.BaseCompiler;
import reflaxe.PluginCompiler;
import reflaxe.helpers.OperatorHelper;

using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.ModuleTypeHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.NullableMetaAccessHelper;
using reflaxe.helpers.OperatorHelper;
using reflaxe.helpers.TypeHelper;

// ---

import cscompiler.components.*;

/**
	The class that manages the generation of the C# code.

	Its "impl" functions are called from Reflaxe.
**/
class CSCompiler extends reflaxe.PluginCompiler<CSCompiler> {
	/**
		Handles implementation of `compileClassImpl`.
	**/
	var classComp: CSClass;

	/**
		Handles implementation of `compileEnumImpl`.
	**/
	var enumComp: CSEnum;

	/**
		Handles implementation of `compileExprImpl`.
	**/
	var exprComp: CSExpression;

	/**
		Handles implementation of `compileType`, `compileModuleType`, and `compileClassName`.
	**/
	var typeComp: CSType;

	/**
		Constructor.
	**/
	public function new() {
		super();
		createComponents();
	}

	/**
		Constructs all the components of the compiler.

		See the `cscompiler.components` package for more info.
	**/
	function createComponents() {
		classComp = new CSClass(this);
		enumComp = new CSEnum(this);
		exprComp = new CSExpression(this);
		typeComp = new CSType(this);
	}

	// ---

	/**
		Called at the start of compilation.
	**/
	public override function onCompileStart() {
		createComponents();
	}

	/**
		Called at the end of compilation.
	**/
	public override function onCompileEnd() {
	}

	/**
		Required for adding semicolons at the end of each line. Overridden from Reflaxe.
	**/
	override function formatExpressionLine(expr: String): String {
		return expr + ";";
	}

	// ---

	/**
		Generate the C# output given the Haxe class information.
	**/
	public function compileClassImpl(classType: ClassType, varFields: ClassFieldVars, funcFields: ClassFieldFuncs): Null<String> {
		return classComp.compile(classType, varFields, funcFields);
	}

	/**
		Generate the C# output given the Haxe enum information.
	**/
	public function compileEnumImpl(enumType: EnumType, options: EnumOptions): Null<String> {
		return enumComp.compile(enumType, options);
	}

	// ---

	/**
		Generates the C# type from `haxe.macro.Type`.

		A `Position` is provided so compilation errors can be reported to it.
	**/
	public function compileType(type: Type, pos: Position): String {
		return typeComp.compile(type, pos);
	}

	/**
		Generate C# output for `ModuleType` used in an expression
		(i.e. for cast or static access).
	**/
	public function compileModuleType(m: ModuleType): String {
		return typeComp.compileModule(m);
	}

	/**
		Get the name of the `ClassType` as it should appear in
		the C# output.
	**/
	public function compileClassName(classType: ClassType): String {
		return typeComp.compileClassName(classType);
	}

	// ---

	/**
		Generate the C# output for a function argument.
	**/
	public function compileFunctionArgument(t: Type, name: String, pos: Position, expr: Null<TypedExpr> = null) {
		var result = compileType(t, pos) + " " + compileVarName(name);
		if(expr != null) {
			result += " = " + compileExpression(expr);
		}
		return result;
	}
  
	/**
		Generate the C# output given the Haxe typed expression (`TypedExpr`).
	**/
	public function compileExpressionImpl(expr: TypedExpr): Null<String> {
		return exprComp.compile(expr);
	}
}

#end