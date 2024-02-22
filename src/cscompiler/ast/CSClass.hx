package cscompiler.ast;

#if (macro || cs_runtime)

/**
	Represents a class in C#.

	TODO.
**/
class CSClass {
	public var name(default, null): String;

	var superClass: Null<CSClass>;
	var superClassTypeParams: Null<Array<CSType>>;

	public function new(name: String) {
		this.name = name;
	}

	public function setSuperClass(superClass: CSClass, typeParams: Array<CSType>) {
		this.superClass = superClass;
		superClassTypeParams = typeParams;
	}
}

#end
