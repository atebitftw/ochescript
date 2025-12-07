import 'package:test/test.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/parser.dart';
import 'package:oche_script/src/compiler/stmt_gen.dart';
import 'package:oche_script/src/compiler/expr_gen.dart';
import 'package:oche_script/src/compiler/token_type.dart';

void main() {
  group('Parser', () {
    List<dynamic> parse(String source) {
      final lexer = Lexer(source);
      final tokens = lexer.scan();
      final parser = Parser(tokens);
      return parser.parse();
    }

    test('parses variable declaration', () {
      final statements = parse('var a = 1;');
      expect(statements.length, 1);
      expect(statements[0], isA<Var>());
      final varStmt = statements[0] as Var;
      expect(varStmt.name.lexeme, 'a');
      expect(varStmt.initializer, isA<Literal>());
      expect((varStmt.initializer as Literal).value, 1);
    });

    test('parses function declaration', () {
      final statements = parse('fun foo(a, b) { return a + b; }');
      expect(statements.length, 1);
      expect(statements[0], isA<ScriptFunction>());
      final funStmt = statements[0] as ScriptFunction;
      expect(funStmt.name.lexeme, 'foo');
      expect(funStmt.params.length, 2);
      expect(funStmt.params[0].lexeme, 'a');
      expect(funStmt.params[1].lexeme, 'b');
      expect(funStmt.body.length, 1);
      expect(funStmt.body[0], isA<Return>());
    });

    test('parses class declaration', () {
      final statements = parse('class Foo { bar() {} }');
      expect(statements.length, 1);
      expect(statements[0], isA<Class>());
      final classStmt = statements[0] as Class;
      expect(classStmt.name.lexeme, 'Foo');
      expect(classStmt.methods.length, 1);
      expect(classStmt.methods[0].name.lexeme, 'bar');
    });

    test('parses if statement', () {
      final statements = parse('if (true) print "yes"; else print "no";');
      expect(statements.length, 1);
      expect(statements[0], isA<If>());
      final ifStmt = statements[0] as If;
      expect(ifStmt.condition, isA<Literal>());
      expect(ifStmt.thenBranch, isA<Print>());
      expect(ifStmt.elseBranch, isA<Print>());
    });

    test('parses while statement', () {
      final statements = parse('while (true) { break; }');
      expect(statements.length, 1);
      expect(statements[0], isA<While>());
      final whileStmt = statements[0] as While;
      expect(whileStmt.condition, isA<Literal>());
      expect(whileStmt.body, isA<Block>());
    });

    test('parses for statement', () {
      final statements = parse('for (var i = 0; i < 10; i = i + 1) { print i; }');
      expect(statements.length, 1);
      expect(statements[0], isA<For>());
      final forStmt = statements[0] as For;
      expect(forStmt.initializer, isA<Var>());
      expect(forStmt.condition, isA<Binary>());
      expect(forStmt.increment, isA<Assign>());
      expect(forStmt.body, isA<Block>());
    });

    test('parses block', () {
      final statements = parse('{ var a = 1; print a; }');
      expect(statements.length, 1);
      expect(statements[0], isA<Block>());
      final block = statements[0] as Block;
      expect(block.statements.length, 2);
    });

    test('parses binary expression', () {
      final statements = parse('print 1 + 2;');
      expect(statements[0], isA<Print>());
      final printStmt = statements[0] as Print;
      expect(printStmt.expression, isA<Binary>());
      final binary = printStmt.expression as Binary;
      expect(binary.left, isA<Literal>());
      expect(binary.operation.type, TokenType.PLUS);
      expect(binary.right, isA<Literal>());
    });

    test('parses unary expression', () {
      final statements = parse('print -1;');
      final printStmt = statements[0] as Print;
      expect(printStmt.expression, isA<Unary>());
      final unary = printStmt.expression as Unary;
      expect(unary.operation.type, TokenType.MINUS);
      expect(unary.right, isA<Literal>());
    });

    test('parses call expression', () {
      final statements = parse('foo(1, 2);');
      final exprStmt = statements[0] as Expression;
      expect(exprStmt.expression, isA<Call>());
      final call = exprStmt.expression as Call;
      expect(call.callee, isA<Variable>());
      expect(call.arguments.length, 2);
    });

    test('parses list literal', () {
      final statements = parse('var a = [1, 2, 3];');
      final varStmt = statements[0] as Var;
      expect(varStmt.initializer, isA<ListLiteral>());
      final listLit = varStmt.initializer as ListLiteral;
      expect(listLit.elements.length, 3);
    });

    test('parses map literal', () {
      final statements = parse('var a = {"a": 1, "b": 2};');
      final varStmt = statements[0] as Var;
      expect(varStmt.initializer, isA<MapLiteral>());
      final mapLit = varStmt.initializer as MapLiteral;
      expect(mapLit.keys.length, 2);
      expect(mapLit.values.length, 2);
    });

    test('handles parse error and synchronizes', () {
      final lexer = Lexer('var a = 1; var b = ; var c = 2;'); // Error in middle statement
      final tokens = lexer.scan();
      final parser = Parser(tokens);
      final statements = parser.parse();

      expect(parser.hadError, isTrue);
      // specific behavior depends on how _synchronize works.
      // var a = 1; -> Parses correctly (1 stmt)
      // var b = ; -> Fails, consumes ';', synchronizes.
      // var c = 2; -> Should parse correctly (1 stmt)
      // Total statements: 2
      expect(statements.length, 2);
      expect((statements[0] as Var).name.lexeme, 'a');
      expect((statements[1] as Var).name.lexeme, 'c');
    });

    test('recovers from multiple errors', () {
      final source = '''
        print "first";
        print +; // Error 1
        print "second";
        var x = ; // Error 2
        print "third";
      ''';
      final statements = parse(source);

      // print "first" -> ok
      // print + -> error, sync
      // print "second" -> ok
      // var x = -> error, sync
      // print "third" -> ok

      // Note: "hadError" check is not available via `parse` helper,
      // but we can check the statements list length and content.
      expect(statements.length, 3);
      expect((statements[0] as Print).expression, isA<Literal>()); // "first"
      expect((statements[1] as Print).expression, isA<Literal>()); // "second"
      expect((statements[2] as Print).expression, isA<Literal>()); // "third"
    });
  });
}
