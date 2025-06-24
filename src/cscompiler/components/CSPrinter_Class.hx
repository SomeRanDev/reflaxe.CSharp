package cscompiler.components;

#if(macro || cs_runtime)
import cscompiler.ast.*;

/**
	The component responsible for printing
	C# Classes AST to C# code
**/
class CSPrinter_Class extends CSPrinter_Base {
	public function printClass(cls: CSClass) {
		write('class ');
		write(cls.name);
		
		printer.printTypeParams(cls.typeParams);
		
		if(cls.superClass != null) {
			write(': ');
			write(cls.superClass);
			
			printer.printTypeParams(cls.superClassTypeParams);
		}
		
		// TODO
	}
}
#end
