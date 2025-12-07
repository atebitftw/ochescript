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
import 'package:oche_script/native_functions/define_native_functions.dart';

void main() {
  group('VM Duration Methods Tests', () {
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
      defineVmNativeFunctions(vm);
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
    // Duration Creation
    // =========================================================================

    group('Duration Creation', () {
      test('duration() creates duration from components', () async {
        final result = await run('''
          // duration(milliseconds, seconds, minutes, hours, days)
          var d = duration(500, 30, 5, 2, 1);
          out("inHours", d.inHours());
        ''');
        // 1 day + 2 hours = 26 hours
        expect(result['inHours'], 26);
      });

      test('duration with only milliseconds', () async {
        final result = await run('''
          var d = duration(5000, 0, 0, 0, 0);
          out("inMilliseconds", d.inMilliseconds());
          out("inSeconds", d.inSeconds());
        ''');
        expect(result['inMilliseconds'], 5000);
        expect(result['inSeconds'], 5);
      });
    });

    // =========================================================================
    // Time Unit Conversions
    // =========================================================================

    group('Time Unit Conversions', () {
      test('inMilliseconds() returns total milliseconds', () async {
        final result = await run('''
          var d = duration(0, 5, 0, 0, 0);
          out("ms", d.inMilliseconds());
        ''');
        expect(result['ms'], 5000);
      });

      test('inSeconds() returns total seconds', () async {
        final result = await run('''
          var d = duration(0, 0, 2, 0, 0);
          out("seconds", d.inSeconds());
        ''');
        expect(result['seconds'], 120);
      });

      test('inMinutes() returns total minutes', () async {
        final result = await run('''
          var d = duration(0, 0, 0, 2, 0);
          out("minutes", d.inMinutes());
        ''');
        expect(result['minutes'], 120);
      });

      test('inHours() returns total hours', () async {
        final result = await run('''
          var d = duration(0, 0, 0, 0, 2);
          out("hours", d.inHours());
        ''');
        expect(result['hours'], 48);
      });

      test('inYears() returns approximate years', () async {
        final result = await run('''
          var d = duration(0, 0, 0, 0, 730);
          out("years", d.inYears());
        ''');
        expect(result['years'], 2.0);
      });
    });

    // =========================================================================
    // Duration Properties
    // =========================================================================

    group('Duration Properties', () {
      test('isNegative() returns false for positive duration', () async {
        final result = await run('''
          var d = duration(1000, 0, 0, 0, 0);
          out("isNeg", d.isNegative());
        ''');
        expect(result['isNeg'], false);
      });

      test('isNegative() detected via date subtraction', () async {
        // Creating negative duration by subtracting larger from smaller
        final result = await run('''
          var d1 = date(2024, 1, 10, 0, 0, 0, 0);
          var d2 = date(2024, 1, 1, 0, 0, 0, 0);
          var diff = d2 - d1;
          out("isNeg", diff.isNegative());
        ''');
        expect(result['isNeg'], true);
      });

      test('abs() returns absolute duration', () async {
        final result = await run('''
          var d1 = date(2024, 1, 1, 0, 0, 0, 0);
          var d2 = date(2024, 1, 11, 0, 0, 0, 0);
          var negDiff = d1 - d2;
          var absDiff = negDiff.abs();
          
          out("negHours", negDiff.inHours());
          out("absHours", absDiff.inHours());
        ''');
        expect(result['negHours'], -240); // -10 days
        expect(result['absHours'], 240); // 10 days
      });
    });

    // =========================================================================
    // Duration Comparison
    // =========================================================================

    group('Duration Comparison', () {
      test('compareTo() returns correct comparison', () async {
        final result = await run('''
          var short = duration(0, 0, 30, 0, 0);
          var long = duration(0, 0, 0, 2, 0);
          var same = duration(0, 0, 30, 0, 0);
          
          out("shortVsLong", short.compareTo(long));
          out("longVsShort", long.compareTo(short));
          out("sameVsSame", short.compareTo(same));
        ''');
        expect((result['shortVsLong'] as int) < 0, true);
        expect((result['longVsShort'] as int) > 0, true);
        expect(result['sameVsSame'], 0);
      });
    });

    // =========================================================================
    // Duration Arithmetic
    // =========================================================================

    group('Duration Arithmetic', () {
      test('adding durations', () async {
        final result = await run('''
          var d1 = duration(0, 0, 30, 0, 0);
          var d2 = duration(0, 0, 45, 0, 0);
          var total = d1 + d2;
          out("minutes", total.inMinutes());
        ''');
        expect(result['minutes'], 75);
      });

      test('subtracting durations', () async {
        final result = await run('''
          var d1 = duration(0, 0, 0, 3, 0);
          var d2 = duration(0, 0, 0, 1, 0);
          var diff = d1 - d2;
          out("hours", diff.inHours());
        ''');
        expect(result['hours'], 2);
      });

      test('duration from date difference', () async {
        final result = await run('''
          var start = date(2024, 1, 1, 10, 0, 0, 0);
          var end = date(2024, 1, 1, 12, 30, 0, 0);
          var elapsed = end - start;
          
          out("minutes", elapsed.inMinutes());
          out("hours", elapsed.inHours());
        ''');
        expect(result['minutes'], 150);
        expect(result['hours'], 2);
      });
    });

    // =========================================================================
    // Complex Operations
    // =========================================================================

    group('Complex Operations', () {
      test('calculate total time from multiple durations', () async {
        final result = await run('''
          var times = [
            duration(0, 0, 30, 0, 0),
            duration(0, 0, 45, 0, 0),
            duration(0, 0, 0, 1, 0),
            duration(0, 0, 15, 0, 0)
          ];
          
          var total = duration(0, 0, 0, 0, 0);
          for (var i = 0; i < times.length(); i = i + 1) {
            total = total + times[i];
          }
          
          out("totalMinutes", total.inMinutes());
        ''');
        // 30 + 45 + 60 + 15 = 150 minutes
        expect(result['totalMinutes'], 150);
      });

      test('time tracking scenario', () async {
        final result = await run('''
          var startWork = date(2024, 6, 15, 9, 0, 0, 0);
          var lunchStart = date(2024, 6, 15, 12, 0, 0, 0);
          var lunchEnd = date(2024, 6, 15, 13, 0, 0, 0);
          var endWork = date(2024, 6, 15, 17, 30, 0, 0);
          
          var morningWork = lunchStart - startWork;
          var afternoonWork = endWork - lunchEnd;
          var totalWork = morningWork + afternoonWork;
          
          out("morningHours", morningWork.inHours());
          out("afternoonHours", afternoonWork.inHours());
          out("totalMinutes", totalWork.inMinutes());
        ''');
        expect(result['morningHours'], 3);
        expect(result['afternoonHours'], 4);
        expect(result['totalMinutes'], 450); // 7.5 hours = 450 minutes
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================

    group('Edge Cases', () {
      test('zero duration', () async {
        final result = await run('''
          var zero = duration(0, 0, 0, 0, 0);
          out("ms", zero.inMilliseconds());
          out("hours", zero.inHours());
          out("isNeg", zero.isNegative());
        ''');
        expect(result['ms'], 0);
        expect(result['hours'], 0);
        expect(result['isNeg'], false);
      });

      test('very large duration', () async {
        final result = await run('''
          var years = duration(0, 0, 0, 0, 3650);
          out("inYears", years.inYears());
          out("inHours", years.inHours());
        ''');
        expect(result['inYears'], 10.0);
        expect(result['inHours'], 87600);
      });

      test('same date difference is zero', () async {
        final result = await run('''
          var d = date(2024, 6, 15, 12, 0, 0, 0);
          var diff = d - d;
          out("ms", diff.inMilliseconds());
        ''');
        expect(result['ms'], 0);
      });
    });
  });
}
