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

    test("expression as switch value", () async {
      final result = await run('''
        var a = 1;
        var res = "";
        switch (a + a * 3) {
          case 2: res = "two"; break;
          case 4: res = "four"; break;
        }
        out("res", res);
      ''');
      expect(result['res'], "four");
    });
    test('matches integer cases', () async {
      final result = await run('''
        var a = 1;
        var res = "";
        switch (a) {
          case 0: res = "zero"; break;
          case 1: res = "one"; break;
          case 2: res = "two"; break;
        }
        out("res", res);
      ''');
      expect(result['res'], "one");
    });

    test('matches string cases', () async {
      final result = await run('''
        var a = "b";
        var res = "";
        switch (a) {
          case "a": res = "A"; break;
          case "b": res = "B"; break;
          case "c": res = "C"; break;
        }
        out("res", res);
      ''');
      expect(result['res'], "B");
    });

    test('matches default case', () async {
      final result = await run('''
        var a = 5;
        var res = "";
        switch (a) {
          case 0: res = "zero"; break;
          case 1: res = "one"; break;
          default: res = "default";
        }
        out("res", res);
      ''');
      expect(result['res'], "default");
    });

    test('handles fallthrough', () async {
      final result = await run('''
        var a = 0;
        var count = 0;
        switch (a) {
          case 0: count = count + 1;
          case 1: count = count + 1;
          case 2: count = count + 1; break;
          case 3: count = count + 1;
        }
        out("count", count);
      ''');
      expect(result['count'], 3);
    });

    test('handles break', () async {
      final result = await run('''
        var a = 0;
        var count = 0;
        switch (a) {
          case 0: 
            count = count + 1;
            break;
          case 1: 
            count = count + 1;
        }
        out("count", count);
      ''');
      expect(result['count'], 1);
    });

    test('evaluates expressions in cases', () async {
      final result = await run('''
        var a = 4;
        var res = "";
        switch (a) {
          case 1 + 1: res = "two"; break;
          case 2 * 2: res = "four"; break;
        }
        out("res", res);
      ''');
      expect(result['res'], "four");
    });

    test('evaluates switch expression once', () async {
      final result = await run('''
        var a = 2;
        var res = "";
        switch (a + a) {
          case 4: res = "four"; break;
          default: res = "other";
        }
        out("res", res);
      ''');
      expect(result['res'], "four");
    });

    test('handles nested switches', () async {
      final result = await run('''
        var x = 1;
        var y = 2;
        var res = "";
        switch (x) {
          case 1:
            switch (y) {
              case 2: res = "nested"; break;
            }
            break;
        }
        out("res", res);
      ''');
      expect(result['res'], "nested");
    });

    test('handles switch inside loop with break', () async {
      final result = await run('''
        var res = 0;
        for (var i = 0; i < 3; i = i + 1) {
          switch (i) {
            case 1: 
              res = res + 10; 
              break; // Should break switch, not loop
            default:
              res = res + 1;
          }
        }
        out("res", res);
      ''');
      // i=0: default -> res=1
      // i=1: case 1 -> res=11 (break switch)
      // i=2: default -> res=12
      expect(result['res'], 12);
    });

    test('handles switch inside loop with continue', () async {
      final result = await run('''
        var res = 0;
        for (var i = 0; i < 3; i = i + 1) {
          switch (i) {
            case 1: 
              continue; // Should continue loop
            default:
              res = res + 1;
          }
        }
        out("res", res);
      ''');
      // i=0: default -> res=1
      // i=1: continue loop -> res=1
      // i=2: default -> res=2
      expect(result['res'], 2);
    });

    test('scope isolation', () async {
      final result = await run('''
        var res = 0;
        switch (1) {
          case 1:
            var a = 10;
            res = a;
            break;
          case 2:
            break;
        }
        out("res", res);
      ''');
      expect(result['res'], 10);
    });

    test('empty switch', () async {
      final result = await run('''
        var a = 1;
        switch (a) {}
        out("a", a);
      ''');
      expect(result['a'], 1);
    });

    test('switch with only default', () async {
      final result = await run('''
        var res = "";
        switch (1) {
          default: res = "default";
        }
        out("res", res);
      ''');
      expect(result['res'], "default");
    });

    test('no match no default', () async {
      final result = await run('''
        var res = "initial";
        switch (1) {
          case 2: res = "changed";
        }
        out("res", res);
      ''');
      expect(result['res'], "initial");
    });

    test('default in middle', () async {
      final result = await run('''
        var res = "";
        switch (1) {
          default: res = "default"; break;
          case 1: res = "one";
        }
        out("res", res);
      ''');
      expect(result['res'], "one");
    });

    test('default in middle fallthrough', () async {
      final result = await run('''
        var res = "";
        switch (5) {
          case 1: res = "one";
          default: res = "default";
          case 2: res = res + " fallthrough";
        }
        out("res", res);
      ''');
      expect(result['res'], "default fallthrough");
    });
  });
}
