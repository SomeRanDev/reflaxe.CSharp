package cscompiler.printer;

#if(macro || cs_runtime)
import cscompiler.ast.*;

import haxe.macro.Expr;

/**
	The component responsible for printing
	C# Expression AST to C# code
**/
class CSPrinter_Expression extends CSPrinter_Base {
	public function printExpression(expression: CSExpr) {
		switch(expression.def) {
			case CSConst(constant): {
					printConstant(constant);
				}
			case CSLocalVar(varData): {
					write(varData.name); // assuming CSVar has a name
				}
			case CSArray(baseExpr, indexExpr):
				{
					printExpression(baseExpr);
					write("[");
					printExpression(indexExpr);
					write("]");
				}
			case CSBinop(op, leftExpr, rightExpr):
				{
					printExpression(leftExpr);
					write(" ");
					printBinop(op);
					write(" ");
					printExpression(rightExpr);
				}
			case CSField(e, fieldAccess): {
					printFieldAccess(e, fieldAccess);
				}
			case CSTypeExpr(type): {
					printType(type);
				}
			case CSParenthesis(e):
				{
					write("(");
					printExpression(e);
					write(")");
				}
			case CSArrayDecl(expressions):
				{
					write("{");
					for(i in 0...expressions.length) {
						if(i > 0)
							write(", ");
						printExpression(expressions[i]);
					}
					write("}");
				}
			case CSCall(baseExpr, typeParams, arguments):
				{
					printExpression(baseExpr);
					if(typeParams.length > 0) {
						write("<");
						for(i in 0...typeParams.length) {
							if(i > 0)
								write(", ");
							printType(typeParams[i]);
						}
						write(">");
					}
					write("(");
					for(i in 0...arguments.length) {
						if(i > 0)
							write(", ");
						printExpression(arguments[i]);
					}
					write(")");
				}
			case CSNew(cls, typeParams, arguments):
				{
					write("new ");
					printTypePath(cls);
					if(typeParams.length > 0) {
						write("<");
						for(i in 0...typeParams.length) {
							if(i > 0)
								write(", ");
							printType(typeParams[i]);
						}
						write(">");
					}
					write("(");
					for(i in 0...arguments.length) {
						if(i > 0)
							write(", ");
						printExpression(arguments[i]);
					}
					write(")");
				}
			case CSUnop(op, postFix, baseExpr):
				{
					if(postFix) {
						printExpression(baseExpr);
						printUnop(op, true);
					} else {
						printUnop(op, false);
						printExpression(baseExpr);
					}
				}
			case CSFunctionExpr(tfunc): {
					printFunctionExpr(tfunc);
				}
			case CSIdent(s): {
					write(s);
				}
			case CSInject(entries):
				{
					for(entry in entries) {
						switch(entry) {
							case Code(csCode): {
									write(csCode);
								}
							case Expression(expression): {
									printer.printExpression(expression);
								}
						}
					}
				}
		}
	}
	
	function printConstant(c: CSConstant): Void {
		// Just an example—fill in with real formatting logic
		switch(c) {
			case CSChar(c): write("'" + c + "'");
			case CSInt(i): write(Std.string(i));
			case CSFloat(f): write(Std.string(f));
			case CSDouble(f): write(Std.string(f));
			case CSBool(b): write(b ? "true" : "false");
			case CSString(s): write('"' + StringTools.replace(s, "\"", "\\\"") + '"');
			case CSNull: write("null");
			case CSBase: "base";
			case CSThis: "this";
		}
	}
	
	function printBinop(op: Binop): Void {
		write(switch(op) {
			case OpAdd: "+";
			case OpSub: "-";
			case OpMult: "*";
			case OpDiv: "/";
			case OpAssign: "=";
			case OpEq: "==";
			case OpNotEq: "!=";
			case OpGt: ">";
			case OpLt: "<";
			case OpGte: ">=";
			case OpLte: "<=";
			case OpBoolAnd: "&&";
			case OpBoolOr: "||";
			case OpAnd: "&";
			case OpOr: "|";
			case OpXor: "^";
			case OpShl: "<<";
			case OpShr: ">>";
			case OpUShr: ">>>";
			default: throw 'Unsupported Binop: $op';
		});
	}
	
	function printFieldAccess(e: CSExpr, f: CSFieldAccess): Void {
		switch(f) {
			case CSFInstance(c, params, cf):
				{
					printExpression(e);
					write(".");
					if(params.length > 0) {
						write("<");
						for(i in 0...params.length) {
							if(i > 0)
								write(", ");
							printType(params[i]);
						}
						write(">");
					}
					write(".");
					write(cf);
				}
			case CSFStatic(c, params, cf):
				{
					printTypePath(c);
					if(params.length > 0) {
						write("<");
						for(i in 0...params.length) {
							if(i > 0)
								write(", ");
							printType(params[i]);
						}
						write(">");
					}
					write(".");
					write(cf);
				}
		}
	}
	
	inline function printType(type: CSType): Void {
		printer.printType(type);
	}
	
	inline function printTypePath(typePath: CSTypePath): Void {
		printer.printTypePath(typePath);
	}
	
	function printUnop(op: Unop, post: Bool): Void {
		switch(op) {
			case OpIncrement: write("++");
			case OpDecrement: write("--");
			case OpNot: write("!");
			case OpNeg: write("-");
			default: throw 'Unsupported Unop: $op';
		}
	}
	
	function printFunctionExpr(f: CSFunction): Void {
		write("(");
		for(i in 0...f.args.length) {
			if(i > 0)
				write(", ");
			printArg(f.args[i]);
		}
		write(")");
		
		switch(f.returnKind) {
			case Constructor: {
					throw "Function expression cannot be a constructor.";
				}
			case ReturnVoid: {
					write(": void");
				}
			case ReturnType(returnType):
				{
					write(": ");
					printType(returnType);
				}
			case InferReturnType: {}
		}
		
		if(f.statement != null) {
			write(" ");
			printer.printStatement(f.statement);
		} else {
			write(" => default");
		}
	}
	
	function printArg(arg: CSArg): Void {
		printType(arg.type);
		if(arg.name != null) {
			write(" ");
			write(arg.name);
			if(arg.value != null) {
				write(" = ");
				printExpression(arg.value);
			}
		}
	}
}
#end
