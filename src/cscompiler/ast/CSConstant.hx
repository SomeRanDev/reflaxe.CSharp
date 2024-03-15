package cscompiler.ast;

#if (macro || cs_runtime)

/**
	Represents a constant expression.

	TODO: Give each case a better description.
**/
enum CSConstant {
	CSInt(i: Int);

	/**
		TODO:
		Should there be a `CSDouble`?
		Or some better way to handle different suffixes?
	**/
	CSFloat(s: String);
	CSDouble(s: String);

	CSString(s: String);
	CSBool(b: Bool);

	CSNull;
	CSThis;
	CSBase;
}

#end
