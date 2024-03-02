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
	/**
	 	Both haxe TInst and TEnum will be transpiled to this because
		Haxe enum instances will become C# class instances anyway
	**/
	CSInst(typePath: CSTypePath, params: Array<CSType>);

	/**
		Only used when generating actual C# enums, which could happen if
		it is an extern C# enum or a haxe enum marked with `@:nativeGen`

		TODO: generate C# enum from haxe enum when using @:nativeGen
	**/
	CSEnum(typePath: CSTypePath, params: Array<CSType>);

	/**
		Function type, that may be translated into
		an `Action<T1,T2,...>` or `Func<T1,T2,...>`
		when used as an object type.
	**/
	CSFunction(args: Array<CSArg>, ret: CSType);

	/**
		A C# value type (primitives like `int`, `bool`... or `struct` types) type. Optionally nullable (`int?` etc...)
	**/
	CSValue(typePath: CSTypePath, params: Array<CSType>, nullable: Bool);

}

#end
