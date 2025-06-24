# Contributing to Reflaxe/C#

This project requires Haxe 5.0+. At the time of writing this, Haxe 5.0 is unreleased and only available through the nightly release. You can download the latest version [here](https://build.haxe.org/builds/haxe/windows64/haxe_latest.zip).

Simply download the repo and run `haxe Test.hxml` to test it out!

## Test.hxml Arguments

To run a specific test use the `test=<folder name>` argument.
```
haxe Test.hxml test=HelloWorld
```

To update the "intended" output for the tests (or a single test using `test=`), use the `update-intended` argument.
```
haxe Test.hxml update-intended
```

## DevEnv.hxml

The `DevEnv.hxml` has multiple purposes.
* It should be the `.hxml` file selected in Visual Studio Code while developing Reflaxe/C#.
* Run `haxe DevEnv.hxml` to check for any compiler errors and null-safety errors.

## Adding a Test

Add a folder with a unique name to `test/tests`. 

Copy the `Main.hx`, `Test.hxml`, and `.gitignore` from `test/tests/HelloWorld` to get started.

Once you've completed your test, run `haxe Test.hxml test=YourTestFolderName update-intended` to generate the `intended` folder containing the desired output for your test. Run without `update-intended` to compare the outputs.

# Before Contributing

Always do the following before opening your PR request:

1) Check for null-safety issues.
```
haxe DevEnv.hxml
```

2) Run the tests!
```
haxe Test.hxml
```

3) Run the formatter!
```
haxelib run formatter -s src
```

# Style Guide

### Variable Names

Variable names should be:
* Long and descriptive!
* Please no one character variable names (outside of `for(i in ...)`)!
* If a variable is of type `Null<T>`, its name must start with "maybe"!

### Imports

There should be an empty line between `import` and `using` imports with `using`s coming second. Within each second, the imports should be in alphabetical order and additionally separated into sections ordered as followed:
* Imports from modules within this project.
* Haxe standard library imports.
* Reflaxe imports.
* Third-party library imports.
