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
  group('VM Async/Await', () {
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

    test('executes simple async function', () async {
      final result = await run('''
        async fun getValue() {
          return 100;
        }
        
        var res = getValue();
        out("result", res);
      ''');
      expect(result['result'], 100);
    });

    test('executes await expression', () async {
      final result = await run('''
        async fun asyncOperation() {
          return 42;
        }
        
        async fun caller() {
          var value = await asyncOperation();
          return value;
        }
        
        var res = caller();
        out("result", res);
      ''');
      expect(result['result'], 42);
    });

    test('await works with non-Future values', () async {
      final result = await run('''
        async fun test() {
          var normalValue = 10;
          var awaited = await normalValue;
          return awaited;
        }
        
        var res = test();
        out("result", res);
      ''');
      expect(result['result'], 10);
    });

    test('async function chains', () async {
      final result = await run('''
        async fun getBase() {
          return 10;
        }
        
        async fun getDouble() {
          var base = await getBase();
          return base * 2;
        }
        
        async fun getQuadruple() {
          var doubled = await getDouble();
          return doubled * 2;
        }
        
        var res = getQuadruple();
        out("result", res);
      ''');
      expect(result['result'], 40);
    });

    test('async function with multiple awaits', () async {
      final result = await run('''
        async fun getValue(x) {
          return x;
        }
        
        async fun sum() {
          var a = await getValue(10);
          var b = await getValue(20);
          var c = await getValue(30);
          return a + b + c;
        }
        
        var res = sum();
        out("result", res);
      ''');
      expect(result['result'], 60);
    });

    test('async function with conditionals', () async {
      final result = await run('''
        async fun getValue(flag) {
          if (flag) {
            return 100;
          } else {
            return 200;
          }
        }
        
        async fun test() {
          var a = await getValue(true);
          var b = await getValue(false);
          return a + b;
        }
        
        var res = test();
        out("result", res);
      ''');
      expect(result['result'], 300);
    });

    test('async function with sequential calls', () async {
      final result = await run('''
        async fun getValue() {
          return 5;
        }
        
        async fun sum() {
          var a = 1;
          var b = 2;
          var c = 3;
          var d = 4;
          var e = await getValue();
          return a + b + c + d + e;
        }
        
        var res = sum();
        out("result", res);
      ''');
      expect(result['result'], 15);
    });

    test('async anonymous functions', () async {
      final result = await run('''
        var asyncFunc = async fun(x) {
          return x * 2;
        };
        
        async fun caller() {
          var result = await asyncFunc(21);
          return result;
        }
        
        var output = caller();
        out("output", output);
      ''');
      expect(result['output'], 42);
    });

    test('async recursion', () async {
      final result = await run('''
        async fun factorial(n) {
          if (n <= 1) {
            return 1;
          }
          var prev = await factorial(n - 1);
          return n * prev;
        }
        
        var res = factorial(5);
        out("result", res);
      ''');
      expect(result['result'], 120); // 5!
    });

    test('await in arithmetic expressions', () async {
      final result = await run('''
        async fun getValue(x) {
          return x;
        }
        
        async fun test() {
          var a = (await getValue(10)) + (await getValue(5));
          return a;
        }
        
        var res = test();
        out("result", res);
      ''');
      expect(result['result'], 15);
    });

    test('async function with loops', () async {
      final result = await run('''
        async fun getNumber(n) {
          return n;
        }
        
        async fun sumNumbers() {
          var total = 0;
          for (var i = 1; i < 6; i = i + 1) {
            var myNum = await getNumber(i);
            total = total + myNum;
          }
          return total;
        }
        
        var res = sumNumbers();
        out("result", res);
      ''');
      expect(result['result'], 15); // 1+2+3+4+5
    });

    test('async with lists', () async {
      final result = await run('''
        async fun getList() {
          return [1, 2, 3];
        }
        
        async fun test() {
          var myList = await getList();
          return myList[0];
        }
        
        var res = test();
        out("result", res);
      ''');
      expect(result['result'], 1);
    });

    test('mixed async and sync functions', () async {
      final result = await run('''
        fun syncFunc(x) {
          return x * 2;
        }
        
        async fun asyncFunc(x) {
          return x + 10;
        }
        
        async fun mixed() {
          var a = syncFunc(5);
          var b = await asyncFunc(5);
          return a + b;
        }
        
        var res = mixed();
        out("result", res);
      ''');
      expect(result['result'], 25); // (5*2) + (5+10)
    });

    test('async function with early return', () async {
      final result = await run('''
        async fun test(flag) {
          if (flag) {
            return 99;
          }
          return 0;
        }
        
        var res = test(true);
        out("result", res);
      ''');
      expect(result['result'], 99);
    });

    test('nested async calls', () async {
      final result = await run('''
        async fun add(a, b) {
          return a + b;
        }
        
        async fun multiply(a, b) {
          return a * b;
        }
        
        async fun compute() {
          var sum = await add(5, 3);
          var product = await multiply(sum, 2);
          return product;
        }
        
        var res = compute();
        out("result", res);
      ''');
      expect(result['result'], 16); // (5+3)*2
    });
  });
}
