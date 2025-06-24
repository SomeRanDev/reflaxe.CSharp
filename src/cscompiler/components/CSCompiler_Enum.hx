package cscompiler.components;

#if(macro || cs_runtime)
import haxe.macro.Type;

import reflaxe.data.EnumOptionData;

import cscompiler.ast.CSTopLevel;

/**
	The component responsible for compiling Haxe
	enums into C#.
**/
class CSCompiler_Enum extends CSCompiler_Base {
	/**
		Implementation of `CSCompiler.compileEnumImpl`.

		TODO.
	**/
	public function compile(enumType: EnumType, options: Array<EnumOptionData>): Null<CSTopLevel> {
		return {
			nameSpace: compiler.typeComp.getNameSpace(enumType),
			def: CSTopLevelEnum({
				name: compiler.compileEnumName(enumType),
			})
		};
	}
}
#end
