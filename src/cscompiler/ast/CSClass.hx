package cscompiler.ast;

#if (macro || cs_runtime)

/**
	Represents a class in C#.

	TODO.
**/
@:structInit
class CSClass {
	public var name(default, null): String;

	public var superClass(default, null): Null<CSClass> = null;

	public var superClassTypeParams(default, null): Array<CSType> = [];

	public var fields(default, null): Array<CSField> = [];
}

#end
