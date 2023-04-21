package cscompiler.components;

#if (macro || cs_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;

using reflaxe.helpers.ModuleTypeHelper;
using reflaxe.helpers.NameMetaHelper;

/**
	The component responsible for compiling Haxe
	types into C#.
**/
class CSType extends CSBase {
	/**
		Generates the C# type code given the Haxe `haxe.macro.Type`.

		TODO.
	**/
	public function compile(type: Type, pos: Position): Null<String> {
		return switch(type) {
			case TAbstract(_.get() => { name: "Void" }, []): {
				"void";
			}
			case TAbstract(_.get() => { name: "Int" }, []): {
				"int";
			}
			case _: {
				"UNKNOWN_TYPE";
			}
		}
	}

	/**
		Generate C# output for `ModuleType` used in an expression
		(i.e. for cast or static access).
	**/
	public function compileModule(moduleType: ModuleType): String {
		switch(moduleType) {
			case TClassDecl(clsRef): compileClassName(clsRef.get());
			case _:
		}
		return moduleType.getNameOrNative();
	}

	/**
		Get the name of the `ClassType` as it should appear in
		the C# output.
	**/
	public function compileClassName(classType: ClassType): String {
		return classType.getNameOrNative();
	}
}
#end
