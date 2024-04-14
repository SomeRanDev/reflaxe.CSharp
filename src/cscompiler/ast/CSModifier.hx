package cscompiler.ast;

#if (macro || cs_runtime)

enum CSModifier {

    CSStatic;

    CSAbstract;

    CSVirtual;

    CSOverride;

    CSPublic;

    CSPrivate;

    CSProtected;

    CSInternal;

}

#end