package cscompiler.ast;

#if(macro || cs_runtime)
import haxe.macro.Type;

/**
	Represents a class in C#.

	TODO.
**/
@:structInit
class CSClass {
	public var name(default, null): String;
	
	public var typeParams(default, null): Array<CSType> = [];
	
	public var superClass(default, null): Null<CSTypePath> = null;
	
	public var superClassTypeParams(default, null): Array<CSType> = [];
	
	public var fields(default, null): Array<CSField> = [];
}
#end
