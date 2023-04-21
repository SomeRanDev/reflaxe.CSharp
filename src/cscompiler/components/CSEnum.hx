package cscompiler.components;

#if (macro || cs_runtime)

import haxe.macro.Type;

import reflaxe.BaseCompiler;

/**
	The component responsible for compiling Haxe
	enums into C#.
**/
class CSEnum extends CSBase {
	/**
		Implementation of `CSCompiler.compileEnumImpl`.

		TODO.
	**/
	public function compile(enumType: EnumType, options: EnumOptions): Null<String> {
		return null;
	}
}
#end
