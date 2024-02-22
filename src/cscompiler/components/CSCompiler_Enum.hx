package cscompiler.components;

#if (macro || cs_runtime)

import haxe.macro.Type;

import reflaxe.BaseCompiler;
import reflaxe.data.EnumOptionData;
import reflaxe.helpers.OperatorHelper;

import cscompiler.ast.CSEnum;

/**
	The component responsible for compiling Haxe
	enums into C#.
**/
class CSCompiler_Enum extends CSCompiler_Base {
	/**
		Implementation of `CSCompiler.compileEnumImpl`.

		TODO.
	**/
	public function compile(enumType: EnumType, options: Array<EnumOptionData>): Null<CSEnum> {
		return null;
	}
}
#end
