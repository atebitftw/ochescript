import 'package:oche_script/src/compiler/stmt_gen.dart';
import 'package:oche_script/src/compiler/token.dart';

abstract class Stmt {
  final Token token;

  Stmt({required this.token});

  R accept<R>(StmtVisitor<R> visitor);
}
