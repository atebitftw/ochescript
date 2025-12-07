import 'package:test/test.dart';
import 'package:oche_script/oche_script.dart';

class MockPreprocesser extends IncludesPreprocesser {
  @override
  Map<String, String> getLibraries(String source) {
    return {};
  }
}

void main() {
  group('Bytecode VM String Concatenation', () {
    Future<Map<String, Object>> run(String source) async {
      return await compileAndRun(source, preprocesser: MockPreprocesser());
    }

    test('string + number concatenation', () async {
      final result = await run('''
        var s = "Value: " + 42;
        out("result", s);
      ''');
      expect(result['result'], equals('Value: 42'));
    });

    test('number + string concatenation', () async {
      final result = await run('''
        var s = 42 + " items";
        out("result", s);
      ''');
      expect(result['result'], equals('42 items'));
    });

    test('string + (number - number) concatenation', () async {
      final result = await run('''
        var start = 100;
        var end = 150;
        var s = "Difference: " + (end - start);
        out("result", s);
      ''');
      expect(result['result'], equals('Difference: 50'));
    });

    test('benchmark_fib style concatenation', () async {
      final result = await run('''
        var start = clock();
        var elapsed = clock() - start;
        var msg = "Finished in " + elapsed + "ms";
        out("result", msg);
      ''');
      expect(result['result'], matches(RegExp(r'Finished in \d+ms')));
    });
  });
}
