import 'package:test/test.dart';
import 'package:oche_script/oche_script.dart';

class MockPreprocesser extends IncludesPreprocesser {
  @override
  Map<String, String> getLibraries(String source) {
    return {};
  }
}

void main() {
  group('String Interpolation VM', () {
    Future<Map<String, Object>> run(String source) async {
      return await compileAndRun(source, preprocesser: MockPreprocesser());
    }

    test('interpolates single variable', () async {
      final result = await run(r'''
        var name = "World";
        var s = "Hello $name!";
        out("result", s);
      ''');
      expect(result['result'], equals('Hello World!'));
    });

    test('interpolates expression', () async {
      final result = await run(r'''
        var a = 10;
        var b = 20;
        var s = "Sum: ${a + b}";
        out("result", s);
      ''');
      expect(result['result'], equals('Sum: 30'));
    });

    test('interpolates multiple parts', () async {
      final result = await run(r'''
        var item = "apple";
        var count = 5;
        var s = "I have $count ${item}s.";
        out("result", s);
      ''');
      expect(result['result'], equals('I have 5 apples.'));
    });

    test('interpolates nested strings', () async {
      final result = await run(r'''
        var s = "Outer ${ "Inner" } Space";
        out("result", s);
      ''');
      expect(result['result'], equals('Outer Inner Space'));
    });

    test('nested interpolation with variables', () async {
      final result = await run(r'''
        var name = "Inception";
        var s = "Level ${ "Deep: $name" }";
        out("result", s);
      ''');
      expect(result['result'], equals('Level Deep: Inception'));
    });

    test('escaped dollar sign', () async {
      final result = await run(r'''
        var s = "Cost: \$100";
        out("result", s);
      ''');
      expect(result['result'], equals(r'Cost: $100'));
    });

    test('complex expression with mixed types', () async {
      final result = await run(r'''
        var s = "Bool: ${true}, Num: ${1.5}, List: ${[1,2]}";
        out("result", s);
      ''');
      // Lists/Maps toString might be specific, checking partially
      expect(result['result'], contains('Bool: true'));
      expect(result['result'], contains('Num: 1.5'));
    });
  });
}
