package cscompiler.config;

/**
    Represents the value for the `-D namespace_style` define.
**/
enum NamespaceStyle {
    Default;
    Pascal;
}

/**
    Converts a `String` from a define to the `NamespaceStyle` enum.
**/
function fromString(defineValue: String) {
    return switch(defineValue.toLowerCase()) {
        case "pascal": Pascal;
        case _: Default;
    }
}
