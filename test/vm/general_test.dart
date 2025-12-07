import 'package:test/test.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/parser.dart';
import 'package:oche_script/src/compiler/compiler.dart';
import 'package:oche_script/src/runtime/vm.dart';
import 'package:oche_script/native_methods/list_methods.dart' as list_methods;
import 'package:oche_script/native_methods/string_methods.dart' as string_methods;
import 'package:oche_script/native_methods/map_methods.dart' as map_methods;
import 'package:oche_script/native_methods/number_methods.dart' as number_methods;
import 'package:oche_script/native_methods/date_methods.dart' as date_methods;
import 'package:oche_script/native_methods/duration_methods.dart' as duration_methods;

void main() {
  group('VM General Interpreter Tests', () {
    late BytecodeCompiler compiler;
    late VM vm;

    setUp(() {
      list_methods.registerListExtensions();
      string_methods.registerStringExtensions();
      map_methods.registerMapExtensions();
      number_methods.registerNumberExtensions();
      date_methods.registerDateExtensions();
      duration_methods.registerDurationExtensions();
      compiler = BytecodeCompiler();
      vm = VM();
    });

    Future<Map<String, Object>> run(String source) async {
      final lexer = Lexer(source);
      final tokens = lexer.scan();
      final parser = Parser(tokens);
      final statements = parser.parse();
      final chunk = compiler.compile(statements);
      return await vm.interpret(chunk);
    }

    test('evaluates postfix increment', () async {
      final result = await run('var a = 1; a++; out("a", a);');
      expect(result['a'], 2);
    });

    test('evaluates postfix decrement', () async {
      final result = await run('var a = 1; a--; out("a", a);');
      expect(result['a'], 0);
    });

    test('evaluates arithmetic', () async {
      final result = await run('var a = 1 + 2 * 3; out("a", a);');
      expect(result['a'], 7);
    });

    test('evaluates prefix increment', () async {
      final result = await run('var a = 1; ++a; out("a", a);');
      expect(result['a'], 2);
    });

    test('evaluates prefix decrement', () async {
      final result = await run('var a = 1; --a; out("a", a);');
      expect(result['a'], 0);
    });

    test('evaluates string concatenation', () async {
      final result = await run('var a = "hello" + " " + "world"; out("a", a);');
      expect(result['a'], "hello world");
    });

    test('evaluates control flow (if/else)', () async {
      final result = await run('''
        var a = 0;
        if (true) {
          a = 1;
        } else {
          a = 2;
        }
        var b = 0;
        if (false) {
          b = 1;
        } else {
          b = 2;
        }
        out("a", a);
        out("b", b);
      ''');
      expect(result['a'], 1);
      expect(result['b'], 2);
    });

    test('evaluates while loop', () async {
      final result = await run('''
        var i = 0;
        while (i < 5) {
          i = i + 1;
        }
        out("i", i);
      ''');
      expect(result['i'], 5);
    });

    test('evaluates for loop', () async {
      final result = await run('''
        var sum = 0;
        for (var i = 0; i < 5; i = i + 1) {
          sum = sum + i;
        }
        out("sum", sum);
      ''');
      expect(result['sum'], 10); // 0+1+2+3+4
    });

    test('evaluates break', () async {
      final result = await run('''
        var sum = 0;
        for (var i = 0; i < 5; i = i + 1) {
          if (i == 3) break;
          sum = sum + i;
        }
        out("sum", sum);
      ''');
      expect(result['sum'], 3); // 0+1+2
    });

    test("evaluates loop with nested functions", () async {
      final result = await run('''
        var sum = 0;
        for (var i = 0; i < 5; i = i + 1) {
          fun add(a, b) {
            for (var j = 0; j < 5; j = j + 1) {
              for (var k = 0; k < 5; k = k + 1) {
                a = b + a;
              }
            }
            return a + b;
          }
          sum = sum + add(i, 1);
        }
        out("sum", sum);
      ''');
      expect(result['sum'], 140); // 0+1+2+3+4
    });

    test('evaluates functions', () async {
      final result = await run('''
        fun add(a, b) {
          return a + b;
        }
        var res = add(1, 2);
        out("res", res);
      ''');
      expect(result['res'], 3);
    });

    test('evaluates recursion', () async {
      final result = await run('''
        fun fib(n) {
          if (n <= 1) return n;
          return fib(n - 1) + fib(n - 2);
        }
        var res = fib(6);
        out("res", res);
      ''');
      expect(result['res'], 8);
    });

    test('evaluates closures', () async {
      final result = await run('''
        fun makeCounter() async {
          var i = 0;
          fun count() async {
            i = i + 1;
            return i;
          }
          return count;
        }
        var counter = makeCounter();
        var c1 = counter();
        var c2 = counter();
        out("c1", c1);
        out("c2", c2);
      ''');
      expect(result['c1'], 1);
      expect(result['c2'], 2);
    });

    test('evaluates classes', () async {
      final result = await run('''
        class Foo {
          bar() async {
            return "baz";
          }
        }
        var f = Foo();
        var res = f.bar();
        out("res", res);
      ''');
      expect(result['res'], "baz");
    });

    test('evaluates classes with multiple methods', () async {
      final result = await run('''
        class Person {
          init(name, age) {
            this.name = name;
            this.age = age;
          }
          
          greet() async {
            return "Hello, I'm " + this.name;
          }
          
          getAge() async {
            return this.age;
          }
          
          birthday() async {
            this.age = this.age + 1;
            return this.age;
          }
        }
        var p = Person("Alice", 30);
        var greeting = p.greet();
        var currentAge = p.getAge();
        var newAge = p.birthday();
        out("greeting", greeting);
        out("currentAge", currentAge);
        out("newAge", newAge);
      ''');
      expect(result['greeting'], "Hello, I'm Alice");
      expect(result['currentAge'], 30);
      expect(result['newAge'], 31);
    });

    test('evaluates class fields', () async {
      final result = await run('''
        class Foo {}
        var f = Foo();
        f.bar = 1;
        var res = f.bar;
        out("res", res);
      ''');
      expect(result['res'], 1);
    });

    test('evaluates break and continue', () async {
      final result = await run('''
        var sum = 0;
        for (var i = 0; i < 10; i = i + 1) {
          if (i == 5) continue;
          if (i == 8) break;
          sum = sum + i;
        }
        out("sum", sum);
      ''');
      // 0+1+2+3+4 (skip 5) +6+7 (break at 8)
      // = 23
      expect(result['sum'], 23);
    });

    test('evaluates nested function calls (regression fix)', () async {
      final result = await run('''
        var res = 0;
        fun main() async {
          test();
        }
        fun test() async {
          res = 1;
        }
        main();
        out("res", res);
      ''');
      expect(result['res'], 1);
    });

    test('evaluates list operations', () async {
      final result = await run('''
        var l = [1, 2, 3];
        l.add(4);
        var foo = l.length();
        var first = l[0];
        out("foo", foo);
        out("first", first);
      ''');
      expect(result['foo'], 4);
      expect(result['first'], 1);
    });

    test('evaluates map operations', () async {
      final result = await run('''
        var m = {"a": 1};
        m["b"] = 2;
        var valA = m["a"];
        var valB = m["b"];
        out("valA", valA);
        out("valB", valB);
      ''');
      expect(result['valA'], 1);
      expect(result['valB'], 2);
    });

    test('evaluates map and length with async', () async {
      final result = await run('''
        fun transform(k) { return k; }
        var l = ["a", "b"];
        var mapped = await l.map(transform);
        var len = mapped.length();
        out("len", len);
      ''');
      expect(result['len'], 2);
    });

    test('evaluates models logic', () async {
      final result = await run('''
         var data = {"a": 1, "b": 2};
         var keys = data.keys();
         var transformedKeys = await keys.map(fun(key) { return key + "_x"; });
         var len = transformedKeys.length();
         out("len", len);
       ''');
      expect(result['len'], 2);
    });

    // =========================================================================
    // STRESS TESTS - Deeply nested structures, combinations, and edge cases
    // =========================================================================

    group('Stress Tests - Nesting', () {
      test('deeply nested if-else chains', () async {
        final result = await run('''
          var result = 0;
          var x = 5;
          if (x > 0) {
            if (x > 2) {
              if (x > 4) {
                if (x > 6) {
                  result = 1;
                } else {
                  if (x == 5) {
                    result = 2;
                  } else {
                    result = 3;
                  }
                }
              } else {
                result = 4;
              }
            } else {
              result = 5;
            }
          } else {
            result = 6;
          }
          out("result", result);
        ''');
        expect(result['result'], 2);
      });

      test('deeply nested for loops', () async {
        final result = await run('''
          var count = 0;
          for (var i = 0; i < 3; i = i + 1) {
            for (var j = 0; j < 3; j = j + 1) {
              for (var k = 0; k < 3; k = k + 1) {
                for (var l = 0; l < 2; l = l + 1) {
                  count = count + 1;
                }
              }
            }
          }
          out("count", count);
        ''');
        expect(result['count'], 54); // 3 * 3 * 3 * 2
      });

      test('nested loops with mixed break/continue', () async {
        final result = await run('''
          var sum = 0;
          for (var i = 0; i < 5; i = i + 1) {
            for (var j = 0; j < 5; j = j + 1) {
              if (j == 2) continue;
              if (j == 4) break;
              for (var k = 0; k < 3; k = k + 1) {
                if (k == 1) continue;
                sum = sum + 1;
              }
            }
          }
          out("sum", sum);
        ''');
        // For each i (0-4): j iterates 0,1,3 (skip 2, break at 4)
        // For each valid j: k iterates 0,2 (skip 1)
        // = 5 * 3 * 2 = 30
        expect(result['sum'], 30);
      });

      test('deeply nested function calls', () async {
        final result = await run('''
          fun level1(x) {
            fun level2(y) {
              fun level3(z) {
                fun level4(w) {
                  return w * 2;
                }
                return level4(z) + 1;
              }
              return level3(y) * 2;
            }
            return level2(x) + x;
          }
          var res = level1(5);
          out("res", res);
        ''');
        // level4(5) = 10
        // level3(5) = 10 + 1 = 11
        // level2(5) = 11 * 2 = 22
        // level1(5) = 22 + 5 = 27
        expect(result['res'], 27);
      });

      test('nested closures capturing variables at different levels', () async {
        final result = await run('''
          fun outer(a) async {
            var x = a;
            fun middle(b) async {
              var y = b;
              fun inner(c) async {
                return x + y + c;
              }
              return inner;
            }
            return middle;
          }
          var m = outer(10);
          var i = m(20);
          var res = i(30);
          out("res", res);
        ''');
        expect(result['res'], 60); // 10 + 20 + 30
      });
    });

    group('Stress Tests - Complex Combinations', () {
      test('closures with loops and state mutation', () async {
        final result = await run('''
          fun makeAccumulator(initial) async {
            var total = initial;
            fun add(n) async {
              total = total + n;
              return total;
            }
            return add;
          }
          
          var acc = makeAccumulator(0);
          var sum = 0;
          for (var i = 1; i <= 5; i = i + 1) {
            sum = acc(i);
          }
          out("sum", sum);
        ''');
        expect(result['sum'], 15); // 1+2+3+4+5
      });

      test('recursive function with closure state', () async {
        final result = await run('''
          fun makeCounter() async {
            var count = 0;
            fun increment() async {
              count = count + 1;
              return count;
            }
            return increment;
          }
          
          fun recursiveCall(counter, n) async {
            if (n <= 0) return counter();
            counter();
            return recursiveCall(counter, n - 1);
          }
          
          var c = makeCounter();
          var res = recursiveCall(c, 5);
          out("res", res);
        ''');
        expect(result['res'], 6); // Called 6 times (5 recursive + 1 base case)
      });

      test('class methods calling closures', () async {
        final result = await run('''
          class Calculator {
            init(base) {
              this.base = base;
            }
            
            compute(operation) async {
              return operation(this.base);
            }
          }
          
          var calc = Calculator(10);
          var double = fun(x) { return x * 2; };
          var square = fun(x) { return x * x; };
          var addTen = fun(x) { return x + 10; };
          
          var r1 = calc.compute(double);
          var r2 = calc.compute(square);
          var r3 = calc.compute(addTen);
          
          out("r1", r1);
          out("r2", r2);
          out("r3", r3);
        ''');
        expect(result['r1'], 20);
        expect(result['r2'], 100);
        expect(result['r3'], 20);
      });

      test('mutual recursion between functions', () async {
        final result = await run('''
          fun isEven(n) {
            if (n == 0) return true;
            return isOdd(n - 1);
          }
          
          fun isOdd(n) {
            if (n == 0) return false;
            return isEven(n - 1);
          }
          
          out("even4", isEven(4));
          out("even5", isEven(5));
          out("odd3", isOdd(3));
          out("odd4", isOdd(4));
        ''');
        expect(result['even4'], true);
        expect(result['even5'], false);
        expect(result['odd3'], true);
        expect(result['odd4'], false);
      });

      test('classes with recursive methods', () async {
        final result = await run('''
          class TreeNode {
            init(value) {
              this.value = value;
              this.children = [];
            }
            
            addChild(child) async {
              this.children.add(child);
            }
            
            countNodes() async {
              var count = 1;
              var i = 0;
              while (i < this.children.length()) {
                count = count + this.children[i].countNodes();
                i = i + 1;
              }
              return count;
            }
          }
          
          var root = TreeNode(1);
          var child1 = TreeNode(2);
          var child2 = TreeNode(3);
          var grandchild = TreeNode(4);
          
          root.addChild(child1);
          root.addChild(child2);
          child1.addChild(grandchild);
          
          var total = root.countNodes();
          out("total", total);
        ''');
        expect(result['total'], 4);
      });

      test('complex list transformations with closures', () async {
        final result = await run('''
          var numbers = [1, 2, 3, 4, 5];
          
          // Double each number
          var doubled = await numbers.map(fun(n) { return n * 2; });
          
          // Filter even numbers
          var evens = await doubled.filter(fun(n) { return n > 4; });
          
          // Sum up
          var sum = 0;
          var i = 0;
          while (i < evens.length()) {
            sum = sum + evens[i];
            i = i + 1;
          }
          
          out("sum", sum);
        ''');
        // doubled = [2, 4, 6, 8, 10]
        // evens = [6, 8, 10] (those > 4)
        // sum = 24
        expect(result['sum'], 24);
      });
    });

    group('Stress Tests - Edge Cases', () {
      test('empty loops execute correctly', () async {
        final result = await run('''
          var count = 0;
          for (var i = 0; i < 0; i = i + 1) {
            count = count + 1;
          }
          
          var j = 10;
          while (j < 5) {
            count = count + 1;
            j = j + 1;
          }
          
          out("count", count);
        ''');
        expect(result['count'], 0);
      });

      test('single iteration loops', () async {
        final result = await run('''
          var sum = 0;
          for (var i = 0; i < 1; i = i + 1) {
            sum = sum + 10;
          }
          
          var j = 0;
          while (j < 1) {
            sum = sum + 5;
            j = j + 1;
          }
          
          out("sum", sum);
        ''');
        expect(result['sum'], 15);
      });

      test('deeply chained arithmetic expressions', () async {
        final result = await run('''
          var a = 1;
          var b = 2;
          var c = 3;
          var d = 4;
          var e = 5;
          
          var res = ((a + b) * (c + d) - e) / 2 + (a * b * c * d * e) / 10;
          out("res", res);
        ''');
        // ((1+2) * (3+4) - 5) / 2 + (1*2*3*4*5) / 10
        // (3 * 7 - 5) / 2 + 120 / 10
        // (21 - 5) / 2 + 12
        // 16 / 2 + 12
        // 8 + 12 = 20
        expect(result['res'], 20);
      });

      test('complex boolean expressions', () async {
        final result = await run('''
          var a = true;
          var b = false;
          var c = true;
          var d = false;
          
          var r1 = (a && b) || (c && !d);
          var r2 = !(a && b) && (c || d);
          var r3 = ((a || b) && (c || d)) && !(b && d);
          
          out("r1", r1);
          out("r2", r2);
          out("r3", r3);
        ''');
        expect(result['r1'], true); // false || true
        expect(result['r2'], true); // true && true
        expect(result['r3'], true); // true && true
      });

      test('function with many parameters', () async {
        final result = await run('''
          fun multiParam(a, b, c, d, e, f, g, h) {
            return a + b + c + d + e + f + g + h;
          }
          
          var sum = multiParam(1, 2, 3, 4, 5, 6, 7, 8);
          out("sum", sum);
        ''');
        expect(result['sum'], 36);
      });

      test('long chain of method calls', () async {
        final result = await run('''
          class Builder {
            init() {
              this.value = 0;
            }
            
            add(n) async {
              this.value = this.value + n;
              return this;
            }
            
            multiply(n) async {
              this.value = this.value * n;
              return this;
            }
            
            subtract(n) async {
              this.value = this.value - n;
              return this;
            }
            
            get() async {
              return this.value;
            }
          }
          
          var b = Builder();
          b.add(5);
          b.multiply(3);
          b.add(2);
          b.subtract(1);
          var res = b.get();
          
          out("res", res);
        ''');
        // 0 + 5 = 5, * 3 = 15, + 2 = 17, - 1 = 16
        expect(result['res'], 16);
      });

      test('string operations stress test', () async {
        final result = await run('''
          var s = "";
          for (var i = 0; i < 10; i = i + 1) {
            s = s + "a";
          }
          var len = s.length();
          
          var parts = s.split("");
          var partCount = parts.length();
          
          out("len", len);
          out("partCount", partCount);
        ''');
        expect(result['len'], 10);
        expect(result['partCount'], 10);
      });

      test('nested map and list operations', () async {
        final result = await run('''
          var data = {
            "users": [
              {"name": "Alice", "age": 30},
              {"name": "Bob", "age": 25}
            ],
            "count": 2
          };
          
          var users = data["users"];
          var first = users[0];
          var name = first["name"];
          var count = data["count"];
          
          out("name", name);
          out("count", count);
        ''');
        expect(result['name'], "Alice");
        expect(result['count'], 2);
      });

      test('multiple closures sharing same environment', () async {
        final result = await run('''
          fun makeOps() async {
            var x = 0;
            
            fun increment() async { x = x + 1; return x; }
            fun decrement() async { x = x - 1; return x; }
            fun double() async { x = x * 2; return x; }
            fun get() async { return x; }
            
            return [increment, decrement, double, get];
          }
          
          var ops = makeOps();
          var inc = ops[0];
          var dec = ops[1];
          var dbl = ops[2];
          var get = ops[3];
          
          inc();  // x = 1
          inc();  // x = 2
          inc();  // x = 3
          dbl();  // x = 6
          dec();  // x = 5
          
          var final = get();
          out("final", final);
        ''');
        expect(result['final'], 5);
      });
    });

    group('Stress Tests - Performance Scenarios', () {
      test('fibonacci stress test (recursive)', () async {
        final result = await run('''
          fun fib(n) {
            if (n <= 1) return n;
            return fib(n - 1) + fib(n - 2);
          }
          
          var res = fib(15);
          out("res", res);
        ''');
        expect(result['res'], 610);
      });

      test('factorial stress test', () async {
        final result = await run('''
          fun factorial(n) {
            if (n <= 1) return 1;
            return n * factorial(n - 1);
          }
          
          var res = factorial(10);
          out("res", res);
        ''');
        expect(result['res'], 3628800);
      });

      test('many variables in scope', () async {
        final result = await run('''
          var v1 = 1; var v2 = 2; var v3 = 3; var v4 = 4; var v5 = 5;
          var v6 = 6; var v7 = 7; var v8 = 8; var v9 = 9; var v10 = 10;
          var v11 = 11; var v12 = 12; var v13 = 13; var v14 = 14; var v15 = 15;
          var v16 = 16; var v17 = 17; var v18 = 18; var v19 = 19; var v20 = 20;
          
          var sum = v1 + v2 + v3 + v4 + v5 + v6 + v7 + v8 + v9 + v10 +
                    v11 + v12 + v13 + v14 + v15 + v16 + v17 + v18 + v19 + v20;
          out("sum", sum);
        ''');
        expect(result['sum'], 210);
      });

      test('class with many methods', () async {
        final result = await run('''
          class ManyMethods {
            init() {
              this.value = 0;
            }
            
            m1() async { this.value = this.value + 1; return this.value; }
            m2() async { this.value = this.value + 2; return this.value; }
            m3() async { this.value = this.value + 3; return this.value; }
            m4() async { this.value = this.value + 4; return this.value; }
            m5() async { this.value = this.value + 5; return this.value; }
            m6() async { this.value = this.value + 6; return this.value; }
            m7() async { this.value = this.value + 7; return this.value; }
            m8() async { this.value = this.value + 8; return this.value; }
            m9() async { this.value = this.value + 9; return this.value; }
            m10() async { this.value = this.value + 10; return this.value; }
          }
          
          var obj = ManyMethods();
          obj.m1(); obj.m2(); obj.m3(); obj.m4(); obj.m5();
          obj.m6(); obj.m7(); obj.m8(); obj.m9(); obj.m10();
          
          out("value", obj.value);
        ''');
        expect(result['value'], 55);
      });

      test('deeply nested list access', () async {
        final result = await run('''
          var nested = [[[1, 2], [3, 4]], [[5, 6], [7, 8]]];
          
          var v1 = nested[0][0][0];
          var v2 = nested[0][0][1];
          var v3 = nested[0][1][0];
          var v4 = nested[1][1][1];
          
          var sum = v1 + v2 + v3 + v4;
          out("sum", sum);
        ''');
        expect(result['sum'], 14); // 1 + 2 + 3 + 8
      });

      test('loop with conditional function calls', () async {
        final result = await run('''
          fun double(x) { return x * 2; }
          fun triple(x) { return x * 3; }
          fun square(x) { return x * x; }
          
          var sum = 0;
          for (var i = 1; i <= 10; i = i + 1) {
            if (i % 3 == 0) {
              sum = sum + triple(i);
            } else {
              if (i % 2 == 0) {
                sum = sum + double(i);
              } else {
                sum = sum + square(i);
              }
            }
          }
          out("sum", sum);
        ''');
        // i=1: square(1) = 1
        // i=2: double(2) = 4
        // i=3: triple(3) = 9
        // i=4: double(4) = 8
        // i=5: square(5) = 25
        // i=6: triple(6) = 18
        // i=7: square(7) = 49
        // i=8: double(8) = 16
        // i=9: triple(9) = 27
        // i=10: double(10) = 20
        // sum = 1+4+9+8+25+18+49+16+27+20 = 177
        expect(result['sum'], 177);
      });
    });

    group('Stress Tests - Advanced Patterns', () {
      test('closure factory pattern', () async {
        final result = await run('''
          fun createMultiplier(factor) async {
            return fun(x) { return x * factor; };
          }
          
          var double = createMultiplier(2);
          var triple = createMultiplier(3);
          var quadruple = createMultiplier(4);
          
          var sum = double(5) + triple(5) + quadruple(5);
          out("sum", sum);
        ''');
        expect(result['sum'], 45); // 10 + 15 + 20
      });

      test('state machine pattern', () async {
        final result = await run('''
          class StateMachine {
            init() {
              this.state = "idle";
              this.history = [];
            }
            
            transition(newState) async {
              this.history.add(this.state);
              this.state = newState;
            }
            
            getHistoryLength() async {
              return this.history.length();
            }
          }
          
          var sm = StateMachine();
          sm.transition("running");
          sm.transition("paused");
          sm.transition("running");
          sm.transition("stopped");
          
          out("state", sm.state);
          out("histLen", sm.getHistoryLength());
        ''');
        expect(result['state'], "stopped");
        expect(result['histLen'], 4);
      });

      test('composition of async functions', () async {
        final result = await run('''
          async fun addOne(x) { return x + 1; }
          async fun double(x) { return x * 2; }
          async fun square(x) { return x * x; }
          
          async fun compose(value) {
            var step1 = await addOne(value);
            var step2 = await double(step1);
            var step3 = await square(step2);
            return step3;
          }
          
          var res = compose(3);
          out("res", res);
        ''');
        // addOne(3) = 4, double(4) = 8, square(8) = 64
        expect(result['res'], 64);
      });

      test('complex conditional chains with functions', () async {
        final result = await run('''
          fun classify(n) {
            if (n < 0) {
              return "negative";
            } else {
              if (n == 0) {
                return "zero";
              } else {
                if (n < 10) {
                  return "single";
                } else {
                  if (n < 100) {
                    return "double";
                  } else {
                    return "large";
                  }
                }
              }
            }
          }
          
          out("c1", classify(-5));
          out("c2", classify(0));
          out("c3", classify(7));
          out("c4", classify(42));
          out("c5", classify(999));
        ''');
        expect(result['c1'], "negative");
        expect(result['c2'], "zero");
        expect(result['c3'], "single");
        expect(result['c4'], "double");
        expect(result['c5'], "large");
      });

      test('iterative vs recursive equivalence', () async {
        final result = await run('''
          fun sumIterative(n) {
            var sum = 0;
            for (var i = 1; i <= n; i = i + 1) {
              sum = sum + i;
            }
            return sum;
          }
          
          fun sumRecursive(n) {
            if (n <= 0) return 0;
            return n + sumRecursive(n - 1);
          }
          
          var iterResult = sumIterative(100);
          var recurResult = sumRecursive(100);
          
          out("iterative", iterResult);
          out("recursive", recurResult);
          out("equal", iterResult == recurResult);
        ''');
        expect(result['iterative'], 5050);
        expect(result['recursive'], 5050);
        expect(result['equal'], true);
      });

      test('ternary-like conditional expression pattern', () async {
        final result = await run('''
          fun ternary(cond, then, otherwise) {
            if (cond) {
              return then;
            } else {
              return otherwise;
            }
          }
          
          var r1 = ternary(true, "yes", "no");
          var r2 = ternary(false, "yes", "no");
          var r3 = ternary(5 > 3, 100, 200);
          
          out("r1", r1);
          out("r2", r2);
          out("r3", r3);
        ''');
        expect(result['r1'], "yes");
        expect(result['r2'], "no");
        expect(result['r3'], 100);
      });

      test('deeply chained mixed-type indexing', () async {
        final result = await run('''
          // Structure: list -> map -> map -> list -> list -> string
          var data = [
            {
              "level1": {
                "items": [
                  ["alpha", "beta", "gamma"],
                  ["delta", "epsilon", "zeta"]
                ],
                "meta": {
                  "nested": [
                    {"value": "deep1"},
                    {"value": "deep2"}
                  ]
                }
              },
              "other": "skip"
            },
            {
              "level1": {
                "items": [
                  ["one", "two", "three"],
                  ["four", "five", "six"]
                ]
              }
            }
          ];
          
          // list[0] -> map["level1"] -> map["items"] -> list[0] -> list[2] -> string
          var r1 = data[0]["level1"]["items"][0][2];
          
          // list[0] -> map["level1"] -> map["items"] -> list[1] -> list[0] -> string
          var r2 = data[0]["level1"]["items"][1][0];
          
          // list[1] -> map["level1"] -> map["items"] -> list[1] -> list[2] -> string
          var r3 = data[1]["level1"]["items"][1][2];
          
          // list[0] -> map["level1"] -> map["meta"] -> map["nested"] -> list[1] -> map["value"] -> string
          var r4 = data[0]["level1"]["meta"]["nested"][1]["value"];
          
          // String method on deeply accessed value (need intermediate var)
          var r5 = data[0]["level1"]["items"][0][0].toUpper();
          var r6 = data[0]["level1"]["items"][0][0].length();
          
          out("r1", r1);
          out("r2", r2);
          out("r3", r3);
          out("r4", r4);
          out("r5", r5);
          out("r6", r6);
        ''');
        expect(result['r1'], "gamma");
        expect(result['r2'], "delta");
        expect(result['r3'], "six");
        expect(result['r4'], "deep2");
        expect(result['r5'], "ALPHA");
        expect(result['r6'], 5);
      });

      test('chained indexing with intermediate variables', () async {
        final result = await run('''
          var root = {
            "users": [
              {
                "name": "Alice",
                "addresses": [
                  {"city": "NYC", "zip": ["10001", "10002"]},
                  {"city": "LA", "zip": ["90001"]}
                ]
              },
              {
                "name": "Bob",
                "addresses": [
                  {"city": "Chicago", "zip": ["60601", "60602", "60603"]}
                ]
              }
            ]
          };
          
          // Direct deep access
          var zip1 = root["users"][0]["addresses"][0]["zip"][1];
          
          // Step-by-step access
          var users = root["users"];
          var bob = users[1];
          var addrs = bob["addresses"];
          var chicago = addrs[0];
          var zips = chicago["zip"];
          var zip2 = zips[2];
          
          // Mixed: partial chain then continue
          var aliceAddrs = root["users"][0]["addresses"];
          var laZip = aliceAddrs[1]["zip"][0];
          
          out("zip1", zip1);
          out("zip2", zip2);
          out("laZip", laZip);
        ''');
        expect(result['zip1'], "10002");
        expect(result['zip2'], "60603");
        expect(result['laZip'], "90001");
      });

      test('chained indexing with dynamic keys', () async {
        final result = await run('''
          var data = {
            "a": {"x": 1, "y": 2},
            "b": {"x": 3, "y": 4},
            "c": {"x": 5, "y": 6}
          };
          
          var keys = ["a", "b", "c"];
          var fields = ["x", "y"];
          
          var sum = 0;
          for (var i = 0; i < keys.length(); i = i + 1) {
            for (var j = 0; j < fields.length(); j = j + 1) {
              var key = keys[i];
              var field = fields[j];
              sum = sum + data[key][field];
            }
          }
          
          out("sum", sum);
        ''');
        // (1+2) + (3+4) + (5+6) = 21
        expect(result['sum'], 21);
      });
    });
  });
}
