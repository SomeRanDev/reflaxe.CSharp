package cscompiler.components;

#if (macro || cs_runtime)

import reflaxe.helpers.Context; // same as haxe.macro.Context
import haxe.macro.Expr;
import haxe.macro.Type;

import cscompiler.ast.CSType;
import cscompiler.config.Define;
import cscompiler.config.NamespaceStyle;
import cscompiler.config.NamespaceStyle.fromString as NamespaceStyle_fromString;
import cscompiler.helpers.StringTools;

using reflaxe.helpers.ModuleTypeHelper;
using reflaxe.helpers.NameMetaHelper;

/**
	The component responsible for compiling Haxe
	types into C#.
**/
class CSCompiler_Type extends CSCompiler_Base {
	/**
		Generates the C# type code given the Haxe `haxe.macro.Type`.

		TODO.
	**/
	public function compile(type: Type, pos: Position): Null<CSType> {
		// Temp fix for CSType return
		return null;

		/* return */ switch(type) {
			case TMono(refType): {
				final maybeType = refType.get();
				if(maybeType != null) {
					compile(maybeType, pos);
				} else {
					null;
				}
			}
			case TEnum(enumRef, params): {
				withTypeParams(compileEnumName(enumRef.get()), params, pos);
			}
			case TInst(clsRef, params): {
				withTypeParams(compileClassName(clsRef.get()), params, pos);
			}
			case TType(_, _): {
				compile(Context.follow(type), pos);
			}
			case TFun(args, ref): {
				// TODO
				null;
			}
			case TAnonymous(anonRef): {
				// TODO
				// For now, we simply use `object` type. Might change later
				"object";
			}
			case TDynamic(maybeType): {
				// TODO
				null;
			}
			case TLazy(callback): {
				compile(callback(), pos);
			}
			case TAbstract(absRef, params): {
				var absType = absRef.get();
				var primitiveType = checkPrimitiveType(absType, params);

				if (primitiveType != null) {
					primitiveType;
				}
				else if (absType.name == "Null") {
					if (params != null && params.length > 0 && isValueType(params[0])) {
						compile(params[0], pos) + "?";
					}
					else {
						compile(params[0], pos);
					}
				}
				else {
					compile(Context.followWithAbstracts(type), pos);
				}
			}
		}
	}

	/**
		If the provided `TAbstract` info should generate a primitive type,
		this function compiles and returns the type name.

		Returns `null` if the abstract is not a primitive.
	**/
	function checkPrimitiveType(absType: AbstractType, params: Array<Type>): Null<String> {
		if(params.length > 0 || absType.pack.length > 0) {
			return null;
		}
		return switch(absType.name) {
			case "Void": "void";
			case "Int": "int";
			case "UInt": "uint";
			case "Float": "double";
			case "Bool": "bool";
			case _: null;
		}
	}

	/**
		Returns `true` if the given type is a **value type**.
		A **value type** is either a primitive type or a (C#) struct type.
	**/
	function isValueType(type: Type): Bool {
		return switch type {
			case TInst(t, params):
				// TODO classes with @:structAccess
				false;
			case TAbstract(absRef, params):
				final absType = absRef.get();
				final primitiveType = checkPrimitiveType(absType, params);
				if (primitiveType != null) {
					true;
				}
				else {
					isValueType(Context.followWithAbstracts(type));
				}
			case _:
				false;
		}
	}

	/**
		Append type parameters to the compiled type.
	**/
	function withTypeParams(name: String, params: Array<Type>, pos: Position): String {
		return name + (params.length > 0 ? '<${params.map(p -> compile(p, pos)).join(", ")}>' : "");
	}

	/**
		Generate C# output for `ModuleType` used in an expression
		(i.e. for cast or static access).
	**/
	public function compileModuleExpression(moduleType: ModuleType): String {
		return switch(moduleType) {
			case TClassDecl(clsRef):
				compileClassName(clsRef.get(), true);
			case _:
				moduleType.getNameOrNative();
		}
	}

	/**
		Get the name of the `ClassType` as it should appear in
		the C# output.
	**/
	public function compileClassName(classType: ClassType, withPack: Bool = false): String {
		return if(withPack) {
			getNameSpace(classType) + "." + classType.getNameOrNative();
		} else {
			classType.getNameOrNative();
		}
	}

	/**
		Get the name of the `EnumType` as it should appear in
		the C# output.
	**/
	public function compileEnumName(enumType: EnumType, withPack: Bool = false): String {
		return if(withPack) {
			getNameSpace(enumType) + "." + enumType.getNameOrNative();
		} else {
			enumType.getNameOrNative();
		}
	}

	/**
		Get a C# namespace for the given package
	**/
	public function getNameSpace(baseType: BaseType):String {
		final pack = getPackWithoutModule(baseType);
		if (pack.length == 0) {
			return CSCompiler.DEFAULT_ROOT_NAMESPACE;
		}

		final result = pack.join(".");
		return switch(NamespaceStyle_fromString(D_NamespaceStyle.getValueOrNull() ?? "")) {
			case Pascal: {
				StringTools.toPascalCase(result);
			}
			case Default: {
				result;
			}
		}
	}

	/**
		Get copy of `pack` from a `BaseType` with the module name
		removed.
	**/
	public function getPackWithoutModule(baseType: BaseType): Array<String> {
		final pack = baseType.pack.copy();

		if(pack.length > 0) {
			inline function shouldExcludeLastPackItem(item: String):Bool {
				return item.toLowerCase() != item;
			}

			while (pack.length > 0 && shouldExcludeLastPackItem(pack[pack.length - 1])) {
				pack.pop();
			}
		}

		return pack;
	}
}
#end
