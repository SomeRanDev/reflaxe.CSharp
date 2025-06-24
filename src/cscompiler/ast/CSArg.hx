package cscompiler.ast;

#if(macro || cs_runtime)
import cscompiler.ast.CSExpr;

typedef CSArg = {
	public var ?name(default, null): Null<String>;
	
	public var type(default, null): CSType;
	
	public var opt(default, null): Bool;
	
	public var ?value(default, null): Null<CSExpr>;
}
#end
