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
import 'package:oche_script/native_functions/define_native_functions.dart';

void main() {
  group('VM Date Methods Tests', () {
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
    // Date Components
    // =========================================================================

    group('Date Components', () {
      test('year() returns year', () async {
        final result = await run(r'''
          var d = date(2024, 12, 25, 10, 30, 45, 500);
          out("year", d.year());
        ''');
        expect(result['year'], 2024);
      });

      test('month() returns month', () async {
        final result = await run('''
          var d = date(2024, 12, 25, 10, 30, 45, 500);
          out("month", d.month());
        ''');
        expect(result['month'], 12);
      });

      test('day() returns day', () async {
        final result = await run('''
          var d = date(2024, 12, 25, 10, 30, 45, 500);
          out("day", d.day());
        ''');
        expect(result['day'], 25);
      });

      test('hour() returns hour', () async {
        final result = await run('''
          var d = date(2024, 12, 25, 10, 30, 45, 500);
          out("hour", d.hour());
        ''');
        expect(result['hour'], 10);
      });

      test('minute() returns minute', () async {
        final result = await run('''
          var d = date(2024, 12, 25, 10, 30, 45, 500);
          out("minute", d.minute());
        ''');
        expect(result['minute'], 30);
      });

      test('millisecond() returns millisecond', () async {
        final result = await run('''
          var d = date(2024, 12, 25, 10, 30, 45, 500);
          out("ms", d.millisecond());
        ''');
        expect(result['ms'], 500);
      });

      test('weekday() returns day of week', () async {
        final result = await run('''
          // December 25, 2024 is a Wednesday (3)
          var d = date(2024, 12, 25, 0, 0, 0, 0);
          out("weekday", d.weekday());
        ''');
        expect(result['weekday'], 3); // Wednesday
      });
    });

    // =========================================================================
    // Time Zone
    // =========================================================================

    group('Time Zone', () {
      test('isUtc() returns false for local dates', () async {
        final result = await run('''
          var d = date(2024, 12, 25, 10, 30, 45, 500);
          out("isUtc", d.isUtc());
        ''');
        expect(result['isUtc'], false);
      });

      test('timeZoneName() returns timezone name', () async {
        final result = await run('''
          var d = date(2024, 12, 25, 10, 30, 45, 500);
          var tz = d.timeZoneName();
          out("hasName", tz.length() > 0);
        ''');
        expect(result['hasName'], true);
      });

      test('timeZoneOffset() returns duration', () async {
        final result = await run('''
          var d = date(2024, 12, 25, 10, 30, 45, 500);
          var offset = d.timeZoneOffset();
          // Offset is a Duration - just check it exists
          out("inHours", offset.inHours());
        ''');
        // Just verify it returns a number (timezone offset in hours)
        expect(result['inHours'] is int, true);
      });
    });

    // =========================================================================
    // Date Comparison
    // =========================================================================

    group('Date Comparison', () {
      test('compareTo() returns correct comparison', () async {
        final result = await run(r'''
          var earlier = date(2024, 1, 1, 0, 0, 0, 0);
          var later = date(2024, 12, 31, 0, 0, 0, 0);
          var same = date(2024, 1, 1, 0, 0, 0, 0);
          
          out("earlierVsLater", earlier.compareTo(later));
          out("laterVsEarlier", later.compareTo(earlier));
          out("sameVsSame", earlier.compareTo(same));
        ''');
        expect((result['earlierVsLater'] as int) < 0, true);
        expect((result['laterVsEarlier'] as int) > 0, true);
        expect(result['sameVsSame'], 0);
      });

      test('comparing dates with same date different time', () async {
        final result = await run('''
          var morning = date(2024, 6, 15, 8, 0, 0, 0);
          var evening = date(2024, 6, 15, 20, 0, 0, 0);
          
          out("morningVsEvening", morning.compareTo(evening));
        ''');
        expect((result['morningVsEvening'] as int) < 0, true);
      });
    });

    // =========================================================================
    // Date Arithmetic with Duration
    // =========================================================================

    group('Date Arithmetic', () {
      test('adding duration to date', () async {
        final result = await run('''
          var d = date(2024, 1, 1, 0, 0, 0, 0);
          var oneDay = duration(0, 0, 0, 24, 0);
          var tomorrow = d + oneDay;
          
          out("day", tomorrow.day());
          out("month", tomorrow.month());
        ''');
        expect(result['day'], 2);
        expect(result['month'], 1);
      });

      test('subtracting duration from date', () async {
        final result = await run('''
          var d = date(2024, 1, 10, 12, 0, 0, 0);
          var oneDay = duration(0, 0, 0, 24, 0);
          var yesterday = d - oneDay;
          
          out("day", yesterday.day());
        ''');
        expect(result['day'], 9);
      });

      test('difference between dates', () async {
        final result = await run('''
          var d1 = date(2024, 1, 1, 0, 0, 0, 0);
          var d2 = date(2024, 1, 11, 0, 0, 0, 0);
          var diff = d2 - d1;
          
          // diff should be a Duration
          out("days", diff.inHours() / 24);
        ''');
        expect(result['days'], 10.0);
      });
    });

    // =========================================================================
    // Using now()
    // =========================================================================

    group('Current Date', () {
      test('now() returns current time', () async {
        final result = await run('''
          var n = now();
          var year = n.year();
          out("year", year);
        ''');
        // Should be current year (2024 or later)
        expect((result['year'] as int) >= 2024, true);
      });

      test('now() has reasonable values', () async {
        final result = await run('''
          var n = now();
          out("month", n.month());
          out("day", n.day());
          out("hour", n.hour());
        ''');
        expect((result['month'] as int) >= 1 && (result['month'] as int) <= 12, true);
        expect((result['day'] as int) >= 1 && (result['day'] as int) <= 31, true);
        expect((result['hour'] as int) >= 0 && (result['hour'] as int) <= 23, true);
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================

    group('Edge Cases', () {
      test('leap year date', () async {
        final result = await run('''
          var leapDay = date(2024, 2, 29, 12, 0, 0, 0);
          out("month", leapDay.month());
          out("day", leapDay.day());
        ''');
        expect(result['month'], 2);
        expect(result['day'], 29);
      });

      test('end of year', () async {
        final result = await run('''
          var endOfYear = date(2024, 12, 31, 23, 59, 59, 999);
          out("month", endOfYear.month());
          out("day", endOfYear.day());
          out("hour", endOfYear.hour());
          out("minute", endOfYear.minute());
        ''');
        expect(result['month'], 12);
        expect(result['day'], 31);
        expect(result['hour'], 23);
        expect(result['minute'], 59);
      });

      test('new year midnight', () async {
        final result = await run('''
          var newYear = date(2025, 1, 1, 0, 0, 0, 0);
          out("year", newYear.year());
          out("month", newYear.month());
          out("day", newYear.day());
        ''');
        expect(result['year'], 2025);
        expect(result['month'], 1);
        expect(result['day'], 1);
      });
    });

    // =========================================================================
    // Complex Operations
    // =========================================================================

    group('Complex Operations', () {
      test('date components to string', () async {
        final result = await run('''
          var d = date(2024, 6, 15, 14, 30, 0, 0);
          var y = d.year().toString();
          var m = d.month().toString();
          var day = d.day().toString();
          var formatted = y + "-" + m + "-" + day;
          out("formatted", formatted);
        ''');
        expect(result['formatted'], "2024-6-15");
      });

      test('comparing multiple dates', () async {
        final result = await run('''
          var dates = [
            date(2024, 3, 15, 0, 0, 0, 0),
            date(2024, 1, 10, 0, 0, 0, 0),
            date(2024, 6, 20, 0, 0, 0, 0)
          ];
          
          // Find earliest month
          var minMonth = 12;
          for (var i = 0; i < dates.length(); i = i + 1) {
            var m = dates[i].month();
            if (m < minMonth) {
              minMonth = m;
            }
          }
          out("minMonth", minMonth);
        ''');
        expect(result['minMonth'], 1);
      });
    });
  });
}
