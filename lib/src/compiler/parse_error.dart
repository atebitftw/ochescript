import 'package:oche_script/src/compiler/token.dart';

/// Represents a parsing error during code compilation
class ParseError extends Error {
  final Token token;
  final String message;
  ParseError(this.token, {this.message = ""});

  @override
  String toString() => "ParseError: ${token.line}, ${token.type}, ${token.lexeme}, $message";
}
