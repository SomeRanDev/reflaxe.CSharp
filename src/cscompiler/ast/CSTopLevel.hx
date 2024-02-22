package cscompiler.ast;

#if (macro || cs_runtime)

/**
	Represents a top-level entry in a C# source file.

	TODO:
	Should this be an enum only?
	If it's a class, the C# namespace path can be stored separately instead of repeating in every enum case.
**/
class CSTopLevel {
	public var def(default, null): CSTopLevelDef;

	public function new(def: CSTopLevelDef) {
		this.def = def;
	}
}

enum CSTopLevelDef {
	CSTopLevelClass(c: CSClass);
	CSTopLevelEnum(e: CSEnum);
}

#end
