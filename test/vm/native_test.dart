import 'package:test/test.dart';
import 'package:oche_script/oche_script.dart';

class MockPreprocesser extends IncludesPreprocesser {
  @override
  Future<Map<String, String>> getLibraries(String source) async {
    return {};
  }
}

void main() {
  group('Bytecode VM Native Functions and Methods', () {
    Future<Map<String, Object>> run(String source) async {
      return await compileAndRun(source, preprocesser: MockPreprocesser());
    }

    group('Global Native Functions', () {
      test('clock() returns timestamp', () async {
        final result = await run('''
          var ts = clock();
          out("ts", ts);
        ''');
        expect(result['ts'], isA<int>());
        expect(result['ts'] as int, greaterThan(0));
      });

      test('jsonEncode() encodes objects', () async {
        final result = await run(r'''
          var encoded = jsonEncode({"key": "value"});
          out("encoded", encoded);
        ''');
        expect(result['encoded'], contains('key'));
        expect(result['encoded'], contains('value'));
      });

      test('jsonDecode() decodes strings', () async {
        // Use jsonEncode to create the JSON string to avoid escaping issues
        final result = await run('''
          var obj = {"key": "value"};
          var str = jsonEncode(obj);
          var decoded = jsonDecode(str);
          var val = decoded["key"];
          out("val", val);
        ''');
        expect(result['val'], equals('value'));
      });
    });

    group('String Native Methods', () {
      test('length() returns string length', () async {
        final result = await run('''
          var s = "hello";
          var len = s.length();
          out("len", len);
        ''');
        expect(result['len'], equals(5));
      });

      test('toUpper() converts to uppercase', () async {
        final result = await run('''
          var s = "hello";
          var upper = s.toUpper();
          out("upper", upper);
        ''');
        expect(result['upper'], equals('HELLO'));
      });

      test('toLower() converts to lowercase', () async {
        final result = await run('''
          var s = "HELLO";
          var lower = s.toLower();
          out("lower", lower);
        ''');
        expect(result['lower'], equals('hello'));
      });

      test('substring() extracts substring', () async {
        final result = await run('''
          var s = "hello world";
          var sub = s.substring(0, 5);
          out("sub", sub);
        ''');
        expect(result['sub'], equals('hello'));
      });

      test('contains() checks for substring', () async {
        final result = await run('''
          var s = "hello world";
          var has = s.contains("world");
          out("has", has);
        ''');
        expect(result['has'], equals(true));
      });
    });

    group('Number Native Methods', () {
      test('abs() returns absolute value', () async {
        final result = await run('''
          var n = -42;
          var a = n.abs();
          out("a", a);
        ''');
        expect(result['a'], equals(42));
      });

      test('isEven() checks if even', () async {
        final result = await run('''
          var n = 4;
          var even = n.isEven();
          out("even", even);
        ''');
        expect(result['even'], equals(true));
      });

      test('isOdd() checks if odd', () async {
        final result = await run('''
          var n = 3;
          var odd = n.isOdd();
          out("odd", odd);
        ''');
        expect(result['odd'], equals(true));
      });

      test('floor() rounds down', () async {
        final result = await run('''
          var n = 3.7;
          var f = n.floor();
          out("f", f);
        ''');
        expect(result['f'], equals(3));
      });

      test('ceil() rounds up', () async {
        final result = await run('''
          var n = 3.2;
          var c = n.ceil();
          out("c", c);
        ''');
        expect(result['c'], equals(4));
      });
    });

    group('List Native Methods', () {
      test('length() returns list length', () async {
        final result = await run('''
          var l = [1, 2, 3];
          var len = l.length();
          out("len", len);
        ''');
        expect(result['len'], equals(3));
      });

      test('add() adds element to list', () async {
        final result = await run('''
          var l = [1, 2];
          l.add(3);
          var len = l.length();
          out("len", len);
        ''');
        expect(result['len'], equals(3));
      });

      test('contains() checks for element', () async {
        final result = await run('''
          var l = [1, 2, 3];
          var has = l.contains(2);
          out("has", has);
        ''');
        expect(result['has'], equals(true));
      });

      test('indexOf() finds element index', () async {
        final result = await run('''
          var l = ["a", "b", "c"];
          var idx = l.indexOf("b");
          out("idx", idx);
        ''');
        expect(result['idx'], equals(1));
      });

      test('head() returns first element', () async {
        final result = await run('''
          var l = [1, 2, 3];
          var h = l.head();
          out("h", h);
        ''');
        expect(result['h'], equals(1));
      });
    });

    group('Map Native Methods', () {
      test('length() returns map size', () async {
        final result = await run('''
          var m = {"a": 1, "b": 2};
          var len = m.length();
          out("len", len);
        ''');
        expect(result['len'], equals(2));
      });

      test('containsKey() checks for key', () async {
        final result = await run('''
          var m = {"a": 1};
          var has = m.containsKey("a");
          out("has", has);
        ''');
        expect(result['has'], equals(true));
      });

      test('keys() returns list of keys', () async {
        final result = await run('''
          var m = {"a": 1, "b": 2};
          var k = m.keys();
          var len = k.length();
          out("len", len);
        ''');
        expect(result['len'], equals(2));
      });

      test('values() returns list of values', () async {
        final result = await run('''
          var m = {"a": 1, "b": 2};
          var v = m.values();
          var len = v.length();
          out("len", len);
        ''');
        expect(result['len'], equals(2));
      });

      test('remove() removes key', () async {
        final result = await run('''
          var m = {"a": 1, "b": 2};
          m.remove("a");
          var has = m.containsKey("a");
          out("has", has);
        ''');
        expect(result['has'], equals(false));
      });
    });
  });
}
