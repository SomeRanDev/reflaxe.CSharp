package cscompiler;

#if(macro || cs_runtime)
import cscompiler.helpers.Printer;
import cscompiler.ast.*;
import cscompiler.printer.CSPrinter_Type;
import cscompiler.printer.CSPrinter_Class;

/**
	A class that prints actual C# code from a C# AST
**/
class CSPrinter extends Printer {
	/**
		Handles printing of C# types AST
	**/
	public var typePrinter(default, null): CSPrinter_Type;
	
	/**
		Handles printing of C# class AST
	**/
	public var classPrinter(default, null): CSPrinter_Class;
	
	/**
		Constructor.
	**/
	public function new() {
		super();
		createComponents();
	}
	
	/**
		Constructs all the components of the printer.

		See the `cscompiler.components` package for more info.
	**/
	inline function createComponents() {
		// Bypass Haxe null-safety not allowing `this` usage.
		@:nullSafety(Off) var self = this;
		
		typePrinter = new CSPrinter_Type(self);
		classPrinter = new CSPrinter_Class(self);
		// TODO more printer components
	}
	
	public function printTopLevel(topLevel: CSTopLevel) {
		if(topLevel.nameSpace != null) {
			write('namespace ');
			write(topLevel.nameSpace);
			write(' {');
			newline();
			indent();
		}
		
		switch topLevel.def {
			case CSTopLevelClass(c): printClass(c);
			case CSTopLevelEnum(e): printEnum(e);
		}
		
		if(topLevel.nameSpace != null) {
			unindent();
			line('}');
		}
	}
	
	inline public function printClass(cls: CSClass) {
		classPrinter.printClass(cls);
	}
	
	public function printEnum(enm: CSEnum) {
		// TODO
	}
	
	public function printField(field: CSField) {
		// TODO
	}
	
	inline public function printType(type: CSType) {
		typePrinter.printType(type);
	}
	
	inline public function printTypeParams(typeParams: Array<CSType>) {
		typePrinter.printTypeParams(typeParams);
	}
}
#end
