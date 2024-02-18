package cscompiler.components;

#if (macro || cs_runtime)
import cscompiler.CSCompiler;

/**
	The super class of all the compiler components.

	Simply stores reference to `CSCompiler` so components
	can interact with each other.
**/
class CSBase {
	var compiler: CSCompiler;

	var printer(get, never): CSPrinter;

	inline function get_printer(): CSPrinter {
		return compiler.printer;
	}

	public function new(compiler: CSCompiler) {
		this.compiler = compiler;
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
