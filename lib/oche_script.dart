import 'package:oche_script/oche_script.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/parser.dart';
import 'package:oche_script/native_functions/define_native_functions.dart' show defineVmNativeFunctions;
import 'package:oche_script/native_methods/date_methods.dart' show registerDateExtensions;
import 'package:oche_script/native_methods/duration_methods.dart' show registerDurationExtensions;
import 'package:oche_script/native_methods/list_methods.dart' show registerListExtensions;
import 'package:oche_script/native_methods/map_methods.dart' show registerMapExtensions;
import 'package:oche_script/native_methods/number_methods.dart' show registerNumberExtensions;
import 'package:oche_script/native_methods/string_methods.dart' show registerStringExtensions;
import 'package:oche_script/src/runtime/native_method.dart';
import 'package:oche_script/src/compiler/compiler.dart';
import 'package:oche_script/src/runtime/vm.dart' show VM;
import 'package:oche_script/src/source_mapper.dart';
import 'package:logging/logging.dart';
export "src/includes_preprocesser.dart" show IncludesPreprocesser;
export "src/runtime/runtime_error.dart" show RuntimeError;
export "src/compiler/parse_error.dart" show ParseError;
export "src/runtime/native_method.dart" show NativeMethodDefinition, NativeMethodTarget, NativeMethodFunction;
export 'package:oche_script/src/runtime/obj.dart' show ObjClosure;

final _log = Logger.root;

/// Defines a signature for a callback function that handles out() function calls at runtime.
typedef OutCallback = void Function(String name, Object value);

/// Defines a signature for a callback function that handles dart() function calls at runtime.
typedef DartFunctionCallback = Future<Object> Function(String name, List<dynamic> args);

/// Defines a signature for a native function.
typedef NativeFunction = Function(List<Object> args);

/// Registry for user-defined native functions.
final Map<String, NativeFunction> _customNativeFunctions = {};

bool _areExtensionsRegistered = false;

/// Compiles and runs the given OcheScript source code.
///
/// Returns a [Map<String, Object>] containing the state exported by the script out() function,
/// if any were used.
///
/// **Example:**
/// ```dart
/// final result = await compileAndRun(r"print("Hello World!");");
/// ```
///
/// * [preprocesser] is the platform-specific [IncludesPreprocesser] to use for
/// preprocessing the source code for any requested libraries.
/// * [outCallback] is the callback to use for handling out() function calls at runtime.
/// * [dartFunctionCallback] is the callback to use for handling dart() function calls at runtime.
/// * [initialGlobalState] is the initial global state to use for the runtime.
/// This essentially injects the states as global variables in the script.
///
/// For a full-featured example, see `example/main.dart` in the project source code.
Future<Map<String, Object>> compileAndRun(
  String source, {
  IncludesPreprocesser? preprocesser,
  OutCallback? outCallback,
  DartFunctionCallback? dartFunctionCallback,
  Map<String, Object> initialGlobalState = const {},
}) async {
  return _run(
    source,
    preprocesser: preprocesser,
    outCallback: outCallback,
    dartFunctionCallback: dartFunctionCallback,
    initialGlobalState: initialGlobalState,
  );
}

Future<Map<String, Object>> _run(
  String source, {
  IncludesPreprocesser? preprocesser,
  OutCallback? outCallback,
  DartFunctionCallback? dartFunctionCallback,
  Map<String, Object> initialGlobalState = const {},
}) async {
  _registerTypeExtensions();

  String sourceWithIncludes = source;

  if (preprocesser != null) {
    final libraries = await preprocesser.getLibraries(source);
    final processedLibraries = libraries.entries.map((entry) {
      return "// #source ${entry.key}\n${entry.value}\n// #end_source ${entry.key}";
    });

    sourceWithIncludes = [...processedLibraries, source].join("\n");
  }

  // Create a new VM instance for this run
  final vm = VM();

  // Inject global state directly into the VM.
  for (final entry in initialGlobalState.entries) {
    vm.defineGlobal(entry.key, entry.value, override: true);
  }

  final l = Lexer(sourceWithIncludes);
  final tokens = l.scan();

  final p = Parser(tokens);
  final statements = p.parse();

  if (p.hadError) {
    print("Parser error.");
    return {};
  }

  final mapper = SourceMapper(sourceWithIncludes);
  final compiler = BytecodeCompiler(mapper);
  final chunk = compiler.compile(statements);
  vm.sourceMapper = mapper;

  defineVmNativeFunctions(vm);

  // Register custom native functions
  for (final entry in _customNativeFunctions.entries) {
    vm.defineNative(entry.key, entry.value);
  }

  if (outCallback != null) {
    vm.registerOutCallback((name, value) => outCallback(name, value));
  }

  dartFunctionCallback ??= (_, _) {
    throw vm.reportRuntimeError(vm.getCurrentLine(), "dart() function callback is not registered.");
  };

  vm.defineNative("dart", (args) {
    if (args.isEmpty) {
      throw vm.reportRuntimeError(vm.getCurrentLine(), "dart() requires function name");
    }
    final name = args[0] as String;

    if (args[1] is! List) {
      throw vm.reportRuntimeError(
        vm.getCurrentLine(),
        "dart() requires function arguments in a list. Empty list if no arguments.",
      );
    }
    final functionArgs = args[1];
    return dartFunctionCallback!(name, functionArgs);
  });

  return await vm.interpret(chunk);
}

void _registerTypeExtensions() {
  if (_areExtensionsRegistered) return;
  _log.info("Registering type extensions.");
  _areExtensionsRegistered = true;
  registerStringExtensions();
  registerNumberExtensions();
  registerListExtensions();
  registerMapExtensions();
  registerDateExtensions();
  registerDurationExtensions();
}

/// Registers a native method to extend the language capabilities.
///
/// * [definition] is the [NativeMethodDefinition] to register.
///
/// Native methods are functions that can be called on supported types.
///
/// Native methods are registered using the [NativeMethodDefinition] class.
///
/// Example:
/// ```dart
/// registerNativeMethod(NativeMethodDefinition(
///   name: "toUpperCase",
///   target: NativeMethodTarget.string,
///   function: (interpreter, arguments) {
///     // you would want to add some error checking here.
///     return arguments[0].toUpperCase();
///   },
/// ));
/// ```
///
/// Now in OcheScript, you can call .toUpper() on any string, like this:
/// ```js
/// var y = "hello".toUpper();
/// print(y); // HELLO
/// ```
///
/// Calling this during script execution will throw a [RuntimeError].
void registerNativeMethod(NativeMethodDefinition definition) {
  NativeMethod.registerNativeMethod(definition);
}

/// Registers a native function to extend the language capabilities.
///
/// * [name] is the name of the function.
/// * [function] is the function to register.
///
/// Native functions are functions that can be called globally in OcheScript.
///
/// Example:
/// ```dart
/// registerNativeFunction("wait", (args) {
///   _arityCheck(1, args.length);
///   _numberTypeCheck(args[0]);
///   final ms = args[0] as num;
///   return Future.delayed(Duration(milliseconds: ms.toInt()), () => ms);
/// });
/// ```
///
/// Now in OcheScript, you can call wait() like this:
/// ```js
/// await wait(1000);
/// print("Completed after 1 second.");
/// ```
///
/// Calling this during script execution will throw a [RuntimeError].
void registerNativeFunction(String name, NativeFunction function) {
  _customNativeFunctions[name] = function;
}
