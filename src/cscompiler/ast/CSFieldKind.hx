package cscompiler.ast;

import cscompiler.ast.CSExpr;
import cscompiler.ast.CSStatement;
import cscompiler.ast.CSFunction;

enum CSFieldKind {

    CSMethod(func:CSFunction);

    CSVar(type:CSType, expr:Null<CSStatement>);

    // TODO will we need that?
    CSProp(type:CSType, get:Null<CSStatement>, set:Null<CSStatement>);

}
