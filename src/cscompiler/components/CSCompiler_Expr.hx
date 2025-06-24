package cscompiler.components;

#if(macro || cs_runtime)
import cscompiler.ast.*;
import cscompiler.ast.CSExprDef.CSInjectEntry;
import cscompiler.ast.CSStatement;
import cscompiler.ast.CSVar.CSVarType;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

import reflaxe.compiler.TargetCodeInjection;
import reflaxe.helpers.OperatorHelper;

using reflaxe.helpers.ModuleTypeHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.NullHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using reflaxe.helpers.TypeHelper;

/**
	The component responsible for compiling Haxe
	typed expressions into C#.
**/
class CSCompiler_Expr extends CSCompiler_Base {
	/**
		Calls `compiler.compileExpressionOrError`.
	**/
	public function compileToCSStatement(e: TypedExpr): CSStatement {
		return compiler.compileExpressionOrError(e);
	}
	
	/**
		Calls `compiler.compileExpressionOrError`.
	**/
	public function compileToCSStatementArray(e: TypedExpr): Array<CSStatement> {
		final baseStatement = compileToCSStatement(e);
		return switch baseStatement.def {
			case CSBlock(statements):
				statements;
			case _:
				[baseStatement];
		}
	}
	
	/**
		Calls `compileToCSStatement` then converts that to CSExpr (if applicable)
	**/
	public function compileToCSExpr(e: TypedExpr): CSExpr {
		return csStatementToExpr(compileToCSStatement(e));
	}
	
	/**
		Implementation of `CSCompiler.csStatementToExpr`.
	**/
	public function csStatementToExpr(statement: CSStatement): CSExpr {
		return switch statement.def {
			case CSExprStatement(expression):
				expression;
				
			case CSBlock(statements):
				throw "Not implemented";
				
			case CSIf(condition, ifContent, elseContent):
				throw "Not implemented";
				
			case CSWhile(condition, content, normalWhile):
				throw "Not implemented";
				
			case CSForeach(varData, iterExpr, content):
				throw "Not implemented";
				
			case CSSwitch(subject, cases, edef):
				throw "Not implemented";
				
			case CSCast(expr, type, directCasting):
				throw "Not implemented";
				
			case CSBreak:
				throw "Not implemented";
				
			case CSContinue:
				throw "Not implemented";
				
			case CSReturn(maybeExpr):
				throw "Not implemented";
				
			case CSThrow(expr):
				throw "Not implemented";
				
			case CSTry(content, catches):
				throw "Not implemented";
				
			case CSVar(varData, expr):
				throw "Not implemented";
		}
	}
	
	/**
		Implementation of `CSCompiler.compileExpressionImpl`.
	**/
	public function compile(expr: TypedExpr, topLevel: Bool): Null<CSStatement> {
		final csType: Null<CSType> = expr.t != null ? compiler.compileType(expr.t, expr.pos) : null;
		
		return switch(expr.expr) {
			case TConst(constant): {
					haxeExpr: expr,
					def: CSExprStatement({
						haxeExpr: expr,
						type: csType,
						def: CSConst(compileConstant(constant))
					})
				}
			case TLocal(v): {
					haxeExpr: expr,
					def: CSExprStatement({
						haxeExpr: expr,
						type: csType,
						def: CSIdent(compiler.compileVarName(v.name, expr))
					})
				}
			case TIdent(s): {
					haxeExpr: expr,
					def: CSExprStatement({
						haxeExpr: expr,
						type: csType,
						def: CSIdent(compiler.compileVarName(s, expr))
					})
				}
			case TArray(e1, e2): {
					haxeExpr: expr,
					def: CSExprStatement({
						haxeExpr: expr,
						type: csType,
						def: CSArray(compileToCSExpr(e1), compileToCSExpr(e2))
					})
				}
			case TBinop(op, e1, e2): {
					haxeExpr: expr,
					def: CSExprStatement({
						haxeExpr: expr,
						type: csType,
						def: CSBinop(op, compileToCSExpr(e1), compileToCSExpr(e2))
					})
				}
			case TField(e, fa): {
					switch(fa) {
						case FInstance(classTypeRef, _, _) | FStatic(classTypeRef, _): {
								compiler.addModuleTypeForCompilation(TClassDecl(classTypeRef));
							}
						case FEnum(enumRef, _): {
								compiler.addModuleTypeForCompilation(TEnumDecl(enumRef));
							}
						case _:
					}
					{
						haxeExpr: expr,
						def: CSExprStatement({
							haxeExpr: expr,
							type: csType,
							def: switch(fa) {
								case FInstance(c, params, cf): {
										CSField(
											compileToCSExpr(e),
											CSFInstance(
												compiler.typeComp.compileClassTypePath(c.get()),
												compiler.typeComp.compileTypeParams(params),
												cf.get().name
											)
										);
									}
								case FStatic(c, cf): {
										CSField(
											compileToCSExpr(e),
											CSFStatic(
												compiler.typeComp.compileClassTypePath(
													c.get()
												), // C# type inference should be able to infer generic types
												// from arguments, but it also allows the types to be explicit.
												// We might need that in some situation where inference is not enough?
												[],
												cf.get().name
											)
										);
									}
								case FAnon(cf): {
										// We rely on dynamic access to read anon fields, because for now,
										// they will be backed with `haxe.lang.DynamicObject` anyway
										compileDynamicGetField(expr, cf.get().name);
									}
								case FDynamic(s): {
										compileDynamicGetField(expr, s);
									}
								case FClosure(maybeClassData, cf): {
										// TODO: do we need to generate different code than FInstance?
										final fieldAccess: CSFieldAccess = if(maybeClassData != null) {
											CSFInstance(
												compiler.typeComp.compileClassTypePath(
													maybeClassData.c.get()
												),
												compiler.typeComp.compileTypeParams(
													maybeClassData.params
												),
												cf.get().name
											);
										} else {
											CSFInstance(
												'object', // TODO: Should it be 'object' if we don't have any class type there?
												[],
												cf.get().name
											);
										};
										CSField(compileToCSExpr(e), fieldAccess);
									}
								case FEnum(en, ef): {
										CSField(
											compileToCSExpr(e),
											CSFInstance(
												compiler.typeComp.compileEnumTypePath(en.get()),
												[],
												ef.name
											)
										);
									}
							}
						})
					}
				}
				
			case TTypeExpr(moduleType): {
					compiler.addModuleTypeForCompilation(moduleType);
					
					// Note:
					//     we don't have access to type params here,
					//     so they are always empty.
					// TODO: or can we resolve them from the expression type?
					final haxeType = TypeHelper.fromModuleType(moduleType);
					{
						haxeExpr: expr,
						def: CSExprStatement({
							haxeExpr: expr,
							type: csType,
							def: CSTypeExpr(compiler.compileTypeOrError(haxeType, expr.pos))
						})
					}
				}
			case TParenthesis(e): {
					haxeExpr: expr,
					def: CSExprStatement({
						haxeExpr: expr,
						type: csType,
						def: CSParenthesis(compileToCSExpr(e))
					})
				}
			// We are generating the same as original C# target here
			case TObjectDecl(fields): {
					haxeExpr: expr,
					def: CSExprStatement({
						haxeExpr: expr,
						type: csType,
						def: CSNew("haxe.lang.DynamicObject", [], compileObjectDeclArgs(fields))
					})
				}
			// We are generating the same as original C# target here too:
			// a dedicated Array type specific to Haxe so that it can
			// work the same as haxe arrays in general
			case TArrayDecl(el): {
					final arrayParams = switch csType {
						case CSInst(_, p):
							p;
						case _:
							[];
					};
					{
						haxeExpr: expr,
						def: CSExprStatement({
							haxeExpr: expr,
							type: csType,
							def: CSNew(
								"Array",
								arrayParams,
								compileArrayDeclArgs(
									el,
									arrayParams.length > 0 ? arrayParams[0] : null
								)
							)
						})
					}
				}
			case TCall(e, el): {
					if(compiler.options.targetCodeInjectionName != null) {
						final result = TargetCodeInjection.checkTargetCodeInjectionGeneric(
							compiler.options.targetCodeInjectionName,
							expr,
							compiler
						);
						if(result != null) {
							final entries: Array<CSInjectEntry> = [];
							for(entry in result) {
								switch(entry) {
									case Left(code): {
											entries.push(Code(code));
										}
									case Right({def: CSExprStatement(expression)}): {
											entries.push(Expression(expression));
										}
									case Right(_): {
											// TODO: Convert to Context.error
											throw "Cannot use statement within inject expression.";
										}
								}
							}
							return {
								haxeExpr: expr,
								def: CSExprStatement({
									haxeExpr: expr,
									type: csType,
									def: CSInject(entries)
								})
							};
						}
					}
					
					{
						// TODO: do we need to generate something different if using @:nativeFunctionCode here? (reflaxe feature)
						haxeExpr: expr,
						def: CSExprStatement({
							haxeExpr: expr,
							type: csType,
							def: CSCall(
								compileToCSExpr(
									e
								), // TODO: do we need to explicitly add type params on generic C# method calls?
								
								[],
								el.map(e -> compileToCSExpr(e))
							)
						})
					}
				}
			case TNew(classTypeRef, params, el): {
					compiler.addModuleTypeForCompilation(TClassDecl(classTypeRef));
					
					// TODO: do we need to generate something different if using @:nativeFunctionCode here? (reflaxe feature)
					{
						haxeExpr: expr,
						def: CSExprStatement({
							haxeExpr: expr,
							type: csType,
							def: CSNew(
								compiler.typeComp.compileClassTypePath(classTypeRef.get()),
								params.map(p -> compiler.compileTypeOrError(p, expr.pos)),
								el.map(e -> compileToCSExpr(e))
							)
						})
					}
				}
			case TUnop(op, postFix, e): {
					haxeExpr: expr,
					def: CSExprStatement({
						haxeExpr: expr,
						type: csType,
						def: CSUnop(op, postFix, compileToCSExpr(e))
					})
				}
			case TFunction(tfunc): {
					final returnType = compiler.compileType(tfunc.t, expr.pos);
					{
						haxeExpr: expr,
						def: CSExprStatement({
							haxeExpr: expr,
							type: csType,
							def: CSFunctionExpr({
								args: compileFuncArgs(tfunc.args, expr.pos),
								returnKind: returnType != null ? ReturnType(
									returnType
								) : InferReturnType,
								statement: compileToCSStatement(tfunc.expr)
							})
						})
					}
				}
			case TVar(tvar, maybeExpr): {
					final tvarCsType = compiler.compileType(tvar.t, expr.pos);
					{
						haxeExpr: expr,
						def: CSVar({
							name: compiler.compileVarName(tvar.name),
							type: tvarCsType != null ? KnownType(tvarCsType) : Infer,
						}, maybeExpr != null ? compileToCSExpr(maybeExpr) : null)
					}
				}
			case TBlock(expressionList): {
					haxeExpr: expr,
					def: CSBlock(expressionList.map(e -> compileToCSStatement(e)))
				}
			case TFor(tvar, iterExpr, blockExpr): {
					final tvarType = compiler.compileType(tvar.t, expr.pos);
					{
						haxeExpr: expr,
						def: CSForeach({
							name: compiler.compileVarName(tvar.name),
							type: tvarType != null ? KnownType(tvarType) : Infer,
						}, compileToCSExpr(iterExpr), compileToCSStatementArray(blockExpr))
					}
				}
			case TIf(condExpr, ifContentExpr, elseExpr): {
					haxeExpr: expr,
					def: CSIf(
						compileToCSExpr(condExpr),
						compileToCSStatementArray(
							ifContentExpr
						), // We can handle `else if` case at print stage
						
						elseExpr != null ? compileToCSStatementArray(elseExpr) : null
					)
				}
			case TWhile(condExpr, blockExpr, normalWhile): {
					haxeExpr: expr,
					def: CSWhile(
						compileToCSExpr(condExpr),
						compileToCSStatementArray(blockExpr),
						normalWhile
					)
				}
			case TSwitch(switchedExpr, cases, edef): {
					haxeExpr: expr,
					def: CSSwitch(
						compileToCSExpr(switchedExpr),
						compileSwitchCases(cases),
						edef != null ? compileToCSStatementArray(edef) : null
					)
				}
			case TTry(e, catches): {
					haxeExpr: expr,
					def: CSTry(compileToCSStatementArray(e), compileTryCatches(catches))
				}
			case TReturn(maybeExpr): {
					haxeExpr: expr,
					def: CSReturn(maybeExpr != null ? compileToCSExpr(maybeExpr) : null)
				}
			case TBreak: {
					haxeExpr: expr,
					def: CSBreak
				}
			case TContinue: {
					haxeExpr: expr,
					def: CSContinue
				}
			case TThrow(subExpr): {
					haxeExpr: expr,
					def: CSThrow(compileToCSExpr(subExpr))
				}
			case TCast(subExpr, maybeModuleType): {
					if(maybeModuleType == null) {
						compileToCSStatement(subExpr);
					} else {
						compiler.addModuleTypeForCompilation(maybeModuleType);
						
						final haxeType = {
							#if macro
							// This function does not exist outside of "macro" target.
							TypeTools.fromModuleType(maybeModuleType);
							#else
							throw "Impossible";
							#end
						}
						{
							haxeExpr: expr,
							def: CSCast(
								compileToCSExpr(subExpr),
								compiler.compileTypeOrError(haxeType, expr.pos),
								compiler.typeComp.isValueType(haxeType)
							)
						}
					}
				}
			case TMeta(metadataEntry, subExpr): {
					// TODO: Handle expression meta?
					// Only works if `-D retain-untyped-meta` is enabled.
					compileToCSStatement(subExpr);
				}
			case TEnumParameter(subExpr, enumField, index): {
					// TODO
					// Given an expression that is an instance of an enum,
					// generate the C# code to extract a value from this enum.
					null;
				}
			case TEnumIndex(subExpr): {
					// TODO
					// Given an expression that is an instance of an enum,
					// generate the C# code to extract its index.
					null;
				}
		}
	}
	
	/**
		Generate a block scope from an expression.

		If the typed expression is `TypedExprDef.TBlock`, then each
		sub-expression is compiled on a new line.

		Otherwise, the expression is compiled normally.

		Each line of the output is preemptively tabbed.
	**/
	function toIndentedScope(e: TypedExpr): String {
		return "";
		/*
			var el = switch(e.expr) {
				case TBlock(el): el;
				case _: [e];
			}

			return if(el.length == 0) {
				"";
			} else {
				compiler.compileExpressionsIntoLines(el).tab();
			}
		 */
	}
	
	/**
		Generate an expression given a `TConstant` (from `TypedExprDef.TConst`).
	**/
	function compileConstant(constant: TConstant): CSConstant {
		return switch(constant) {
			case TInt(i): CSInt(i);
			case TFloat(s): CSDouble(s); // Haxe Float is actually a C# double
			case TString(s): CSString(compileString(s));
			case TBool(b): CSBool(b);
			case TNull: CSNull;
			case TThis: CSThis;
			case TSuper: CSBase;
		}
	}
	
	/**
		Generate the String literal for C# given its contents.
	**/
	function compileString(stringContent: String): String {
		return "\""
			+ StringTools.replace(StringTools.replace(stringContent, "\\", "\\\\"), "\"", "\\\"")
			+ "\"";
	}
	
	/**
		Generate a dynamic "getField" access
	**/
	function compileDynamicGetField(expr: TypedExpr, name: String): CSExprDef {
		return CSCall({
			haxeExpr: expr,
			def: CSField({
				haxeExpr: expr,
				def: CSTypeExpr(CSInst("haxe.lang.Runtime", []))
			}, CSFStatic("haxe.lang.Runtime", [], "getField"))
		}, [], [
			{
				haxeExpr: expr,
				def: CSConst(CSString(name))
			}
			// TODO
			//   add an integer argument used to retrieve fields names
			//   that are known at compile time in a faster way
		]);
	}
	
	/**
		Generate arguments given to `new haxe.lang.DynamicObject()`.
		Instead of transpiling to string keys, we encode as int hashes.
	**/
	function compileObjectDeclArgs(fields: Array<{
		name: String,
		expr: TypedExpr
	}>): Array<CSExpr> {
		var hashExprs: Array<CSExpr> = [];
		var valueExprs: Array<CSExpr> = [];
		
		for(field in fields) {
			final hash = compiler.nameToHash(field.name);
			
			hashExprs.push({
				type: CSInst('int', []),
				def: CSConst(CSInt(hash))
			});
			
			valueExprs.push(compileToCSExpr(field.expr));
		}
		
		return [
			{
				type: CSArray('int', []),
				def: CSArrayDecl(hashExprs)
			},
			{
				type: CSArray('object', []),
				def: CSArrayDecl(valueExprs)
			}
		];
	}
	
	/**
		Generate arguments given to `new Array<T>()`.
	**/
	function compileArrayDeclArgs(elements: Array<TypedExpr>,
			?csElementType: Null<CSType>): Array<CSExpr> {
		final arrayType: CSType = switch csElementType {
			// TODO: we might want to use `object[]` in some cases
			// even if we know the more specialized type?
			case CSInst(typePath, params): CSArray(typePath, params);
			
			case _: CSArray('object', []);
		}
		
		var elementExprs: Array<CSExpr> = [];
		for(element in elements) {
			elementExprs.push(compileToCSExpr(element));
		}
		
		return [
			{
				type: arrayType,
				def: CSArrayDecl(elementExprs)
			}
		];
	}
	
	/**
		Generate an expression given a `Unop` and typed expression (from `TypedExprDef.TUnop`).
	**/
	function unopToCS(op: Unop, e: TypedExpr, isPostfix: Bool): String {
		final csExpr = compileToCSStatement(e);
		final operatorStr = OperatorHelper.unopToString(op);
		return isPostfix ? (csExpr + operatorStr) : (operatorStr + csExpr);
	}
	
	/**
		Generate an expression given a `FieldAccess` and typed expression (from `TypedExprDef.TField`).
	**/
	function fieldAccessToCS(e: TypedExpr, fa: FieldAccess): String {
		final nameMeta: NameAndMeta = switch(fa) {
			case FInstance(_, _, classFieldRef): classFieldRef.get();
			case FStatic(_, classFieldRef): classFieldRef.get();
			case FAnon(classFieldRef): classFieldRef.get();
			case FClosure(_, classFieldRef): classFieldRef.get();
			case FEnum(_, enumField): enumField;
			case FDynamic(s): {
					name: s,
					meta: null
				};
		}
		
		return if(nameMeta.hasMeta(":native")) {
			nameMeta.getNameOrNative();
		} else {
			final name = compiler.compileVarName(nameMeta.getNameOrNativeName());
			
			// Check if a special field access and intercept.
			switch(fa) {
				case FStatic(clsRef, cfRef): {
						final cf = cfRef.get();
						final className = compiler.compileClassName(clsRef.get());
						// TODO: generate static access
						// return ...
					}
				case FEnum(_, enumField): {
						// TODO: generate enum access
						// return ...
					}
				case _:
			}
			
			final csExpr = compileToCSStatement(e);
			
			// Check if a special field access that requires the compiled expression.
			switch(fa) {
				case FAnon(classFieldRef): {
						// TODO: generate anon struct access
						// return ...
					}
				case _:
			}
			
			csExpr + "." + name;
		}
	}
	
	function compileIf(condExpr: TypedExpr, ifContentExpr: TypedExpr, elseExpr: Null<TypedExpr>) {
		var result = "if(" + compileToCSStatement(condExpr.unwrapParenthesis()) + ") {\n";
		result += toIndentedScope(ifContentExpr);
		if(elseExpr != null) {
			switch(elseExpr.expr) {
				case TIf(condExpr2, ifContentExpr2, elseExpr2): {
						result += "\n} else " + compileIf(condExpr2, ifContentExpr2, elseExpr2);
					}
				case _:
					{
						result += "\n} else {\n";
						result += toIndentedScope(elseExpr);
						result += "\n}";
					}
			}
		} else {
			result += "\n}";
		}
		return result;
	}
	
	function compileFuncArgs(args: Array<{
		v: TVar,
		value: Null<TypedExpr>
	}>, pos: Position): Array<CSArg> {
		// For now, we are opting to the most robust solution even if
		// that might not be the most efficient one in some situations.
		// Let's first make it work, then after that we can think about improving it.
		
		var result: Array<CSArg> = [];
		
		for(arg in args) {
			result.push({
				name: compiler.compileVarName(arg.v.name),
				type: compiler.compileTypeOrError(arg.v.t, pos),
				opt: arg.value != null,
				value: arg.value != null ? compileToCSExpr(arg.value) : null
			});
		}
		
		return result;
	}
	
	function compileSwitchCases(cases: Array<{
		values: Array<TypedExpr>,
		expr: TypedExpr
	}>): Array<{
		value: CSExpr,
		content: Null<Array<CSStatement>>
	}> {
		var result = [];
		
		for(aCase in cases) {
			final numValues = aCase.values.length;
			
			var csContent = compileToCSStatementArray(aCase.expr);
			csContent.push({
				def: CSBreak
			});
			
			for(i in 0...numValues) {
				final value = aCase.values[i];
				result.push({
					value: compileToCSExpr(value),
					content: i == numValues - 1 ? csContent : null
				});
			}
		}
		
		return result;
	}
	
	function compileTryCatches(catches: Array<{
		v: TVar,
		expr: TypedExpr
	}>): Array<{
		name: String,
		type: CSType,
		content: Array<CSStatement>
	}> {
		var result = [];
		
		for(aCatch in catches) {
			result.push({
				name: compiler.compileVarName(aCatch.v.name),
				type: compiler.compileTypeOrError(aCatch.v.t, aCatch.expr.pos),
				content: compileToCSStatementArray(aCatch.expr)
			});
		}
		
		return result;
	}
}
#end
