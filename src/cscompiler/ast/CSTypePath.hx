package cscompiler.ast;

/**
    A reference to a C# type described by the given type path.

    This is mostly used as reference to an actual type without needing
    the underlying type right away. Once the whole C# AST has been generated,
    an actual type can be retrieved from its type path (at printing stage).
**/
typedef CSTypePath = String;
