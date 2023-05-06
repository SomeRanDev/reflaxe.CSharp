import haxe.PosInfos;
// import cil.DynamicObject;
// import cs.system.Console;
import haxe.ds.Vector;
import haxe.ds.StringMap;

@:analyzer(ignore)
class Main {
	static function main() {
		untyped __cs__("System.Console.WriteLine({0})", "Main.main()");

		trueValue = true;
		falseValue = false;
		// testAssignment();
		// testNullAssignment();
		// testUnops();
		// testNullUnops();
		// testOps();
		// testNullshit();
		// testNullOps();
		// testNadakoOps();
		// testNativeArray();
		// testStringMap();
		// testDynamicObject();
		// Sys.println('Done $numTests tests with $numFailures failures');
	}

	static var numTests:Int;
	static var numFailures:Int;

	@:generic static function eq<T>(expected:T, actual:T, ?p:PosInfos) {
		numTests++;
		if (expected != actual) {
			numFailures++;
			//Console.WriteLine('${p.lineNumber}: Failed!');
		}
	}

	function foo(optInt:Int = 4, reqString:String) {

	}

	function foo2(optInt:Int = 4, reqString:String, optBool:Bool = false) {
		return false;
	}

	function foo3(nullableInt:Null<Int>) {

	}

	function foo4(?optInt:Int) {

	}

	function foo5(nullableIntWithDef:Null<Int> = 4) {

	}

	function foo6(?optIntWithDef:Int = 4) {

	}

	// @:generic static function neq<T>(expected:T, actual:T, ?p:PosInfos) {
	// 	numTests++;
	// 	if (expected == actual) {
	// 		numFailures++;
	// 		//Console.WriteLine('${p.lineNumber}: Failed!');
	// 	}
	// }

	// static function t(v:Bool) {
	// 	eq(true, v);
	// }

	// static function f(v:Bool) {
	// 	eq(false, v);
	// }

	// // tests

	static var trueValue:Bool;
	static var falseValue:Bool;
	static var staticVar:Int;
	static var staticNullVar:Null<Int>;

	// static function testAssignment() {
	// 	var a = 1;
	// 	eq(1, a);
	// 	a = 2;
	// 	eq(2, a);

	// 	staticVar = 1;
	// 	eq(1, staticVar);

	// 	var m = new Main();
	// 	m.localVar = 1;
	// 	eq(1, m.localVar);

	// 	m.localVar += m.localVar += 1;
	// 	eq(3, m.localVar);

	// 	m.localVar = m.localVar += 1;
	// 	eq(4, m.localVar);
	// }

	// static function testNullAssignment() {
	// 	var a:Null<Int> = 1;
	// 	eq(1, a);
	// 	a = 2;
	// 	eq(2, a);

	// 	staticNullVar = 1;
	// 	eq(1, staticNullVar);

	// 	var m = new Main();
	// 	m.localNullVar = 1;
	// 	eq(1, m.localNullVar);

	// 	m.localNullVar += m.localNullVar += 1;
	// 	eq(3, m.localNullVar);

	// 	m.localNullVar = m.localNullVar += 1;
	// 	eq(4, m.localNullVar);
	// }

	// static function testUnops() {
	// 	var a = 0;
	// 	eq(0, a++);
	// 	eq(1, a);
	// 	eq(2, ++a);
	// 	eq(2, a);

	// 	var a = 0;
	// 	eq(0, a--);
	// 	eq(-1, a);
	// 	eq(-2, --a);
	// 	eq(-2, a);

	// 	staticVar = 0;
	// 	eq(0, staticVar++);
	// 	eq(1, staticVar);
	// 	eq(2, ++staticVar);
	// 	eq(2, staticVar);

	// 	staticVar = 0;
	// 	eq(0, staticVar--);
	// 	eq(-1, staticVar);
	// 	eq(-2, --staticVar);
	// 	eq(-2, staticVar);

	// 	var m = new Main();
	// 	m.localVar = 0;
	// 	eq(0, m.localVar++);
	// 	eq(1, m.localVar);
	// 	eq(2, ++m.localVar);
	// 	eq(2, m.localVar);

	// 	m.localVar = 0;
	// 	eq(0, m.localVar--);
	// 	eq(-1, m.localVar);
	// 	eq(-2, --m.localVar);
	// 	eq(-2, m.localVar);
	// }

	// static function testNullUnops() {
	// 	var a:Null<Int> = 0;
	// 	eq(0, a++);
	// 	eq(1, a);
	// 	eq(2, ++a);
	// 	eq(2, a);

	// 	var a:Null<Int> = 0;
	// 	eq(0, a--);
	// 	eq(-1, a);
	// 	eq(-2, --a);
	// 	eq(-2, a);

	// 	staticNullVar = 0;
	// 	eq(0, staticNullVar++);
	// 	eq(1, staticNullVar);
	// 	eq(2, ++staticNullVar);
	// 	eq(2, staticNullVar);

	// 	staticNullVar = 0;
	// 	eq(0, staticNullVar--);
	// 	eq(-1, staticNullVar);
	// 	eq(-2, --staticNullVar);
	// 	eq(-2, staticNullVar);

	// 	var m = new Main();
	// 	m.localNullVar = 0;
	// 	eq(0, m.localNullVar++);
	// 	eq(1, m.localNullVar);
	// 	eq(2, ++m.localNullVar);
	// 	eq(2, m.localNullVar);

	// 	m.localNullVar = 0;
	// 	eq(0, m.localNullVar--);
	// 	eq(-1, m.localNullVar);
	// 	eq(-2, --m.localNullVar);
	// 	eq(-2, m.localNullVar);
	// }

	// static function testOps() {
	// 	var a = 10;
	// 	// arithmetic
	// 	eq(9, a - 1);
	// 	eq(20, a * 2);
	// 	// eq(5., a / 2); // careful with Float comparison...
	// 	eq(1, a % 3);

	// 	// bit
	// 	eq(20, a << 1);
	// 	eq(5, a >> 1);
	// 	eq(5, a >>> 1);
	// 	eq(10, a & 15);
	// 	eq(15, a | 15);
	// 	eq(2, a ^ 8);

	// 	// unary
	// 	eq(-10, -a);
	// 	eq(-11, ~a);

	// 	// boolean
	// 	var b = true;
	// 	eq(false, !b);
	// 	eq(false, b && falseValue);
	// 	eq(true, b && trueValue);
	// 	eq(true, b || falseValue);
	// 	eq(true, b || trueValue);

	// 	b = false;
	// 	eq(true, !b);
	// 	eq(false, b && falseValue);
	// 	eq(false, b && trueValue);
	// 	eq(false, b || falseValue);
	// 	eq(true, b || trueValue);

	// 	eq(true, a > 5);
	// 	eq(true, a >= 5);
	// 	eq(false, a < 5);
	// 	eq(false, a <= 5);
	// 	eq(true, a != 5);
	// 	eq(false, a != 10);

	// 	eq(false, 0 > a);
	// 	eq(false, 0 >= a);
	// 	eq(true, 0 < a);
	// 	eq(true, 0 <= a);
	// 	eq(true, 0 != a);
	// 	eq(false, 0 == a);

	// 	var minusA = -10;
	// 	eq(true, 0 > minusA);
	// 	eq(true, 0 >= minusA);
	// 	eq(false, 0 < minusA);
	// 	eq(false, 0 <= minusA);
	// 	eq(true, 0 != minusA);
	// 	eq(false, 0 == minusA);
	// }

	// static function getNullNull():Null<Int> {
	// 	return null;
	// }

	// static function getNull0():Null<Int> {
	// 	return 0;
	// }

	// static function getNull1():Null<Int> {
	// 	return 1;
	// }

	// static function testNullshit() {
	// 	var nullInt:Null<Int> = null;
	// 	var nullInt2:Null<Int> = null;
	// 	eq(0, nullInt);
	// 	neq(nullInt, 0);
	// 	neq(true, nullInt == 0);
	// 	eq(false, 0 == nullInt);
	// 	eq(true, nullInt != 0);
	// 	eq(true, 0 != nullInt);
	// 	var realInt:Int = 0;
	// 	realInt = nullInt;
	// 	eq(0, realInt);
	// 	eq(realInt, 0);
	// 	nullInt = nullInt2;
	// 	eq(null, nullInt);
	// 	eq(nullInt, null);

	// 	eq(null, getNullNull());
	// 	eq(getNullNull(), null);
	// 	eq(true, getNullNull() == null);
	// 	eq(true, null == getNullNull());
	// 	eq(false, getNull0() == null);
	// 	eq(false, null == getNull0());
	// 	eq(false, getNull1() == null);
	// 	eq(false, null == getNull1());

	// 	eq(true, getNullNull() == getNullNull());
	// 	eq(false, getNullNull() == getNull0());
	// 	eq(false, getNull0() == getNullNull());
	// 	eq(false, getNull0() == getNull1());
	// 	eq(false, getNull1() == getNull0());
	// 	eq(1, getNull1());
	// 	eq(getNull1(), 1);

	// 	var nullFloat:Null<Float> = null;
	// 	var realFloat = 0.;
	// 	realFloat = nullFloat;
	// 	eq(0., realFloat);
	// 	realFloat = nullInt;
	// 	eq(0., realFloat);
	// }

	// static function testNullOps() {
	// 	var a:Null<Int> = 10;
	// 	// arithmetic
	// 	eq(9, a - 1);
	// 	eq(20, a * 2);
	// 	eq(5., a / 2);
	// 	eq(1, a % 3);

	// 	// bit
	// 	eq(20, a << 1);
	// 	eq(5, a >> 1);
	// 	eq(5, a >>> 1);
	// 	eq(10, a & 15);
	// 	eq(15, a | 15);
	// 	eq(2, a ^ 8);

	// 	// unary
	// 	eq(-10, -a);
	// 	eq(-11, ~a);

	// 	// boolean
	// 	var b:Null<Bool> = true;
	// 	eq(false, !b);
	// 	eq(false, b && falseValue);
	// 	eq(true, b && trueValue);
	// 	eq(true, b || falseValue);
	// 	eq(true, b || trueValue);

	// 	b = false;
	// 	eq(true, !b);
	// 	eq(false, b && falseValue);
	// 	eq(false, b && trueValue);
	// 	eq(false, b || falseValue);
	// 	eq(true, b || trueValue);

	// 	eq(true, a > 5);
	// 	eq(true, a >= 5);
	// 	eq(false, a < 5);
	// 	eq(false, a <= 5);
	// 	eq(true, a != 5);
	// 	eq(false, a != 10);

	// 	eq(false, 0 > a);
	// 	eq(false, 0 >= a);
	// 	eq(true, 0 < a);
	// 	eq(true, 0 <= a);
	// 	eq(true, 0 != a);
	// 	eq(false, 0 == a);

	// 	var minusA:Null<Int> = -10;
	// 	eq(true, 0 > minusA);
	// 	eq(true, 0 >= minusA);
	// 	eq(false, 0 < minusA);
	// 	eq(false, 0 <= minusA);
	// 	eq(true, 0 != minusA);
	// 	eq(false, 0 == minusA);
	// }

	// static function testNadakoOps() {
	// 	// bool
	// 	var nullBool:Null<Bool> = null;

	// 	t(null == nullBool);
	// 	t(nullBool == null);
	// 	f(false == nullBool);
	// 	f(nullBool == false);
	// 	t(false != nullBool);
	// 	t(nullBool != false);

	// 	// int
	// 	var nullInt:Null<Int> = null;

	// 	t(null == nullInt);
	// 	t(nullInt == null);
	// 	f(0 == nullInt);
	// 	f(nullInt == 0);
	// 	t(0 != nullInt);
	// 	t(nullInt != 0);

	// 	f(0 > nullInt);
	// 	f(0 >= nullInt);
	// 	f(0 < nullInt);
	// 	f(0 <= nullInt);

	// 	f(nullInt > 0);
	// 	f(nullInt >= 0);
	// 	f(nullInt < 0);
	// 	f(nullInt <= 0);

	// 	f(1 > nullInt);
	// 	f(1 >= nullInt);
	// 	f(1 < nullInt);
	// 	f(1 <= nullInt);

	// 	f(nullInt > 1);
	// 	f(nullInt >= 1);
	// 	f(nullInt < 1);
	// 	f(nullInt <= 1);

	// 	f(-1 > nullInt);
	// 	f(-1 >= nullInt);
	// 	f(-1 < nullInt);
	// 	f(-1 <= nullInt);

	// 	f(nullInt > -1);
	// 	f(nullInt >= -1);
	// 	f(nullInt < -1);
	// 	f(nullInt <= -1);

	// 	// // float
	// 	var nullFloat:Null<Float> = null;

	// 	t(null == nullFloat);
	// 	t(nullFloat == null);
	// 	f(0. == nullFloat);
	// 	f(nullFloat == 0.);
	// 	t(0. != nullFloat);
	// 	t(nullFloat != 0.);

	// 	f(0. > nullFloat);
	// 	f(0. >= nullFloat);
	// 	f(0. < nullFloat);
	// 	f(0. <= nullFloat);

	// 	f(nullFloat > 0.);
	// 	f(nullFloat >= 0.);
	// 	f(nullFloat < 0.);
	// 	f(nullFloat <= 0.);

	// 	f(1. > nullFloat);
	// 	f(1. >= nullFloat);
	// 	f(1. < nullFloat);
	// 	f(1. <= nullFloat);

	// 	f(nullFloat > 1.);
	// 	f(nullFloat >= 1.);
	// 	f(nullFloat < 1.);
	// 	f(nullFloat <= 1.);

	// 	f(-1. > nullFloat);
	// 	f(-1. >= nullFloat);
	// 	f(-1. < nullFloat);
	// 	f(-1. <= nullFloat);

	// 	f(nullFloat > -1.);
	// 	f(nullFloat >= -1.);
	// 	f(nullFloat < -1.);
	// 	f(nullFloat <= -1.);
	// }

	// static function testNativeArray() {
	// 	var a = new Vector(1);
	// 	a[0] = new Vector(1);
	// 	eq(0, a[0][0]);
	// 	eq(12, a[0][0] = 12);
	// 	eq(12, a[0][0]);
	// 	eq(12, a[0][0]++);
	// 	eq(13, a[0][0]);
	// 	eq(14, ++a[0][0]);
	// 	eq(28, a[0][0] += a[0][0]);

	// 	var a = new Vector<Vector<Null<Int>>>(1);
	// 	a[0] = new Vector<Null<Int>>(1);
	// 	eq(null, a[0][0]);
	// 	eq(12, a[0][0] = 12);
	// 	eq(12, a[0][0]);
	// 	eq(12, a[0][0]++);
	// 	eq(13, a[0][0]);
	// 	eq(14, ++a[0][0]);
	// 	eq(28, a[0][0] += a[0][0]);

	// 	var a = new cs.NativeArray(1);
	// 	a[0] = new cs.NativeArray(1);
	// 	eq(0, a[0][0]);
	// 	eq(12, a[0][0] = 12);
	// 	eq(12, a[0][0]);
	// 	eq(12, a[0][0]++);
	// 	eq(13, a[0][0]);
	// 	eq(14, ++a[0][0]);
	// 	eq(28, a[0][0] += a[0][0]);

	// 	var a = new cs.NativeArray<cs.NativeArray<Null<Int>>>(1);
	// 	a[0] = new cs.NativeArray<Null<Int>>(1);
	// 	eq(null, a[0][0]);
	// 	eq(12, a[0][0] = 12);
	// 	eq(12, a[0][0]);
	// 	eq(12, a[0][0]++);
	// 	eq(13, a[0][0]);
	// 	eq(14, ++a[0][0]);
	// 	eq(28, a[0][0] += a[0][0]);
	// }

	// static function testStringMap() {
	// 	var sm = new StringMap<Int>();
	// 	// eq(null, sm.get("foo"));
	// 	eq(false, sm.exists("foo"));
	// 	sm.set("foo", 12);
	// 	eq(true, sm.exists("foo"));
	// 	eq(12, sm.get("foo"));
	// 	sm.remove("foo");
	// 	// eq(null, sm.get("foo"));

	// 	// var sm = new StringMap();
	// 	// sm.set("foo", 12);
	// 	// sm.set("bar", 13);
	// 	// var keys = [];
	// 	// var values = [];
	// 	// for (key => value in sm) {
	// 	// 	keys.push(key);
	// 	// 	values.push(value);
	// 	// }
	// 	// keys.sort(Reflect.compare);
	// 	// values.sort(Reflect.compare);
	// 	// eq(2, keys.length);
	// 	// eq(2, values.length);
	// 	// eq("bar", keys[0]);
	// 	// eq("foo", keys[1]);
	// 	// eq(12, values[0]);
	// 	// eq(13, values[1]);
	// }

	// static function testDynamicObject() {
	// 	var td = new cil.DynamicObject();

	// 	var value = "value";

	// 	eq(false, td._hx_hasField("unknownField"));
	// 	eq(false, td._hx_deleteField("unknownField"));
	// 	td._hx_setField("unknownField", value);
	// 	eq(value, td._hx_getField("unknownField"));
	// 	eq(true, td._hx_hasField("unknownField"));
	// 	eq(true, td._hx_deleteField("unknownField"));
	// 	eq(false, td._hx_deleteField("unknownField"));
	// 	eq(false, td._hx_hasField("unknownField"));
	// 	eq(null, td._hx_getField("unknownField"));

	// 	var td = new cil.DynamicObject();
	// 	var value = 12;

	// 	eq(false, td._hx_hasField("unknownField"));
	// 	eq(false, td._hx_deleteField("unknownField"));
	// 	td._hx_setField("unknownField", value);
	// 	eq(value, td._hx_getField("unknownField"));
	// 	eq(true, td._hx_hasField("unknownField"));
	// 	eq(true, td._hx_deleteField("unknownField"));
	// 	eq(false, td._hx_deleteField("unknownField"));
	// 	eq(false, td._hx_hasField("unknownField"));
	// 	eq(null, td._hx_getField("unknownField"));
	// }

	var localVar:Int;
	var localNullVar:Null<Int>;

	function new() {

	}
}