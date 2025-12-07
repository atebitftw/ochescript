import 'package:oche_script/src/compiler/stmt.dart';
import 'package:oche_script/src/compiler/token.dart';

/// Represents a runtime error during script execution.
class RuntimeError implements Exception {
  final Token? token;
  final Stmt? statement;
  final String message;
  final int? line;
  final String? file;

  RuntimeError(this.message) : token = null, statement = null, line = null, file = null;
  RuntimeError.withToken(this.token, this.message) : statement = null, line = null, file = null;
  RuntimeError.withStatement(this.statement, this.message) : token = null, line = null, file = null;
  RuntimeError.withLine(this.line, this.message, {this.file}) : statement = null, token = null;

  @override
  String toString() {
    final location = file != null ? "$file:$line" : "Line $line";

    if (token == null && statement == null && line == null) {
      return message;
    } else if (statement != null) {
      return "[Line ${statement!.token.line}] $statement: $message";
    } else if (token != null) {
      return "[Line ${token!.line}] ${token!.lexeme}: $message";
    } else {
      return "[$location] $message";
    }
  }
}
