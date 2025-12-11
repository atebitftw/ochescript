import 'package:test/test.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/parser.dart';
import 'package:oche_script/src/compiler/compiler.dart';
import 'package:oche_script/src/runtime/vm.dart';
import 'package:oche_script/native_methods/string_methods.dart';

void main() {
  group('Ternary Expression', () {
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
        return null;
      });

      // Register extensions for tests
      registerStringExtensions();
    });

    Future<Map<String, Object>> run(String source) async {
      final lexer = Lexer(source);
      final tokens = lexer.scan();
      final parser = Parser(tokens);
      final statements = parser.parse();
      // Ensure we haven't broken basic parsing
      if (parser.hadError) {
        throw Exception("Parser error encountered");
      }
      final chunk = compiler.compile(statements);
      return await vm.interpret(chunk);
    }

    // =====================
    // DEBUGGING CONTROL
    // =====================

    group('Debugging Control', () {
      test('basic class with this works (control test)', () async {
        final result = await run("""
          class Test {
            init(val) {
              this.val = val;
            }
            getVal() {
              return this.val;
            }
          }
          var t = Test(123);
          out("result", t.getVal());
        """);
        expect(result['result'], equals(123));
      });
    });

    // =====================
    // BASIC TERNARY TESTS
    // =====================

    group('Basic', () {
      test('ternary with true condition returns then value', () async {
        final result = await run("""
          var x = true ? 1 : 2;
          out("result", x);
        """);
        expect(result['result'], equals(1));
      });

      test('ternary with false condition returns else value', () async {
        final result = await run("""
          var x = false ? 1 : 2;
          out("result", x);
        """);
        expect(result['result'], equals(2));
      });

      test('ternary with string values', () async {
        final result = await run("""
          var x = true ? "yes" : "no";
          out("result", x);
        """);
        expect(result['result'], equals("yes"));
      });

      test('ternary with numeric values', () async {
        final result = await run("""
          var x = false ? 100 : 200;
          out("result", x);
        """);
        expect(result['result'], equals(200));
      });
    });

    // =====================
    // COMPARISON CONDITIONS
    // =====================

    group('Comparison Conditions', () {
      test('ternary with greater than condition', () async {
        final result = await run("""
          var a = 5;
          var x = a > 3 ? "big" : "small";
          out("result", x);
        """);
        expect(result['result'], equals("big"));
      });

      test('ternary with less than condition', () async {
        final result = await run("""
          var a = 2;
          var x = a < 3 ? "small" : "big";
          out("result", x);
        """);
        expect(result['result'], equals("small"));
      });

      test('ternary with equality condition', () async {
        final result = await run("""
          var a = 5;
          var x = a == 5 ? "equal" : "not equal";
          out("result", x);
        """);
        expect(result['result'], equals("equal"));
      });

      test('ternary with inequality condition', () async {
        final result = await run("""
          var a = 5;
          var x = a != 5 ? "not equal" : "equal";
          out("result", x);
        """);
        expect(result['result'], equals("equal"));
      });

      test('ternary with greater than or equal condition', () async {
        final result = await run("""
          var a = 5;
          var x = a >= 5 ? "yes" : "no";
          out("result", x);
        """);
        expect(result['result'], equals("yes"));
      });

      test('ternary with less than or equal condition', () async {
        final result = await run("""
          var a = 5;
          var x = a <= 4 ? "yes" : "no";
          out("result", x);
        """);
        expect(result['result'], equals("no"));
      });
    });

    // =====================
    // LOGICAL CONDITIONS
    // =====================

    group('Logical Conditions', () {
      test('ternary with AND condition - both true', () async {
        final result = await run("""
          var a = true;
          var b = true;
          var x = a && b ? 1 : 2;
          out("result", x);
        """);
        expect(result['result'], equals(1));
      });

      test('ternary with AND condition - one false', () async {
        final result = await run("""
          var a = true;
          var b = false;
          var x = a && b ? 1 : 2;
          out("result", x);
        """);
        expect(result['result'], equals(2));
      });

      test('ternary with OR condition - one true', () async {
        final result = await run("""
          var a = false;
          var b = true;
          var x = a || b ? 1 : 2;
          out("result", x);
        """);
        expect(result['result'], equals(1));
      });

      test('ternary with OR condition - both false', () async {
        final result = await run("""
          var a = false;
          var b = false;
          var x = a || b ? 1 : 2;
          out("result", x);
        """);
        expect(result['result'], equals(2));
      });

      test('ternary with NOT condition', () async {
        final result = await run("""
          var a = false;
          var x = !a ? "yes" : "no";
          out("result", x);
        """);
        expect(result['result'], equals("yes"));
      });

      test('ternary with complex logical condition', () async {
        final result = await run("""
          var a = 5;
          var b = 10;
          var x = (a > 3 && b < 15) || false ? "pass" : "fail";
          out("result", x);
        """);
        expect(result['result'], equals("pass"));
      });
    });

    // =====================
    // NESTED TERNARY
    // =====================

    group('Nested Ternary', () {
      test('nested ternary in then branch', () async {
        final result = await run("""
          var a = true;
          var b = false;
          var x = a ? (b ? 1 : 2) : 3;
          out("result", x);
        """);
        expect(result['result'], equals(2));
      });

      test('nested ternary in else branch', () async {
        final result = await run("""
          var a = false;
          var b = true;
          var x = a ? 1 : (b ? 2 : 3);
          out("result", x);
        """);
        expect(result['result'], equals(2));
      });

      test('chained ternary (right-associative)', () async {
        // a ? b : c ? d : e should be a ? b : (c ? d : e)
        final result = await run("""
          var x = false ? 1 : true ? 2 : 3;
          out("result", x);
        """);
        expect(result['result'], equals(2));
      });

      test('deeply nested ternary', () async {
        final result = await run("""
          var a = 3;
          var x = a == 1 ? "one" : a == 2 ? "two" : a == 3 ? "three" : "other";
          out("result", x);
        """);
        expect(result['result'], equals("three"));
      });

      test('multiple levels of nesting', () async {
        final result = await run("""
          var a = true;
          var b = true;
          var c = false;
          var x = a ? (b ? (c ? 1 : 2) : 3) : 4;
          out("result", x);
        """);
        expect(result['result'], equals(2));
      });
    });

    // =====================
    // EXPRESSION CONTEXTS
    // =====================

    group('Expression Contexts', () {
      test('ternary in variable assignment', () async {
        final result = await run("""
          var cond = true;
          var x = cond ? 100 : 200;
          out("result", x);
        """);
        expect(result['result'], equals(100));
      });

      test('ternary in function arguments', () async {
        final result = await run("""
          fun add(a, b) { return a + b; }
          var cond = true;
          var x = add(cond ? 10 : 20, cond ? 5 : 15);
          out("result", x);
        """);
        expect(result['result'], equals(15));
      });

      test('ternary in return statement', () async {
        final result = await run("""
          fun check(x) {
            return x > 0 ? "positive" : "non-positive";
          }
          out("result", check(5));
        """);
        expect(result['result'], equals("positive"));
      });

      test('ternary with arithmetic expressions', () async {
        final result = await run("""
          var a = 5;
          var b = 3;
          var x = a > b ? a + b : a - b;
          out("result", x);
        """);
        expect(result['result'], equals(8));
      });

      test('ternary with function calls in branches', () async {
        final result = await run("""
          fun getA() { return 10; }
          fun getB() { return 20; }
          var cond = false;
          var x = cond ? getA() : getB();
          out("result", x);
        """);
        expect(result['result'], equals(20));
      });

      test('ternary in print statement', () async {
        // This tests that ternary works in expression context for print
        final result = await run("""
          var cond = true;
          out("result", cond ? "printed yes" : "printed no");
        """);
        expect(result['result'], equals("printed yes"));
      });
    });

    // =====================
    // SHORT-CIRCUIT BEHAVIOR
    // =====================

    group('Short-circuit Behavior', () {
      test('only then branch evaluated when condition true', () async {
        final result = await run("""
          var counter = 0;
          fun incAndReturn(val) {
            counter = counter + 1;
            return val;
          }
          var x = true ? incAndReturn(1) : incAndReturn(2);
          out("result", x);
          out("counter", counter);
        """);
        expect(result['result'], equals(1));
        expect(result['counter'], equals(1)); // Only one call was made
      });

      test('only else branch evaluated when condition false', () async {
        final result = await run("""
          var counter = 0;
          fun incAndReturn(val) {
            counter = counter + 1;
            return val;
          }
          var x = false ? incAndReturn(1) : incAndReturn(2);
          out("result", x);
          out("counter", counter);
        """);
        expect(result['result'], equals(2));
        expect(result['counter'], equals(1)); // Only one call was made
      });

      test('side effects only happen in evaluated branch', () async {
        final result = await run("""
          var a = 0;
          var b = 0;
          fun setA() { a = 100; return 1; }
          fun setB() { b = 200; return 2; }
          var x = true ? setA() : setB();
          out("result", x);
          out("a", a);
          out("b", b);
        """);
        expect(result['result'], equals(1));
        expect(result['a'], equals(100));
        expect(result['b'], equals(0)); // setB was not called
      });
    });

    // =====================
    // STRING INTERPOLATION
    // =====================

    group('String Interpolation', () {
      test('ternary inside string interpolation - true', () async {
        final result = await run(r'''
          var cond = true;
          var s = "Result: ${cond ? "yes" : "no"}";
          out("result", s);
        ''');
        expect(result['result'], equals("Result: yes"));
      });

      test('ternary inside string interpolation - false', () async {
        final result = await run(r'''
          var cond = false;
          var s = "Result: ${cond ? "yes" : "no"}";
          out("result", s);
        ''');
        expect(result['result'], equals("Result: no"));
      });

      test('ternary returning strings for concatenation', () async {
        final result = await run(r'''
          var a = 5;
          var s = "Value is " + (a > 3 ? "big" : "small");
          out("result", s);
        ''');
        expect(result['result'], equals("Value is big"));
      });

      test('ternary with string concatenation in branches', () async {
        final result = await run(r'''
          var name = "World";
          var greet = true;
          var s = greet ? "Hello, " + name + "!" : "Goodbye!";
          out("result", s);
        ''');
        expect(result['result'], equals("Hello, World!"));
      });

      test('complex string interpolation with ternary', () async {
        final result = await run(r'''
          var count = 5;
          var s = "You have ${count} ${count == 1 ? "item" : "items"}";
          out("result", s);
        ''');
        expect(result['result'], equals("You have 5 items"));
      });

      test('nested ternary in string interpolation', () async {
        final result = await run(r'''
          var n = 0;
          var s = "Number is ${n > 0 ? "positive" : n < 0 ? "negative" : "zero"}";
          out("result", s);
        ''');
        expect(result['result'], equals("Number is zero"));
      });

      test('ternary with numeric to string in interpolation', () async {
        final result = await run(r'''
          var x = 10;
          var s = "Value: ${x > 5 ? x : 0}";
          out("result", s);
        ''');
        expect(result['result'], equals("Value: 10"));
      });
    });

    // =====================
    // COMPLEX SCENARIOS
    // =====================

    group('Complex Scenarios', () {
      test('ternary with list access', () async {
        final result = await run("""
          var arr = [10, 20, 30];
          var idx = 1;
          var x = idx < 3 ? arr[idx] : 0;
          out("result", x);
        """);
        expect(result['result'], equals(20));
      });

      test('ternary with map access', () async {
        final result = await run("""
          var m = {"a": 1, "b": 2};
          var key = "b";
          var x = key == "a" ? m["a"] : m["b"];
          out("result", x);
        """);
        expect(result['result'], equals(2));
      });

      test('ternary with method calls', () async {
        final result = await run("""
          var s = "hello";
          var upper = true;
          var result = upper ? s.toUpper() : s.toLower();
          out("result", result);
        """);
        expect(result['result'], equals("HELLO"));
      });

      test('ternary in loop', () async {
        final result = await run("""
          var sum = 0;
          for (var i = 0; i < 5; i = i + 1) {
            sum = sum + (i % 2 == 0 ? i : 0);
          }
          out("result", sum);
        """);
        // 0 + 0 + 2 + 0 + 4 = 6
        expect(result['result'], equals(6));
      });

      test('ternary with class property', () async {
        final result = await run("""
          class Person {
            init(name, age) {
              this.name = name;
              this.age = age;
            }
            describe() {
              return this.age >= 18 ? "adult" : "minor";
            }
          }
          var p = Person("John", 25);
          out("result", p.describe());
        """);
        expect(result['result'], equals("adult"));
      });

      test('ternary returning different types', () async {
        // The language is dynamically typed, so this should work
        final result = await run("""
          var useString = true;
          var x = useString ? "hello" : 42;
          out("result", x);
        """);
        expect(result['result'], equals("hello"));
      });

      test('ternary with boolean results', () async {
        final result = await run("""
          var a = 5;
          var b = 10;
          var isValid = a < b ? true : false;
          out("result", isValid);
        """);
        expect(result['result'], equals(true));
      });
    });
  });
}
