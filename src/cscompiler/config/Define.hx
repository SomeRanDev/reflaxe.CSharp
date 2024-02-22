package cscompiler.config;

#if (macro || cs_runtime)

import reflaxe.helpers.Context; // same as haxe.macro.Context

/**
	Lists all the custom defines available for configuring Reflaxe/C#.
**/
@:using(cscompiler.config.Define.DefineTools)
enum abstract Define(String) from String to String {
	/**
		-D csproj=[path to file]

		When set, the csproj at the specified path will be used for C#
		instead of an auto-generated csproj.

		This will be ignored when the `Define` `no-csproj` is set.
	**/
	var D_Csproj = "csproj";

	/**
		-D namespace_style=[default|pascal]

		Default value: `default`

		Determines how namespace names are generated for C#.

		If set to `pascal`, snake-case package names are converted
		to pascal-case C# namespaces.
	**/
	var D_NamespaceStyle = "namespace_style";

	/**
		-D no-csproj

		When set, a csproj file will not be generated C#.

		This also applies to any csproj file specified with
		the Define `csproj`.
	**/
	var D_NoCsproj = "no-csproj";
}

/**
	A class containing static extension functions for `Define`.

	Should be used like this:
	```haxe
	if(Define.XYZ.isDefined()) {
		final value = Define.XYZ.getValue();
	}
	```
**/
class DefineTools {
	/**
		Checks if the define is defined using `Context.defined`.
	**/
	public static function isDefined(self: Define): Bool {
		return Context.defined(self);
	}

	/**
		Returns the value of the define using `Context.definedValue`.
		If it isn't defined, `null` is returned.
	**/
	public static function getValueOrNull(self: Define): Null<String> {
		return Context.definedValue(self);
	}

	/**
		Returns the value of the define using `Context.definedValue`.
		Throws an error if the define does not exist.
	**/
	public static function getValue(self: Define): String {
		final result = getValueOrNull(self);
		if(result == null) {
			throw "DefineTools.getValue called on undefined Define.";
		}
		return result;
	}
}

#end
