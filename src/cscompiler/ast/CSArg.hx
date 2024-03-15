package cscompiler.ast;

import cscompiler.ast.CSExpr;

typedef CSArg = {

    public var ?name(default, null):Null<String>;

    public var type(default, null):CSType;

    public var opt(default, null):Bool;

    public var ?expr(default, null):Null<CSExpr>;

}
