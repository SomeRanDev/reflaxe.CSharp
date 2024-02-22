package cscompiler.components;

#if (macro || cs_runtime)

import cscompiler.CSCompiler;

/**
	The super class of all the compiler components.

	Simply stores reference to `CSCompiler` so components
	can interact with each other.
**/
class CSCompiler_Base {
	var compiler: CSCompiler;

	public function new(compiler: CSCompiler) {
		this.compiler = compiler;
	}
}

#end
