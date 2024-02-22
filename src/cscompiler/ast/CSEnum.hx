package cscompiler.ast;

#if (macro || cs_runtime)

/**
	Represents an enum in C#.

	TODO.
**/
class CSEnum {
	public var name(default, null): String;

	public function new(name: String) {
		this.name = name;
	}
}

#end
