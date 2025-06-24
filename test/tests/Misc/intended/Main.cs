namespace haxe.root {
  class Main {
    public int localVar;
    public int? localNullVar;
    public static int numTests;
    public static int numFailures;
    public static bool trueValue;
    public static bool falseValue;
    public static int staticVar;
    public static int? staticNullVar;
    public  Main() {

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
      {
        System.Console.WriteLine("\"Main.main()\"");
        haxe.root.Main.trueValue = true;
        haxe.root.Main.falseValue = false;
      }
    }

  }
}