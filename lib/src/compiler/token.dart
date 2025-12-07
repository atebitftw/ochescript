import 'package:oche_script/src/compiler/token_type.dart';

class Token {
  final TokenType type;
  final String lexeme;
  final int line;
  Object? literal;

  Token(this.type, this.lexeme, this.line, {this.literal});

  @override
  String toString() =>
      "($type, Lexeme: $lexeme, Literal: $literal, line: $line)";
}
