import 'package:test/test.dart';
import 'package:oche_script/oche_script.dart';

class MockPreprocesser extends IncludesPreprocesser {
  @override
  Future<Map<String, String>> getLibraries(String source) => Future.value({});
}

void main() {
  group('Integration', () {
    test('compileAndRun with useBytecode: true', () async {
      final source = """
        var a = 10;
        var b = 20;
        out("result", a + b);
      """;

      final result = await compileAndRun(source, preprocesser: MockPreprocesser());

      expect(result['result'], equals(30));
    });

    test('compileAndRun supports dart() callback', () async {
      final source = """
        var res = dart("myFunc", [5]);
        out("result", res);
      """;

      final result = await compileAndRun(
        source,
        preprocesser: MockPreprocesser(),
        dartFunctionCallback: (name, args) async {
          if (name == "myFunc") {
            return args[0] * 2;
          }
          return 0;
        },
      );

      expect(result['result'], equals(10));
    });
  });
}
