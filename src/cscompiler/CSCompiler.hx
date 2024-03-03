package cscompiler;

import cscompiler.ast.CSTopLevel;
import reflaxe.optimization.ExprOptimizer;
#if (macro || cs_runtime)

import sys.io.File;

import haxe.io.Path;
import haxe.macro.Expr;
import haxe.macro.Type;

// ---

import reflaxe.BaseCompiler;
import reflaxe.GenericCompiler;
import reflaxe.data.ClassVarData;
import reflaxe.data.ClassFuncData;
import reflaxe.data.EnumOptionData;
import reflaxe.helpers.Context;
import reflaxe.output.DataAndFileInfo;
import reflaxe.output.StringOrBytes;

using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.ModuleTypeHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.NullableMetaAccessHelper;
using reflaxe.helpers.OperatorHelper;
using reflaxe.helpers.TypeHelper;

// ---

import cscompiler.ast.CSClass;
import cscompiler.ast.CSEnum;
import cscompiler.ast.CSStatement;
import cscompiler.ast.CSType;
import cscompiler.components.*;
import cscompiler.config.Define;

/**
	The class that manages the generation of the C# code.

	Its "impl" functions are called from Reflaxe.
**/
class CSCompiler extends reflaxe.GenericCompiler<CSTopLevel, CSTopLevel, CSStatement> {
	/**
		The namespace used for top-level module types.
	**/
	public static final DEFAULT_ROOT_NAMESPACE = "haxe.root";

	/**
		Handles implementation of `compileClassImpl`.
	**/
	public var classComp(default, null): CSCompiler_Class;

	/**
		Handles implementation of `compileEnumImpl`.
	**/
	public var enumComp(default, null): CSCompiler_Enum;

	/**
		Handles implementation of `compileExprImpl`.
	**/
	public var exprComp(default, null): CSCompiler_Expr;

	/**
		Handles implementation of `compileType`, `compileModuleType`, and `compileClassName`.
	**/
	public var typeComp(default, null): CSCompiler_Type;

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

		classComp = new CSCompiler_Class(self);
		enumComp = new CSCompiler_Enum(self);
		exprComp = new CSCompiler_Expr(self);
		typeComp = new CSCompiler_Type(self);
	}

	// ---

	/**
		The file name used for main function code.

		TODO: Was this the name used in the original Haxe/C# target?
	**/
	static final BootFilename = "HaxeBoot.cs";

	/**
		Called at the start of compilation.
	**/
	public override function onCompileStart() {
		setupMainFunction();
		setupCsProj();
	}

	/**
		If -main exists, generate a Main function in C#.
	**/
	function setupMainFunction() {
		final mainExpr = getMainExpr();
		if(mainExpr != null) {
			final csExpr = compileExpressionOrError(mainExpr);

			// TODO: Convert `csExpr` to `String` using printer
			final csCode = "";

			appendToExtraFile(BootFilename, haxeBootContent(csCode));
		}
	}

	/**
		Returns the content generated for the `HaxeBoot.cs`.

		TODO:
			Store `args` to use with `Sys.args()` later.
	**/
	function haxeBootContent(csCode: String) {
		return StringTools.trim('
namespace Haxe {
	class HaxeBoot {
		static void Main(string[] args) {
			${csCode};
		}
	}
}
		');
	}

	/**
		Adds a .csproj file to the output directory.

		If the Define `no_csproj` is specified, then nothing is added.

		Otherwise, if the Define `csproj` specifies a path to an existing
		.csproj file, then that is used.

		Otherwise, a default .csproj is generated.
	**/
	function setupCsProj() {
		if (D_NoCsproj.isDefined()) {
			return;
		}
		if (!D_Csproj.isDefined()) {
			appendToExtraFile("build.csproj", csProjDefaultContent());
			return;
		}
		final path = new Path(Context.resolvePath(D_Csproj.getValue()));
		appendToExtraFile('${path.file}.${path.ext}', File.getContent(path.toString()));
	}

	/**
		Returns the default content of the .csproj file.
	**/
	function csProjDefaultContent() {
		return StringTools.trim('
<Project Sdk="Microsoft.NET.Sdk">

<PropertyGroup>
	<OutputType>Exe</OutputType>
	<TargetFramework>net6.0</TargetFramework>
	<ImplicitUsings>enable</ImplicitUsings>
	<Nullable>enable</Nullable>
	<StartupObject>Haxe.HaxeBoot</StartupObject>
</PropertyGroup>

</Project>
		');
	}

	/**
		Called at the end of compilation.
	**/
	public override function onCompileEnd() {
	}

	/**
		Generate output.

		TODO.
	**/
	public function generateOutputIterator(): Iterator<DataAndFileInfo<StringOrBytes>> {
		// TODO: Print all classes and enums using these vars from `GenericCompiler`:
		// var classes: Array<CSClass>
		// var enums: Array<CSEnum>

		return {
			hasNext: () -> false,
			next: () -> {
				return new DataAndFileInfo(StringOrBytes.fromString(""), @:nullSafety(Off) null, null, null);
			}
		};
	}

	// ---

	/**
		Generate the C# output given the Haxe class information.
	**/
	public function compileClassImpl(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<CSTopLevel> {
		return classComp.compile(classType, varFields, funcFields);
	}

	/**
		Generate the C# output given the Haxe enum information.
	**/
	public function compileEnumImpl(enumType: EnumType, options: Array<EnumOptionData>): Null<CSTopLevel> {
		return enumComp.compile(enumType, options);
	}

	// ---

	/**
		Generates the C# type from `haxe.macro.Type`.

		A `Position` is provided so compilation errors can be reported to it.
	**/
	public function compileType(type: Type, pos: Position): CSType {
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
			if (optional) {
				result += " = null";
			}
		}
		return result;
	}

	public function compileClassVarExpr(expr: TypedExpr): Null<CSStatement> {

		// TODO: do we need to unwrap and optimize in that case?
		//final exprs = ExprOptimizer.optimizeAndUnwrap(expr);

		return compileExpression(expr);
	}

	/**
		Generate the C# output given the Haxe typed expression (`TypedExpr`).
	**/
	public function compileExpressionImpl(expr: TypedExpr, topLevel: Bool): Null<CSStatement> {
		return exprComp.compile(expr, topLevel);
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