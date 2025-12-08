package cscompiler;

#if(macro || cs_runtime)
import cscompiler.ast.CSArg;
import cscompiler.ast.CSClass;
import cscompiler.ast.CSExpr;
import cscompiler.ast.CSField;
import cscompiler.ast.CSFunction;
import cscompiler.ast.CSStatement;
import cscompiler.ast.CSTopLevel;
import cscompiler.ast.CSType;
import cscompiler.ast.CSTypePath;
import cscompiler.components.*;
import cscompiler.config.Define;

import haxe.io.Path;
import haxe.macro.Expr;
import haxe.macro.Type;

import sys.io.File;

import reflaxe.BaseCompiler;
import reflaxe.GenericCompiler;
import reflaxe.data.ClassVarData;
import reflaxe.data.ClassFuncData;
import reflaxe.data.EnumOptionData;
import reflaxe.helpers.Context;
import reflaxe.output.DataAndFileInfo;
import reflaxe.output.StringOrBytes;

// ---
using reflaxe.helpers.ModuleTypeHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.NullableMetaAccessHelper;
using reflaxe.helpers.NullHelper;
using reflaxe.helpers.OperatorHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypeHelper;

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
		Keep the inverted mapping of `nameToHashTable` to handle potential collisions
	**/
	public var hashToNameTable(default, null): Map<Int, String> = new Map();
	
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
		compileMainFunction();
		setupCsProj();
	}
	
	/**
		If -main exists, generate a Main function in C#.
	**/
	function compileMainFunction() {
		final mainExpr = getMainExpr();
		if(mainExpr != null) {
			final csStatement: CSStatement = compileExpressionOrError(mainExpr);
			
			final stringArrayArg: CSArg = {
				name: "args",
				type: CSArray("string", []),
				opt: false,
				value: null
			};
			
			final csMainFunction: CSField = {
				name: "Main",
				modifiers: [CSPublic, CSStatic],
				kind: CSMethod(
					new CSFunction([stringArrayArg], CSFunctionReturnKind.ReturnVoid, csStatement)
				)
			};
			
			final csMainClass: CSClass = {
				name: "HaxeBoot",
				typeParams: [],
				superClass: null,
				superClassTypeParams: [],
				fields: [csMainFunction]
			};
			
			final csTopLevel = new CSTopLevel(CSTopLevelClass(csMainClass), "Haxe");
			
			final printer = new CSPrinter();
			printer.printTopLevel(csTopLevel);
			appendToExtraFile(BootFilename, printer.toString());
		}
	}
	
	/**
		Adds a .csproj file to the output directory.

		If the Define `no_csproj` is specified, then nothing is added.

		Otherwise, if the Define `csproj` specifies a path to an existing
		.csproj file, then that is used.

		Otherwise, a default .csproj is generated.
	**/
	function setupCsProj() {
		if(D_NoCsproj.isDefined()) {
			return;
		}
		if(!D_Csproj.isDefined()) {
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
		return StringTools.trim(
			'
<Project Sdk="Microsoft.NET.Sdk">

<PropertyGroup>
	<OutputType>Exe</OutputType>
	<TargetFramework>${D_Csproj_TargetFramework.getValueOr("net8.0")}</TargetFramework>
	<ImplicitUsings>enable</ImplicitUsings>
	<Nullable>enable</Nullable>
	<StartupObject>Haxe.HaxeBoot</StartupObject>
</PropertyGroup>

</Project>
		'
		);
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
		return new CSOutputIterator(this);
	}
	
	// ---
	
	/**
		Generate the C# output given the Haxe class information.
	**/
	public function compileClassImpl(classType: ClassType, varFields: Array<ClassVarData>,
			funcFields: Array<ClassFuncData>): Null<CSTopLevel> {
		return classComp.compile(classType, varFields, funcFields);
	}
	
	/**
		Generate the C# output given the Haxe enum information.
	**/
	public function compileEnumImpl(enumType: EnumType,
			options: Array<EnumOptionData>): Null<CSTopLevel> {
		return enumComp.compile(enumType, options);
	}
	
	// ---
	
	/**
		Generates the C# type from `haxe.macro.Type`.

		A `Position` is provided so compilation errors can be reported to it.

		If the type cannot be represented in C#, `null` is returned.
	**/
	public function compileType(type: Type, pos: Position): Null<CSType> {
		return typeComp.compile(type, pos);
	}
	
	/**
		Generates the C# type from `haxe.macro.Type`.

		A `Position` is provided so compilation errors can be reported to it.

		Generates an error if the type cannot be compiled to C#. Use this to generate types you must have.
	**/
	public function compileTypeOrError(type: Type, pos: Position): CSType {
		final result = compileType(type, pos);
		return if(result == null) {
			Context.error("Type could not be generated: " + Std.string(type), pos);
		} else {
			result;
		}
	}
	
	/**
		Generate C# output for `ModuleType` used in an expression
		(i.e. for cast or static access).
	**/
	public function compileModuleType(m: ModuleType): CSTypePath {
		return typeComp.compileModuleType(m);
	}
	
	/**
		Get the name of the `ClassType` as it should appear in
		the C# output.
	**/
	public function compileClassName(classType: ClassType): String {
		return typeComp.compileClassName(classType);
	}
	
	/**
		Get the name of the `EnumType` as it should appear in
		the C# output.
	**/
	public function compileEnumName(enumType: EnumType): String {
		return typeComp.compileEnumName(enumType);
	}
	
	// ---
	
	/**
		Generate the C# output for a function argument.

		Note: it's possible for an argument to be optional but not have an `expr`.
	**/
	public function compileFunctionArgument(t: Type, name: String, pos: Position, optional: Bool,
			expr: Null<TypedExpr> = null): CSArg {
		return {
			name: compileVarName(name),
			type: compileTypeOrError(t, pos),
			opt: optional,
			value: expr != null ? compileToCSExpr(expr) : null
		};
	}
	
	public function compileClassVarExpr(expr: TypedExpr): Null<CSExpr> {
		return compileToCSExpr(expr);
	}
	
	public function compileClassFuncExpr(expr: TypedExpr): Null<CSStatement> {
		return compileExpression(expr);
	}
	
	/**
		Compile an expression and ensure it is an actual C# expression (not a statement)
	**/
	public function compileToCSExpr(expr: TypedExpr): Null<CSExpr> {
		return exprComp.compileToCSExpr(expr);
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
	public function wrapNameSpace(nameSpace: String, s: String): String {
		return "namespace " + nameSpace + " {\n" + StringTools.rtrim(s.tab()) + "\n}\n";
	}
	
	/**
		Remove blank white space at the end of each line,
		and trim empty lines.
	**/
	public function cleanWhiteSpaces(s: String): String {
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
	
	/**
		Get a hash code for the given name. If the name is new,
		add an entry to `hashToNameTable` so that it can be used
		for field lookup in generated code.
	**/
	public function nameToHash(name: String): Int {
		var h: Int = 0;
		for(i in 0...name.length) {
			h = 223 * h + name.charCodeAt(i).trustMe();
		}
		h %= 0x1FFFFF7B;
		
		while(hashToNameTable.exists(h) && hashToNameTable.get(h) != name) {
			h++;
		}
		
		if(!hashToNameTable.exists(h)) {
			hashToNameTable.set(h, name);
		}
		
		return h;
	}
}
#end
