import 'package:test/test.dart';
import 'package:oche_script/oche_script.dart';

void main() {
  group('Global State Injection', () {
    test('Injects primitives', () async {
      final source = 'out("r", globalInt);';
      final result = await compileAndRun(source, initialGlobalState: {'globalInt': 42});
      expect(result['r'], 42);
    });

    test('Injects Maps', () async {
      final source = 'out("r", globalConf["key"]);';
      final result = await compileAndRun(
        source,
        initialGlobalState: {
          'globalConf': {'key': 'val'},
        },
      );
      expect(result['r'], 'val');
    });

    test('Script can assign to injected global', () async {
      final source = 'globalInt = 100; out("r", globalInt);';
      final result = await compileAndRun(source, initialGlobalState: {'globalInt': 42});
      expect(result['r'], 100);
    });

    test('Script can redeclare injected global', () async {
      // This verifies that 'var x' overwrites the defineGlobal-injected 'x'
      final source = 'var globalInt = 100; out("r", globalInt);';
      final result = await compileAndRun(source, initialGlobalState: {'globalInt': 42});
      expect(result['r'], 100);
    });
  });
}
