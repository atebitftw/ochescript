import 'package:oche_script/native_methods/date_methods.dart' as date_methods;
import 'package:oche_script/native_methods/duration_methods.dart'
    as duration_methods;
import 'package:oche_script/native_methods/list_methods.dart' as list_methods;
import 'package:oche_script/native_methods/map_methods.dart' as map_methods;
import 'package:oche_script/native_methods/number_methods.dart'
    as number_methods;
import 'package:oche_script/native_methods/string_methods.dart'
    as string_methods;
import 'package:test/test.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/parser.dart';
import 'package:oche_script/src/compiler/compiler.dart';
import 'package:oche_script/src/runtime/vm.dart';

void main() {
  group('VM Switch Statement', () {
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

    test("for in basic", () async {
      final result = await run('''
        var res = "";
        for (var i in [1, 2, 3]) {
          res = res + i;
        }
        out("res", res);
      ''');
      expect(result['res'], "123");
    });

    test("for in with break", () async {
      final result = await run('''
        var res = "";
        for (var i in [1, 2, 3]) {
          if (i == 2) break;
          res = res + i;
        }
        out("res", res);
      ''');
      expect(result['res'], "1");
    });

    test("for in with continue", () async {
      final result = await run('''
        var res = "";
        for (var i in [1, 2, 3]) {
          if (i == 2) continue;
          res = res + i;
        }
        out("res", res);
      ''');
      expect(result['res'], "13");
    });

    test("for in  with empty list", () async {
      final result = await run('''
        var res = "";
        for (var i in []) {
          res = res + i;
        }
        out("res", res);
      ''');
      expect(result['res'], "");
    });

    test("for in - list of list", () async {
      final result = await run('''
        var res = "";
        for (var i in [[1, 2], [3, 4]]) {
          res = res + i[0];
        }
        out("res", res);
      ''');
      expect(result['res'], "13");
    });

    test("for in - inside closure", () async {
      final result = await run('''
        var res = "";
        var closure = fun() {
          for (var i in [1, 2, 3]) {
            res = res + i;
          }
        };
        closure();
        out("res", res);
      ''');
      expect(result['res'], "123");
    });

    test("for in - inside loop", () async {
      final result = await run('''
        var res = "";
        for (var i = 0; i < 3; i++) {
          for (var j in [1, 2, 3]) {
            res = res + (i + 1) + j;
          }
        }
        out("res", res);
      ''');
      expect(result['res'], "111213212223313233");
    });

    test("for in - inside loop with break", () async {
      final result = await run('''
        var res = "";
        for (var i = 0; i < 3; i++) {
          for (var j in [1, 2, 3]) {
            if (j == 2) break;
            res = res + (i + 1) + j;
          }
        }
        out("res", res);
      ''');
      expect(result['res'], "112131");
    });

    test("for in - inside loop with continue", () async {
      final result = await run('''
        var res = "";
        for (var i in [1, 2, 3]) {
          for (var j in [1, 2, 3]) {
            if (j == 2) continue;
            res = res + i + j;
          }
        }
        out("res", res);
      ''');
      expect(result['res'], "111321233133");
    });

    test("for in - inside loop with break and continue", () async {
      final result = await run('''
        var res = "";
        for (var i in [1, 2, 3]) {
          for (var j in [1, 2, 3]) {
            if (j == 2) break;
            if (j == 2) continue;
            res = res + i + j;
          }
        }
        out("res", res);
      ''');
      expect(result['res'], "112131");
    });
    test("for in- nested for-in", () async {
      final result = await run('''
        var res = "";
        for (var i in [1, 2, 3]) {
          for (var j in [1, 2, 3]) {
            res = res + i + j;
          }
        }
        out("res", res);
      ''');
      expect(result['res'], "111213212223313233");
    });

    test("for in - inside loop with break and continue", () async {
      final result = await run('''
        var res = "";
        for (var i in [1, 2, 3]) {
          for (var j in [1, 2, 3]) {
            if (j == 2) break;
            if (j == 2) continue;
            res = res + i + j;
          }
        }
        out("res", res);
      ''');
      expect(result['res'], "112131");
    });

    test("for in - loop inside for-in", () async {
      final result = await run('''
        var res = "";
        for (var i in [1, 2, 3]) {
          for (var j in [1, 2, 3]) {
            res = res + i + j;
          }
        }
        out("res", res);
      ''');
      expect(result['res'], "111213212223313233");
    });

    test("for in - async function inside for-in", () async {
      final result = await run('''
        var res = "";
        async fun asyncFunc() {
          return 1;
        }
        for (var i in [await asyncFunc(), 2, 3]) {
          for (var j in [1, 2, 3]) {
            res = res + i + j;
          }
        }
        out("res", res);
      ''');
      expect(result['res'], "111213212223313233");
    });

    test("for in - async function inside for-in with break", () async {
      final result = await run('''
        var res = "";
        async fun asyncFunc() {
          return 1;
        }

        for (var i in [await asyncFunc(), 2, 3]) {
          for (var j in [1, 2, 3]) {
            if (j == 2) break;
            res = res + i + j;
          }
        }
        out("res", res);
      ''');
      expect(result['res'], "112131");
    });

    test("for in - async function inside for-in with continue", () async {
      final result = await run('''
        var res = "";
        async fun asyncFunc() {
          return 1;
        }
        for (var i in [await asyncFunc(), 2, 3]) {
          for (var j in [1, 2, 3]) {
            if (j == 2) continue;
            res = res + i + j;
          }
        }
        out("res", res);
      ''');
      expect(result['res'], "111321233133");
    });

    test(
      "for in - async function inside for-in with break and continue",
      () async {
        final result = await run('''
        var res = "";
        async fun asyncFunc() {
          return 1;
        }
        for (var i in [await asyncFunc(), 2, 3]) {
          for (var j in [1, 2, 3]) {
            if (j == 2) break;
            if (j == 2) continue;
            res = res + i + j;
          }
        }
        out("res", res);
      ''');
        expect(result['res'], "112131");
      },
    );

    test("for in - async function inside loop", () async {
      final result = await run('''
        var res = "";
        async fun asyncFunc() {
          return 1;
        }



        for (var i in [1, 2, 3]) {
          for (var j in [1, 2, 3]) {
            res = res + i + j + await asyncFunc();
          }
        }
        out("res", res);
      ''');
      expect(result['res'], "111121131211221231311321331");
    });
    test("for in - deep nesting (3 levels)", () async {
      final result = await run('''
        var res = "";
        for (var i in ["a", "b"]) {
          for (var j in [1, 2]) {
            for (var k in ["x", "y"]) {
              res = res + i + j + k;
            }
          }
        }
        out("res", res);
      ''');
      expect(result['res'], "a1xa1ya2xa2yb1xb1yb2xb2y");
    });

    test("for in - switch inside loop", () async {
      final result = await run('''
        var res = "";
        for (var i in ["a", "b", "c"]) {
          switch (i) {
            case "a": res = res + "A"; break;
            case "b": res = res + "B"; break;
            default: res = res + "*";
          }
        }
        out("res", res);
      ''');
      expect(result['res'], "AB*");
    });

    test("for in - loop inside switch", () async {
      final result = await run('''
        var res = "";
        var val = "go";
        switch (val) {
          case "go":
            for (var i in [1, 2, 3]) {
              res = res + i;
            }
            break;
          default:
            res = "fail";
        }
        out("res", res);
      ''');
      expect(result['res'], "123");
    });

    test("for in - complex list expression", () async {
      final result = await run('''
        fun getList() {
          return [1, 2, 3];
        }
        var res = "";
        for (var i in getList()) {
          res = res + i;
        }
        out("res", res);
      ''');
      expect(result['res'], "123");
    });

    test("for in - list of maps", () async {
      final result = await run('''
        var list = [{"val": 1}, {"val": 2}];
        var res = 0;
        for (var m in list) {
          res = res + m["val"];
        }
        out("res", res);
      ''');
      expect(result['res'], 3);
    });
    test("for in - recursion", () async {
      final result = await run('''
        fun sumTree(list) {
          var sum = 0;
          for (var item in list) {
            if (item is List) {
              sum = sum + sumTree(item);
            } else {
              sum = sum + item;
            }
          }
          return sum;
        }
        var res = sumTree([1, [2, 3], [4, [5]]]);
        out("res", res);
      ''');
      expect(result['res'], 15);
    });
  });
}
