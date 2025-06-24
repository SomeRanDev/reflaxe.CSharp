package cscompiler.ast;

#if(macro || cs_runtime)
import cscompiler.ast.CSType;

/**
	Represents a variable in C#.
**/
@:structInit
class CSVar {
	/**
		TODO:
		Is an `id` system necessary?
		Haxe equality should work since we're not regenerating
		objects when obtaining data from OCaml.
	**/
	// var id: Int;
	public var name(default, null): String;
	
	public var type(default, null): CSVarType;
	
	// static var nextId = 0;
	
	public function new(name: String, type: CSVarType) {
		// id = nextId++;
		
		this.name = name;
		this.type = type;
	}
}

enum CSVarType {
	Infer;
	KnownType(type: CSType);
}
#end
