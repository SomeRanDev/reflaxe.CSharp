package cscompiler.helpers;

#if (macro || cs_runtime)

/**
	`String` helper methods used with Reflaxe/C#.
**/
class StringTools {
	/**
		Converts a snake-case identifier or path to pascal-case.
	**/
	public static function toPascalCase(snakeCase: String) {
		// If single character or empty, return uppercase version.
		if(snakeCase.length < 2) {
			return snakeCase.toUpperCase();
		}

		// Remove underscores and uppercase subsequent character.
		final result = ~/[\._]\w/g.map(
			snakeCase,
			(each) -> {
				final part = each.matched(0);
				final separator = part.charAt(0);
				final character = part.charAt(1).toUpperCase();
				return '${separator == "." ? separator : ""}${character}';
			}
		);

		// Make the first character uppercase.
		return '${result.charAt(0).toUpperCase()}${result.substr(1)}';
	}
}

#end
