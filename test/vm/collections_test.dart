import 'package:test/test.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/parser.dart';
import 'package:oche_script/src/compiler/compiler.dart';
import 'package:oche_script/src/runtime/vm.dart';

void main() {
  group('Bytecode VM Collections & Logic', () {
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

    test('List literal and indexing', () async {
      final result = await run("""
        var l = [1, 2, 3];
        out("first", l[0]);
        out("last", l[2]);
      """);
      expect(result['first'], equals(1));
      expect(result['last'], equals(3));
    });

    test('Map literal and indexing', () async {
      final result = await run("""
        var m = {"a": 1, "b": 2};
        out("a", m["a"]);
        out("b", m["b"]);
      """);
      expect(result['a'], equals(1));
      expect(result['b'], equals(2));
    });

    test('List index assignment', () async {
      final result = await run("""
        var l = [1, 2, 3];
        l[1] = 42;
        out("val", l[1]);
      """);
      expect(result['val'], equals(42));
    });

    test('Map index assignment', () async {
      final result = await run("""
        var m = {"a": 1};
        m["a"] = 42;
        m["b"] = 100;
        out("a", m["a"]);
        out("b", m["b"]);
      """);
      expect(result['a'], equals(42));
      expect(result['b'], equals(100));
    });

    test('Logical AND short-circuit', () async {
      final result = await run("""
        var a = true;
        var b = false;
        out("and1", a && true);
        out("and2", a && b);
        out("and3", b && true); // Short-circuit
      """);
      expect(result['and1'], equals(true));
      expect(result['and2'], equals(false));
      expect(result['and3'], equals(false));
    });

    test('Logical OR short-circuit', () async {
      final result = await run("""
        var a = true;
        var b = false;
        out("or1", a || false); // Short-circuit
        out("or2", b || true);
        out("or3", b || false);
      """);
      expect(result['or1'], equals(true));
      expect(result['or2'], equals(true));
      expect(result['or3'], equals(false));
    });

    test('Postfix increment/decrement', () async {
      final result = await run("""
        var i = 10;
        var j = i++;
        out("i_after", i);
        out("j_old", j);
        
        var k = 20;
        var l = k--;
        out("k_after", k);
        out("l_old", l);
      """);
      expect(result['i_after'], equals(11));
      expect(result['j_old'], equals(10));
      expect(result['k_after'], equals(19));
      expect(result['l_old'], equals(20));
    });
  });
}
