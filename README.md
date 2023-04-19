# Reflaxe/C# (Haxe -> C# Compiler)
A remake of the Haxe/C# target written entirely within Haxe using Reflaxe.

* This project is currently in development.
* Requires Haxe v5 or later (nightly).

&nbsp;

# Nightly Installation

If this project isn't on haxelib yet, or you'd like to use the development version, use `haxelib git` on the nightly branch.
```sh
haxelib git csharp https://github.com/RobertBorghese/reflaxe.CSharp nightly
```

Here's a simple `.hxml` template to get you started!
```hxml
-cp src
-main Main

-lib csharp
--custom-target csharp=out
```
