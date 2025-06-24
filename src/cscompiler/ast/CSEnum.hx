package cscompiler.ast;

#if(macro || cs_runtime)
/**
	Represents an enum in C#.

	TODO.
**/
@:structInit
class CSEnum {
	public var name(default, null): String;
}
#end
