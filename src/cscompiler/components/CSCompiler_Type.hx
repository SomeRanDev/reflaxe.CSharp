package cscompiler.components;

import cscompiler.ast.CSTypePath;
import cscompiler.ast.CSFunction;
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
		return switch(type) {
			case TMono(refType): {
				final maybeType = refType.get();
				if(maybeType != null) {
					compile(maybeType, pos);
				} else {
					null;
				}
			}
			case TEnum(enumRef, params): {
				CSInst(
					compileEnumType(enumRef.get()),
					compileTypeParams(params)
				);
			}
			case TInst(clsRef, params): {
				final cls = clsRef.get();
				if (cls.hasMeta(':struct')) {
					// When using @:struct meta, we are
					// dealing with a C# `struct` value type
					CSValue(
						compileClassType(cls),
						compileTypeParams(params),
						false
					);
				}
				else {
					CSInst(
						compileClassType(cls),
						compileTypeParams(params)
					);
				}
			}
			case TType(_, _): {
				compile(Context.follow(type), pos);
			}
			case TFun(args, ret): {
				compileFunctionType(args, ret, pos);
			}
			case TAnonymous(anonRef): {
				// For now, we simply use `object` type. Might change later
				CSInst('object', []);
			}
			case TDynamic(maybeType): {
				// TODO, returning `dynamic` type for now here
				CSInst('dynamic', []);
			}
			case TLazy(callback): {
				compile(callback(), pos);
			}
			case TAbstract(absRef, params): {
				var absType = absRef.get();
				var primitiveType = checkPrimitiveType(absType, params);

				if (primitiveType != null) {
					CSValue(
						primitiveType, [], false
					);
				}
				else if (absType.name == "Null") {
					makeNullable(compile(params[0], pos));
				}
				else {
					compile(Context.followWithAbstracts(type), pos);
				}
			}
		}
	}

	function compileEnumType(enumType:EnumType):CSTypePath {

		return compileEnumName(enumType, true);

	}

	function compileClassType(classType:ClassType):CSTypePath {

		return compileClassName(classType, true);

	}

	function compileTypeParams(params:Array<Type>):Array<CSType> {

		// TODO
		return [];

	}

	function compileFunctionType(args:Array<{name:String, opt:Bool, t:Type}>, ret:Type, pos:Position):CSType {

		return CSFunction(
			args.map(arg -> {
				name: arg.name,
				opt: arg.opt,
				type: compile(arg.t, pos)
			}),
			compile(ret, pos)
		);

	}

	function makeNullable(type: Null<CSType>): Null<CSType> {

		return switch type {
			case null:
				null;
			case CSInst(typePath, params):
				type;
			case CSEnum(typePath, params):
				type;
			case CSFunction(args, ret):
				type;
			case CSValue(typePath, params, _):
				// Value types need to be explicitly nullable,
				// whereas other types are already implicitly
				// nullable so we don't change them.
				CSValue(typePath, params, true);
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
