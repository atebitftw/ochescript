import 'package:test/test.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/token_type.dart';

void main() {
  group('Lexer String Interpolation', () {
    test('scans basic interpolation', () {
      final source = '"Hello \$name"';
      final lexer = Lexer(source);
      final tokens = lexer.scan();

      // "Hello " + name
      // LEFT_PAREN, STRING("Hello "), PLUS, IDENTIFIER("name"), RIGHT_PAREN, EOF
      // Note: The specific implementation might put parens around the whole thing or just parts.
      // Based on plan: Inject PAREN, PLUS.
      // Expected: "Hello \$name" -> LEFT_PAREN "Hello " PLUS IDENTIFIER(name) RIGHT_PAREN

      expect(tokens[0].type, TokenType.LEFT_PAREN);
      expect(tokens[1].type, TokenType.STRING);
      expect(tokens[1].literal, "Hello ");
      expect(tokens[2].type, TokenType.PLUS);
      expect(tokens[3].type, TokenType.IDENTIFIER);
      expect(tokens[3].literal, "name");
      expect(tokens[4].type, TokenType.RIGHT_PAREN);
      expect(tokens[5].type, TokenType.EOF);
    });

    test('scans expression interpolation', () {
      final source = '"Result: \${a + b}"';
      final lexer = Lexer(source);
      final tokens = lexer.scan();

      // "Result: " + (a + b)
      // LEFT_PAREN "Result: " PLUS LEFT_PAREN IDENTIFIER(a) PLUS IDENTIFIER(b) RIGHT_PAREN RIGHT_PAREN

      expect(tokens[0].type, TokenType.LEFT_PAREN);
      expect(tokens[1].type, TokenType.STRING);
      expect(tokens[1].literal, "Result: ");
      expect(tokens[2].type, TokenType.PLUS);

      // The brace ${...} should act as a grouping, or just emit expression tokens?
      // Typically ${ } implies a block or expression.
      // My plan says: "Detect $ and ${... Emit PLUS tokens to join parts."
      // If I use ${ }, I need to make sure the lexer effectively recurses or handles the brace matching.
      // Simplest approach: ${ becomes LEFT_PAREN and } becomes RIGHT_PAREN, but we need to ensure they are balanced for the string logic.
      // Wait, if I do `"val: ${expr}"` -> `LEFT_PAREN "val: " PLUS LEFT_PAREN expr RIGHT_PAREN RIGHT_PAREN`?
      // Yes, treating ${ as `PLUS LEFT_PAREN` (or just start expression) and } as `RIGHT_PAREN`.
      // But we need to handle the initial string part too.

      // Let's assume the lexer implementation will do:
      // "Str${expr}" -> ( "Str" + ( expr ) )

      expect(tokens[3].type, TokenType.LEFT_PAREN); // The ${ starts a group?
      expect(tokens[4].type, TokenType.IDENTIFIER);
      expect(tokens[4].literal, "a");
      expect(tokens[5].type, TokenType.PLUS);
      expect(tokens[6].type, TokenType.IDENTIFIER);
      expect(tokens[6].literal, "b");
      expect(tokens[7].type, TokenType.RIGHT_PAREN); // The } ends the group

      expect(tokens[8].type, TokenType.RIGHT_PAREN); // End of string interpolation
      expect(tokens[9].type, TokenType.EOF);
    });

    test('scans interpolation at start', () {
      final source = '"\$name is here"';
      final lexer = Lexer(source);
      final tokens = lexer.scan();

      // LEFT_PAREN "" PLUS IDENTIFIER(name) PLUS " is here" RIGHT_PAREN
      // Or optimization: IDENTIFIER(name) PLUS " is here" ... but keeping it uniform is safer.
      // "EMPTY" + name + " is here"

      expect(tokens[0].type, TokenType.LEFT_PAREN);
      expect(tokens[1].type, TokenType.STRING);
      expect(tokens[1].literal, "");
      expect(tokens[2].type, TokenType.PLUS);
      expect(tokens[3].type, TokenType.IDENTIFIER);
      expect(tokens[3].literal, "name");
      expect(tokens[4].type, TokenType.PLUS);
      expect(tokens[5].type, TokenType.STRING);
      expect(tokens[5].literal, " is here");
      expect(tokens[6].type, TokenType.RIGHT_PAREN);
    });

    test('scans nested interpolation', () {
      // "${ "nested" }"
      final source = '"\${ "nested" }"';
      final lexer = Lexer(source);
      final tokens = lexer.scan();

      // LEFT_PAREN "" PLUS LEFT_PAREN STRING("nested") RIGHT_PAREN PLUS "" RIGHT_PAREN
      // Inner string "nested" is just a string literal.

      expect(tokens[0].type, TokenType.LEFT_PAREN);
      expect(tokens[1].type, TokenType.STRING);
      expect(tokens[1].literal, "");
      expect(tokens[2].type, TokenType.PLUS);
      expect(tokens[3].type, TokenType.LEFT_PAREN); // ${

      expect(tokens[4].type, TokenType.STRING);
      expect(tokens[4].literal, "nested");

      expect(tokens[5].type, TokenType.RIGHT_PAREN); // }
      // Optimized: No trailing PLUS or empty string
      expect(tokens[6].type, TokenType.RIGHT_PAREN);
    });

    test('handles escapes', () {
      final source = '"Normal \\" string \\\$ not var"';
      final lexer = Lexer(source);
      final tokens = lexer.scan();

      // Should be just one string token, no interpolation
      expect(tokens[0].type, TokenType.STRING);
      expect(tokens[0].literal, 'Normal " string \$ not var');
    });
  });
}
