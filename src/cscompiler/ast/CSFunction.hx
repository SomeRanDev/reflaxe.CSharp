package cscompiler.ast;

#if (macro || cs_runtime)

/**
	Represents a function in C#.
**/
class CSFunction {

	public var args(default, null): Array<CSArg>;

	public var ret(default, null): CSType;

	public var expr(default, null): Null<CSExpr> = null;

	public function new(args: Array<CSArg>, ret: CSType, ?expr: CSExpr) {
		this.args = args;
		this.ret = ret;
		this.expr = expr;
	}

}

#end
