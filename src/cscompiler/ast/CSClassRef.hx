package cscompiler.ast;

import cscompiler.ast.CSClass;

// A reference to a `CSClass` object, useful when we need
// to reference a type for which we don't have full AST yet.
class CSClassRef {

    public var typePath(default, null):String;

    // For now, we identify a reference a `CSClass` with its
    // type path as `String`, but it's ok if we decide to use
    // something else as identity later (or not).
    public function new(typePath:String) {
        this.typePath = typePath;
    }
}
