package cscompiler.ast;

#if (macro || cs_runtime)

/**
	Represents a function in C#.
**/
@:structInit
class CSFunction {

	public var args(default, null): Array<CSArg>;

	public var ret(default, null): CSType;

	public var statement(default, null): Null<CSStatement> = null;

	public function new(args: Array<CSArg>, ret: CSType, ?statement: CSStatement) {
		this.args = args;
		this.ret = ret;
		this.statement = statement;
	}

}

#end
