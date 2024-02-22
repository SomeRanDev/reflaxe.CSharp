package cscompiler.ast;

#if (macro || cs_runtime)

/**
	Represents a C# type.

	TODO:
	This might be the best way to do this?

	A `CSType` should be generated from a Haxe `Type` right?
	But a `CSClass` requires parsing an entire `ClassType` to be created (including fields);
	do we want to parse extern classes that we don't need to generate? 
**/
enum CSType {
	IsCSClass(c: CSClass);
	IsCSEnum(e: CSEnum);
}

#end
