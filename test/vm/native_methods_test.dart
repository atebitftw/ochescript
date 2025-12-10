import 'package:test/test.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/parser.dart';
import 'package:oche_script/src/compiler/compiler.dart';
import 'package:oche_script/src/runtime/vm.dart';
import 'package:oche_script/native_methods/list_methods.dart' as list_methods;
import 'package:oche_script/native_methods/string_methods.dart'
    as string_methods;
import 'package:oche_script/native_methods/map_methods.dart' as map_methods;
import 'package:oche_script/native_methods/number_methods.dart'
    as number_methods;
import 'package:oche_script/native_methods/date_methods.dart' as date_methods;
import 'package:oche_script/native_methods/duration_methods.dart'
    as duration_methods;

void main() {
  group('VM Native Methods', () {
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

    group('String Methods', () {
      test('length', () async {
        final result = await run(
          'var s = "hello"; var len = s.length(); out("len", len);',
        );
        expect(result['len'], 5);
      });

      test('toUpper', () async {
        final result = await run(
          'var s = "hello"; var upper = s.toUpper(); out("upper", upper);',
        );
        expect(result['upper'], "HELLO");
      });

      test('toLower', () async {
        final result = await run(
          'var s = "HELLO"; var lower = s.toLower(); out("lower", lower);',
        );
        expect(result['lower'], "hello");
      });

      test('isNotEmpty', () async {
        final result = await run(
          'var s = "hello"; var notEmpty = s.isNotEmpty(); out("notEmpty", notEmpty);',
        );
        expect(result['notEmpty'], true);
      });

      test('isEmpty', () async {
        final result = await run(
          'var s = ""; var empty = s.isEmpty(); out("empty", empty);',
        );
        expect(result['empty'], true);
      });

      test('contains', () async {
        final result = await run(
          'var s = "hello world"; var hasWorld = s.contains("world"); out("hasWorld", hasWorld);',
        );
        expect(result['hasWorld'], true);
      });

      test('split', () async {
        final result = await run(
          'var s = "a,b,c"; var parts = s.split(","); var first = parts[0]; out("first", first);',
        );
        expect(result['first'], "a");
      });

      test('substring', () async {
        final result = await run(
          'var s = "hello"; var sub = s.substring(1, 4); out("sub", sub);',
        );
        expect(result['sub'], "ell");
      });

      test('head', () async {
        final result = await run(
          'var s = "hello"; var h = s.head(); out("h", h);',
        );
        expect(result['h'], "h");
      });

      test('tail', () async {
        final result = await run(
          'var s = "hello"; var t = s.tail(); out("t", t);',
        );
        expect(result['t'], "ello");
      });

      test('compareTo', () async {
        final result = await run(
          'var s1 = "a"; var s2 = "b"; var res = s1.compareTo(s2); out("res", res);',
        );
        expect(result['res'], lessThan(0));
      });

      test('trim', () async {
        final result = await run(
          'var s = "  hello  "; var trimmed = s.trim(); out("trimmed", trimmed);',
        );
        expect(result['trimmed'], "hello");
      });
    });

    group('Number Methods', () {
      test('toString', () async {
        final result = await run(
          'var n = 123; var s = n.toString(); out("s", s);',
        );
        expect(result['s'], "123");
      });

      test('isOdd', () async {
        final result = await run(
          'var n = 3; var odd = n.isOdd(); out("odd", odd);',
        );
        expect(result['odd'], true);
      });

      test('isEven', () async {
        final result = await run(
          'var n = 2; var even = n.isEven(); out("even", even);',
        );
        expect(result['even'], true);
      });

      test('truncate', () async {
        final result = await run(
          'var n = 3.5; var t = n.truncate(); out("t", t);',
        );
        expect(result['t'], 3);
      });

      test('floor', () async {
        final result = await run(
          'var n = 3.5; var f = n.floor(); out("f", f);',
        );
        expect(result['f'], 3);
      });

      test('ceil', () async {
        final result = await run('var n = 3.5; var c = n.ceil(); out("c", c);');
        expect(result['c'], 4);
      });

      test('round', () async {
        final result = await run(
          'var n = 3.5; var r = n.round(); out("r", r);',
        );
        expect(result['r'], 4);
      });

      test('abs', () async {
        final result = await run('var n = -5; var a = n.abs(); out("a", a);');
        expect(result['a'], 5);
      });

      test('pow', () async {
        final result = await run('var n = 2; var p = n.pow(3); out("p", p);');
        expect(result['p'], 8);
      });

      test('sqrt', () async {
        final result = await run('var n = 9; var s = n.sqrt(); out("s", s);');
        expect(result['s'], 3.0);
      });

      test('max', () async {
        final result = await run('var n = 10; var m = n.max(20); out("m", m);');
        expect(result['m'], 20);
      });

      test('min', () async {
        final result = await run('var n = 10; var m = n.min(20); out("m", m);');
        expect(result['m'], 10);
      });
    });

    group('List Methods', () {
      test('length', () async {
        final result = await run(
          'var l = [1, 2, 3]; var len = l.length(); out("len", len);',
        );
        expect(result['len'], 3);
      });

      test('add', () async {
        final result = await run(
          'var l = []; l.add(1); var len = l.length(); out("len", len);',
        );
        expect(result['len'], 1);
      });

      test('addAll', () async {
        final result = await run(
          'var l = [1]; l.addAll([2, 3]); var len = l.length(); out("len", len);',
        );
        expect(result['len'], 3);
      });

      test('isEmpty', () async {
        final result = await run(
          'var l = []; var empty = l.isEmpty(); out("empty", empty);',
        );
        expect(result['empty'], true);
      });

      test('isNotEmpty', () async {
        final result = await run(
          'var l = [1]; var notEmpty = l.isNotEmpty(); out("notEmpty", notEmpty);',
        );
        expect(result['notEmpty'], true);
      });

      test('contains', () async {
        final result = await run(
          'var l = [1, 2, 3]; var has2 = l.contains(2); out("has2", has2);',
        );
        expect(result['has2'], true);
      });

      test('indexOf', () async {
        final result = await run(
          'var l = ["a", "b"]; var idx = l.indexOf("b"); out("idx", idx);',
        );
        expect(result['idx'], 1);
      });

      test('head', () async {
        final result = await run(
          'var l = [1, 2, 3]; var h = l.head(); out("h", h);',
        );
        expect(result['h'], 1);
      });

      test('tail', () async {
        final result = await run(
          'var l = [1, 2, 3]; var t = l.tail(); var first = t[0]; out("first", first);',
        );
        expect(result['first'], 2);
      });

      test('join', () async {
        final result = await run(
          'var l = ["a", "b"]; var s = l.join(","); out("s", s);',
        );
        expect(result['s'], "a,b");
      });

      test('clear', () async {
        final result = await run(
          'var l = [1, 2]; l.clear(); var len = l.length(); out("len", len);',
        );
        expect(result['len'], 0);
      });

      test('removeAt', () async {
        final result = await run(
          'var l = [1, 2, 3]; l.removeAt(1); var val = l[1]; out("val", val);',
        );
        expect(result['val'], 3);
      });

      test('reversed', () async {
        final result = await run(
          'var l = [1, 2]; var r = l.reversed(); var first = r[0]; out("first", first);',
        );
        expect(result['first'], 2);
      });

      test('map', () async {
        final result = await run('''
          var l = [1, 2, 3];
          var m = await l.map(async fun(x) { return x * 2; });
          var first = m[0];
          out("first", first);
        ''');
        expect(result['first'], 2);
      });

      test('filter', () async {
        final result = await run('''
          var l = [1, 2, 3, 4];
          var f = await l.filter(async fun(x) { return x.isEven(); });
          var len = f.length();
          out("len", len);
        ''');
        expect(result['len'], 2);
      });

      test('every', () async {
        final result = await run('''
          var l = [2, 4, 6];
          var allEven = await l.every(async fun(x) { return x.isEven(); });
          out("allEven", allEven);
        ''');
        expect(result['allEven'], true);
      });

      test('any', () async {
        final result = await run('''
          var l = [1, 2, 3];
          var hasEven = await l.any(async fun(x) { return x.isEven(); });
          out("hasEven", hasEven);
        ''');
        expect(result['hasEven'], true);
      });

      test('fold', () async {
        final result = await run('''
          var l = [1, 2, 3];
          var sum = await l.fold(0, async fun(e, acc) { return acc + e; });
          out("sum", sum);
        ''');
        expect(result['sum'], 6);
      });
    });

    group('Map Methods', () {
      test('length', () async {
        final result = await run(
          'var m = {"a": 1}; var len = m.length(); out("len", len);',
        );
        expect(result['len'], 1);
      });

      test('keys', () async {
        final result = await run(
          'var m = {"a": 1}; var k = m.keys(); var first = k[0]; out("first", first);',
        );
        expect(result['first'], "a");
      });

      test('values', () async {
        final result = await run(
          'var m = {"a": 1}; var v = m.values(); var first = v[0]; out("first", first);',
        );
        expect(result['first'], 1);
      });

      test('containsKey', () async {
        final result = await run(
          'var m = {"a": 1}; var hasA = m.containsKey("a"); out("hasA", hasA);',
        );
        expect(result['hasA'], true);
      });

      test('containsValue', () async {
        final result = await run(
          'var m = {"a": 1}; var has1 = m.containsValue(1); out("has1", has1);',
        );
        expect(result['has1'], true);
      });

      test('isEmpty', () async {
        final result = await run(
          'var m = {}; var empty = m.isEmpty(); out("empty", empty);',
        );
        expect(result['empty'], true);
      });

      test('isNotEmpty', () async {
        final result = await run(
          'var m = {"a": 1}; var notEmpty = m.isNotEmpty(); out("notEmpty", notEmpty);',
        );
        expect(result['notEmpty'], true);
      });

      test('remove', () async {
        final result = await run(
          'var m = {"a": 1, "b": 2}; m.remove("a"); var hasA = m.containsKey("a"); out("hasA", hasA);',
        );
        expect(result['hasA'], false);
      });

      test('clear', () async {
        final result = await run(
          'var m = {"a": 1}; m.clear(); var len = m.length(); out("len", len);',
        );
        expect(result['len'], 0);
      });

      test('merge', () async {
        final result = await run(
          'var m1 = {"a": 1}; var m2 = {"b": 2}; m1.merge(m2); var hasB = m1.containsKey("b"); out("hasB", hasB);',
        );
        expect(result['hasB'], true);
      });
    });
  });
}
