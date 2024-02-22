package cscompiler.ast;

#if (macro || cs_runtime)

/**
	Represents a variable in C#.
**/
class CSVar {
	/**
		TODO:
		Is an `id` system necessary?
		Haxe equality should work since we're not regenerating
		objects when obtaining data from OCaml.
	**/
	// var id: Int;

	var name: String;
	var type: CSType;

	// static var nextId = 0;

	public function new(name: String, type: CSType) {
		// id = nextId++;

		this.name = name;
		this.type = type;
	}
}

#end
