package cscompiler.ast;

#if (macro || cs_runtime)

/**
	Represents a top-level entry in a C# source file.

	TODO:
	Should this be an enum only?
	If it's a class, the C# namespace path can be stored separately instead of repeating in every enum case.
**/
@:structInit
class CSTopLevel {
	public var def(default, null): CSTopLevelDef;

	public var nameSpace(default, null): String;

	public function new(def: CSTopLevelDef, nameSpace: String) {
		this.def = def;
		this.nameSpace = nameSpace;
	}
}

enum CSTopLevelDef {
	CSTopLevelClass(c: CSClass);
	CSTopLevelEnum(e: CSEnum);
}

#end
