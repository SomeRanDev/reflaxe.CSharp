package cscompiler.ast;

import cscompiler.ast.CSTypePath;

enum CSFieldAccess {

	/**
		Access of field `cf` on a class instance `c` with type parameters
		`params`.
	**/
	CSFInstance(c:CSTypePath, params:Array<CSType>, cf:String);

	/**
		Static access of a field `cf` on a class `c`.
        Note that we accept type params here because it is valid in C#
	**/
	CSFStatic(c:CSTypePath, params:Array<CSType>, cf:String);

}
