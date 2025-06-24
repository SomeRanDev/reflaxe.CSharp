package;

class Base {
	public function func() {}
	public function func2() {}
}

@:keep
class Child extends Base {
	public override function func() {}
}

// ---

function main() {
	var num = 123;
	untyped __cs__("System.Console.WriteLine({0})", "Hello world! (" + num + ")");
}
