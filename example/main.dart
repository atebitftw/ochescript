import 'package:oche_script/oche_script.dart' as oche;
import 'package:oche_script/windows_preprocessor.dart';
import 'package:logging/logging.dart';
import 'dart:io';

// In the example below, we are taking advantage of many of the Dart interop
// features of OcheScript.  We are also demonstrating the use of the
// preprocesser to handle include directives.

void main() async {
  // Output any script runtime exceptions to the console.
  // Not required, but recommended.
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print("${record.level.name}: Script Error:  ${record.message}");
  });

  // Call the script API to compile and run the script.
  final scriptResult = await oche.compileAndRun(
    File("example.oche").readAsStringSync(),

    // 'globalStuff' is injected into the script, just prior to runtime, as a
    // global variable.
    initialGlobalState: {"globalStuff": 25},

    // We are using the WindowsPlatformPreProcessor to handle include directives.
    preprocesser: WindowsPlatformPreProcessor(
      librarySearchPaths: {"./", "./includes"},
    ),

    // Not strictly necessary, but we are including a callback for any out()
    // calls made by the script.  These are also stored in the output map return
    // after the script completes.
    outCallback: (key, value) {
      print("\n(Dart) Out Received: {$key: $value}\n");
    },

    // We are including a callback for any dart() calls made by the script.
    // It's important that this callback and the scripts are both aware of
    // the valid function names, argument types, and return types.
    dartFunctionCallback: (name, args) async {
      if (name == "double_me") {
        // add some delay to simulate a long running task
        await Future.delayed(Duration(seconds: 3));
        return args[0] * 2;
      }
      throw Exception("Unknown function: $name");
    },
  );

  print("(Dart) Script Completed.");

  // The output map contains any out() calls made by the script.  Plus return
  // code.
  print("(Dart) Script Result: $scriptResult");
}
