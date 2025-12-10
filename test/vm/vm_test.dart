import 'package:test/test.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/parser.dart';
import 'package:oche_script/src/compiler/compiler.dart';
import 'package:oche_script/src/runtime/vm.dart';

void main() {
  group('VM', () {
    late BytecodeCompiler compiler;
    late VM vm;

    setUp(() {
      compiler = BytecodeCompiler();
      vm = VM();
      vm.defineNative("out", (args) {
        if (args.length != 2) {
          throw vm.reportRuntimeError(
            vm.getCurrentLine(),
            "out() requires name and value.",
          );
        }

        if (args[0] is! String) {
          throw vm.reportRuntimeError(
            vm.getCurrentLine(),
            "out() requires name to resolve to a string: ${args[0]}",
          );
        }

        final name = args[0] as String;
        final value = args[1];

        vm.setOutState(name, value);
        //outCallback!(name, value);
        return null;
      });
    });

    Future<Map<String, Object>> run(String source) async {
      final lexer = Lexer(source);
      final tokens = lexer.scan();
      final parser = Parser(tokens);
      final statements = parser.parse();
      final chunk = compiler.compile(statements);
      return await vm.interpret(chunk);
    }

    test('executes arithmetic', () async {
      final result = await run('''var a = 1 + 2; out("a", a);''');
      expect(result["a"], 3);
    });

    test('executes control flow', () async {
      final result = await run("""
        var a = 0;
        if (true) {
          a = 1;
        }
        var b = 0;
        if (false) {
          b = 1;
        }
        out("a", a);
        out("b", b);
      """);

      expect(result["a"], 1);
      expect(result["b"], 0);
    });

    test('executes loops', () async {
      final result = await run("""
        var i = 0;
        while (i < 5) {
          i = i + 1;
        }
        out("i", i);
      """);

      expect(result["i"], 5);
    });

    test('executes closures', () async {
      final result = await run("""
        var a = "global";
        {
          var b = "local";
          fun closure() {
            out("a", a);
            out("b", b);
          }
          closure();
        }
      """);

      expect(result["a"], "global");
      expect(result["b"], "local");
    });

    test('executes native functions', () async {
      vm.defineNative("nativeAdd", (args) {
        return args[0] + args[1];
      });

      final result = await run("""
        var result = nativeAdd(10, 20);
        out("result", result);
      """);

      expect(result["result"], 30);
    });

    test('executes simple class', () async {
      final result = await run("""
        class Foo {
          init(val) {
            this.value = val;
          }
          getValue() {
            return this.value;
          }
        }
        var f = Foo(42);
        out("value", f.getValue());
      """);

      expect(result["value"], 42);
    });

    test("add field after creation", () async {
      final result = await run("""
        class Foo {
          init(val) {
            this.value = val;
          }
        }
        var f = Foo(42);
        f.newField = "someValue";
        out("value", f.value);
        out("newField", f.newField);
      """);

      expect(result["value"], 42);
      expect(result["newField"], "someValue");
    });

    test('executes class inheritance', () async {
      final result = await run("""
        class Base {
          init(desc) {
            this.description = desc;
          }
        }
        class Derived extends Base {
          init() {
            super.init("test");
            this.description = "derived";
            this.amount = 42;
          }
        }
        var d = Derived();
        out("description", d.description);
        out("amount", d.amount);
      """);

      expect(result["description"], "derived");
      expect(result["amount"], 42);
    });
  });
}
