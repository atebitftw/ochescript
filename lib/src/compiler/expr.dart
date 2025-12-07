import 'package:oche_script/src/compiler/expr_gen.dart';
import 'package:oche_script/src/compiler/token.dart';

abstract class Expr {
  final Token token;

  Expr({required this.token});

  R accept<R>(ExprVisitor<R> visitor);
}
