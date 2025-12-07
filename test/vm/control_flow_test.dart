import 'package:test/test.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/parser.dart';
import 'package:oche_script/src/compiler/compiler.dart';

import 'package:oche_script/src/runtime/vm.dart';

void main() {
  group('Bytecode VM Control Flow', () {
    late BytecodeCompiler compiler;
    late VM vm;

    setUp(() {
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

    test('For loop', () async {
      final result = await run("""
        var sum = 0;
        for (var i = 0; i < 5; i = i + 1) {
          sum = sum + i;
        }
        out("sum", sum);
      """);
      expect(result['sum'], equals(10));
    });

    test('For loop with break', () async {
      final result = await run("""
        var sum = 0;
        for (var i = 0; i < 10; i = i + 1) {
          if (i == 5) break;
          sum = sum + i;
        }
        out("sum", sum);
      """);
      expect(result['sum'], equals(10)); // 0+1+2+3+4
    });

    test('For loop with continue', () async {
      final result = await run("""
        var sum = 0;
        for (var i = 0; i < 5; i = i + 1) {
          if (i == 2) continue;
          sum = sum + i;
        }
        out("sum", sum);
      """);
      expect(result['sum'], equals(8)); // 0+1+3+4 = 8
    });

    test('While loop with break', () async {
      final result = await run("""
        var i = 0;
        while (true) {
          if (i == 3) break;
          i = i + 1;
        }
        out("i", i);
      """);
      expect(result['i'], equals(3));
    });

    test('Switch statement', () async {
      final result = await run("""
        var a = 2;
        var res = "";
        switch (a) {
          case 1:
            res = "one";
            break;
          case 2:
            res = "two";
            break;
          case 3:
            res = "three";
            break;
          default:
            res = "other";
        }
        out("res", res);
      """);
      expect(result['res'], equals("two"));
    });

    test('Switch default', () async {
      final result = await run("""
        var a = 5;
        var res = "";
        switch (a) {
          case 1:
            res = "one";
          default:
            res = "other";
        }
        out("res", res);
      """);
      expect(result['res'], equals("other"));
    });

    test('Nested loops with break', () async {
      final result = await run("""
         var sum = 0;
         for (var i = 0; i < 3; i = i + 1) {
           for (var j = 0; j < 3; j = j + 1) {
             if (j == 1) break;
             sum = sum + 1;
           }
         }
         out("sum", sum);
       """);
      // i=0: j=0 (sum=1), j=1 (break)
      // i=1: j=0 (sum=2), j=1 (break)
      // i=2: j=0 (sum=3), j=1 (break)
      expect(result['sum'], equals(3));
    });

    test('Switch with break', () async {
      final result = await run("""
        var fruit = "apple";
        var result = "";
        switch(fruit) {
          case "apple":
            result = "apple";
            break;
          case "banana":
            result = "banana";
            break;
          default:
            result = "default";
        }
        out("result", result);
      """);
      expect(result['result'], equals("apple"));
    });

    test('Switch with multiple breaks', () async {
      final result = await run("""
        var n = 1;
        var result = "";
        switch(n) {
          case 0:
            result = "zero";
            break;
          case 1:
            result = "one";
            break;
          case 2:
            result = "two";
            break;
          default:
            result = "default";
        }
        out("result", result);
      """);
      expect(result['result'], equals("one"));
    });

    test('Switch fallthrough', () async {
      final result = await run("""
        var a = 0;
        var count = 0;
        switch(a) {
          case 0:
            count = count + 1;
          case 1:
            count = count + 1;
            break;
          case 2:
            count = count + 1;
        }
        out("count", count);
      """);
      // a=0 matches case 0: count becomes 1
      // Falls through to case 1: count becomes 2
      // Break exits
      expect(result['count'], equals(2));
    });

    test('Switch fallthrough to default', () async {
      final result = await run("""
        var a = 2;
        var count = 0;
        switch(a) {
          case 0:
            count = count + 1;
            break;
          case 2:
            count = count + 10;
          default:
            count = count + 100;
        }
        out("count", count);
      """);
      // a=2 matches case 2: count becomes 10
      // Falls through to default: count becomes 110
      expect(result['count'], equals(110));
    });

    test('Prefix increment', () async {
      final result = await run("""
        var a = 1;
        var b = ++a;
        out("a", a);
        out("b", b);
      """);
      expect(result['a'], equals(2));
      expect(result['b'], equals(2)); // prefix returns new value
    });

    test('Prefix decrement', () async {
      final result = await run("""
        var a = 5;
        var b = --a;
        out("a", a);
        out("b", b);
      """);
      expect(result['a'], equals(4));
      expect(result['b'], equals(4)); // prefix returns new value
    });

    test('Postfix vs Prefix increment', () async {
      final result = await run("""
        var a = 1;
        var b = a++;
        out("postfix_a", a);
        out("postfix_b", b);
        
        var c = 1;
        var d = ++c;
        out("prefix_c", c);
        out("prefix_d", d);
      """);
      expect(result['postfix_a'], equals(2));
      expect(result['postfix_b'], equals(1)); // postfix returns old value
      expect(result['prefix_c'], equals(2));
      expect(result['prefix_d'], equals(2)); // prefix returns new value
    });

    test('Nested switch statements', () async {
      final result = await run("""
        var x = 1;
        var y = 2;
        var res = "";
        switch (x) {
          case 1:
            switch (y) {
              case 2:
                res = "nested match";
                break;
              default:
                res = "nested default";
            }
            break;
          default:
            res = "outer default";
        }
        out("res", res);
      """);
      expect(result['res'], equals("nested match"));
    });

    test('Switch in closure', () async {
      final result = await run("""
        var f = fun(x) {
          var res = "";
          switch (x) {
            case 10:
              res = "ten";
              break;
            default:
              res = "other";
          }
          return res;
        };
        var val = f(10);
        out("val", val);
      """);
      expect(result['val'], equals("ten"));
    });

    test('Switch in loop', () async {
      final result = await run("""
        var sum = 0;
        for (var i = 0; i < 3; i = i + 1) {
          switch (i) {
            case 0:
              sum = sum + 1;
              break;
            case 1:
              sum = sum + 2;
              break;
            case 2:
              sum = sum + 3;
              break;
          }
        }
        out("sum", sum);
      """);
      expect(result['sum'], equals(6)); // 1 + 2 + 3
    });
  });
}
