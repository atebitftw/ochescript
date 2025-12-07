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
  group('VM Map Methods Tests', () {
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

    // =========================================================================
    // Basic Map Operations
    // =========================================================================

    group('Basic Operations', () {
      test('length() returns map size', () async {
        final result = await run('''
          var empty = {};
          var one = {"a": 1};
          var many = {"a": 1, "b": 2, "c": 3, "d": 4, "e": 5};
          
          out("empty", empty.length());
          out("one", one.length());
          out("many", many.length());
        ''');
        expect(result['empty'], 0);
        expect(result['one'], 1);
        expect(result['many'], 5);
      });

      test('isEmpty() checks for empty map', () async {
        final result = await run('''
          var empty = {};
          var notEmpty = {"a": 1, "b": 2};
          
          out("empty", empty.isEmpty());
          out("notEmpty", notEmpty.isEmpty());
        ''');
        expect(result['empty'], true);
        expect(result['notEmpty'], false);
      });

      test('isNotEmpty() checks for non-empty map', () async {
        final result = await run('''
          var empty = {};
          var notEmpty = {"a": 1, "b": 2};
          
          out("empty", empty.isNotEmpty());
          out("notEmpty", notEmpty.isNotEmpty());
        ''');
        expect(result['empty'], false);
        expect(result['notEmpty'], true);
      });

      test('keys() returns list of keys', () async {
        final result = await run('''
          var mp = {"x": 10, "y": 20, "z": 30};
          var k = mp.keys();
          out("len", k.length());
          out("hasX", k.contains("x"));
          out("hasY", k.contains("y"));
          out("hasZ", k.contains("z"));
        ''');
        expect(result['len'], 3);
        expect(result['hasX'], true);
        expect(result['hasY'], true);
        expect(result['hasZ'], true);
      });

      test('values() returns list of values', () async {
        final result = await run('''
          var mp = {"a": 100, "b": 200, "c": 300};
          var v = mp.values();
          out("len", v.length());
          out("has100", v.contains(100));
          out("has200", v.contains(200));
          out("has300", v.contains(300));
        ''');
        expect(result['len'], 3);
        expect(result['has100'], true);
        expect(result['has200'], true);
        expect(result['has300'], true);
      });

      test('toString() converts map to string', () async {
        final result = await run('''
          var mp = {"a": 1};
          var str = mp.toString();
          out("str", str);
        ''');
        expect(result['str'], "{a: 1}");
      });
    });

    // =========================================================================
    // Search Operations
    // =========================================================================

    group('Search Operations', () {
      test('containsKey() checks for key presence', () async {
        final result = await run('''
          var mp = {"name": "Alice", "age": 30};
          out("hasName", mp.containsKey("name"));
          out("hasAge", mp.containsKey("age"));
          out("hasEmail", mp.containsKey("email"));
        ''');
        expect(result['hasName'], true);
        expect(result['hasAge'], true);
        expect(result['hasEmail'], false);
      });

      test('containsValue() checks for value presence', () async {
        final result = await run('''
          var mp = {"a": 10, "b": 20, "c": 30};
          out("has10", mp.containsValue(10));
          out("has20", mp.containsValue(20));
          out("has99", mp.containsValue(99));
        ''');
        expect(result['has10'], true);
        expect(result['has20'], true);
        expect(result['has99'], false);
      });

      test('containsValue() with string values', () async {
        final result = await run('''
          var mp = {"greeting": "hello", "farewell": "goodbye"};
          out("hasHello", mp.containsValue("hello"));
          out("hasGoodbye", mp.containsValue("goodbye"));
          out("hasHi", mp.containsValue("hi"));
        ''');
        expect(result['hasHello'], true);
        expect(result['hasGoodbye'], true);
        expect(result['hasHi'], false);
      });
    });

    // =========================================================================
    // Mutating Operations
    // =========================================================================

    group('Mutating Operations', () {
      test('merge() combines two maps', () async {
        final result = await run('''
          var mp1 = {"a": 1, "b": 2};
          var mp2 = {"c": 3, "d": 4};
          mp1.merge(mp2);
          out("len", mp1.length());
          out("a", mp1["a"]);
          out("c", mp1["c"]);
          out("d", mp1["d"]);
        ''');
        expect(result['len'], 4);
        expect(result['a'], 1);
        expect(result['c'], 3);
        expect(result['d'], 4);
      });

      test('merge() overwrites existing keys', () async {
        final result = await run('''
          var mp1 = {"a": 1, "b": 2};
          var mp2 = {"b": 99, "c": 3};
          mp1.merge(mp2);
          out("b", mp1["b"]);
          out("c", mp1["c"]);
        ''');
        expect(result['b'], 99);
        expect(result['c'], 3);
      });

      test('remove() deletes a key', () async {
        final result = await run('''
          var mp = {"a": 1, "b": 2, "c": 3};
          mp.remove("b");
          out("len", mp.length());
          out("hasB", mp.containsKey("b"));
          out("hasA", mp.containsKey("a"));
          out("hasC", mp.containsKey("c"));
        ''');
        expect(result['len'], 2);
        expect(result['hasB'], false);
        expect(result['hasA'], true);
        expect(result['hasC'], true);
      });

      test('remove() non-existent key does nothing', () async {
        final result = await run('''
          var mp = {"a": 1, "b": 2};
          mp.remove("z");
          out("len", mp.length());
        ''');
        expect(result['len'], 2);
      });

      test('clear() removes all entries', () async {
        final result = await run('''
          var mp = {"a": 1, "b": 2, "c": 3};
          mp.clear();
          out("len", mp.length());
          out("isEmpty", mp.isEmpty());
        ''');
        expect(result['len'], 0);
        expect(result['isEmpty'], true);
      });
    });

    // =========================================================================
    // Iteration Operations
    // =========================================================================

    group('Iteration Operations', () {
      test('forEach() iterates over entries', () async {
        final result = await run('''
          var mp = {"a": 1, "b": 2, "c": 3};
          var sum = 0;
          var keys = "";
          await mp.forEach(fun(k, v) { 
            sum = sum + v; 
            keys = keys + k;
          });
          out("sum", sum);
        ''');
        expect(result['sum'], 6);
      });

      test('forEach() with complex values', () async {
        final result = await run('''
          var mp = {
            "alice": {"score": 90},
            "bob": {"score": 85},
            "charlie": {"score": 95}
          };
          var total = 0;
          await mp.forEach(fun(name, data) { 
            total = total + data["score"]; 
          });
          out("total", total);
        ''');
        expect(result['total'], 270);
      });
    });

    // =========================================================================
    // Complex Operations
    // =========================================================================

    group('Complex Operations', () {
      test('keys().map() transformation', () async {
        final result = await run('''
          var mp = {"apple": 1, "banana": 2, "cherry": 3};
          var k = mp.keys();
          var upper = await k.map(fun(key) { return key.toUpper(); });
          out("first", upper[0]);
        ''');
        // Note: map key order may vary, just check transformation works
        expect((result['first'] as String).toUpperCase(), result['first']);
      });

      test('values().filter() operation', () async {
        final result = await run('''
          var mp = {"a": 10, "b": 25, "c": 5, "d": 30};
          var v = mp.values();
          var big = await v.filter(fun(val) { return val > 15; });
          out("len", big.length());
        ''');
        expect(result['len'], 2); // 25 and 30
      });

      test('nested map access and modification', () async {
        final result = await run('''
          var data = {
            "users": {
              "alice": {"age": 30, "active": true},
              "bob": {"age": 25, "active": false}
            },
            "count": 2
          };
          
          var users = data["users"];
          var alice = users["alice"];
          alice["age"] = 31;
          
          out("aliceAge", data["users"]["alice"]["age"]);
          out("count", data["count"]);
        ''');
        expect(result['aliceAge'], 31);
        expect(result['count'], 2);
      });

      test('building map dynamically', () async {
        final result = await run('''
          var mp = {};
          for (var i = 0; i < 5; i = i + 1) {
            var key = "key" + i.toString();
            mp[key] = i * 10;
          }
          out("len", mp.length());
          out("key0", mp["key0"]);
          out("key4", mp["key4"]);
        ''');
        expect(result['len'], 5);
        expect(result['key0'], 0);
        expect(result['key4'], 40);
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================

    group('Edge Cases', () {
      test('operations on empty map', () async {
        final result = await run('''
          var mp = {};
          var k = mp.keys();
          var v = mp.values();
          
          out("keysLen", k.length());
          out("valuesLen", v.length());
          out("isEmpty", mp.isEmpty());
          out("hasKey", mp.containsKey("anything"));
        ''');
        expect(result['keysLen'], 0);
        expect(result['valuesLen'], 0);
        expect(result['isEmpty'], true);
        expect(result['hasKey'], false);
      });

      test('single entry map', () async {
        final result = await run('''
          var mp = {"only": 42};
          out("len", mp.length());
          out("hasOnly", mp.containsKey("only"));
          out("value", mp["only"]);
          
          mp.remove("only");
          out("afterRemove", mp.isEmpty());
        ''');
        expect(result['len'], 1);
        expect(result['hasOnly'], true);
        expect(result['value'], 42);
        expect(result['afterRemove'], true);
      });

      test('map with mixed value types', () async {
        final result = await run('''
          var mp = {
            "num": 42,
            "str": "hello",
            "bool": true,
            "arr": [1, 2, 3],
            "nested": {"inner": "value"}
          };
          
          out("num", mp["num"]);
          out("str", mp["str"]);
          out("bool", mp["bool"]);
          out("arrLen", mp["arr"].length());
          out("nested", mp["nested"]["inner"]);
        ''');
        expect(result['num'], 42);
        expect(result['str'], "hello");
        expect(result['bool'], true);
        expect(result['arrLen'], 3);
        expect(result['nested'], "value");
      });

      test('overwriting existing keys', () async {
        final result = await run('''
          var mp = {"a": 1};
          mp["a"] = 100;
          mp["a"] = 200;
          out("a", mp["a"]);
          out("len", mp.length());
        ''');
        expect(result['a'], 200);
        expect(result['len'], 1);
      });
    });
  });
}
