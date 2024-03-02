package cscompiler.ast;

import cscompiler.ast.CSExpr;
import cscompiler.ast.CSFunction;

enum CSFieldKind {

    CSMethod(func:CSFunction);

    CSVar(type:CSType, expr:CSExpr);

    // TODO will we need that?
    CSProp(type:CSType, get:CSExpr, set:CSExpr);

}
