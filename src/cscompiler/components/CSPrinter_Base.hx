package cscompiler.components;

#if (macro || cs_runtime)

/**
	The super class of all the printer components.

	Simply stores reference to `CSPrinter` so components
	can interact with each other.
**/
class CSPrinter_Base {

	var printer: CSPrinter;

	public function new(printer: CSPrinter) {
		this.printer = printer;
	}

	public inline function indent() {
		printer.indent();
	}

	public inline function unindent() {
		printer.unindent();
	}

	public inline function write(s: String) {
		printer.write(s);
	}

	public extern inline overload function writeln() {
		printer.writeln();
	}

	public extern inline overload function writeln(s: String) {
		printer.writeln(s);
	}

	public inline function newline() {
		printer.newline();
	}

	public inline function tab() {
		printer.tab();
	}

	public extern inline overload function line() {
		printer.line();
	}

	public extern inline overload function line(s: String) {
		printer.line(s);
	}

	public inline function clear() {
		printer.clear();
	}

	public inline function toString() {
		return printer.toString();
	}

}

#end
