package cscompiler.ast;

import haxe.macro.Type.Ref;
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
	// Both haxe TInst and TEnum will be transpiled to this because
	// Haxe enum instances will become C# class instances anyway
	CSInst(c: CSClassRef, params: Null<Array<CSType>>);
}

#end
