namespace haxe.root {
	class Main {
		int localVar;

		int? localNullVar;

		static int numTests;

		static int numFailures;

		static bool trueValue;

		static bool falseValue;

		static int staticVar;

		static int? staticNullVar;

		public Main() {

		}

		public void foo(int optInt, String reqString) {

		}

		public void foo(String reqString) {
			foo(4, reqString);
		}

		public bool foo2(int optInt, String reqString, bool optBool = false) {
			return false;
		}

		public bool foo2(String reqString, bool optBool = false) {
			return foo2(4, reqString, optBool);
		}

		public void foo3(int? nullableInt) {

		}

		public void foo4(int? optInt = null) {

		}

		public void foo5(int? nullableIntWithDef = 4) {

		}

		public void foo6(int? optIntWithDef = 4) {

		}

		public static void main() {
			System.Console.WriteLine("Main.main()");
			Main.trueValue = true;
			Main.falseValue = false;
		}
	}
}
