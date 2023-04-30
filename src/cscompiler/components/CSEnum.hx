package cscompiler.components;

#if (macro || cs_runtime)

import haxe.macro.Type;

import reflaxe.BaseCompiler;
import reflaxe.data.EnumOptionData;
import reflaxe.helpers.OperatorHelper;

/**
	The component responsible for compiling Haxe
	enums into C#.
**/
class CSEnum extends CSBase {
	/**
		Implementation of `CSCompiler.compileEnumImpl`.

		TODO.
	**/
	public function compile(enumType: EnumType, options: Array<EnumOptionData>): Null<String> {
		return null;
	}
}
#end
