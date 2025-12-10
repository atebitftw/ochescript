import 'package:test/test.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/parser.dart';
import 'package:oche_script/src/compiler/compiler.dart';
import 'package:oche_script/src/runtime/vm.dart';
import 'package:oche_script/src/runtime/runtime_error.dart';

void main() {
  group('VM Missing Features Tests', () {
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

    test('access "fields" property on class instance', () async {
      final result = await run('''
        class Person {
          init(name, age) {
            this.name = name;
            this.age = age;
          }
        }
        var p = Person("Alice", 30);
        var fields = p.fields;
        var name = fields["name"];
        var age = fields["age"];
        
        out("name", name);
        out("age", age);
      ''');
      expect(result['name'], "Alice");
      expect(result['age'], 30);
    });

    test('modify "fields" property affects instance', () async {
      final result = await run('''
        class Person {
          init(name) {
            this.name = name;
          }
        }
        var p = Person("Alice");
        var fields = p.fields;
        fields["name"] = "Bob";
        
        out("name", p.name);
      ''');
      expect(result['name'], "Bob");
    });

    test('super method calls', () async {
      final result = await run('''
        class A {
          method() {
            return "A";
          }
        }
        class B extends A {
          method() {
            return "B " + super.method();
          }
        }
        var b = B();
        out("res", b.method());
      ''');
      expect(result['res'], "B A");
    });

    test('super.init calls', () async {
      final result = await run('''
        class A {
          init(val) {
            this.val = val;
          }
        }
        class B extends A {
          init(val) {
            super.init(val * 2);
          }
        }
        var b = B(10);
        out("val", b.val);
      ''');
      expect(result['val'], 20);
    });

    test('runtime error: list index out of bounds', () async {
      final result = await run('''
          var l = [1, 2, 3];
          var x = l[10];
        ''');
      expect(result.containsKey("error"), isTrue);
    });

    test('runtime error: map key not found', () async {
      final result = await run('''
          var m = {"a": 1};
          var x = m["b"];
        ''');
      expect(result.containsKey("error"), isTrue);
    });

    test('runtime error: wrong number of arguments', () async {
      final result = await run('''
          fun add(a, b) { return a + b; }
          add(1);
        ''');
      expect(result.containsKey("error"), isTrue);
    });

    test('runtime error: calling non-function', () async {
      final result = await run('''
          var x = 1;
          x();
        ''');
      expect(result.containsKey("error"), isTrue);
    });

    test('runtime error: accessing property on non-instance', () async {
      final result = await run('''
          var x = 1;
          var y = x.foo;
        ''');
      expect(result.containsKey("error"), isTrue);
    });

    test('continue in switch within loop', () async {
      final result = await run('''
        var i = 0;
        var sum = 0;
        while (i < 5) {
          i = i + 1;
          switch (i) {
            case 2:
              continue;
            default:
              // do nothing
          }
          sum = sum + i;
        }
        out("sum", sum);
      ''');
      expect(result['sum'], 13);
    });

    test('return value in init is ignored', () async {
      final result = await run('''
        class A {
          init() {
            return 123;
          }
        }
        var a = A();
        out("isA", a is A);
      ''');
      expect(result['isA'], true);
    });

    test('compile error: this outside class', () {
      expect(() async {
        await run('''
          fun foo() {
            print this;
          }
        ''');
      }, throwsA(isA<RuntimeError>()));
    });

    test('return at top level exits script', () async {
      final result = await run('''
        var a = 1;
        if (true) return;
        out("a", a);
      ''');
      expect(result.containsKey('a'), false);
    });
  });
}
