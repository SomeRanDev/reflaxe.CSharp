package;

final TEST_DIR = "test/tests";
final OUT_DIR = "out";
final OUT_DIR_LEGACY_CS = "out-legacy-cs";
final INTENDED_DIR = "intended";
final BUILD_DIR = "build";

final COMPARISON_IGNORE_PATHS = ["bin", "obj"];

var HaxeCommand = "haxe";

var ShowAllOutput = false;
var UpdateIntended = false;
var NoDetails = false;
var PrintCommand = false;
var LegacyCS = false;

function printlnErr(msg: String) {
	Sys.stderr().writeString(msg + "\n", haxe.io.Encoding.UTF8);
	Sys.stderr().flush();
}

function main() {
	// ------------------------------------
	// Parse options
	// ------------------------------------
	final args = Sys.args();
	if(args.contains("help")) {
		Sys.println("Run this .hxml file from the root of the repo.
Append the following options to the command:

* help
Shows this output.

* nocompile
The C# compiling/run tests do not occur.

* always-compile
The C# compiling/run tests will occur no matter what, even if the initial output comparison tests fail.

* show-all-output
The output of the C# compilation and executable is always shown, even if it ran successfuly.

* update-intended
The C# output is generated in the `intended` folder.

* no-details
The list of C# output lines that do not match the tests are ommitted from the output.

* dev-mode
Enables `always-compile`, `show-all-output`, and `no-details`.

* print-command
Prints the Haxe commands instead of running them.

* legacy-cs
Also export code from legacy/original C# target

* test=TestName
Makes it so only this test is ran. This option can be added multiple times to perform multiple tests.");

		return;
	}

	// ------------------------------------
	// Test options
	// ------------------------------------
	ShowAllOutput = args.contains("show-all-output");
	UpdateIntended = args.contains("update-intended");
	NoDetails = args.contains("no-details");
	PrintCommand = args.contains("print-command");
	LegacyCS = args.contains("legacy-cs");

	var alwaysCompile = args.contains("always-compile");

	if(args.contains("dev-mode")) {
		alwaysCompile = true;
		ShowAllOutput = true;
		NoDetails = true;
	}

	// ------------------------------------
	// Allowed tests
	// ------------------------------------
	final allowedTests = args.map(a -> {
		final r = ~/test=(\w+)/;
		if(r.match(a)) {
			r.matched(1);
		} else {
			null;
		}
	}).filter(a -> a != null);

	// ------------------------------------
	// Allow defining a specific path for haxe executable.
	// ------------------------------------
	final haxeCmd = Sys.getEnv("REFLAXE_CS_TEST_HAXE_CMD");
	if(haxeCmd != null && haxeCmd.length > 0) {
		HaxeCommand = haxeCmd;
	}

	// ------------------------------------
	// Haxe compiling
	// ------------------------------------
	var tests = checkAndReadDir(TEST_DIR);
	tests = tests.filter(t -> t != '.DS_Store');
	if(allowedTests.length > 0) {
		tests = tests.filter(t -> allowedTests.contains(t));
		if(tests.length <= 0) {
			printlnErr("The provided tests do not exist: " + tests);
			Sys.exit(1);
		}
	}

	final hxmlFiles: Map<String, Array<String>> = [];

	var failures = 0;
	for(t in tests) {
		final testHxmlFiles = processTest(t);
		if(testHxmlFiles == null) {
			failures++;
		} else {
			hxmlFiles.set(t, testHxmlFiles);
		}
	}

	final testCount = tests.length;
	final success = testCount - failures;
	Sys.println("");
	Sys.println(success + " / " + testCount + " tests passed.");

	if(failures > 0 && !alwaysCompile) {
		Sys.exit(1);
	}

	// ------------------------------------
	// C# compiling
	// ------------------------------------
	if(args.contains("nocompile")) {
		return;
	}

	failures = 0;
	final systemName = Sys.systemName();
	final originalCwd = Sys.getCwd();

	Sys.println("\n===========\nTesting C# Compilation\n===========\n");

	if(systemName != "Windows" && systemName != "Linux" && systemName != "Mac") {
		Sys.println("C# compilation test not supported for `" + systemName + "`");
		return;
	}

	for(t in tests) {
		var testHxmlFiles = hxmlFiles.get(t);

		if(testHxmlFiles == null || testHxmlFiles.length == 1) {
			// If only 1 `.hxml` file, pass as `null`.
			testHxmlFiles = [null];
		} else {
			// Remove `.hxml` extension for directory name.
			testHxmlFiles = testHxmlFiles.map(haxe.io.Path.withoutExtension);
		}

		// Compile C# output generated from each `.hxml` file.
		for(maybeHxmlFile in testHxmlFiles) {
			if(!processCsCompile(t, systemName, originalCwd, maybeHxmlFile)) {
				failures++;
				break;
			}
		}
	}

	final success = testCount - failures;
	Sys.println("");
	Sys.println(success + " / " + testCount + " successfully compiled in C#.");

	if(failures > 0) {
		Sys.exit(1);
	}
}

function checkAndReadDir(path: String): Array<String> {
	if(!sys.FileSystem.exists(path)) {
		throw "Path: `" + path + "` could not be found. Is the current working directory (cwd) the top folder of the repository??";
	}
	return sys.FileSystem.readDirectory(path);
}

/**
	If the test was successful, returns an array of all the `.hxml` files.
	Returns `null` if failed.
**/
function processTest(t: String): Null<Array<String>> {
	Sys.println("-- " + t + " --");
	final testDir = haxe.io.Path.join([TEST_DIR, t]);
	final hxmlFiles = checkAndReadDir(testDir).filter(function(file) {
		final p = new haxe.io.Path(file);
		return p.ext == "hxml";
	});
	return if(hxmlFiles.length == 0) {
		printFailed("No .hxml files found in test directory: `" + testDir + "`!");
		null;
	} else {
		executeTests(testDir, hxmlFiles) ? hxmlFiles : null;
	}
}

function printFailed(msg: Null<String> = null) {
	printlnErr("Failed... 💔");
	if(msg != null) {
		printlnErr(msg);
	}
}

function executeTests(testDir: String, hxmlFiles: Array<String>): Bool {
	final hasMultipleHxmlFiles = hxmlFiles.length > 1;
	for(hxml in hxmlFiles) {
		final absPath = haxe.io.Path.join([testDir, hxml]);
		final outputSubDir = hasMultipleHxmlFiles ? haxe.io.Path.withoutExtension(hxml) : null;
		final systemNameDefine = Sys.systemName().toLowerCase();
		final args = [
			"--no-opt",
			"-cp std",
			"-cp std/ucpp/_std",
			"-cp src",
			"-lib reflaxe",
			"extraParams.hxml",
			"-cp " + testDir,
			"--custom-target csharp=" + getOutputDirectory(testDir, outputSubDir),
			"-D " + systemNameDefine,
			"-D reflaxe_no_generated_metadata", // Don't generate metadata in _GeneratedFiles.txt
			"\"" + absPath + "\""
		];

		if(PrintCommand) {
			Sys.println("Command:\nhaxe " + args.join(" "));
			return true;
		}

		final process = new sys.io.Process("\"" + HaxeCommand + "\" " + args.join(" "));
		final _out = process.stdout.readAll();
		final _in = process.stderr.readAll();

		final stdoutContent = _out.toString();
		final stderrContent = _in.toString();

		final ec = process.exitCode();
		if(ec != 0) {
			onProcessFail(process, hxml, ec, stdoutContent, stderrContent);
			return false;
		} else {
			if(stdoutContent.length > 0) {
				Sys.println(stdoutContent);
			}
		}

		if (LegacyCS)
			executeLegacyCSExport(testDir, hxml);
	}
	return if(compareOutputFolders(testDir)) {
		Sys.println("Success! Output matches! ❤️");
		true;
	} else {
		false;
	}
}

function executeLegacyCSExport(testDir: String, hxml: String) {

	// It can be useful to see what the original C# target is exporting, to compare

	final absPath = haxe.io.Path.join([testDir, hxml]);
	final systemNameDefine = Sys.systemName().toLowerCase();
	final args = [
		"--no-opt",
		"-cp", testDir,
		"--cs", haxe.io.Path.join([testDir, OUT_DIR_LEGACY_CS]),
		"-D", "real-position",
		"-D", "no-compilation",
		"-D", systemNameDefine,
		absPath
	];

	Sys.command(HaxeCommand, args);

}

function getOutputDirectory(testDir: String, subDir: Null<String>) {
	final parts = [
		testDir,
		getOutputDirectoryName(testDir)
	];

	if(subDir != null) {
		parts.push(subDir);
	}

	return haxe.io.Path.join(parts);
}

function getOutputDirectoryName(testDir: String): String {
	final sysDir = INTENDED_DIR + "-" + Sys.systemName();
	final sysDirExists = sys.FileSystem.exists(haxe.io.Path.join([testDir, sysDir]));
	return if(UpdateIntended) {
		// If the system exclusive directory exists, use it instead
		if(sysDirExists) {
			sysDir;
		} else {
			INTENDED_DIR;
		}
	} else {
		OUT_DIR;
	}
}

function onProcessFail(process: sys.io.Process, hxml: String, ec: Int, stdoutContent: String, stderrContent: String) {
	final info = [];
	info.push(".hxml File:\n" + hxml);
	info.push("Exit Code:\n" + ec);

	if(stdoutContent.length > 0) {
		info.push("Output:\n" + stdoutContent);
	}

	if(stderrContent.length > 0) {
		info.push("Error Output:\n" + stderrContent);
	}

	var result = "\nFAILURE INFO\n------------------------------------\n";
	result += info.join("\n\n");
	result += "\n------------------------------------\n";

	printFailed(result);
}

function compareOutputFolders(testDir: String): Bool {
	final outFolder = haxe.io.Path.join([testDir, OUT_DIR]);
	final intendedFolderSys = haxe.io.Path.join([testDir, INTENDED_DIR + "-" + Sys.systemName()]);
	final intendedFolder = if(sys.FileSystem.exists(intendedFolderSys)) {
		intendedFolderSys;
	} else {
		haxe.io.Path.join([testDir, INTENDED_DIR]);
	}

	if(!sys.FileSystem.exists(intendedFolder)) {
		printFailed("Intended folder does not exist?");
		return false;
	}

	// Ignore certain paths when comparing `intended/` & `out/`.
	final ignorePaths = [
		for(p in COMPARISON_IGNORE_PATHS)
			haxe.io.Path.join([intendedFolder, p])
	];

	final files = getAllFiles(intendedFolder, ignorePaths);
	final errors = [];
	for(f in files) {
		final intendedPath = haxe.io.Path.join([intendedFolder, f]);
		final outPath = haxe.io.Path.join([outFolder, f]);
		final err = compareFiles(intendedPath, outPath);
		if(err != null) {
			// If updating the intended folder, copy changes to the out/ as well.
			if(UpdateIntended) {
				if(!sys.FileSystem.exists(intendedPath)) {
					sys.FileSystem.deleteFile(outPath);
				} else {
					final dir = haxe.io.Path.directory(outPath);
					if(!sys.FileSystem.exists(dir)) {
						sys.FileSystem.createDirectory(dir);
					}
					sys.io.File.saveContent(outPath, sys.io.File.getContent(intendedPath));
				}
			} else {
				errors.push(err);
			}
		}
	}

	// If updating the intended folder, delete any out/ files that don't match.
	if(UpdateIntended) {
		final outIgnorePaths = [
			for(p in COMPARISON_IGNORE_PATHS)
				haxe.io.Path.join([outFolder, p])
		];
		final outputFiles = getAllFiles(outFolder, outIgnorePaths);
		for(f in outputFiles) {
			if(!files.contains(f)) {
				final path = haxe.io.Path.join([outFolder, f]);
				if(sys.FileSystem.exists(path)) {
					sys.FileSystem.deleteFile(path);
				}
			}
		}
	}

	return if(errors.length > 0) {
		var result = "\nOUTPUT DOES NOT MATCH\n------------------------------------\n";
		result += errors.join("\n");
		result += "\n------------------------------------\n";
		printFailed(result);
		false;
	} else {
		true;
	}
}

function getAllFiles(dir: String, ignore: Array<String>): Array<String> {
	if(ignore.contains(dir)) return [];

	final result = [];
	for(file in sys.FileSystem.readDirectory(dir)) {
		final fullPath = haxe.io.Path.join([dir, file]);
		if(sys.FileSystem.isDirectory(fullPath)) {
			for(f in getAllFiles(fullPath, ignore)) {
				result.push(haxe.io.Path.join([file, f]));
			}
		} else {
			result.push(file);
		}
	}
	return result;
}

function compareFiles(fileA: String, fileB: String): Null<String> {
	if(!sys.FileSystem.exists(fileA)) {
		return "`" + fileA + "` does not exist.";
	}
	if(!sys.FileSystem.exists(fileB)) {
		return "`" + fileB + "` does not exist.";
	}

	function normalize(s: Null<String>) {
		if(s == null) return "";
		return StringTools.trim(StringTools.replace(s, "\r\n", "\n"));
	}

	final contentA = normalize(sys.io.File.getContent(fileA));
	final contentB = normalize(sys.io.File.getContent(fileB));

	if(contentA != contentB) {
		final msg = fileB + "` does not match the intended output.";

		return if(NoDetails) {
			msg;
		} else {
			final result = ["---\n`" + msg + "\n---"];

			final linesA = contentA.split("\n");
			final linesB = contentB.split("\n");

			for(i in 0...linesA.length) {
				if(linesA[i] != linesB[i]) {
					var comp = "* Line " + (i + 1) + "\n";
					comp += "[int] " + linesA[i] + "\n";
					comp += "[out] " + (i < linesB.length ? linesB[i] : "<empty>");
					result.push(comp);
				}
			}

			if(linesB.length > linesA.length) {
				result.push(fileB + " also has " + (linesB.length - linesA.length) + " more lines than " + fileA + ".");
			}

			result.join("\n\n");
		}
	}

	return null;
}

function processCsCompile(t: String, systemName: String, originalCwd: String, subDir: Null<String>): Bool {
	// Implement compile commands before allowing this func
	// Sys.println("Compiling not implemented");
	// return true;

	var result = true;

	Sys.println("-- " + t + " --");

	// This is now done automatically within compiler
	// createCsProjBuildFiles(t);

	final testOutDirParts = [TEST_DIR, t, OUT_DIR];
	if(subDir != null) testOutDirParts.push(subDir);
	final testOutDir = haxe.io.Path.join(testOutDirParts);
	trace(testOutDir);

	if(!sys.FileSystem.exists(testOutDir)) {
		sys.FileSystem.createDirectory(testOutDir);
	}

	Sys.setCwd(testOutDir);

	// final compileCommand = if(systemName == "Windows") {
	// 	// TODO: windows command
	// 	"";
	// } else if(systemName == "Linux") {
	// 	// TODO: linux command
	// 	"";
	// } else if(systemName == "Mac") {
	// 	// TODO: mac command
	// 	"";
	// } else {
	// 	throw "Unsupported system";
	// }

	// Using Sys.command() for now because sys.io.Process() was stuck forever
	final ec = Sys.command("dotnet", ["build", "--nologo"]);

	// final compileProcess = new sys.io.Process(compileCommand);
	// final stdoutContent = compileProcess.stdout.readAll().toString();
	// final stderrContent = compileProcess.stderr.readAll().toString();
	// final ec = compileProcess.exitCode();

	if(ec != 0) {
		Sys.println("C# compilation failed...");
		// Sys.println(stdoutContent);
		// Sys.println(stderrContent);
		result = false;
	} else {
		Sys.println("C# compilation success! 🤑");
		// if(ShowAllOutput) {
		// 	Sys.println(stdoutContent);
		// 	Sys.println(stderrContent);
		// }
	}

	if (result) {
		Sys.println("--");
		final exeEc = Sys.command("dotnet", ["run", "--nologo"]);
		Sys.println("--");

		// // Run output
		// final executeProcess = new sys.io.Process("\"./test_out\"");
		// final exeOut = executeProcess.stdout.readAll().toString();
		// final exeErr = executeProcess.stderr.readAll().toString();
		// final exeEc = executeProcess.exitCode();
		if(exeEc != 0) {
			Sys.println("C# executable returned exit code: " + exeEc);
			// Sys.println(exeOut);
			// Sys.println(exeErr);
			result = false;
		} else {
			Sys.println("C# executable ran successfully! 🦶");
			// if(ShowAllOutput) {
			// 	Sys.println(exeOut);
			// 	Sys.println(exeErr);
			// }
		}
	}

	// Reset to original current working directory
	Sys.setCwd(originalCwd);

	return result;
}

function findMainTypeFromHxml(hxmlFile: String):String {
	final hxmlData = sys.io.File.getContent(hxmlFile);
	for (line in hxmlData.split("\n")) {
		line = StringTools.trim(line);
		if (StringTools.startsWith(line, "-main ")) {
			return StringTools.trim(line.substr(6));
		}
	}
	return null;
}

