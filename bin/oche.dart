import 'dart:io';
import 'package:oche_script/oche_script.dart' as oche;
import 'package:logging/logging.dart';
import 'package:oche_script/windows_preprocessor.dart';

final _logger = Logger.root;

Future<int> main(List<String> args) async {
  if (args.length != 1) {
    print("Usage: oche <path_to_script>");
    exit(1);
  }
  if (!args[0].endsWith(".oche")) {
    args[0] = "${args[0]}.oche";
  }
  final file = File(args[0]);
  if (!file.existsSync()) {
    print("File not found: ${args[0]}");
    exit(1);
  }
  _logger.level = Level.WARNING;
  _logger.onRecord.listen((record) {
    print("${record.level.name}: ${record.message}");
  });

  final source = file.readAsStringSync();

  final result = await oche.compileAndRun(
    source,
    preprocesser: WindowsPlatformPreProcessor(librarySearchPaths: Set<String>.from(["./", "./includes"])),
    dartFunctionCallback: (name, arguments) async {
      _logger.info("dart() -> Requested function call '$name' with args: $arguments.  Returning: $arguments");
      return arguments;
    },
    outCallback: (name, value) {
      _logger.info("out() -> $name: $value");
    },
  );

  print(result);
  return result['return_code'] as int? ?? 1;
}
