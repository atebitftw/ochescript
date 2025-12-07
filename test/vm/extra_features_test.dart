import 'package:oche_script/native_methods/duration_methods.dart' as duration_methods;
import 'package:oche_script/native_methods/list_methods.dart' as list_methods;
import 'package:oche_script/native_methods/map_methods.dart' as map_methods;
import 'package:oche_script/native_methods/number_methods.dart' as number_methods;
import 'package:oche_script/native_methods/string_methods.dart' as string_methods;
import 'package:oche_script/src/runtime/vm.dart' show VM;
import 'package:test/test.dart';
import 'package:oche_script/oche_script.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/parser.dart';
import 'package:oche_script/src/compiler/compiler.dart';

class TestPreprocesser extends IncludesPreprocesser {
  @override
  Map<String, String> getLibraries(String source) {
    // In a real scenario, this would read files.
    // Here we mock the file content.
    if (source.contains('include "helper"')) {
      return {"helper": 'var helperVar = "helperValue";'};
    }
    return {};
  }
}

void main() {
  group('Extra Features Tests', () {
    late BytecodeCompiler compiler;
    late VM vm;

    setUp(() {
      list_methods.registerListExtensions();
      string_methods.registerStringExtensions();
      map_methods.registerMapExtensions();
      number_methods.registerNumberExtensions();
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

    test('List concatenation (+)', () async {
      final result = await run('''
        var l1 = [1, 2];
        var l2 = [3, 4];
        var l3 = l1 + l2;
        out("len", l3.length());
        out("v0", l3[0]);
        out("v2", l3[2]);
      ''');
      expect(result['len'], 4);
      expect(result['v0'], 1);
      expect(result['v2'], 3);
    });

    test('Map concatenation (+)', () async {
      final result = await run('''
        var m1 = {"a": 1};
        var m2 = {"b": 2};
        var m3 = m1 + m2;
        out("len", m3.keys().length());
        out("a", m3["a"]);
        out("b", m3["b"]);
      ''');
      expect(result['len'], 2);
      expect(result['a'], 1);
      expect(result['b'], 2);
    });

    test('Nested class in function', () async {
      final result = await run('''
        fun makeObj() {
          class Inner {
            init(val) { this.val = val; }
            getVal() { return this.val; }
          }
          return Inner(42);
        }
        var obj = makeObj();
        out("val", obj.getVal());
      ''');
      expect(result['val'], 42);
    });

    test('Implicit null return usage error', () async {
      final result = await run('''
          fun noReturn() {
            var foo = 42;
          }
          var x = noReturn();
          var y = x + 1; // Should fail
        ''');
      expect(result.containsKey("error"), isTrue);
    });
  });
}
