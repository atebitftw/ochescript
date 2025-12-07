import 'package:test/test.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/token_type.dart';

void main() {
  group('Lexer', () {
    test('scans empty source', () {
      final lexer = Lexer('');
      final tokens = lexer.scan();
      expect(tokens.length, 1);
      expect(tokens[0].type, TokenType.EOF);
    });

    test('scans single character tokens', () {
      final source = '(){}[],.-+;*';
      final lexer = Lexer(source);
      final tokens = lexer.scan();

      final expectedTypes = [
        TokenType.LEFT_PAREN,
        TokenType.RIGHT_PAREN,
        TokenType.LEFT_BRACE,
        TokenType.RIGHT_BRACE,
        TokenType.LEFT_BRACKET,
        TokenType.RIGHT_BRACKET,
        TokenType.COMMA,
        TokenType.DOT,
        TokenType.MINUS,
        TokenType.PLUS,
        TokenType.SEMICOLON,
        TokenType.STAR,
        TokenType.EOF,
      ];

      expect(tokens.length, expectedTypes.length);
      for (var i = 0; i < expectedTypes.length; i++) {
        expect(tokens[i].type, expectedTypes[i]);
      }
    });

    test('scans operators', () {
      final source = '! != = == > >= < <=';
      final lexer = Lexer(source);
      final tokens = lexer.scan();

      final expectedTypes = [
        TokenType.BANG,
        TokenType.BANG_EQUAL,
        TokenType.EQUAL,
        TokenType.EQUAL_EQUAL,
        TokenType.GREATER,
        TokenType.GREATER_EQUAL,
        TokenType.LESS,
        TokenType.LESS_EQUAL,
        TokenType.EOF,
      ];

      expect(tokens.length, expectedTypes.length);
      for (var i = 0; i < expectedTypes.length; i++) {
        expect(tokens[i].type, expectedTypes[i]);
      }
    });

    test('scans string literals', () {
      final source = '"hello" "world"';
      final lexer = Lexer(source);
      final tokens = lexer.scan();

      expect(tokens[0].type, TokenType.STRING);
      expect(tokens[0].literal, 'hello');
      expect(tokens[1].type, TokenType.STRING);
      expect(tokens[1].literal, 'world');
      expect(tokens[2].type, TokenType.EOF);
    });

    test('scans number literals', () {
      final source = '123 123.456 0.42';
      final lexer = Lexer(source);
      final tokens = lexer.scan();

      expect(tokens[0].type, TokenType.NUMBER);
      expect(tokens[0].literal, 123);
      expect(tokens[1].type, TokenType.NUMBER);
      expect(tokens[1].literal, 123.456);
      expect(tokens[2].type, TokenType.NUMBER);
      expect(tokens[2].literal, 0.42);
      expect(tokens[3].type, TokenType.EOF);
    });

    test('scans identifiers and keywords', () {
      final source = 'var myVar = true; if else while for fun return class this super';
      final lexer = Lexer(source);
      final tokens = lexer.scan();

      final expectedTypes = [
        TokenType.VAR,
        TokenType.IDENTIFIER,
        TokenType.EQUAL,
        TokenType.TRUE,
        TokenType.SEMICOLON,
        TokenType.IF,
        TokenType.ELSE,
        TokenType.WHILE,
        TokenType.FOR,
        TokenType.FUN,
        TokenType.RETURN,
        TokenType.CLASS,
        TokenType.THIS,
        TokenType.SUPER,
        TokenType.EOF,
      ];

      expect(tokens.length, expectedTypes.length);
      for (var i = 0; i < expectedTypes.length; i++) {
        expect(tokens[i].type, expectedTypes[i]);
      }
    });

    test('ignores comments', () {
      final source = '// this is a comment\nvar x = 1;';
      final lexer = Lexer(source);
      final tokens = lexer.scan();

      expect(tokens[0].type, TokenType.VAR);
      expect(tokens[1].type, TokenType.IDENTIFIER);
      expect(tokens[2].type, TokenType.EQUAL);
      expect(tokens[3].type, TokenType.NUMBER);
      expect(tokens[4].type, TokenType.SEMICOLON);
      expect(tokens[5].type, TokenType.EOF);
    });

    test('handles unterminated string', () {
      final source = '"unterminated';
      final lexer = Lexer(source);
      final tokens = lexer.scan();

      expect(tokens.last.type, TokenType.EOF);
      // The lexer adds an ERROR token for unterminated strings
      expect(tokens.any((t) => t.type == TokenType.ERROR), isTrue);
    });

    test('handles unexpected character', () {
      final source = '@';
      final lexer = Lexer(source);
      final tokens = lexer.scan();

      expect(tokens.any((t) => t.type == TokenType.ERROR), isTrue);
    });
  });
}
