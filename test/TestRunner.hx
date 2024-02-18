package;

// ------------------------------------
// Imports
// ------------------------------------
import haxe.io.Path;

import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

// ------------------------------------
// Constants
// ------------------------------------
final TEST_DIR = "test/tests";
final OUT_DIR = "out";
final OUT_DIR_LEGACY_CS = "out-legacy-cs";
final INTENDED_DIR = "intended";
final BUILD_DIR = "build";

final COMPARISON_IGNORE_PATHS = ["bin", "obj"];

// ------------------------------------
// Argument Variables
// ------------------------------------
var HaxeCommand = "haxe";

var ShowAllOutput = false;
var UpdateIntended = false;
var NoDetails = false;
var PrintCommand = false;
var LegacyCS = false;

/**
	Prints a `String` to stderr.
**/
function printlnErr(msg: String) {
	Sys.stderr().writeString(msg + "\n", haxe.io.Encoding.UTF8);
	Sys.stderr().flush();
}

/**
	The main function.
**/
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
			testHxmlFiles = testHxmlFiles.map(Path.withoutExtension);
		}

		// Compile C# output generated from each `.hxml` file.
		for(maybeHxmlFile in testHxmlFiles) {
			if(!compileAndRunCs(t, systemName, originalCwd, maybeHxmlFile)) {
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
	if(!FileSystem.exists(path)) {
		throw "Path: `" + path + "` could not be found. Is the current working directory (cwd) the top folder of the repository??";
	}
	return FileSystem.readDirectory(path);
}

/**
	If the test was successful, returns an array of all the `.hxml` files.
	Returns `null` if failed.
**/
function processTest(t: String): Null<Array<String>> {
	Sys.println("-- " + t + " --");
	final testDir = Path.join([TEST_DIR, t]);
	final hxmlFiles = checkAndReadDir(testDir).filter(function(file) {
		final p = new Path(file);
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

/**
	Runs the haxe compilation for all the tests' `.hxml` files.
**/
function executeTests(testDir: String, hxmlFiles: Array<String>): Bool {
	final hasMultipleHxmlFiles = hxmlFiles.length > 1;
	for(hxml in hxmlFiles) {
		final absPath = Path.join([testDir, hxml]);
		final outputSubDir = hasMultipleHxmlFiles ? Path.withoutExtension(hxml) : null;
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

		final process = new Process("\"" + HaxeCommand + "\" " + args.join(" "));
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

/**
	It can be useful to see what the original C# target is exporting, to compare
**/
function executeLegacyCSExport(testDir: String, hxml: String) {
	final absPath = Path.join([testDir, hxml]);
	final systemNameDefine = Sys.systemName().toLowerCase();
	final args = [
		"--no-opt",
		"-cp", testDir,
		"--cs", Path.join([testDir, OUT_DIR_LEGACY_CS]),
		"-D", "real-position",
		"-D", "no-compilation",
		"-D", systemNameDefine,
		absPath
	];

	Sys.command(HaxeCommand, args);

}

/**
	Generates the full output directory.
**/
function getOutputDirectory(testDir: String, subDir: Null<String>) {
	final parts = [
		testDir,
		getOutputDirectoryBase(testDir)
	];

	if(subDir != null) {
		parts.push(subDir);
	}

	return Path.join(parts);
}

/**
	Returns the base output directory:

	`out` if normal test.
	`intended` if updating intended output.
	`intended-SYSTEM` if updating intended for system-specific test.
**/
function getOutputDirectoryBase(testDir: String): String {
	final sysDir = INTENDED_DIR + "-" + Sys.systemName();
	final sysDirExists = FileSystem.exists(Path.join([testDir, sysDir]));
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

function onProcessFail(process: Process, hxml: String, ec: Int, stdoutContent: String, stderrContent: String) {
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

/**
	Compares the contents of the `out` and `intended` folders.
**/
function compareOutputFolders(testDir: String): Bool {
	final outFolder = Path.join([testDir, OUT_DIR]);
	final intendedFolderSys = Path.join([testDir, INTENDED_DIR + "-" + Sys.systemName()]);
	final intendedFolder = if(FileSystem.exists(intendedFolderSys)) {
		intendedFolderSys;
	} else {
		Path.join([testDir, INTENDED_DIR]);
	}

	if(!FileSystem.exists(intendedFolder)) {
		printFailed("Intended folder does not exist?");
		return false;
	}

	// Ignore certain paths when comparing `intended/` & `out/`.
	final ignorePaths = [
		for(p in COMPARISON_IGNORE_PATHS)
			Path.join([intendedFolder, p])
	];

	final files = getAllFiles(intendedFolder, ignorePaths);
	final errors = [];
	for(f in files) {
		final intendedPath = Path.join([intendedFolder, f]);
		final outPath = Path.join([outFolder, f]);
		final err = compareFile(intendedPath, outPath);
		if(err != null) {
			// If updating the intended folder, copy changes to the out/ as well.
			if(UpdateIntended) {
				if(!FileSystem.exists(intendedPath)) {
					FileSystem.deleteFile(outPath);
				} else {
					final dir = Path.directory(outPath);
					if(!FileSystem.exists(dir)) {
						FileSystem.createDirectory(dir);
					}
					File.saveContent(outPath, File.getContent(intendedPath));
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
				Path.join([outFolder, p])
		];
		final outputFiles = getAllFiles(outFolder, outIgnorePaths);
		for(f in outputFiles) {
			if(!files.contains(f)) {
				final path = Path.join([outFolder, f]);
				if(FileSystem.exists(path)) {
					FileSystem.deleteFile(path);
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
	for(file in FileSystem.readDirectory(dir)) {
		final fullPath = Path.join([dir, file]);
		if(FileSystem.isDirectory(fullPath)) {
			for(f in getAllFiles(fullPath, ignore)) {
				result.push(Path.join([file, f]));
			}
		} else {
			result.push(file);
		}
	}
	return result;
}

function compareFile(fileA: String, fileB: String): Null<String> {
	if(!FileSystem.exists(fileA)) {
		return "`" + fileA + "` does not exist.";
	}
	if(!FileSystem.exists(fileB)) {
		return "`" + fileB + "` does not exist.";
	}

	function normalize(s: Null<String>) {
		if(s == null) return "";
		return StringTools.trim(StringTools.replace(s, "\r\n", "\n"));
	}

	final contentA = normalize(File.getContent(fileA));
	final contentB = normalize(File.getContent(fileB));

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

function compileAndRunCs(t: String, systemName: String, originalCwd: String, subDir: Null<String>): Bool {
	var result = true;

	Sys.println("-- " + t + " --");

	final testOutDirParts = [TEST_DIR, t, OUT_DIR];
	if(subDir != null) testOutDirParts.push(subDir);
	final testOutDir = Path.join(testOutDirParts);

	if(!FileSystem.exists(testOutDir)) {
		FileSystem.createDirectory(testOutDir);
	}

	Sys.setCwd(testOutDir);

	// Compile C#
	// Using Sys.command() for now because sys.io.Process() was stuck forever
	final ec = Sys.command("dotnet", ["build", "--nologo"]);

	if(ec != 0) {
		Sys.println("C# compilation failed...");
		result = false;
	} else {
		Sys.println("C# compilation success! 🤑");
	}

	// Run executable if successfully compiled
	if (result) {
		Sys.println("--");
		final exeEc = Sys.command("dotnet", ["run", "--nologo"]);
		Sys.println("--");

		// Run output
		if(exeEc != 0) {
			Sys.println("C# executable returned exit code: " + exeEc);
			result = false;
		} else {
			Sys.println("C# executable ran successfully! 🦶");
		}
	}

	// Reset to original current working directory
	Sys.setCwd(originalCwd);

	return result;
}

function findMainTypeFromHxml(hxmlFile: String):String {
	final hxmlData = File.getContent(hxmlFile);
	for (line in hxmlData.split("\n")) {
		line = StringTools.trim(line);
		if (StringTools.startsWith(line, "-main ")) {
			return StringTools.trim(line.substr(6));
		}
	}
	return null;
}

