package cscompiler.printer;

#if(macro || cs_runtime)
import cscompiler.ast.*;

/**
	The component responsible for printing
	C# Field AST to C# code
**/
class CSPrinter_Field extends CSPrinter_Base {
	public function printField(field: CSField) {
		for(modifiers in field.modifiers) {
			final modifierCode = switch(modifiers) {
				case CSStatic: "static";
				case CSAbstract: "abstract";
				case CSVirtual: "virtual";
				case CSOverride: "override";
				case CSPublic: "public";
				case CSPrivate: "private";
				case CSProtected: "protected";
				case CSInternal: "internal";
			}
			write(modifierCode);
			write(" ");
		}
		
		switch(field.kind) {
			case CSMethod(csFunc): {
					printMethod(csFunc, field);
				}
			case CSVar(csType, maybeExpr):
				{
					switch(csType) {
						case KnownType(type): printer.printType(type);
						case Infer: write("var");
					}
					write(" ");
					write(field.name);
					if(maybeExpr != null) {
						write(" = ");
						printer.printExpression(maybeExpr);
					}
					write(";");
				}
			case CSProp(_, _, _): {
					// TODO????
				}
		}
	}
	
	function printMethod(csFunc: CSFunction, field: CSField) {
		switch(csFunc.returnKind) {
			case Constructor: {}
			case ReturnVoid: {
					write("void");
				}
			case ReturnType(returnType): {
					printer.printType(returnType);
				}
			case InferReturnType:
				{
					// TODO: Convert this into Context.error
					throw "Cannot infer the return type of a method.";
				}
		}
		
		write(" ");
		write(field.name);
		write("(");
		
		var isFirstArg = true;
		for(arg in csFunc.args) {
			if(isFirstArg) {
				isFirstArg = false;
			} else {
				write(", ");
			}
			
			printer.printType(arg.type);
			if(arg.name != null) {
				write(" ");
				write(arg.name);
				if(arg.value != null) {
					write(" = ");
					printer.printExpression(arg.value);
				}
			}
		}
		
		write(") {");
		newline();
		indent();
		
		switch(csFunc.statement) {
			case null: // do nothing for null statement.
			case {def: CSBlock([])}: // do nothing for empty block statement.
			case statement: printer.printStatement(statement);
		}
		
		newline();
		unindent();
		write("}");
	}
}
#end
