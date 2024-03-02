package cscompiler.ast;

#if (macro || cs_runtime)

import haxe.macro.Type;

/**
	Represents an enum in C#.

	TODO.
**/
@:structInit
class CSEnum {
	public var name(default, null): String;

	public var haxeType(default, null): Type;
}

#end
