package cscompiler.ast;

#if (macro || cs_runtime)

/**
	Represents a constant expression.

	TODO: Give each case a better description.
**/
enum CSConstant {
	CSInt(i: Int, suffix: String);

	/**
		TODO:
		Should there be a `CSDouble`?
		Or some better way to handle differen suffixes?
	**/
	CSFloat(s: String, suffix: String);

	CSString(s: String);
	CSBool(b: Bool);

	CSNull;
	CSThis;
	CSSuper;
}

#end
