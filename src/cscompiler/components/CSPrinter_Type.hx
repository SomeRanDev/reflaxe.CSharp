package cscompiler.components;

#if(macro || cs_runtime)
import cscompiler.ast.*;

/**
	The component responsible for printing
	C# Types AST to C# code
**/
class CSPrinter_Type extends CSPrinter_Base {
	public function printType(type: CSType) {
		switch type {
			case CSInst(typePath, params):
				printTypePath(typePath);
				printTypeParams(params);
				
			case CSEnum(typePath, params):
				printTypePath(typePath);
				printTypeParams(params);
				
			case CSArray(typePath, params):
				printTypePath(typePath);
				printTypeParams(params);
				write('[]');
				
			case CSFunction(args, ret):
				// TODO
				
			case CSValue(typePath, params, nullable):
				printTypePath(typePath);
				printTypeParams(params);
				if(nullable) {
					write('?');
				}
		}
	}
	
	public function printTypePath(typePath: CSTypePath) {
		// TODO
	}
	
	public function printTypeParams(typeParams: Array<CSType>) {
		final len = typeParams.length;
		if(len > 0) {
			write('<');
			for (i in 0...len) {
				if(i > 0)
					write(', ');
				final typeParam = typeParams[i];
				printType(typeParam);
			}
			write('>');
		}
	}
}
#end
