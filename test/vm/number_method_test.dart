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
  group('VM Number Methods Tests', () {
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
    // Conversion
    // =========================================================================

    group('Conversion', () {
      test('toString() converts number to string', () async {
        final result = await run('''
          var n1 = 42;
          var n2 = 3.14;
          var n3 = -100;
          
          out("n1", n1.toString());
          out("n2", n2.toString());
          out("n3", n3.toString());
        ''');
        expect(result['n1'], "42");
        expect(result['n2'], "3.14");
        expect(result['n3'], "-100");
      });
    });

    // =========================================================================
    // Parity Checks
    // =========================================================================

    group('Parity Checks', () {
      test('isOdd() returns true for odd numbers', () async {
        final result = await run('''
          out("r1", 1.isOdd());
          out("r3", 3.isOdd());
          out("r99", 99.isOdd());
          out("r2", 2.isOdd());
          out("r0", 0.isOdd());
        ''');
        expect(result['r1'], true);
        expect(result['r3'], true);
        expect(result['r99'], true);
        expect(result['r2'], false);
        expect(result['r0'], false);
      });

      test('isEven() returns true for even numbers', () async {
        final result = await run('''
          out("r0", 0.isEven());
          out("r2", 2.isEven());
          out("r100", 100.isEven());
          out("r1", 1.isEven());
          out("r99", 99.isEven());
        ''');
        expect(result['r0'], true);
        expect(result['r2'], true);
        expect(result['r100'], true);
        expect(result['r1'], false);
        expect(result['r99'], false);
      });

      test('parity with negative numbers', () async {
        final result = await run('''
          var neg1 = -1;
          var neg2 = -2;
          out("neg1Odd", neg1.isOdd());
          out("neg2Even", neg2.isEven());
        ''');
        expect(result['neg1Odd'], true);
        expect(result['neg2Even'], true);
      });
    });

    // =========================================================================
    // Rounding Operations
    // =========================================================================

    group('Rounding Operations', () {
      test('round() rounds to nearest integer', () async {
        final result = await run('''
          out("r1", 3.4.round());
          out("r2", 3.5.round());
          out("r3", 3.6.round());
          out("r4", (-3.5).round());
        ''');
        expect(result['r1'], 3);
        expect(result['r2'], 4);
        expect(result['r3'], 4);
        expect(result['r4'], -4);
      });

      test('floor() rounds down', () async {
        final result = await run('''
          out("r1", 3.9.floor());
          out("r2", 3.1.floor());
          out("r3", (-3.1).floor());
          out("r4", (-3.9).floor());
        ''');
        expect(result['r1'], 3);
        expect(result['r2'], 3);
        expect(result['r3'], -4);
        expect(result['r4'], -4);
      });

      test('ceil() rounds up', () async {
        final result = await run('''
          out("r1", 3.1.ceil());
          out("r2", 3.9.ceil());
          out("r3", (-3.1).ceil());
          out("r4", (-3.9).ceil());
        ''');
        expect(result['r1'], 4);
        expect(result['r2'], 4);
        expect(result['r3'], -3);
        expect(result['r4'], -3);
      });

      test('truncate() removes decimal part', () async {
        final result = await run('''
          out("r1", 3.9.truncate());
          out("r2", 3.1.truncate());
          out("r3", (-3.9).truncate());
          out("r4", (-3.1).truncate());
        ''');
        expect(result['r1'], 3);
        expect(result['r2'], 3);
        expect(result['r3'], -3);
        expect(result['r4'], -3);
      });
    });

    // =========================================================================
    // Absolute Value
    // =========================================================================

    group('Absolute Value', () {
      test('abs() returns absolute value', () async {
        final result = await run('''
          out("pos", 42.abs());
          out("neg", (-42).abs());
          out("zero", 0.abs());
          out("decimal", (-3.14).abs());
        ''');
        expect(result['pos'], 42);
        expect(result['neg'], 42);
        expect(result['zero'], 0);
        expect(result['decimal'], 3.14);
      });
    });

    // =========================================================================
    // Comparison
    // =========================================================================

    group('Comparison', () {
      test('compareTo() returns correct comparison', () async {
        final result = await run('''
          var a = 10;
          var b = 20;
          var c = 10;
          
          out("aVsB", a.compareTo(b));
          out("bVsA", b.compareTo(a));
          out("aVsC", a.compareTo(c));
        ''');
        expect((result['aVsB'] as int) < 0, true);
        expect((result['bVsA'] as int) > 0, true);
        expect(result['aVsC'], 0);
      });

      test('min() returns minimum value', () async {
        final result = await run('''
          out("r1", 10.min(20));
          out("r2", 20.min(10));
          out("r3", 5.min(5));
          out("r4", (-10).min(-5));
        ''');
        expect(result['r1'], 10);
        expect(result['r2'], 10);
        expect(result['r3'], 5);
        expect(result['r4'], -10);
      });

      test('max() returns maximum value', () async {
        final result = await run('''
          out("r1", 10.max(20));
          out("r2", 20.max(10));
          out("r3", 5.max(5));
          out("r4", (-10).max(-5));
        ''');
        expect(result['r1'], 20);
        expect(result['r2'], 20);
        expect(result['r3'], 5);
        expect(result['r4'], -5);
      });
    });

    // =========================================================================
    // Arithmetic Operations
    // =========================================================================

    group('Arithmetic Operations', () {
      test('mod() returns remainder', () async {
        final result = await run('''
          out("r1", 10.mod(3));
          out("r2", 15.mod(5));
          out("r3", 17.mod(4));
        ''');
        expect(result['r1'], 1);
        expect(result['r2'], 0);
        expect(result['r3'], 1);
      });

      test('pow() raises to power', () async {
        final result = await run('''
          out("r1", 2.pow(3));
          out("r2", 10.pow(2));
          out("r3", 2.pow(10));
          out("r4", 5.pow(0));
        ''');
        expect(result['r1'], 8);
        expect(result['r2'], 100);
        expect(result['r3'], 1024);
        expect(result['r4'], 1);
      });

      test('sqrt() returns square root', () async {
        final result = await run('''
          out("r1", 4.sqrt());
          out("r2", 9.sqrt());
          out("r3", 16.sqrt());
          out("r4", 2.sqrt());
        ''');
        expect(result['r1'], 2.0);
        expect(result['r2'], 3.0);
        expect(result['r3'], 4.0);
        expect((result['r4'] as double).toStringAsFixed(4), "1.4142");
      });
    });

    // =========================================================================
    // Exponential and Logarithm
    // =========================================================================

    group('Exponential and Logarithm', () {
      test('exp() returns e raised to power', () async {
        final result = await run('''
          out("exp0", 0.exp());
          out("exp1", 1.exp());
        ''');
        expect(result['exp0'], 1.0);
        expect((result['exp1'] as double).toStringAsFixed(4), "2.7183");
      });

      test('log() returns natural logarithm', () async {
        final result = await run('''
          out("log1", 1.log());
          out("logE", 2.718281828.log());
        ''');
        expect(result['log1'], 0.0);
        expect((result['logE'] as double).toStringAsFixed(4), "1.0000");
      });
    });

    // =========================================================================
    // Trigonometric Functions
    // =========================================================================

    group('Trigonometric Functions', () {
      test('tan() returns tangent', () async {
        final result = await run('''
          out("tan0", 0.tan());
        ''');
        expect(result['tan0'], 0.0);
      });

      test('asin() returns arc sine', () async {
        final result = await run('''
          out("asin0", 0.asin());
          out("asin1", 1.asin());
        ''');
        expect(result['asin0'], 0.0);
        expect(
          (result['asin1'] as double).toStringAsFixed(4),
          "1.5708",
        ); // pi/2
      });

      test('acos() returns arc cosine', () async {
        final result = await run('''
          out("acos1", 1.acos());
          out("acos0", 0.acos());
        ''');
        expect(result['acos1'], 0.0);
        expect(
          (result['acos0'] as double).toStringAsFixed(4),
          "1.5708",
        ); // pi/2
      });

      test('atan() returns arc tangent', () async {
        final result = await run('''
          out("atan0", 0.atan());
          out("atan1", 1.atan());
        ''');
        expect(result['atan0'], 0.0);
        expect(
          (result['atan1'] as double).toStringAsFixed(4),
          "0.7854",
        ); // pi/4
      });

      test('atan2() returns arc tangent of y/x', () async {
        final result = await run('''
          out("r1", 1.atan2(1));
          out("r2", 0.atan2(1));
        ''');
        expect((result['r1'] as double).toStringAsFixed(4), "0.7854"); // pi/4
        expect(result['r2'], 0.0);
      });
    });

    // =========================================================================
    // Chaining Operations
    // =========================================================================

    group('Chaining Operations', () {
      test('multiple operations combined', () async {
        final result = await run('''
          var n = -16;
          var absVal = n.abs();
          var sqrtVal = absVal.sqrt();
          out("result", sqrtVal);
        ''');
        expect(result['result'], 4.0);
      });

      test('round after sqrt', () async {
        final result = await run('''
          var n = 10;
          var sqrtVal = n.sqrt();
          var rounded = sqrtVal.round();
          out("result", rounded);
        ''');
        expect(result['result'], 3);
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================

    group('Edge Cases', () {
      test('operations on zero', () async {
        final result = await run('''
          out("sqrt", 0.sqrt());
          out("abs", 0.abs());
          out("round", 0.round());
          out("isEven", 0.isEven());
          out("isOdd", 0.isOdd());
        ''');
        expect(result['sqrt'], 0.0);
        expect(result['abs'], 0);
        expect(result['round'], 0);
        expect(result['isEven'], true);
        expect(result['isOdd'], false);
      });

      test('operations on one', () async {
        final result = await run('''
          out("sqrt", 1.sqrt());
          out("exp", 0.exp());
          out("log", 1.log());
          out("pow", 1.pow(100));
        ''');
        expect(result['sqrt'], 1.0);
        expect(result['exp'], 1.0);
        expect(result['log'], 0.0);
        expect(result['pow'], 1);
      });

      test('large numbers', () async {
        final result = await run('''
          var big = 1000000;
          out("sqrt", big.sqrt());
          out("mod", big.mod(7));
        ''');
        expect(result['sqrt'], 1000.0);
        expect(result['mod'], 1); // 1000000 % 7 = 1
      });
    });
  });
}
