package cscompiler;

#if(macro || cs_runtime)
import cscompiler.ast.*;
import cscompiler.helpers.Printer;
import cscompiler.printer.CSPrinter_Class;
import cscompiler.printer.CSPrinter_Expression;
import cscompiler.printer.CSPrinter_Field;
import cscompiler.printer.CSPrinter_Statement;
import cscompiler.printer.CSPrinter_Type;

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
		Handles printing of C# field AST
	**/
	public var fieldPrinter(default, null): CSPrinter_Field;
	
	/**
		Handles printing of C# expression AST
	**/
	public var expressionPrinter(default, null): CSPrinter_Expression;
	
	/**
		Handles printing of C# statement AST
	**/
	public var statementPrinter(default, null): CSPrinter_Statement;
	
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
		fieldPrinter = new CSPrinter_Field(self);
		expressionPrinter = new CSPrinter_Expression(self);
		statementPrinter = new CSPrinter_Statement(self);
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
			newline();
			unindent();
			write('}');
		}
	}
	
	public inline function printClass(cls: CSClass) {
		classPrinter.printClass(cls);
	}
	
	public function printEnum(enm: CSEnum) {
		// TODO
	}
	
	public function printField(field: CSField) {
		fieldPrinter.printField(field);
	}
	
	public function printExpression(expr: CSExpr) {
		expressionPrinter.printExpression(expr);
	}
	
	public function printStatement(statement: CSStatement) {
		statementPrinter.printStatement(statement);
	}
	
	public inline function printType(type: CSType) {
		typePrinter.printType(type);
	}
	
	public inline function printTypeParams(typeParams: Array<CSType>) {
		typePrinter.printTypeParams(typeParams);
	}
	
	public inline function printTypePath(typePath: CSTypePath): Void {
		write(typePath);
	}
}
#end
