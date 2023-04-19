package cscompiler;

#if (macro || cs_runtime)

import haxe.macro.Context;

import reflaxe.ReflectCompiler;
import reflaxe.input.ClassModifier;

using reflaxe.helpers.ExprHelper;

class CSCompilerInit {
	public static function Start() {
		#if !eval
		Sys.println("CSCompilerInit.Start can only be called from a macro context.");
		return;
		#end

		#if (haxe_ver < "4.3.0")
		Sys.println("Reflaxe/C# requires Haxe version 4.3.0 or greater.");
		return;
		#end

		ReflectCompiler.AddCompiler(new CSCompiler(), {
			fileOutputExtension: ".cs",
			outputDirDefineName: "cs-output",
			fileOutputType: FilePerClass,
			reservedVarNames: reservedNames(),
			targetCodeInjectionName: "__cs__",
			smartDCE: true,
			customStdMeta: [":csStd"],
			trackUsedTypes: true,
			allowMetaMetadata: true,
			autoNativeMetaFormat: "[{}]"
		});

		applyMods();
	}

	static function applyMods() {
		// Provide StringTools.isEof implementation for this target.
		ClassModifier.mod("StringTools", "isEof", macro return c == 0);
	}

	// https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/
	static function reservedNames() {
		return [
			"add", "and", "alias", "ascending", "args", "async", "await", "by",
			"descending", "dynamic", "equals", "file", "from", "get", "global",
			"group", "init", "into", "join", "let", "managed", "nameof", "nint",
			"not", "notnull", "nuint", "on", "or", "orderby", "partial", "record",
			"remove", "required", "scoped", "select", "set", "unmanaged", "value",
			"var", "when", "where", "with", "yield"
		];
	}
}

#end