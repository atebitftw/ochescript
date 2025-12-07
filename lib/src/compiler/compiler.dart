import 'package:oche_script/src/compiler/expr.dart';
import 'package:oche_script/src/compiler/expr_gen.dart';
import 'package:oche_script/src/compiler/stmt.dart';
import 'package:oche_script/src/compiler/stmt_gen.dart';
import 'package:oche_script/src/compiler/token.dart';
import 'package:oche_script/src/compiler/token_type.dart';
import 'package:oche_script/src/runtime/chunk.dart';
import 'package:oche_script/src/runtime/obj.dart';
import 'package:oche_script/src/runtime/opcode.dart';
import 'package:oche_script/src/runtime/runtime_error.dart';
import 'package:oche_script/src/source_mapper.dart';

class Local {
  final Token name;
  int depth;
  bool isCaptured = false;

  Local(this.name, this.depth);
}

class Upvalue {
  final int index;
  final bool isLocal;

  Upvalue(this.index, this.isLocal);
}

class Loop {
  final int startOffset;
  final int scopeDepth;
  final int continueOffset;
  final List<int> breakJumps = [];
  final List<int> continueJumps = [];

  Loop(this.startOffset, this.scopeDepth, {this.continueOffset = -1});
}

class SwitchContext {
  final int scopeDepth;
  final List<int> breakJumps = [];

  SwitchContext(this.scopeDepth);
}

enum FunctionType { script, function, method, initializer }

class CompilerState {
  final CompilerState? enclosing;
  final ObjFunction function;
  final FunctionType type;

  final List<Local> locals = [];
  final List<Upvalue> upvalues = [];
  final List<Loop> loops = [];
  final List<SwitchContext> switches = [];
  int scopeDepth = 0;

  CompilerState(this.enclosing, this.function, this.type) {
    // Reserve stack slot 0 for local use (e.g. 'this' or internal)
    locals.add(Local(Token(TokenType.IDENTIFIER, "", 0), 0));
  }
}

class BytecodeCompiler implements ExprVisitor<void>, StmtVisitor<void> {
  late CompilerState _state;
  final List<String> _definedGlobals = [];
  final SourceMapper? sourceMapper;

  BytecodeCompiler([this.sourceMapper]);

  Chunk compile(List<Stmt> statements) {
    // Top-level script is treated as a function
    final scriptFunction = ObjFunction(Chunk(), name: "script");
    _state = CompilerState(null, scriptFunction, FunctionType.script);

    for (final stmt in statements) {
      stmt.accept(this);
    }

    emitOp(OpCode.NIL, 0);
    emitOp(OpCode.RETURN, 0);

    return _state.function.chunk;
  }

  Chunk get _currentChunk => _state.function.chunk;

  void emitByte(int byte, int line) {
    _currentChunk.write(byte, line);
  }

  void emitOp(OpCode op, int line) {
    _currentChunk.writeOp(op, line);
  }

  void emitConstant(Object? value, int line) {
    final index = _currentChunk.addConstant(value);
    emitOp(OpCode.CONSTANT, line);
    emitByte(index, line);
  }

  // --- Statements ---

  @override
  void visitExpressionStmt(Expression stmt) {
    if (_tryCompileOptimizedIncrement(stmt.expression)) {
      return;
    }
    stmt.expression.accept(this);
    emitOp(OpCode.POP, stmt.token.line); // Discard result
  }

  @override
  void visitPrintStmt(Print stmt) {
    stmt.expression.accept(this);
    emitOp(OpCode.PRINT, stmt.token.line);
  }

  @override
  void visitOutStmt(Out stmt) {
    stmt.value.accept(this);
    final nameIdx = _currentChunk.addConstant(stmt.identifier);
    emitOp(OpCode.OUT, stmt.token.line);
    emitByte(nameIdx, stmt.token.line);
  }

  @override
  void visitVarStmt(Var stmt) {
    stmt.initializer.accept(this);

    if (_state.scopeDepth > 0) {
      _addLocal(stmt.name);
    } else {
      // Check for global redeclaration
      if (_definedGlobals.contains(stmt.name.lexeme)) {
        throw _error(stmt.name.line, "Variable '${stmt.name.lexeme}' is already declared.");
      }
      _definedGlobals.add(stmt.name.lexeme);

      final nameIdx = _currentChunk.addConstant(stmt.name.lexeme);
      emitOp(OpCode.DEFINE_GLOBAL, stmt.name.line);
      emitByte(nameIdx, stmt.name.line);
    }
  }

  @override
  void visitBlockStmt(Block stmt) {
    _beginScope();
    for (final s in stmt.statements) {
      s.accept(this);
    }
    _endScope(stmt.token.line);
  }

  @override
  void visitIfStmt(If stmt) {
    stmt.condition.accept(this);

    // Jump if false. We'll patch the offset later.
    emitOp(OpCode.JUMP_IF_FALSE, stmt.token.line);
    emitByte(0xff, stmt.token.line); // Placeholder
    emitByte(0xff, stmt.token.line); // Placeholder
    final elseJump = _currentChunk.code.length - 2;

    // Pop the condition value if we didn't jump (it was true)
    emitOp(OpCode.POP, stmt.token.line);

    stmt.thenBranch.accept(this);

    final endJump = _emitJump(OpCode.JUMP, stmt.token.line);

    _patchJump(elseJump);

    // Pop the condition value if we jumped here (it was false)
    emitOp(OpCode.POP, stmt.token.line);

    if (stmt.elseBranch != null) {
      stmt.elseBranch!.accept(this);
    }

    _patchJump(endJump);
  }

  @override
  void visitWhileStmt(While stmt) {
    final loopStart = _currentChunk.code.length;
    _state.loops.add(Loop(loopStart, _state.scopeDepth, continueOffset: loopStart)); // Push loop

    stmt.condition.accept(this);

    emitOp(OpCode.JUMP_IF_FALSE, stmt.token.line);
    emitByte(0xff, stmt.token.line);
    emitByte(0xff, stmt.token.line);
    final exitJump = _currentChunk.code.length - 2;

    emitOp(OpCode.POP, stmt.token.line); // Pop condition (true)

    stmt.body.accept(this);

    _emitLoop(loopStart, stmt.token.line);

    _patchJump(exitJump);
    emitOp(OpCode.POP, stmt.token.line); // Pop condition (false)

    // Patch breaks
    final loop = _state.loops.removeLast(); // Pop loop
    for (final breakJump in loop.breakJumps) {
      _patchJump(breakJump);
    }
  }

  @override
  void visitScriptFunctionStmt(ScriptFunction stmt) {
    final nameIdx = _currentChunk.addConstant(stmt.name.lexeme);
    _function(FunctionType.function, stmt.params, stmt.body, stmt.name.lexeme);
    emitOp(OpCode.DEFINE_GLOBAL, stmt.name.line);
    emitByte(nameIdx, stmt.name.line);
  }

  @override
  void visitReturnStmt(Return stmt) {
    if (stmt.value != null) {
      stmt.value!.accept(this);
    } else {
      emitOp(OpCode.NIL, stmt.token.line);
    }
    emitOp(OpCode.RETURN, stmt.token.line);
  }

  // --- Expressions ---

  @override
  void visitLiteralExpr(Literal expr) {
    if (expr.value is bool) {
      emitOp((expr.value as bool) ? OpCode.TRUE : OpCode.FALSE, 0);
    } else {
      emitConstant(expr.value, 0);
    }
  }

  @override
  void visitBinaryExpr(Binary expr) {
    expr.left.accept(this);
    expr.right.accept(this);

    switch (expr.operation.type) {
      case TokenType.PLUS:
        emitOp(OpCode.ADD, expr.operation.line);
        break;
      case TokenType.MINUS:
        emitOp(OpCode.SUBTRACT, expr.operation.line);
        break;
      case TokenType.STAR:
        emitOp(OpCode.MULTIPLY, expr.operation.line);
        break;
      case TokenType.SLASH:
        emitOp(OpCode.DIVIDE, expr.operation.line);
        break;
      case TokenType.PERCENT:
        emitOp(OpCode.MODULO, expr.operation.line);
        break;
      case TokenType.EQUAL_EQUAL:
        emitOp(OpCode.EQUAL, expr.operation.line);
        break;
      case TokenType.GREATER:
        emitOp(OpCode.GREATER, expr.operation.line);
        break;
      case TokenType.LESS:
        emitOp(OpCode.LESS, expr.operation.line);
        break;
      case TokenType.GREATER_EQUAL:
        // A >= B  <=>  !(A < B)
        emitOp(OpCode.LESS, expr.operation.line);
        emitOp(OpCode.NOT, expr.operation.line);
        break;
      case TokenType.LESS_EQUAL:
        // A <= B  <=>  !(A > B)
        emitOp(OpCode.GREATER, expr.operation.line);
        emitOp(OpCode.NOT, expr.operation.line);
        break;
      case TokenType.BANG_EQUAL:
        // A != B
        emitOp(OpCode.NOT_EQUAL, expr.operation.line);
        break;
      case TokenType.IS:
        emitOp(OpCode.IS, expr.operation.line);
        break;
      case TokenType.AMP:
        emitOp(OpCode.BIT_AND, expr.operation.line);
        break;
      case TokenType.BITOR:
        emitOp(OpCode.BIT_OR, expr.operation.line);
        break;
      case TokenType.BITXOR:
        emitOp(OpCode.BIT_XOR, expr.operation.line);
        break;
      case TokenType.BITSHIFTLEFT:
        emitOp(OpCode.SHIFT_LEFT, expr.operation.line);
        break;
      case TokenType.BITSHIFTRIGHT:
        emitOp(OpCode.SHIFT_RIGHT, expr.operation.line);
        break;
      default:
        throw _error(expr.operation.line, "Binary operator ${expr.operation.type} not implemented.");
    }
  }

  @override
  void visitGroupingExpr(Grouping expr) {
    expr.expression.accept(this);
  }

  @override
  void visitUnaryExpr(Unary expr) {
    // Handle prefix increment/decrement differently
    if (expr.operation.type == TokenType.INC || expr.operation.type == TokenType.DEC) {
      // Prefix ++a or --a
      // For prefix, we need to: increment/decrement the variable, then leave the new value on stack

      if (expr.right is Variable) {
        final variable = expr.right as Variable;

        // 1. Get current value and calculate new value
        visitVariableExpr(variable);
        emitConstant(1, expr.operation.line);
        if (expr.operation.type == TokenType.INC) {
          emitOp(OpCode.ADD, expr.operation.line);
        } else {
          emitOp(OpCode.SUBTRACT, expr.operation.line);
        }

        // 2. Store the new value (this also leaves it on the stack due to SET behavior)
        // We need to manually implement assignment logic
        int arg = _resolveLocal(_state, variable.name);
        if (arg != -1) {
          emitOp(OpCode.SET_LOCAL, variable.name.line);
          emitByte(arg, variable.name.line);
        } else if ((arg = _resolveUpvalue(_state, variable.name)) != -1) {
          emitOp(OpCode.SET_UPVALUE, variable.name.line);
          emitByte(arg, variable.name.line);
        } else {
          final nameIdx = _currentChunk.addConstant(variable.name.lexeme);
          emitOp(OpCode.SET_GLOBAL, variable.name.line);
          emitByte(nameIdx, variable.name.line);
        }
        // The SET operations leave the value on the stack, which is what we want for prefix
      } else {
        throw _error(expr.operation.line, "Prefix operator only supported on variables for now.");
      }
    } else {
      // Regular unary operators (-, !)
      expr.right.accept(this);
      switch (expr.operation.type) {
        case TokenType.MINUS:
          emitOp(OpCode.NEGATE, expr.operation.line);
          break;
        case TokenType.BANG:
          emitOp(OpCode.NOT, expr.operation.line);
          break;
        case TokenType.BITNOT:
          emitOp(OpCode.BIT_NOT, expr.operation.line);
          break;
        default:
          throw _error(expr.operation.line, "Unary operator ${expr.operation.type} not implemented.");
      }
    }
  }

  @override
  void visitVariableExpr(Variable expr) {
    int arg = _resolveLocal(_state, expr.name);
    if (arg != -1) {
      emitOp(OpCode.GET_LOCAL, expr.name.line);
      emitByte(arg, expr.name.line);
    } else if ((arg = _resolveUpvalue(_state, expr.name)) != -1) {
      emitOp(OpCode.GET_UPVALUE, expr.name.line);
      emitByte(arg, expr.name.line);
    } else {
      final nameIdx = _currentChunk.addConstant(expr.name.lexeme);
      emitOp(OpCode.GET_GLOBAL, expr.name.line);
      emitByte(nameIdx, expr.name.line);
    }
  }

  @override
  void visitAssignExpr(Assign expr) {
    expr.value.accept(this);

    int arg = _resolveLocal(_state, expr.name);
    if (arg != -1) {
      emitOp(OpCode.SET_LOCAL, expr.name.line);
      emitByte(arg, expr.name.line);
    } else if ((arg = _resolveUpvalue(_state, expr.name)) != -1) {
      emitOp(OpCode.SET_UPVALUE, expr.name.line);
      emitByte(arg, expr.name.line);
    } else {
      final nameIdx = _currentChunk.addConstant(expr.name.lexeme);
      emitOp(OpCode.SET_GLOBAL, expr.name.line);
      emitByte(nameIdx, expr.name.line);
    }
  }

  @override
  void visitCallExpr(Call expr) {
    if (expr.callee is Get) {
      final get = expr.callee as Get;
      get.object.accept(this);
      for (final arg in expr.arguments) {
        arg.accept(this);
      }

      if (get.name.lexeme == "add" && expr.arguments.length == 1) {
        emitOp(OpCode.LIST_APPEND, expr.operation.line);
      } else {
        final nameIdx = _currentChunk.addConstant(get.name.lexeme);
        emitOp(OpCode.INVOKE, expr.operation.line);
        emitByte(nameIdx, expr.operation.line);
        emitByte(expr.arguments.length, expr.operation.line);
      }
    } else if (expr.callee is Super) {
      final sup = expr.callee as Super;
      final method = sup.method;
      final nameIdx = _currentChunk.addConstant(method.lexeme);

      visitVariableExpr(Variable(Token(TokenType.THIS, "this", 0), token: sup.token));

      // Args
      for (final arg in expr.arguments) {
        arg.accept(this);
      }

      visitVariableExpr(Variable(Token(TokenType.SUPER, "super", 0), token: sup.token));

      emitOp(OpCode.SUPER_INVOKE, expr.operation.line);
      emitByte(nameIdx, expr.operation.line);
      emitByte(expr.arguments.length, expr.operation.line);
    } else {
      expr.callee.accept(this);
      for (final arg in expr.arguments) {
        arg.accept(this);
      }
      emitOp(OpCode.CALL, expr.operation.line);
      emitByte(expr.arguments.length, expr.operation.line);
    }
  }

  @override
  void visitFunctionExprExpr(FunctionExpr expr) {
    _function(FunctionType.function, expr.params, expr.body, "lambda");
  }

  RuntimeError _error(int line, String message) {
    if (sourceMapper != null) {
      final loc = sourceMapper!.map(line);
      return RuntimeError.withLine(loc.line, message, file: loc.file);
    }
    return RuntimeError.withLine(line, message);
  }

  // --- Helpers ---

  bool _tryCompileOptimizedIncrement(Expr expr) {
    if (expr is Postfix) {
      if (expr.left is Variable) {
        final variable = expr.left as Variable;
        int arg = _resolveLocal(_state, variable.name);
        if (arg != -1) {
          if (expr.operator.type == TokenType.INC) {
            emitOp(OpCode.INC_LOCAL, expr.operator.line);
          } else {
            emitOp(OpCode.DEC_LOCAL, expr.operator.line);
          }
          emitByte(arg, expr.operator.line);
          return true;
        }
      }
    } else if (expr is Unary) {
      if (expr.operation.type == TokenType.INC || expr.operation.type == TokenType.DEC) {
        if (expr.right is Variable) {
          final variable = expr.right as Variable;
          int arg = _resolveLocal(_state, variable.name);
          if (arg != -1) {
            if (expr.operation.type == TokenType.INC) {
              emitOp(OpCode.INC_LOCAL, expr.operation.line);
            } else {
              emitOp(OpCode.DEC_LOCAL, expr.operation.line);
            }
            emitByte(arg, expr.operation.line);
            return true;
          }
        }
      }
    }
    return false;
  }

  void _function(FunctionType type, List<Token> params, List<Stmt> body, String name) {
    final function = ObjFunction(Chunk(), name: name, arity: params.length);
    final enclosing = _state;
    _state = CompilerState(enclosing, function, type);

    if (type == FunctionType.method || type == FunctionType.initializer) {
      _state.locals[0] = Local(Token(TokenType.THIS, "this", 0), 0);
    }

    _beginScope();
    for (final param in params) {
      _addLocal(param);
    }

    for (final stmt in body) {
      stmt.accept(this);
    }

    // Implicit return
    emitOp(OpCode.NIL, 0);
    emitOp(OpCode.RETURN, 0);

    final compiledFunction = _state.function;
    final upvalues = _state.upvalues;
    _state = enclosing; // Restore

    final index = _currentChunk.addConstant(compiledFunction);
    emitOp(OpCode.CLOSURE, 0);
    emitByte(index, 0);

    for (final upvalue in upvalues) {
      emitByte(upvalue.isLocal ? 1 : 0, 0);
      emitByte(upvalue.index, 0);
    }
  }

  void _beginScope() {
    _state.scopeDepth++;
  }

  void _endScope(int line) {
    _state.scopeDepth--;

    // Pop locals from the stack
    while (_state.locals.isNotEmpty && _state.locals.last.depth > _state.scopeDepth) {
      if (_state.locals.last.isCaptured) {
        emitOp(OpCode.CLOSE_UPVALUE, line);
      } else {
        emitOp(OpCode.POP, line);
      }
      _state.locals.removeLast();
    }
  }

  void _addLocal(Token name) {
    // Check for redeclaration in same scope
    for (final local in _state.locals) {
      if (local.depth == _state.scopeDepth && local.name.lexeme == name.lexeme) {
        throw _error(name.line, "Variable '${name.lexeme}' is already declared in this scope.");
      }
    }
    _state.locals.add(Local(name, _state.scopeDepth));
  }

  int _resolveLocal(CompilerState state, Token name) {
    for (int i = state.locals.length - 1; i >= 0; i--) {
      final local = state.locals[i];
      if (local.name.lexeme == name.lexeme) {
        return i;
      }
    }
    return -1;
  }

  int _resolveUpvalue(CompilerState state, Token name) {
    if (state.enclosing == null) return -1;

    final local = _resolveLocal(state.enclosing!, name);
    if (local != -1) {
      state.enclosing!.locals[local].isCaptured = true;
      return _addUpvalue(state, local, true);
    }

    final upvalue = _resolveUpvalue(state.enclosing!, name);
    if (upvalue != -1) {
      return _addUpvalue(state, upvalue, false);
    }

    return -1;
  }

  int _addUpvalue(CompilerState state, int index, bool isLocal) {
    for (int i = 0; i < state.upvalues.length; i++) {
      final upvalue = state.upvalues[i];
      if (upvalue.index == index && upvalue.isLocal == isLocal) {
        return i;
      }
    }

    state.upvalues.add(Upvalue(index, isLocal));
    state.function.upvalues.add(isLocal ? "local:$index" : "upvalue:$index"); // For debug
    return state.upvalues.length - 1;
  }

  int _emitJump(OpCode instruction, int line) {
    emitOp(instruction, line);
    emitByte(0xff, line);
    emitByte(0xff, line);
    return _currentChunk.code.length - 2;
  }

  void _patchJump(int offset) {
    // -2 to adjust for the jump offset itself.
    int jump = _currentChunk.code.length - offset - 2;

    if (jump > 65535) {
      throw RuntimeError("Too much code to jump over.");
    }

    _currentChunk.code[offset] = (jump >> 8) & 0xff;
    _currentChunk.code[offset + 1] = jump & 0xff;
  }

  void _emitLoop(int loopStart, int line) {
    emitOp(OpCode.LOOP, line);

    int offset = _currentChunk.code.length - loopStart + 2;
    // max 32-bit unsigned int

    if (offset > 4_294_967_295) throw _error(line, "Loop body too large.");

    emitByte((offset >> 8) & 0xff, line);
    emitByte(offset & 0xff, line);
  }

  @override
  void visitAwaitExpr(Await expr) {
    expr.expression.accept(this);
    emitOp(OpCode.AWAIT, expr.token.line);
  }

  @override
  void visitBreakStmt(Break stmt) {
    if (_state.loops.isEmpty && _state.switches.isEmpty) {
      throw _error(stmt.token.line, "Cannot use 'break' outside of a loop or switch.");
    }

    bool breakFromLoop = false;
    if (_state.loops.isNotEmpty && _state.switches.isNotEmpty) {
      if (_state.loops.last.scopeDepth > _state.switches.last.scopeDepth) {
        breakFromLoop = true;
      }
    } else if (_state.loops.isNotEmpty) {
      breakFromLoop = true;
    }

    if (breakFromLoop) {
      final loop = _state.loops.last;
      // Pop locals created inside the loop
      for (int i = _state.locals.length - 1; i >= 0; i--) {
        if (_state.locals[i].depth > loop.scopeDepth) {
          emitOp(OpCode.POP, stmt.token.line);
        } else {
          break;
        }
      }

      final jump = _emitJump(OpCode.JUMP, stmt.token.line);
      loop.breakJumps.add(jump);
    } else {
      final switchCtx = _state.switches.last;
      // Pop locals created inside the switch
      for (int i = _state.locals.length - 1; i >= 0; i--) {
        if (_state.locals[i].depth > switchCtx.scopeDepth) {
          emitOp(OpCode.POP, stmt.token.line);
        } else {
          break;
        }
      }

      final jump = _emitJump(OpCode.JUMP, stmt.token.line);
      switchCtx.breakJumps.add(jump);
    }
  }

  @override
  void visitClassStmt(Class stmt) {
    final nameIdx = _currentChunk.addConstant(stmt.name.lexeme);
    emitOp(OpCode.CLASS, stmt.name.line);
    emitByte(nameIdx, stmt.name.line);

    if (_state.scopeDepth > 0) {
      _addLocal(stmt.name);
    } else {
      emitOp(OpCode.DEFINE_GLOBAL, stmt.name.line);
      emitByte(nameIdx, stmt.name.line);
    }

    // If global, we popped it. Need to push it back.
    // Create a scope to properly manage the class placeholder local.
    bool needsClassScope = _state.scopeDepth == 0;
    if (needsClassScope) {
      emitOp(OpCode.GET_GLOBAL, stmt.name.line);
      emitByte(nameIdx, stmt.name.line);
      // Begin a scope and add placeholder local for the class
      // This ensures the local is properly cleaned up when class definition ends
      _beginScope();
      _addLocal(Token(TokenType.IDENTIFIER, "", stmt.name.line));
    }

    if (stmt.superclass != null) {
      visitVariableExpr(stmt.superclass!);
      _beginScope();
      _addLocal(Token(TokenType.SUPER, "super", stmt.name.line));
      emitOp(OpCode.INHERIT, stmt.name.line);
    }

    for (final method in stmt.methods) {
      final nameIdx = _currentChunk.addConstant(method.name.lexeme);
      _function(FunctionType.method, method.params, method.body, method.name.lexeme);
      emitOp(OpCode.METHOD, method.name.line);
      emitByte(nameIdx, method.name.line);
    }

    if (stmt.superclass != null) {
      _endScope(stmt.name.line);
    }

    // End the class scope if we created one (for global classes)
    if (needsClassScope) {
      _endScope(stmt.name.line);
    }
  }

  @override
  void visitConstStmt(Const stmt) {
    throw _error(stmt.token.line, "Const statements are not supported.");
  }

  @override
  void visitContinueStmt(Continue stmt) {
    if (_state.loops.isEmpty) {
      throw _error(stmt.token.line, "Cannot use 'continue' outside of a loop.");
    }

    final loop = _state.loops.last;

    // Pop locals created inside the loop
    for (int i = _state.locals.length - 1; i >= 0; i--) {
      if (_state.locals[i].depth > loop.scopeDepth) {
        emitOp(OpCode.POP, stmt.token.line);
      } else {
        break;
      }
    }

    if (loop.continueOffset != -1) {
      _emitLoop(loop.continueOffset, stmt.token.line);
    } else {
      final jump = _emitJump(OpCode.JUMP, stmt.token.line);
      loop.continueJumps.add(jump);
    }
  }

  @override
  void visitForInStmt(ForIn stmt) {
    _beginScope(); // Outer scope for hidden variables

    // 1. Evaluate iterable
    stmt.iterable.accept(this);
    // Store in hidden local %list
    Token listToken = Token(TokenType.IDENTIFIER, "%list", stmt.token.line);
    _addLocal(listToken);

    // 2. Initialize %index = 0
    emitConstant(0, stmt.token.line);
    Token indexToken = Token(TokenType.IDENTIFIER, "%index", stmt.token.line);
    _addLocal(indexToken);

    // 3. Mark Loop Start
    final loopStart = _currentChunk.code.length;

    _state.loops.add(Loop(loopStart, _state.scopeDepth));

    // 4. Condition: %index < %list.length
    // Get %index
    emitOp(OpCode.GET_LOCAL, stmt.token.line);
    emitByte(_resolveLocal(_state, indexToken), stmt.token.line);

    // Get %list.length
    emitOp(OpCode.GET_LOCAL, stmt.token.line);
    emitByte(_resolveLocal(_state, listToken), stmt.token.line);

    // Invoke length()
    final lengthIdx = _currentChunk.addConstant("length");
    emitOp(OpCode.INVOKE, stmt.token.line);
    emitByte(lengthIdx, stmt.token.line);
    emitByte(0, stmt.token.line); // 0 args

    // Compare
    emitOp(OpCode.LESS, stmt.token.line);

    // Jump if false (Exit)
    emitOp(OpCode.JUMP_IF_FALSE, stmt.token.line);
    emitByte(0xff, stmt.token.line);
    emitByte(0xff, stmt.token.line);
    final exitJump = _currentChunk.code.length - 2;

    emitOp(OpCode.POP, stmt.token.line); // Pop condition (true)

    // 5. Body Setup
    _beginScope(); // Body scope

    // Get element: %list[%index]
    emitOp(OpCode.GET_LOCAL, stmt.token.line);
    emitByte(_resolveLocal(_state, listToken), stmt.token.line);

    emitOp(OpCode.GET_LOCAL, stmt.token.line);
    emitByte(_resolveLocal(_state, indexToken), stmt.token.line);

    emitOp(OpCode.INDEX_GET, stmt.token.line);

    // Declare loop variable 'var foo' initialized with this value
    _addLocal(stmt.loopVariable);

    // 6. Execute Body
    stmt.body.accept(this);

    _endScope(stmt.token.line); // Pop loop variable

    final continueStart = _currentChunk.code.length;
    // Update the Loop object with continueOffset
    _state.loops.last.continueJumps.forEach((j) => _patchJump(j));

    emitOp(OpCode.INC_LOCAL, stmt.token.line);
    emitByte(_resolveLocal(_state, indexToken), stmt.token.line);

    // 8. Loop Back
    _emitLoop(loopStart, stmt.token.line);

    // 9. Patch Exit
    _patchJump(exitJump);
    emitOp(OpCode.POP, stmt.token.line); // Pop condition (false)

    // Patch break jumps
    final loop = _state.loops.removeLast();
    for (final breakJump in loop.breakJumps) {
      _patchJump(breakJump);
    }

    // Patch continue jumps
    for (final continueJump in loop.continueJumps) {
      // Manual patch to specific offset
      int jumpDist = continueStart - continueJump - 2;
      if (jumpDist > 65535) {
        throw RuntimeError("Too much code to jump over.");
      }
      _currentChunk.code[continueJump] = (jumpDist >> 8) & 0xff;
      _currentChunk.code[continueJump + 1] = jumpDist & 0xff;
    }

    _endScope(stmt.token.line); // Pop %list, %index
  }

  @override
  void visitForStmt(For stmt) {
    _beginScope();

    if (stmt.initializer != null) {
      stmt.initializer!.accept(this);
    }

    final loopStart = _currentChunk.code.length;
    final continueOffset = stmt.increment == null ? loopStart : -1;
    _state.loops.add(Loop(loopStart, _state.scopeDepth, continueOffset: continueOffset));

    int exitJump = -1;

    if (stmt.condition != null) {
      stmt.condition!.accept(this);

      emitOp(OpCode.JUMP_IF_FALSE, stmt.token.line);
      emitByte(0xff, stmt.token.line);
      emitByte(0xff, stmt.token.line);
      exitJump = _currentChunk.code.length - 2;

      emitOp(OpCode.POP, stmt.token.line); // Pop condition (true)
    }

    stmt.body.accept(this);

    final loop = _state.loops.last;

    if (stmt.increment != null) {
      for (final jump in loop.continueJumps) {
        _patchJump(jump);
      }
      if (!_tryCompileOptimizedIncrement(stmt.increment!)) {
        stmt.increment!.accept(this);
        emitOp(OpCode.POP, stmt.token.line); // Discard increment result
      }
    }

    _emitLoop(loopStart, stmt.token.line);

    if (exitJump != -1) {
      _patchJump(exitJump);
      emitOp(OpCode.POP, stmt.token.line); // Pop condition (false)
    }

    _state.loops.removeLast();
    for (final breakJump in loop.breakJumps) {
      _patchJump(breakJump);
    }

    _endScope(stmt.token.line);
  }

  @override
  void visitGetExpr(Get expr) {
    expr.object.accept(this);
    final nameIdx = _currentChunk.addConstant(expr.name.lexeme);
    emitOp(OpCode.GET_PROPERTY, expr.name.line);
    emitByte(nameIdx, expr.name.line);
  }

  @override
  void visitIndexExpr(Index expr) {
    expr.object.accept(this);
    expr.index.accept(this);
    emitOp(OpCode.INDEX_GET, expr.bracket.line);
  }

  @override
  void visitListLiteralExpr(ListLiteral expr) {
    for (final element in expr.elements) {
      element.accept(this);
    }
    emitOp(OpCode.BUILD_LIST, expr.token.line);
    emitByte(expr.elements.length, expr.token.line);
  }

  @override
  void visitLogicalExpr(Logical expr) {
    // Short-circuiting logic
    expr.left.accept(this);

    int endJump = -1;

    if (expr.operation.type == TokenType.OR) {
      emitOp(OpCode.JUMP_IF_FALSE, expr.operation.line);
      emitByte(0xff, expr.operation.line);
      emitByte(0xff, expr.operation.line);
      final elseJump = _currentChunk.code.length - 2;

      emitOp(OpCode.JUMP, expr.operation.line);
      emitByte(0xff, expr.operation.line);
      emitByte(0xff, expr.operation.line);
      endJump = _currentChunk.code.length - 2;

      _patchJump(elseJump);
      emitOp(OpCode.POP, expr.operation.line);

      expr.right.accept(this);

      _patchJump(endJump);
    } else {
      emitOp(OpCode.JUMP_IF_FALSE, expr.operation.line);
      emitByte(0xff, expr.operation.line);
      emitByte(0xff, expr.operation.line);
      endJump = _currentChunk.code.length - 2;

      emitOp(OpCode.POP, expr.operation.line);
      expr.right.accept(this);

      _patchJump(endJump);
    }
  }

  @override
  void visitMapLiteralExpr(MapLiteral expr) {
    for (int i = 0; i < expr.keys.length; i++) {
      expr.keys[i].accept(this);
      expr.values[i].accept(this);
    }
    emitOp(OpCode.BUILD_MAP, expr.token.line);
    emitByte(expr.keys.length, expr.token.line);
  }

  @override
  void visitPostfixExpr(Postfix expr) {
    if (expr.left is Variable) {
      final variable = expr.left as Variable;
      visitVariableExpr(variable);
      visitVariableExpr(variable);
      emitConstant(1, expr.operator.line);
      if (expr.operator.type == TokenType.INC) {
        emitOp(OpCode.ADD, expr.operator.line);
      } else {
        emitOp(OpCode.SUBTRACT, expr.operator.line);
      }

      int arg = _resolveLocal(_state, variable.name);
      if (arg != -1) {
        emitOp(OpCode.SET_LOCAL, variable.name.line);
        emitByte(arg, variable.name.line);
      } else if ((arg = _resolveUpvalue(_state, variable.name)) != -1) {
        emitOp(OpCode.SET_UPVALUE, variable.name.line);
        emitByte(arg, variable.name.line);
      } else {
        final nameIdx = _currentChunk.addConstant(variable.name.lexeme);
        emitOp(OpCode.SET_GLOBAL, variable.name.line);
        emitByte(nameIdx, variable.name.line);
      }

      emitOp(OpCode.POP, expr.operator.line); // Pop the set result (new value)
      // Old value remains on stack
    } else {
      throw RuntimeError.withLine(expr.operator.line, "Postfix operator only supported on variables for now.");
    }
  }

  @override
  void visitSetExpr(Set expr) {
    expr.object.accept(this);
    expr.value.accept(this);
    final nameIdx = _currentChunk.addConstant(expr.name.lexeme);
    emitOp(OpCode.SET_PROPERTY, expr.name.line);
    emitByte(nameIdx, expr.name.line);
  }

  @override
  void visitSetIndexExpr(SetIndex expr) {
    expr.object.accept(this);
    expr.index.accept(this);
    expr.value.accept(this);
    emitOp(OpCode.INDEX_SET, expr.bracket.line);
  }

  @override
  void visitSuperExpr(Super expr) {
    // "this"
    int arg = _resolveLocal(_state, Token(TokenType.THIS, "this", expr.keyword.line));
    if (arg != -1) {
      emitOp(OpCode.GET_LOCAL, expr.keyword.line);
      emitByte(arg, expr.keyword.line);
    } else {
      arg = _resolveUpvalue(_state, Token(TokenType.THIS, "this", expr.keyword.line));
      if (arg != -1) {
        emitOp(OpCode.GET_UPVALUE, expr.keyword.line);
        emitByte(arg, expr.keyword.line);
      } else {
        throw RuntimeError.withLine(expr.keyword.line, "Cannot use 'super' outside of a class method.");
      }
    }

    // "super"
    arg = _resolveLocal(_state, Token(TokenType.SUPER, "super", expr.keyword.line));
    if (arg != -1) {
      emitOp(OpCode.GET_LOCAL, expr.keyword.line);
      emitByte(arg, expr.keyword.line);
    } else {
      arg = _resolveUpvalue(_state, Token(TokenType.SUPER, "super", expr.keyword.line));
      if (arg != -1) {
        emitOp(OpCode.GET_UPVALUE, expr.keyword.line);
        emitByte(arg, expr.keyword.line);
      } else {
        throw RuntimeError.withLine(expr.keyword.line, "Cannot use 'super' in a class with no superclass.");
      }
    }

    final nameIdx = _currentChunk.addConstant(expr.method.lexeme);
    emitOp(OpCode.GET_SUPER, expr.keyword.line);
    emitByte(nameIdx, expr.keyword.line);
  }

  @override
  void visitSwitchCaseStmt(SwitchCase stmt) =>
      throw RuntimeError.withLine(stmt.token.line, "SwitchCase should not be visited directly.");

  @override
  void visitSwitchStmt(Switch stmt) {
    stmt.expression.accept(this); // Push switch value

    _beginScope();
    final tempToken = Token(TokenType.IDENTIFIER, "*switch_temp*", stmt.token.line);
    _addLocal(tempToken);
    final switchValueIndex = _state.locals.length - 1;

    // Track this switch for break statements
    final switchCtx = SwitchContext(_state.scopeDepth);
    _state.switches.add(switchCtx);

    // 1. Dispatch Phase
    final caseJumpOffsets = <int, int>{}; // Map case index to jump offset
    int? defaultJumpOffset;

    for (int i = 0; i < stmt.cases.length; i++) {
      final caseStmt = stmt.cases[i];
      if (caseStmt.value != null) {
        // Emit Check
        emitOp(OpCode.GET_LOCAL, caseStmt.token.line);
        emitByte(switchValueIndex, caseStmt.token.line);

        caseStmt.value!.accept(this);
        emitOp(OpCode.EQUAL, caseStmt.token.line);

        // Jump if False (Skip this case)
        final nextCheckJump = _emitJump(OpCode.JUMP_IF_FALSE, caseStmt.token.line);

        // If True (Match): Pop the true value and Jump to Body
        emitOp(OpCode.POP, caseStmt.token.line);
        caseJumpOffsets[i] = _emitJump(OpCode.JUMP, caseStmt.token.line);

        // Target of Skip: Pop the false value
        _patchJump(nextCheckJump);
        emitOp(OpCode.POP, caseStmt.token.line);
      }
    }

    // After all checks, jump to default (if exists) or end
    defaultJumpOffset = _emitJump(OpCode.JUMP, stmt.token.line);

    // 2. Body Phase
    int? previousFallthroughJump;

    for (int i = 0; i < stmt.cases.length; i++) {
      final caseStmt = stmt.cases[i];

      // Patch jump to this body
      if (caseStmt.value != null) {
        _patchJump(caseJumpOffsets[i]!);
      } else {
        if (defaultJumpOffset != null) {
          _patchJump(defaultJumpOffset);
          defaultJumpOffset = null;
        }
      }

      // Handle fallthrough from previous body
      if (previousFallthroughJump != null) {
        _patchJump(previousFallthroughJump);
      }

      // Emit Body
      for (final s in caseStmt.statements) {
        s.accept(this);
      }

      // Emit Fallthrough Jump to next body
      if (i < stmt.cases.length - 1) {
        previousFallthroughJump = _emitJump(OpCode.JUMP, caseStmt.token.line);
      } else {
        previousFallthroughJump = null;
      }
    }

    // If default was not found (or no cases matched and no default), patch to end
    if (defaultJumpOffset != null) {
      _patchJump(defaultJumpOffset);
    }

    // Patch all break jumps to end of switch
    for (final jump in switchCtx.breakJumps) {
      _patchJump(jump);
    }

    _state.switches.removeLast();
    _endScope(stmt.token.line); // This will pop the temp local (switch value)
  }

  @override
  void visitThisExpr(This expr) {
    int arg = _resolveLocal(_state, expr.keyword);
    if (arg != -1) {
      emitOp(OpCode.GET_LOCAL, expr.keyword.line);
      emitByte(arg, expr.keyword.line);
    } else if ((arg = _resolveUpvalue(_state, expr.keyword)) != -1) {
      emitOp(OpCode.GET_UPVALUE, expr.keyword.line);
      emitByte(arg, expr.keyword.line);
    } else {
      throw RuntimeError.withLine(expr.keyword.line, "Cannot use 'this' outside of a class.");
    }
  }
}
