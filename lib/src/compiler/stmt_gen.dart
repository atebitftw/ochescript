// ignore_for_file: unused_import
import 'package:oche_script/src/compiler/expr.dart';
import 'package:oche_script/src/compiler/stmt.dart';
import 'package:oche_script/src/compiler/token.dart';
import 'package:oche_script/src/compiler/expr_gen.dart';

// *** GENERATED CODE.  DO NOT MODIFY ***

abstract class StmtVisitor<R> {
  R visitOutStmt(Out stmt);
  R visitPrintStmt(Print stmt);
  R visitConstStmt(Const stmt);
  R visitExpressionStmt(Expression stmt);
  R visitVarStmt(Var stmt);
  R visitBlockStmt(Block stmt);
  R visitIfStmt(If stmt);
  R visitWhileStmt(While stmt);
  R visitScriptFunctionStmt(ScriptFunction stmt);
  R visitReturnStmt(Return stmt);
  R visitClassStmt(Class stmt);
  R visitBreakStmt(Break stmt);
  R visitContinueStmt(Continue stmt);
  R visitForStmt(For stmt);
  R visitSwitchCaseStmt(SwitchCase stmt);
  R visitSwitchStmt(Switch stmt);
  R visitForInStmt(ForIn stmt);
  R visitTryStmt(Try stmt);
  R visitThrowStmt(Throw stmt);
}

class Try extends Stmt {
  Try(this.tryBlock, this.catchBlock, this.catchVariable, {required super.token});

  final Stmt tryBlock;
  final Stmt catchBlock;
  final Token catchVariable;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitTryStmt(this);
  }

  @override
  String toString() => "Try";
}

class Throw extends Stmt {
  Throw(this.value, {required super.token});

  final Expr value;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitThrowStmt(this);
  }

  @override
  String toString() => "Throw";
}

class Out extends Stmt {
  Out(this.identifier, this.value, {required super.token});

  final String identifier;
  final Expr value;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitOutStmt(this);
  }

  @override
  String toString() => "Out";
}

class Print extends Stmt {
  Print(this.expression, {required super.token});

  final Expr expression;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitPrintStmt(this);
  }

  @override
  String toString() => "Print";
}

class Const extends Stmt {
  Const(this.initializer, {required super.token});

  final Expr initializer;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitConstStmt(this);
  }

  @override
  String toString() => "Const";
}

class Expression extends Stmt {
  Expression(this.expression, {required super.token});

  final Expr expression;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitExpressionStmt(this);
  }

  @override
  String toString() => "Expression";
}

class Var extends Stmt {
  Var(this.name, this.initializer, {required super.token});

  final Token name;
  final Expr initializer;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitVarStmt(this);
  }

  @override
  String toString() => "Var";
}

class Block extends Stmt {
  Block(this.statements, {required super.token});

  final List<Stmt> statements;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitBlockStmt(this);
  }

  @override
  String toString() => "Block";
}

class If extends Stmt {
  If(this.condition, this.thenBranch, this.elseBranch, {required super.token});

  final Expr condition;
  final Stmt thenBranch;
  final Stmt? elseBranch;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitIfStmt(this);
  }

  @override
  String toString() => "If";
}

class While extends Stmt {
  While(this.condition, this.body, {required super.token});

  final Expr condition;
  final Stmt body;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitWhileStmt(this);
  }

  @override
  String toString() => "While";
}

class ScriptFunction extends Stmt {
  ScriptFunction(this.name, this.params, this.body, this.isAsync, {required super.token});

  final Token name;
  final List<Token> params;
  final List<Stmt> body;
  final bool isAsync;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitScriptFunctionStmt(this);
  }

  @override
  String toString() => "ScriptFunction";
}

class Return extends Stmt {
  Return(this.value, {required super.token});

  final Expr? value;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitReturnStmt(this);
  }

  @override
  String toString() => "Return";
}

class Class extends Stmt {
  Class(this.name, this.superclass, this.methods, {required super.token});

  final Token name;
  final Variable? superclass;
  final List<ScriptFunction> methods;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitClassStmt(this);
  }

  @override
  String toString() => "Class";
}

class Break extends Stmt {
  Break({required super.token});

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitBreakStmt(this);
  }

  @override
  String toString() => "Break";
}

class Continue extends Stmt {
  Continue({required super.token});

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitContinueStmt(this);
  }

  @override
  String toString() => "Continue";
}

class For extends Stmt {
  For(this.initializer, this.condition, this.increment, this.body, {required super.token});

  final Stmt? initializer;
  final Expr? condition;
  final Expr? increment;
  final Stmt body;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitForStmt(this);
  }

  @override
  String toString() => "For";
}

class SwitchCase extends Stmt {
  SwitchCase(this.value, this.statements, {required super.token});

  final Expr? value;
  final List<Stmt> statements;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitSwitchCaseStmt(this);
  }

  @override
  String toString() => "SwitchCase";
}

class Switch extends Stmt {
  Switch(this.expression, this.cases, {required super.token});

  final Expr expression;
  final List<SwitchCase> cases;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitSwitchStmt(this);
  }

  @override
  String toString() => "Switch";
}

class ForIn extends Stmt {
  ForIn(this.loopVariable, this.iterable, this.body, {required super.token});

  final Token loopVariable;
  final Expr iterable;
  final Stmt body;

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitForInStmt(this);
  }

  @override
  String toString() => "ForIn";
}
