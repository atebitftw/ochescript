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
  group('VM String Methods Tests', () {
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

    // =========================================================================
    // Case Conversion
    // =========================================================================

    group('Case Conversion', () {
      test('toUpper() converts to uppercase', () async {
        final result = await run('''
          var s = "hello world";
          out("upper", s.toUpper());
        ''');
        expect(result['upper'], "HELLO WORLD");
      });

      test('toLower() converts to lowercase', () async {
        final result = await run('''
          var s = "HELLO WORLD";
          out("lower", s.toLower());
        ''');
        expect(result['lower'], "hello world");
      });

      test('toUpper() on mixed case', () async {
        final result = await run('''
          var s = "HeLLo WoRLd";
          out("upper", s.toUpper());
        ''');
        expect(result['upper'], "HELLO WORLD");
      });

      test('toLower() on mixed case', () async {
        final result = await run('''
          var s = "HeLLo WoRLd";
          out("lower", s.toLower());
        ''');
        expect(result['lower'], "hello world");
      });

      test('case conversion with numbers and symbols', () async {
        final result = await run('''
          var s = "Hello123!@#";
          out("upper", s.toUpper());
          out("lower", s.toLower());
        ''');
        expect(result['upper'], "HELLO123!@#");
        expect(result['lower'], "hello123!@#");
      });
    });

    // =========================================================================
    // Case Checking
    // =========================================================================

    group('Case Checking', () {
      test('isLowerCase() returns true for lowercase', () async {
        final result = await run('''
          var lower = "abc";
          var upper = "ABC";
          var mixed = "aBc";
          
          out("lower", lower.isLowerCase());
          out("upper", upper.isLowerCase());
          out("mixed", mixed.isLowerCase());
        ''');
        expect(result['lower'], true);
        expect(result['upper'], false);
        expect(result['mixed'], false);
      });

      test('isUpperCase() returns true for uppercase', () async {
        final result = await run('''
          var lower = "abc";
          var upper = "ABC";
          var mixed = "aBc";
          
          out("lower", lower.isUpperCase());
          out("upper", upper.isUpperCase());
          out("mixed", mixed.isUpperCase());
        ''');
        expect(result['lower'], false);
        expect(result['upper'], true);
        expect(result['mixed'], false);
      });

      test('isLowerCase() on empty string', () async {
        final result = await run('''
          var s = "";
          out("result", s.isLowerCase());
        ''');
        expect(result['result'], true); // Empty matches regex
      });

      test('isUpperCase() on empty string', () async {
        final result = await run('''
          var s = "";
          out("result", s.isUpperCase());
        ''');
        expect(result['result'], true); // Empty matches regex
      });
    });

    // =========================================================================
    // String Properties
    // =========================================================================

    group('String Properties', () {
      test('length() returns string length', () async {
        final result = await run('''
          var empty = "";
          var short = "hi";
          var longer = "hello world";
          
          out("empty", empty.length());
          out("short", short.length());
          out("longer", longer.length());
        ''');
        expect(result['empty'], 0);
        expect(result['short'], 2);
        expect(result['longer'], 11);
      });

      test('isEmpty() checks for empty string', () async {
        final result = await run('''
          var empty = "";
          var notEmpty = "hello";
          var space = " ";
          
          out("empty", empty.isEmpty());
          out("notEmpty", notEmpty.isEmpty());
          out("space", space.isEmpty());
        ''');
        expect(result['empty'], true);
        expect(result['notEmpty'], false);
        expect(result['space'], false);
      });

      test('isNotEmpty() checks for non-empty string', () async {
        final result = await run('''
          var empty = "";
          var notEmpty = "hello";
          
          out("empty", empty.isNotEmpty());
          out("notEmpty", notEmpty.isNotEmpty());
        ''');
        expect(result['empty'], false);
        expect(result['notEmpty'], true);
      });
    });

    // =========================================================================
    // String Extraction
    // =========================================================================

    group('String Extraction', () {
      test('head() returns first character', () async {
        final result = await run('''
          var s = "hello";
          out("head", s.head());
        ''');
        expect(result['head'], "h");
      });

      test('tail() returns all except first character', () async {
        final result = await run('''
          var s = "hello";
          out("tail", s.tail());
        ''');
        expect(result['tail'], "ello");
      });

      test('substring() extracts portion of string', () async {
        final result = await run('''
          var s = "hello world";
          out("sub1", s.substring(0, 5));
          out("sub2", s.substring(6, 11));
          out("sub3", s.substring(0, 1));
        ''');
        expect(result['sub1'], "hello");
        expect(result['sub2'], "world");
        expect(result['sub3'], "h");
      });

      test('substring() with same start and end', () async {
        final result = await run('''
          var s = "hello";
          out("empty", s.substring(2, 2));
        ''');
        expect(result['empty'], "");
      });
    });

    // =========================================================================
    // String Search
    // =========================================================================

    group('String Search', () {
      test('contains() finds substring', () async {
        final result = await run('''
          var s = "hello world";
          out("hasHello", s.contains("hello"));
          out("hasWorld", s.contains("world"));
          out("hasXyz", s.contains("xyz"));
          out("hasSpace", s.contains(" "));
        ''');
        expect(result['hasHello'], true);
        expect(result['hasWorld'], true);
        expect(result['hasXyz'], false);
        expect(result['hasSpace'], true);
      });

      test('contains() is case sensitive', () async {
        final result = await run('''
          var s = "Hello World";
          out("hasHello", s.contains("Hello"));
          out("hashello", s.contains("hello"));
        ''');
        expect(result['hasHello'], true);
        expect(result['hashello'], false);
      });

      test('contains() with empty string', () async {
        final result = await run('''
          var s = "hello";
          out("hasEmpty", s.contains(""));
        ''');
        expect(result['hasEmpty'], true);
      });
    });

    // =========================================================================
    // String Comparison
    // =========================================================================

    group('String Comparison', () {
      test('compareTo() returns correct comparison', () async {
        final result = await run('''
          var a = "apple";
          var b = "banana";
          var c = "apple";
          
          out("aVsB", a.compareTo(b));
          out("bVsA", b.compareTo(a));
          out("aVsC", a.compareTo(c));
        ''');
        expect((result['aVsB'] as int) < 0, true); // apple < banana
        expect((result['bVsA'] as int) > 0, true); // banana > apple
        expect(result['aVsC'], 0); // apple == apple
      });

      test('compareTo() with case differences', () async {
        final result = await run('''
          var upper = "Apple";
          var lower = "apple";
          out("result", upper.compareTo(lower));
        ''');
        expect((result['result'] as int) < 0, true); // 'A' < 'a' in ASCII
      });
    });

    // =========================================================================
    // String Transformation
    // =========================================================================

    group('String Transformation', () {
      test('trim() removes leading and trailing whitespace', () async {
        final result = await run('''
          var s1 = "  hello  ";
          var s2 = "\\thello\\n";
          var s3 = "hello";
          
          out("s1", s1.trim());
          out("s3", s3.trim());
        ''');
        expect(result['s1'], "hello");
        expect(result['s3'], "hello");
      });

      test('split() divides string by separator', () async {
        final result = await run('''
          var s = "a,b,c,d";
          var parts = s.split(",");
          out("len", parts.length());
          out("first", parts[0]);
          out("last", parts[3]);
        ''');
        expect(result['len'], 4);
        expect(result['first'], "a");
        expect(result['last'], "d");
      });

      test('split() with multi-char separator', () async {
        final result = await run('''
          var s = "one::two::three";
          var parts = s.split("::");
          out("len", parts.length());
          out("second", parts[1]);
        ''');
        expect(result['len'], 3);
        expect(result['second'], "two");
      });

      test('split() with empty separator (char by char)', () async {
        final result = await run('''
          var s = "abc";
          var chars = s.split("");
          out("len", chars.length());
          out("first", chars[0]);
          out("second", chars[1]);
          out("third", chars[2]);
        ''');
        expect(result['len'], 3);
        expect(result['first'], "a");
        expect(result['second'], "b");
        expect(result['third'], "c");
      });

      test('replaceAll() replaces all occurrences', () async {
        final result = await run('''
          var s = "hello hello hello";
          var replaced = s.replaceAll("hello", "hi");
          out("result", replaced);
        ''');
        expect(result['result'], "hi hi hi");
      });

      test('replaceAll() with no matches', () async {
        final result = await run('''
          var s = "hello world";
          var replaced = s.replaceAll("xyz", "abc");
          out("result", replaced);
        ''');
        expect(result['result'], "hello world");
      });

      test('replaceAll() to remove characters', () async {
        final result = await run('''
          var s = "a-b-c-d";
          var replaced = s.replaceAll("-", "");
          out("result", replaced);
        ''');
        expect(result['result'], "abcd");
      });
    });

    // =========================================================================
    // Chaining Operations
    // =========================================================================

    group('Chaining Operations', () {
      test('trim then toUpper', () async {
        final result = await run('''
          var s = "  hello world  ";
          var trimmed = s.trim();
          var upper = trimmed.toUpper();
          out("result", upper);
        ''');
        expect(result['result'], "HELLO WORLD");
      });

      test('split then join (round trip)', () async {
        final result = await run('''
          var original = "a,b,c";
          var parts = original.split(",");
          var rejoined = parts.join("-");
          out("result", rejoined);
        ''');
        expect(result['result'], "a-b-c");
      });

      test('complex string processing', () async {
        final result = await run('''
          var input = "  Hello, World!  ";
          var processed = input.trim();
          processed = processed.toLower();
          processed = processed.replaceAll(",", "");
          processed = processed.replaceAll("!", "");
          out("result", processed);
        ''');
        expect(result['result'], "hello world");
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================

    group('Edge Cases', () {
      test('operations on single character', () async {
        final result = await run('''
          var s = "a";
          out("head", s.head());
          out("tail", s.tail());
          out("upper", s.toUpper());
          out("len", s.length());
        ''');
        expect(result['head'], "a");
        expect(result['tail'], "");
        expect(result['upper'], "A");
        expect(result['len'], 1);
      });

      test('split with no matches returns single element', () async {
        final result = await run('''
          var s = "hello";
          var parts = s.split(",");
          out("len", parts.length());
          out("first", parts[0]);
        ''');
        expect(result['len'], 1);
        expect(result['first'], "hello");
      });

      test('substring full string', () async {
        final result = await run('''
          var s = "hello";
          var full = s.substring(0, 5);
          out("result", full);
        ''');
        expect(result['result'], "hello");
      });

      test('string with special characters', () async {
        final result = await run('''
          var s = "hello\\nworld\\ttab";
          out("len", s.length());
          out("contains", s.contains("world"));
        ''');
        expect(result['contains'], true);
      });

      test('unicode handling', () async {
        final result = await run('''
          var s = "héllo";
          out("len", s.length());
          out("head", s.head());
        ''');
        expect(result['len'], 5);
        expect(result['head'], "h");
      });
    });
  });
}
