package cscompiler.ast;

#if(macro || cs_runtime)
/**
	Represents a function in C#.
**/
@:structInit
class CSFunction {
	public var args(default, null): Array<CSArg>;
	
	public var returnKind(default, null): CSFunctionReturnKind;
	
	public var statement(default, null): Null<CSStatement> = null;
	
	public function new(args: Array<CSArg>, returnKind: CSFunctionReturnKind,
			?statement: CSStatement) {
		this.args = args;
		this.returnKind = returnKind;
		this.statement = statement;
	}
} enum CSFunctionReturnKind {

	Constructor;
	ReturnVoid;
	ReturnType(returnType: CSType);
}
#end
