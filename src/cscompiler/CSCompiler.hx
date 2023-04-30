package cscompiler;

#if (macro || cs_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;

// ---

import reflaxe.BaseCompiler;
import reflaxe.PluginCompiler;
import reflaxe.data.ClassVarData;
import reflaxe.data.ClassFuncData;
import reflaxe.data.EnumOptionData;
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
	inline function createComponents() {
		// Bypass Haxe null-safety not allowing `this` usage.
		@:nullSafety(Off) var self = this;

		classComp = new CSClass(self);
		enumComp = new CSEnum(self);
		exprComp = new CSExpression(self);
		typeComp = new CSType(self);
	}

	// ---

	/**
		Called at the start of compilation.
	**/
	public override function onCompileStart() {
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
	public function compileClassImpl(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<String> {
		return classComp.compile(classType, varFields, funcFields);
	}

	/**
		Generate the C# output given the Haxe enum information.
	**/
	public function compileEnumImpl(enumType: EnumType, options: Array<EnumOptionData>): Null<String> {
		return enumComp.compile(enumType, options);
	}

	// ---

	/**
		Generates the C# type from `haxe.macro.Type`.

		A `Position` is provided so compilation errors can be reported to it.
	**/
	public function compileType(type: Type, pos: Position): String {
		final result = typeComp.compile(type, pos);
		if(result == null) {
			throw "Type could not be generated: " + Std.string(type);
		}
		return result;
	}

	/**
		Generate C# output for `ModuleType` used in an expression
		(i.e. for cast or static access).
	**/
	public function compileModuleType(m: ModuleType): String {
		return typeComp.compileModuleExpression(m);
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

		Note: it's possible for an argument to be optional but not have an `expr`.
	**/
	public function compileFunctionArgument(t: Type, name: String, pos: Position, optional: Bool, expr: Null<TypedExpr> = null) {
		var result = compileType(t, pos) + " " + compileVarName(name);
		if(expr != null) {
			result += " = " + compileExpression(expr);
		} else {
			// TODO: ensure type is nullable
			result += " = null";
		}
		return result;
	}

	/**
		Generate the C# output given the Haxe typed expression (`TypedExpr`).
	**/
	public function compileExpressionImpl(expr: TypedExpr): Null<String> {
		return exprComp.compile(expr);
	}

	/**
		Get a C# namespace for the given package
	**/
	public function packToNameSpace(pack: Array<String>):String {
		if (pack != null) {
			var csPack = [].concat(pack);

			inline function shouldExcludeLastPackItem(item: String):Bool {
				return item.toLowerCase() != item;
			}

			while (csPack.length > 0 && shouldExcludeLastPackItem(csPack[csPack.length - 1])) {
				csPack.pop();
			}

			if (csPack.length > 0) {
				return csPack.join(".");
			}
		}
		return "haxe.root";
	}

	/**
		Wrap a block of code with the given name space
	**/
	public function wrapNameSpace(nameSpace: String, s: String):String {
		return "namespace " + nameSpace + " {\n" + StringTools.rtrim(s.tab()) + "\n}\n";
	}

	/**
		Remove blank white space at the end of each line,
		and trim empty lines.
	**/
	public function cleanWhiteSpaces(s: String):String {

		// Temporary workaround.

		// TODO: edit reflaxe SyntaxHelper.tab() so that it
		// doesn't add spaces/tabs to empty lines when indenting
		// a block, and make this method not needed anymore

		final lines = s.split("\n");
		for(i in 0...lines.length) {
			lines[i] = StringTools.rtrim(lines[i]);
		}
		return lines.join("\n");
	}
}

#end