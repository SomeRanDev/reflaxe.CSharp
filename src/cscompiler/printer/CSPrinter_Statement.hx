package cscompiler.printer;

#if(macro || cs_runtime)
import cscompiler.ast.*;

/**
	The component responsible for printing
	C# Statement AST to C# code
**/
class CSPrinter_Statement extends CSPrinter_Base {
	public function printStatement(statement: CSStatement): Void {
		switch(statement.def) {
			case CSExprStatement(expression):
				{
					printExpression(expression);
					write(";");
				}
			case CSBlock(statements):
				{
					writeln("{");
					indent();
					
					for(stmt in statements) {
						printStatement(stmt);
						newline();
					}
					
					unindent();
					write("}");
				}
			case CSIf(condition, ifContent, elseContent):
				{
					write("if (");
					printExpression(condition);
					write(")");
					writeBlockOrSingle(ifContent);
					if(elseContent != null) {
						write(" else");
						writeBlockOrSingle(elseContent);
					}
				}
			case CSWhile(condition, content, normalWhile):
				{
					write(normalWhile ? "while (" : "do ");
					if(normalWhile) {
						printExpression(condition);
						write(")");
						writeBlockOrSingle(content);
					} else {
						writeBlockOrSingle(content);
						write("while (");
						printExpression(condition);
						write(");");
					}
				}
			case CSForeach(varData, iterExpr, content):
				{
					write("foreach (");
					printVarDeclaration(varData);
					write(" in ");
					printExpression(iterExpr);
					write(")");
					writeBlockOrSingle(content);
				}
			case CSSwitch(subject, cases, edef):
				{
					write("switch (");
					printExpression(subject);
					write(")");
					writeln(" {");
					indent();
					for(c in cases) {
						write("case ");
						printExpression(c.value);
						writeln(":");
						if(c.content != null) {
							indent();
							for(stmt in c.content)
								printStatement(stmt);
							unindent();
						}
					}
					if(edef != null) {
						writeln("default:");
						indent();
						for(stmt in edef)
							printStatement(stmt);
						unindent();
					}
					unindent();
					write("}");
				}
			case CSTry(content, catches):
				{
					writeln("try {");
					indent();
					for(stmt in content)
						printStatement(stmt);
					unindent();
					writeln("}");
					for(c in catches) {
						write("catch (");
						writeType(c.type);
						write(" ");
						write(c.name);
						write(")");
						writeln(" {");
						indent();
						for(stmt in c.content)
							printStatement(stmt);
						unindent();
						write("}");
					}
				}
			case CSBreak: {
					write("break;");
				}
			case CSContinue: {
					write("continue;");
				}
			case CSReturn(maybeExpr):
				{
					write("return");
					if(maybeExpr != null) {
						write(" ");
						printExpression(maybeExpr);
					}
					write(";");
				}
			case CSThrow(expr):
				{
					write("throw ");
					printExpression(expr);
					write(";");
				}
			case CSCast(expr, type, directCasting):
				{
					if(directCasting) {
						write("(");
						writeType(type);
						write(") ");
						printExpression(expr);
					} else {
						printExpression(expr);
						write(" as ");
						writeType(type);
					}
					write(";");
				}
			case CSVar(varData, expr):
				{
					printVarDeclaration(varData);
					if(expr != null) {
						write(" = ");
						printExpression(expr);
					}
					write(";");
				}
		}
	}
	
	function writeBlockOrSingle(statements: Array<CSStatement>): Void {
		if(statements.length == 1 && !isBlock(statements[0])) {
			write(" ");
			printStatement(statements[0]);
		} else {
			write(" ");
			printStatement({def: CSBlock(statements)});
		}
	}
	
	function isBlock(stmt: CSStatement): Bool {
		return switch(stmt.def) {
			case CSBlock(_): true;
			default: false;
		};
	}
	
	inline function printExpression(expr: CSExpr): Void {
		printer.printExpression(expr);
	}
	
	inline function writeType(type: CSType): Void {
		printer.printType(type);
	}
	
	function printVarDeclaration(varData: CSVar): Void {
		switch(varData.type) {
			case KnownType(type): {
					writeType(type);
				}
			case Infer: {
					write("var");
				}
		}
		write(" ");
		write(varData.name);
	}
}
#end
