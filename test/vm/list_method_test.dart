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
  group('VM List Methods Tests', () {
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
    // Basic List Operations
    // =========================================================================

    group('Basic Operations', () {
      test('length() returns list size', () async {
        final result = await run('''
          var empty = [];
          var one = [1];
          var many = [1, 2, 3, 4, 5];
          
          out("empty", empty.length());
          out("one", one.length());
          out("many", many.length());
        ''');
        expect(result['empty'], 0);
        expect(result['one'], 1);
        expect(result['many'], 5);
      });

      test('isEmpty() checks for empty list', () async {
        final result = await run('''
          var empty = [];
          var notEmpty = [1, 2, 3];
          
          out("empty", empty.isEmpty());
          out("notEmpty", notEmpty.isEmpty());
        ''');
        expect(result['empty'], true);
        expect(result['notEmpty'], false);
      });

      test('isNotEmpty() checks for non-empty list', () async {
        final result = await run('''
          var empty = [];
          var notEmpty = [1, 2, 3];
          
          out("empty", empty.isNotEmpty());
          out("notEmpty", notEmpty.isNotEmpty());
        ''');
        expect(result['empty'], false);
        expect(result['notEmpty'], true);
      });

      test('head() returns first element', () async {
        final result = await run('''
          var lst = [10, 20, 30];
          out("head", lst.head());
        ''');
        expect(result['head'], 10);
      });

      test('tail() returns all except first', () async {
        final result = await run('''
          var lst = [1, 2, 3, 4];
          var t = lst.tail();
          out("len", t.length());
          out("first", t[0]);
          out("last", t[2]);
        ''');
        expect(result['len'], 3);
        expect(result['first'], 2);
        expect(result['last'], 4);
      });

      test('toString() converts list to string', () async {
        final result = await run('''
          var lst = [1, 2, 3];
          var str = lst.toString();
          out("str", str);
        ''');
        expect(result['str'], "[1, 2, 3]");
      });
    });

    // =========================================================================
    // Mutating Operations
    // =========================================================================

    group('Mutating Operations', () {
      test('add() appends element and returns new length', () async {
        final result = await run('''
          var lst = [1, 2];
          var newLen = lst.add(3);
          out("newLen", newLen);
          out("listLen", lst.length());
          out("last", lst[2]);
        ''');
        expect(result['newLen'], 3);
        expect(result['listLen'], 3);
        expect(result['last'], 3);
      });

      test('addAll() appends multiple elements', () async {
        final result = await run('''
          var lst = [1, 2];
          var newLen = lst.addAll([3, 4, 5]);
          out("newLen", newLen);
          out("listLen", lst.length());
          out("last", lst[4]);
        ''');
        expect(result['newLen'], 5);
        expect(result['listLen'], 5);
        expect(result['last'], 5);
      });

      test('removeAt() removes element at index', () async {
        final result = await run('''
          var lst = [10, 20, 30, 40];
          var newLen = lst.removeAt(1);
          out("newLen", newLen);
          out("second", lst[1]);
        ''');
        expect(result['newLen'], 3);
        expect(result['second'], 30); // 20 was removed
      });

      test('clear() removes all elements', () async {
        final result = await run('''
          var lst = [1, 2, 3, 4, 5];
          var newLen = lst.clear();
          out("newLen", newLen);
          out("isEmpty", lst.isEmpty());
        ''');
        expect(result['newLen'], 0);
        expect(result['isEmpty'], true);
      });

      test('removeWhere() removes matching elements', () async {
        final result = await run('''
          var lst = [1, 2, 3, 4, 5, 6];
          var newLen = await lst.removeWhere(fun(x) { return x % 2 == 0; });
          out("newLen", newLen);
          out("first", lst[0]);
          out("second", lst[1]);
          out("third", lst[2]);
        ''');
        expect(result['newLen'], 3);
        expect(result['first'], 1);
        expect(result['second'], 3);
        expect(result['third'], 5);
      });
    });

    // =========================================================================
    // Search Operations
    // =========================================================================

    group('Search Operations', () {
      test('indexOf() finds element index', () async {
        final result = await run('''
          var lst = ["a", "b", "c", "d"];
          out("found", lst.indexOf("c"));
          out("notFound", lst.indexOf("z"));
        ''');
        expect(result['found'], 2);
        expect(result['notFound'], -1);
      });

      test('contains() checks for element presence', () async {
        final result = await run('''
          var lst = [10, 20, 30];
          out("has20", lst.contains(20));
          out("has50", lst.contains(50));
        ''');
        expect(result['has20'], true);
        expect(result['has50'], false);
      });
    });

    // =========================================================================
    // Transformation Operations
    // =========================================================================

    group('Transformation Operations', () {
      test('map() transforms each element', () async {
        final result = await run('''
          var lst = [1, 2, 3, 4];
          var doubled = await lst.map(fun(x) { return x * 2; });
          out("len", doubled.length());
          out("first", doubled[0]);
          out("last", doubled[3]);
        ''');
        expect(result['len'], 4);
        expect(result['first'], 2);
        expect(result['last'], 8);
      });

      test('filter() keeps matching elements', () async {
        final result = await run('''
          var lst = [1, 2, 3, 4, 5, 6, 7, 8];
          var evens = await lst.filter(fun(x) { return x % 2 == 0; });
          out("len", evens.length());
          out("first", evens[0]);
          out("last", evens[3]);
        ''');
        expect(result['len'], 4);
        expect(result['first'], 2);
        expect(result['last'], 8);
      });

      test('reversed() returns reversed list', () async {
        final result = await run('''
          var lst = [1, 2, 3, 4, 5];
          var rev = lst.reversed();
          out("origFirst", lst[0]);
          out("revFirst", rev[0]);
          out("revLast", rev[4]);
        ''');
        expect(result['origFirst'], 1); // Original unchanged
        expect(result['revFirst'], 5);
        expect(result['revLast'], 1);
      });

      test('join() combines elements with separator', () async {
        final result = await run('''
          var lst = ["a", "b", "c"];
          var joined = lst.join("-");
          out("joined", joined);
          
          var nums = [1, 2, 3];
          var numJoined = nums.join(", ");
          out("numJoined", numJoined);
        ''');
        expect(result['joined'], "a-b-c");
        expect(result['numJoined'], "1, 2, 3");
      });

      test('sort() sorts with comparator', () async {
        final result = await run('''
          var lst = [3, 1, 4, 1, 5, 9, 2, 6];
          await lst.sort(fun(a, b) { return a - b; });
          out("first", lst[0]);
          out("second", lst[1]);
          out("last", lst[7]);
        ''');
        expect(result['first'], 1);
        expect(result['second'], 1);
        expect(result['last'], 9);
      });

      test('sort() descending order', () async {
        final result = await run('''
          var lst = [3, 1, 4, 1, 5];
          await lst.sort(fun(a, b) { return b - a; });
          out("first", lst[0]);
          out("last", lst[4]);
        ''');
        expect(result['first'], 5);
        expect(result['last'], 1);
      });
    });

    // =========================================================================
    // Aggregation Operations
    // =========================================================================

    group('Aggregation Operations', () {
      test('fold() reduces to single value (sum)', () async {
        final result = await run('''
          var lst = [1, 2, 3, 4, 5];
          var sum = await lst.fold(0, fun(el, acc) { return acc + el; });
          out("sum", sum);
        ''');
        expect(result['sum'], 15);
      });

      test('fold() reduces to single value (product)', () async {
        final result = await run('''
          var lst = [1, 2, 3, 4, 5];
          var product = await lst.fold(1, fun(el, acc) { return acc * el; });
          out("product", product);
        ''');
        expect(result['product'], 120);
      });

      test('fold() with string concatenation', () async {
        final result = await run('''
          var words = ["Hello", "World", "Test"];
          var sentence = await words.fold("", fun(word, acc) { 
            if (acc == "") { return word; }
            return acc + " " + word;
          });
          out("sentence", sentence);
        ''');
        expect(result['sentence'], "Hello World Test");
      });

      test('every() checks if all match', () async {
        final result = await run('''
          var allPositive = [1, 2, 3, 4, 5];
          var mixed = [1, -2, 3, -4, 5];
          
          var r1 = await allPositive.every(fun(x) { return x > 0; });
          var r2 = await mixed.every(fun(x) { return x > 0; });
          
          out("allPositive", r1);
          out("mixed", r2);
        ''');
        expect(result['allPositive'], true);
        expect(result['mixed'], false);
      });

      test('any() checks if any match', () async {
        final result = await run('''
          var lst = [1, 2, 3, 4, 5];
          var noMatch = [1, 2, 3];
          
          var r1 = await lst.any(fun(x) { return x > 4; });
          var r2 = await noMatch.any(fun(x) { return x > 10; });
          
          out("hasGreaterThan4", r1);
          out("hasGreaterThan10", r2);
        ''');
        expect(result['hasGreaterThan4'], true);
        expect(result['hasGreaterThan10'], false);
      });
    });

    // =========================================================================
    // Iteration Operations
    // =========================================================================

    group('Iteration Operations', () {
      test('forEach() iterates over elements', () async {
        final result = await run('''
          var lst = [1, 2, 3, 4, 5];
          var sum = 0;
          await lst.forEach(fun(x) { sum = sum + x; });
          out("sum", sum);
        ''');
        expect(result['sum'], 15);
      });

      test('forEach() with index tracking', () async {
        final result = await run('''
          var lst = ["a", "b", "c"];
          var count = 0;
          await lst.forEach(fun(x) { count = count + 1; });
          out("count", count);
        ''');
        expect(result['count'], 3);
      });
    });

    // =========================================================================
    // Chaining Operations
    // =========================================================================

    group('Chaining Operations', () {
      test('map then filter', () async {
        final result = await run('''
          var lst = [1, 2, 3, 4, 5];
          var doubled = await lst.map(fun(x) { return x * 2; });
          var filtered = await doubled.filter(fun(x) { return x > 5; });
          out("len", filtered.length());
          out("first", filtered[0]);
        ''');
        expect(result['len'], 3); // [6, 8, 10]
        expect(result['first'], 6);
      });

      test('filter then map then fold', () async {
        final result = await run('''
          var lst = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
          // Get evens, double them, sum
          var evens = await lst.filter(fun(x) { return x % 2 == 0; });
          var doubled = await evens.map(fun(x) { return x * 2; });
          var sum = await doubled.fold(0, fun(el, acc) { return acc + el; });
          out("sum", sum);
        ''');
        // evens: [2, 4, 6, 8, 10]
        // doubled: [4, 8, 12, 16, 20]
        // sum: 60
        expect(result['sum'], 60);
      });

      test('complex pipeline with multiple operations', () async {
        final result = await run('''
          var data = [
            {"name": "Alice", "age": 30},
            {"name": "Bob", "age": 25},
            {"name": "Charlie", "age": 35},
            {"name": "Diana", "age": 28}
          ];
          
          // Filter age > 26, map to names, join
          var adults = await data.filter(fun(p) { return p["age"] > 26; });
          var names = await adults.map(fun(p) { return p["name"]; });
          var result = names.join(", ");
          
          out("result", result);
          out("count", names.length());
        ''');
        expect(result['result'], "Alice, Charlie, Diana");
        expect(result['count'], 3);
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================

    group('Edge Cases', () {
      test('operations on empty list', () async {
        final result = await run('''
          var empty = [];
          
          var mapped = await empty.map(fun(x) { return x * 2; });
          var filtered = await empty.filter(fun(x) { return true; });
          var sum = await empty.fold(0, fun(el, acc) { return acc + el; });
          var allTrue = await empty.every(fun(x) { return false; });
          var anyTrue = await empty.any(fun(x) { return true; });
          
          out("mappedLen", mapped.length());
          out("filteredLen", filtered.length());
          out("sum", sum);
          out("allTrue", allTrue);
          out("anyTrue", anyTrue);
        ''');
        expect(result['mappedLen'], 0);
        expect(result['filteredLen'], 0);
        expect(result['sum'], 0);
        expect(result['allTrue'], true); // vacuous truth
        expect(result['anyTrue'], false);
      });

      test('single element list operations', () async {
        final result = await run('''
          var single = [42];
          
          out("head", single.head());
          out("tailLen", single.tail().length());
          out("reversed", single.reversed()[0]);
          out("contains", single.contains(42));
          out("indexOf", single.indexOf(42));
        ''');
        expect(result['head'], 42);
        expect(result['tailLen'], 0);
        expect(result['reversed'], 42);
        expect(result['contains'], true);
        expect(result['indexOf'], 0);
      });

      test('nested lists', () async {
        final result = await run('''
          var nested = [[1, 2], [3, 4], [5, 6]];
          
          out("len", nested.length());
          out("firstLen", nested[0].length());
          out("deepVal", nested[1][1]);
          
          // Map over nested
          var sums = await nested.map(fun(inner) { 
            return inner[0] + inner[1]; 
          });
          out("sums", sums.join(","));
        ''');
        expect(result['len'], 3);
        expect(result['firstLen'], 2);
        expect(result['deepVal'], 4);
        expect(result['sums'], "3,7,11");
      });

      test('list with mixed types', () async {
        final result = await run('''
          var mixed = [1, "two", true, 4.5];
          
          out("len", mixed.length());
          out("first", mixed[0]);
          out("second", mixed[1]);
          out("third", mixed[2]);
        ''');
        expect(result['len'], 4);
        expect(result['first'], 1);
        expect(result['second'], "two");
        expect(result['third'], true);
      });
    });
  });
}
