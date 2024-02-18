package cscompiler;

// Mostly a copy of https://github.com/fourst4r/reflaxe.dart/blob/347da05bef374dd63c68881046dcaad0c1aca202/src/dartcompiler/Printer.hx from fourst4r
#if (macro || cs_runtime)
import cscompiler.helpers.Printer;

class CSPrinter extends Printer {
	var compiler: CSCompiler;

	public function new(compiler: CSCompiler, indent: String, newline: String) {
		super(indent, newline);
		this.compiler = compiler;
	}

	public extern inline overload function beginBlock() {
		indent();
		line();
	}

	public extern inline overload function endBlock() {
		line();
		unindent();
	}

	public extern inline overload function beginBlock(delimiter: String) {
		write(delimiter);
		indent();
		line();
	}

	public extern inline overload function endBlock(delimiter: String) {
		line();
		unindent();
		write(delimiter);
	}

}
#end
