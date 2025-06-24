package cscompiler;

#if(macro || cs_runtime)
import reflaxe.output.DataAndFileInfo;
import reflaxe.output.StringOrBytes;

import cscompiler.ast.CSTopLevel;

/**
	The iterator returned from `CSCompiler.generateOutputIterator`.

	This iterates through all the `DataAndFileInfo<CSTopLevel>` objects and uses the `CSPrinter`
	to generate the output for each as a `DataAndFileInfo<StringOrBytes>`.
**/
@:access(cscompiler.CSCompiler)
class CSOutputIterator {
	var compiler: CSCompiler;
	var printer: CSPrinter;
	
	var index: Int;
	var maxIndex: Int;
	
	public function new(compiler: CSCompiler) {
		this.compiler = compiler;
		printer = new CSPrinter();
		
		index = 0;
		// TODO: Include typedefs and abstracts?
		maxIndex = compiler.classes.length + compiler.enums.length;
	}
	
	public function hasNext() {
		return index < maxIndex;
	}
	
	public function next(): DataAndFileInfo<StringOrBytes> {
		// TODO: Include typedefs and abstracts?
		final topLevelAst: DataAndFileInfo<CSTopLevel> = if(index < compiler.classes.length) {
			compiler.classes[index];
		} else {
			compiler.enums[index - compiler.classes.length];
		}
		
		index++;
		
		final printer = new CSPrinter();
		printer.printTopLevel(topLevelAst.data);
		return topLevelAst.withOutput(printer.toString());
	}
}
#end
