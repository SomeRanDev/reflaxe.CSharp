package cscompiler.ast;

@:structInit
class CSField {
	/**
		The name of the field.
	**/
	public var name:String;

	/**
		The modifiers of the field.
	**/
	public var modifiers:Array<CSModifier>;

	/**
		The kind of the field.
	**/
	public var kind:CSFieldKind;
}
