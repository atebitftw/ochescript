// ignore_for_file: unused_import
import 'package:oche_script/src/compiler/expr.dart';
import 'package:oche_script/src/compiler/stmt.dart';
import 'package:oche_script/src/compiler/token.dart';

// *** GENERATED CODE.  DO NOT MODIFY ***

abstract class ExprVisitor<R> {
  R visitBinaryExpr(Binary expr);
  R visitGroupingExpr(Grouping expr);
  R visitLiteralExpr(Literal expr);
  R visitUnaryExpr(Unary expr);
  R visitVariableExpr(Variable expr);
  R visitAssignExpr(Assign expr);
  R visitLogicalExpr(Logical expr);
  R visitCallExpr(Call expr);
  R visitGetExpr(Get expr);
  R visitSetExpr(Set expr);
  R visitThisExpr(This expr);
  R visitSuperExpr(Super expr);
  R visitListLiteralExpr(ListLiteral expr);
  R visitIndexExpr(Index expr);
  R visitSetIndexExpr(SetIndex expr);
  R visitMapLiteralExpr(MapLiteral expr);
  R visitFunctionExprExpr(FunctionExpr expr);
  R visitPostfixExpr(Postfix expr);
  R visitAwaitExpr(Await expr);
}

class Binary extends Expr {
  Binary(this.left, this.operation, this.right, {required super.token});

  final Expr left;
  final Token operation;
  final Expr right;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitBinaryExpr(this);
  }

  @override
  String toString() => "Binary";
}

class Grouping extends Expr {
  Grouping(this.expression, {required super.token});

  final Expr expression;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitGroupingExpr(this);
  }

  @override
  String toString() => "Grouping";
}

class Literal extends Expr {
  Literal(this.value, {required super.token});

  final Object value;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitLiteralExpr(this);
  }

  @override
  String toString() => "Literal";
}

class Unary extends Expr {
  Unary(this.operation, this.right, {required super.token});

  final Token operation;
  final Expr right;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitUnaryExpr(this);
  }

  @override
  String toString() => "Unary";
}

class Variable extends Expr {
  Variable(this.name, {required super.token});

  final Token name;
  Object? cachedValue;
  int cachedVersion = -1;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitVariableExpr(this);
  }

  @override
  String toString() => "Variable";
}

class Assign extends Expr {
  Assign(this.name, this.value, {required super.token});

  final Token name;
  final Expr value;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitAssignExpr(this);
  }

  @override
  String toString() => "Assign";
}

class Logical extends Expr {
  Logical(this.left, this.operation, this.right, {required super.token});

  final Expr left;
  final Token operation;
  final Expr right;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitLogicalExpr(this);
  }

  @override
  String toString() => "Logical";
}

class Call extends Expr {
  Call(this.callee, this.operation, this.arguments, {required super.token});

  final Expr callee;
  final Token operation;
  final List<Expr> arguments;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitCallExpr(this);
  }

  @override
  String toString() => "Call";
}

class Get extends Expr {
  Get(this.object, this.name, {required super.token});

  final Expr object;
  final Token name;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitGetExpr(this);
  }

  @override
  String toString() => "Get";
}

class Set extends Expr {
  Set(this.object, this.name, this.value, {required super.token});

  final Expr object;
  final Token name;
  final Expr value;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitSetExpr(this);
  }

  @override
  String toString() => "Set";
}

class This extends Expr {
  This(this.keyword, {required super.token});

  final Token keyword;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitThisExpr(this);
  }

  @override
  String toString() => "This";
}

class Super extends Expr {
  Super(this.keyword, this.method, {required super.token});

  final Token keyword;
  final Token method;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitSuperExpr(this);
  }

  @override
  String toString() => "Super";
}

class ListLiteral extends Expr {
  ListLiteral(this.elements, {required super.token});

  final List<Expr> elements;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitListLiteralExpr(this);
  }

  @override
  String toString() => "ListLiteral";
}

class Index extends Expr {
  Index(this.object, this.bracket, this.index, {required super.token});

  final Expr object;
  final Token bracket;
  final Expr index;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitIndexExpr(this);
  }

  @override
  String toString() => "Index";
}

class SetIndex extends Expr {
  SetIndex(
    this.object,
    this.bracket,
    this.index,
    this.value, {
    required super.token,
  });

  final Expr object;
  final Token bracket;
  final Expr index;
  final Expr value;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitSetIndexExpr(this);
  }

  @override
  String toString() => "SetIndex";
}

class MapLiteral extends Expr {
  MapLiteral(this.keys, this.values, {required super.token});

  final List<Expr> keys;
  final List<Expr> values;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitMapLiteralExpr(this);
  }

  @override
  String toString() => "MapLiteral";
}

class FunctionExpr extends Expr {
  FunctionExpr(this.params, this.body, this.isAsync, {required super.token});

  final List<Token> params;
  final List<Stmt> body;
  final bool isAsync;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitFunctionExprExpr(this);
  }

  @override
  String toString() => "FunctionExpr";
}

class Postfix extends Expr {
  Postfix(this.left, this.operator, {required super.token});

  final Expr left;
  final Token operator;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitPostfixExpr(this);
  }

  @override
  String toString() => "Postfix";
}

class Await extends Expr {
  Await(this.expression, {required super.token});

  final Expr expression;

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitAwaitExpr(this);
  }

  @override
  String toString() => "Await";
}
