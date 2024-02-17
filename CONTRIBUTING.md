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
