import 'package:test/test.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/parser.dart';
import 'package:oche_script/src/compiler/compiler.dart';
import 'package:oche_script/src/runtime/vm.dart';

void main() {
  group('VM Error Handling', () {
    late BytecodeCompiler compiler;
    late VM vm;

    setUp(() {
      compiler = BytecodeCompiler();
      vm = VM();
    });

    Future<Map<String, Object>> run(String source) async {
      // Helper to easily run code and get the result map which contains errors
      final lexer = Lexer(source);
      final tokens = lexer.scan();
      final parser = Parser(tokens);
      final statements = parser.parse();
      final chunk = compiler.compile(statements);
      return await vm.interpret(chunk);
    }

    test('Accessing undefined variable throws error', () async {
      final result = await run('out("val", undefinedVariable);');
      expect(
        result["error"],
        contains("Undefined variable 'undefinedVariable'"),
      );
    });

    test('Adding invalid types throws error', () async {
      final result = await run('var a = 1 + true;');
      expect(result["error"], contains("ADD: Invalid operands"));
    });

    test('Subtracting invalid types throws error', () async {
      final result = await run('var a = "string" - 1;');
      expect(result["error"], contains("SUBTRACT: Invalid operands"));
    });

    test('Bitwise operations with non-integers throw error', () async {
      final result = await run('var a = 1.5 & 2;');
      expect(result["error"], contains("Operands must be integers"));
    });

    test('List index out of bounds throws error', () async {
      final result = await run('''
        var l = [1, 2, 3];
        var a = l[10];
      ''');
      expect(result["error"], contains("List index out of bounds"));
    });

    test('List index must be integer', () async {
      final result = await run('''
        var l = [1, 2, 3];
        var a = l["1"];
      ''');
      expect(result["error"], contains("List index must be an integer"));
    });

    test('Map key not found throws error', () async {
      final result = await run('''
        var m = {"a": 1};
        var val = m["b"];
      ''');
      expect(result["error"], contains("Map key 'b' not found"));
    });

    test('Accessing property on non-instance throws error', () async {
      final result = await run('var a = "string".someProperty;');
      expect(result["error"], contains("Only instances have properties"));
    });

    test('Accessing undefined property on instance throws error', () async {
      final result = await run('''
        class Foo {}
        var f = Foo();
        var val = f.bar;
      ''');
      expect(result["error"], contains("Undefined property 'bar'"));
    });

    test('Call function with wrong number of arguments', () async {
      final result = await run('''
        fun foo(a, b) {}
        foo(1);
      ''');
      expect(result["error"], contains("Expected 2 arguments but got 1"));
    });

    test('Inherit from non-class throws error', () async {
      final result = await run('''
        var NotAClass = "string";
        class Foo extends NotAClass {}
      ''');
      expect(result["error"], contains("Superclass must be a class"));
    });

    test('Operand must be a number for increment', () async {
      // Wrapped in a block to ensure 'a' is a local variable, triggering INC_LOCAL optimization
      final result = await run('''
        {
          var a = "string";
          a++;
        }
      ''');
      expect(result["error"], contains("Operand must be a number"));
    });

    test('Invalid type operand for is check', () async {
      final result = await run('''
         var type = 123;
         var res = "test" is type;
       ''');
      expect(result["error"], contains("Invalid type operand for 'is'"));
    });
  });
}
