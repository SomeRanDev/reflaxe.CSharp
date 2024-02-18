package cscompiler;

import haxe.EnumTools;
#if (macro || cs_runtime)
import haxe.macro.Expr;
import haxe.macro.Type;
// ---
import reflaxe.BaseCompiler;
import reflaxe.GenericCompiler;
import reflaxe.data.ClassVarData;
import reflaxe.data.ClassFuncData;
import reflaxe.data.EnumOptionData;
import reflaxe.helpers.Context;
import reflaxe.optimization.ExprOptimizer;

import reflaxe.output.DataAndFileInfo;
import reflaxe.output.StringOrBytes;

using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.ModuleTypeHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.NullableMetaAccessHelper;
using reflaxe.helpers.OperatorHelper;
using reflaxe.helpers.TypeHelper;
using reflaxe.helpers.TypedExprHelper;

using StringTools;

// ---
import cscompiler.components.*;

/**
	The class that manages the generation of the C# code.

	Its "impl" functions are called from Reflaxe.
**/
class CSCompiler extends GenericCompiler<CSPrinter, CSPrinter, CSPrinter, CSPrinter, CSPrinter> {
	/**
		The namespace used for top-level module types.
	**/
	public static final DEFAULT_ROOT_NAMESPACE = "haxe.root";

	/**
		The indentation tab characters
	**/
	public static final INDENT_CHARS = "    ";

	/**
		Handles implementation of `compileClassImpl`.
	**/
	public var classComp(default, null): CSClass;

	/**
		Handles implementation of `compileEnumImpl`.
	**/
	public var enumComp(default, null): CSEnum;

	/**
		Handles implementation of `compileExprImpl`.
	**/
	public var exprComp(default, null): CSExpression;

	/**
		Handles implementation of `compileType`, `compileModuleType`, and `compileClassName`.
	**/
	public var typeComp(default, null): CSType;

	/**
		Used to print C# code
	**/
	@:nullSafety(Off)
	public var printer(default, null): CSPrinter;

	/**
	 * Stacked printers, needed when we want
	 * to print some output in a separate printer
	 */
	var printerStack(default, null): Array<CSPrinter> = [];

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
		if (mainExpr != null) {
			pushPrinter();
			compileExpressionOrError(mainExpr);
			appendToExtraFile(BootFilename, haxeBootContent(popPrinter().toString()));
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
		Generates the .csproj file.
	**/
	function setupCsProj() {
		if (!Context.defined("no-csproj")) {
			appendToExtraFile("build.csproj", csProjContent());
		}
	}

	/**
		Returns the content of the .csproj file.
	**/
	function csProjContent() {
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

	function makePrinter() {
		return new CSPrinter(this, INDENT_CHARS, "\n");
	}

	/**
		Push a temporary printer that will be used for following output
	**/
	function pushPrinter() {
		printerStack.push(printer);
		printer = makePrinter();
	}

	/**
	 	Stop using the last temporary printer and restore the previous
	 	Returns the now unused printer so that it can be converted to string.
	**/
	function popPrinter() {
		final prevPrinter = printer;
		@:nullSafety(Off) printer = printerStack.pop();
		return prevPrinter;
	}

    override function setupModule(mt:Null<ModuleType>) {
        super.setupModule(mt);

		printer = makePrinter();
	}

	/**
		Called at the end of compilation.
	**/
	public override function onCompileEnd() {}

	// ---

	/**
		Generate the C# output given the Haxe class information.
	**/
	public function compileClassImpl(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<CSPrinter> {
		return classComp.compile(classType, varFields, funcFields);
	}

	/**
		Generate the C# output given the Haxe enum information.
	**/
	public function compileEnumImpl(enumType: EnumType, options: Array<EnumOptionData>): Null<CSPrinter> {
		return enumComp.compile(enumType, options);
	}

	// ---

	/**
		Calls "ExprOptimizer.optimizeAndUnwrap"
		and "compileExpressionsIntoLines" from the "expr".
	**/
	public function compileClassVarExpr(expr: TypedExpr) {
		final exprs = ExprOptimizer.optimizeAndUnwrap(expr);
		compileExpressionsIntoLines(exprs);
	}

	/**
		Same as "compileClassVarExpr", but also uses
		EverythingIsExprSanitizer if required.
	**/
	public function compileClassFuncExpr(expr: TypedExpr) {
		compileClassVarExpr(expr);
	}

	/**
		Convert a list of expressions to lines of output code.
		The lines of code are spaced out to make it feel like
		it was human-written.
	**/
	public function compileExpressionsIntoLines(exprList: Array<TypedExpr>) {
		var currentType = -1;

		for(e in exprList) {
			final newType = expressionType(e);
			if(currentType != newType) {
				if(currentType != -1) line();
				currentType = newType;
			}

			// Compile expression
			compileExpression(e, true);

			// End of line semicolon
			write(";");
		}
	}

	/**
		Generates the C# type from `haxe.macro.Type`.

		A `Position` is provided so compilation errors can be reported to it.
	**/
	public function compileType(type: Type, pos: Position) {
		var result = typeComp.compile(type, pos);
		if (result == null) {
			// throw "Type could not be generated: " + Std.string(type);
			result = "UNKNOWN(" + type + ")"; // TODO: remove temporary
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

	/**
		This function is for compiling the result of functions
		using the `@:nativeFunctionCode` meta.

		TODO: use printer?
	**/
	public function compileNativeFunctionCodeMeta(callExpr: TypedExpr, arguments: Array<TypedExpr>, typeParamsCallback: Null<(Int) -> Null<String>> = null, custom: Null<(String) -> String> = null): Null<String> {

		// This could probably be reviewed later to treat
		// the string in one single pass and feed a printer with it,
		// but current implementation should be good enough for now.

		final declaration = callExpr.getDeclarationMeta(arguments);
		if(declaration == null) {
			return null;
		}

		final meta = declaration.meta;
		final data = meta != null ? extractStringFromMeta(meta, ":nativeFunctionCode") : null;
		if(data == null) {
			return null;
		}

		final code = data.code;
		var result = code;

		// Handle {this}
		if(code.contains("{this}")) {
			final thisExpr = declaration.thisExpr != null ? compileNFCThisExpression(declaration.thisExpr, declaration.meta) : null;
			if(thisExpr == null) {
				if(declaration.thisExpr == null) {
					#if eval
					Context.error("Cannot use {this} on @:nativeFunctionCode meta for constructors.", data.entry.pos);
					#end
				} else {
					onExpressionUnsuccessful(callExpr.pos);
				}
			} else {
				result = result.replace("{this}", thisExpr);
			}
		}

		// Handle {argX}
		var argExprs: Null<Array<String>> = null;
		for(i in 0...arguments.length) {
			final key = "{arg" + i + "}";
			if(code.contains(key)) {
				if(argExprs == null) {
					argExprs = arguments.map(function(e) {
						pushPrinter();
						this.compileExpressionOrError(e);
						return popPrinter().toString();
					});
				}
				if(argExprs[i] == null) {
					onExpressionUnsuccessful(arguments[i].pos);
				} else {
					result = result.replace(key, argExprs[i]);
				}
			}
		}

		// Handle {typeX} if `typeParamsCallback` exists
		if(typeParamsCallback != null) {
			final typePrefix = "{type";

			var typeParamsResult = null;
			var oldIndex = 0;
			var index = result.indexOf(typePrefix); // Check for `{type`
			while(index != -1) {
				// If found, figure out the number that comes after
				final startIndex = index + typePrefix.length;
				final endIndex = result.indexOf("}", startIndex);
				final numStr = result.substring(startIndex, endIndex);
				final typeIndex = Std.parseInt(numStr);

				// If the number if valid...
				if(typeIndex != null && !Math.isNaN(typeIndex)) {
					// ... add the content before this `{type` to `typeParamsResult`.
					if(typeParamsResult == null) typeParamsResult = "";
					typeParamsResult += result.substring(oldIndex, index);

					// Compile the type
					final typeOutput = typeParamsCallback(typeIndex);
					if(typeOutput != null) {
						typeParamsResult += typeOutput;
					}
				}

				// Skip past this {typeX} and search again.
				oldIndex = endIndex + 1;
				index = result.indexOf(typePrefix, oldIndex);
			}
			// Modify "result" if processing occurred.
			if(typeParamsResult != null) {
				typeParamsResult += result.substr(oldIndex);
				result = typeParamsResult;
			}
		}

		// Apply custom transformations
		if(custom != null) {
			result = custom(result);
		}

		return result;
	}

	/**
		Compiles the {this} expression for `@:nativeFunctionCode`.
	**/
	public function compileNFCThisExpression(expr: TypedExpr, meta: Null<MetaAccess>) {
		pushPrinter();
		compileExpressionOrError(expr);
		return popPrinter().toString();
	}

	// ---

	/**
		Generate the C# output for a function argument.

		Note: it's possible for an argument to be optional but not have an `expr`.
	**/
	public function compileFunctionArgument(t: Type, name: String, pos: Position, optional: Bool, expr: Null<TypedExpr> = null) {
		write(compileType(t, pos) ?? "object");
		write(" ");
		write(compileVarName(name));

		if (expr != null) {
			write(" = ");
			compileExpression(expr);
		}
		else {
			// TODO: ensure type is nullable
			if (optional) {
				write(" = null");
			}
		}

		return printer;
	}

	/**
		Generate the C# output given the Haxe typed expression (`TypedExpr`).
	**/
	public function compileExpressionImpl(expr: TypedExpr, topLevel: Bool) {
		exprComp.compile(expr, topLevel);
		return printer;
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
		for (i in 0...lines.length) {
			lines[i] = StringTools.rtrim(lines[i]);
		}
		return lines.join("\n");
	}

	public function generateOutputIterator():Iterator<DataAndFileInfo<StringOrBytes>> {
		throw new haxe.exceptions.NotImplementedException();
	}

	/// Printer shorthands

	inline function indent() {
		printer.indent();
	}

	inline function unindent() {
		printer.unindent();
	}

	inline function write(s: String) {
		printer.write(s);
		return printer;
	}

	extern inline overload function writeln() {
		printer.writeln();
		return printer;
	}

	extern inline overload function writeln(s: String) {
		printer.writeln(s);
		return printer;
	}

	inline function tab() {
		printer.tab();
		return printer;
	}

	extern inline overload function line() {
		printer.line();
		return printer;
	}

	extern inline overload function line(s: String) {
		printer.line(s);
		return printer;
	}

	extern inline overload function beginBlock() {
		printer.beginBlock();
		return printer;
	}

	extern inline overload function endBlock() {
		printer.endBlock();
		return printer;
	}

	extern inline overload function beginBlock(delimiter: String) {
		printer.beginBlock(delimiter);
		return printer;
	}

	extern inline overload function endBlock(delimiter: String) {
		printer.endBlock(delimiter);
		return printer;
	}

}
#end
