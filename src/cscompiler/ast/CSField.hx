package cscompiler.ast;

@:structInit
class CSField {
	/**
		The name of the field.
	**/
	public var name:String;

	/**
		The access modifiers of the field.
	**/
	public var access:Array<CSAccessModifier>;

	/**
		The kind of the field.
	**/
	public var kind:CSFieldKind;
}
