import 'dart:convert' as json;
import 'dart:math';

import 'package:oche_script/oche_script.dart' show RuntimeError;
import 'package:oche_script/src/runtime/vm.dart' show VM;
import 'package:logging/logging.dart';

final _log = Logger.root;

Random _random = Random();

/// This registers all the built-in native functions.
/// This is called automatically when by the VM.
void defineVmNativeFunctions(VM vm) {
  _log.info("Defining VM native functions.");
  // Register global native functions

  _defineVmSystemFunctions(vm);
  _defineVmConvertFunctions(vm);
  _defineVmMathFunctions(vm);
  _defineVmTimeFunctions(vm);
}

/// Provides a clock() function that returns the current time in milliseconds since the epoch.
///
/// void -> int
///
/// **Example**
/// ```js
/// var start = clock();
/// // do some stuff...
/// var end = clock();
/// var duration = end - start;
/// print("Elapsed: $duration ms.");
/// ```
int clock(List args) => DateTime.now().millisecondsSinceEpoch;

/// Provides a now() function that returns the current time.
///
/// void -> DateTime
///
/// ```js
/// var now = now();
/// print("Current time: $now");
/// ```
DateTime now(List args) => DateTime.now();

/// Provides a date() function that creates a DateTime object from the given arguments.
///
/// year, month, day, hour, minute, second, millisecond
/// int, int, int, int, int, int, int -> DateTime
///
/// **Example**
/// ```js
/// var date = date(2025, 12, 5, 13, 18, 39, 0);
/// print("Current time: $date");
/// ```
DateTime date(List args) {
  _arityCheck(7, args.length);
  _numberTypeCheck(args[0]);
  _numberTypeCheck(args[1]);
  _numberTypeCheck(args[2]);
  _numberTypeCheck(args[3]);
  _numberTypeCheck(args[4]);
  _numberTypeCheck(args[5]);
  _numberTypeCheck(args[6]);
  return DateTime(
    args[0] as int,
    args[1] as int,
    args[2] as int,
    args[3] as int,
    args[4] as int,
    args[5] as int,
    args[6] as int,
    0,
  );
}

/// Provides a duration() function that creates a Duration object from the given arguments.
///
/// days, hours, minutes, seconds, milliseconds
/// int, int, int, int, int -> Duration
///
/// **Example**
/// ```js
/// var duration = duration(0, 0, 0, 0, 1000);
/// print("Duration: $duration");
/// ```
Duration duration(List args) {
  _arityCheck(5, args.length);
  _numberTypeCheck(args[0]);
  _numberTypeCheck(args[1]);
  _numberTypeCheck(args[2]);
  _numberTypeCheck(args[3]);
  _numberTypeCheck(args[4]);
  return Duration(
    milliseconds: args[0] as int,
    seconds: args[1] as int,
    minutes: args[2] as int,
    hours: args[3] as int,
    days: args[4] as int,
  );
}

/// Provides a parseDateTime() function that parses a date string to a DateTime object.
///
/// string
/// String -> DateTime
///
/// **Example**
/// ```js
/// var date = parseDateTime("2022-01-01");
/// print(date is DateTime); // true
/// print("Date: $date");
/// ```
DateTime parseDateTime(List args) {
  _arityCheck(1, args.length);
  _stringTypeCheck(args[0]);
  try {
    return DateTime.parse(args[0] as String);
  } catch (_) {
    throw RuntimeError("parseDateTime: Invalid date string: ${args[0]}");
  }
}

void _defineVmTimeFunctions(VM vm) {
  vm.defineNative("clock", clock);
  vm.defineNative("now", now);
  vm.defineNative("date", date);
  vm.defineNative("duration", duration);
  vm.defineNative("parseDateTime", parseDateTime);
}

/// Provides a wait() function that returns a Future that completes after the given number of milliseconds.
///
/// milliseconds
/// int -> Future
///
/// **Example**
/// ```js
/// var future = wait(1000);
/// print("Future completed after 1 second.");
/// ```
Future wait(List args) {
  _arityCheck(1, args.length);
  _numberTypeCheck(args[0]);
  final ms = args[0] as num;
  return Future.delayed(Duration(milliseconds: ms.toInt()), () => ms);
}

/// Provides a quit() function that immediately halts script execution and exits
/// with the given return code.
///
/// returnCode
/// int -> int
///
/// **Example**
/// ```js
/// quit(1);
/// ```
Function quit(VM vm) => (args) {
  _arityCheck(1, args.length);
  _numberTypeCheck(args[0]);
  final code = args[0] as int;
  vm.returnCode = code;
  vm.halt = true;
  return code;
};

void _defineVmSystemFunctions(VM vm) {
  vm.defineNative("wait", wait);
  vm.defineNative("quit", quit(vm));
}

/// Provides a jsonEncode() function that encodes a map object to a JSON string.
/// Supports conversion of DateTime objects to strings.
///
/// object
/// Map -> String
///
/// **Example**
/// ```js
/// var json = jsonEncode({"name": "John", "age": 30});
/// print(json is String); // true
/// print("JSON: $json");
/// ```
String jsonEncode(List args) {
  if (args[0] is! Map) {
    throw RuntimeError("jsonEncode: Expected a map object, but got ${args[0].runtimeType}");
  }

  _arityCheck(1, args.length);
  return json.jsonEncode(
    args[0],
    toEncodable: (object) {
      if (object is DateTime) {
        return object.toString();
      }
      return object;
    },
  );
}

/// Provides a jsonDecode() function that decodes a JSON string to a map object.
/// Supports conversion of DateTime objects from strings.
///
/// string
/// String -> Map
///
/// **Example**
/// ```js
/// var json = jsonDecode("{\"name\": \"John\", \"age\": 30}");
/// print(json is Map); // true
/// print("JSON: $json");
/// ```
Map<String, dynamic> jsonDecode(List args) {
  _arityCheck(1, args.length);
  if (args[0] is! String) {
    throw RuntimeError("jsonDecode: Expected a string, but got ${args[0].runtimeType}");
  }

  return json.jsonDecode(
    args[0] as String,
    reviver: (key, value) {
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return value;
        }
      } else {
        return value;
      }
    },
  );
}

void _defineVmConvertFunctions(VM vm) {
  vm.defineNative("jsonEncode", jsonEncode);
  vm.defineNative("jsonDecode", jsonDecode);
}

/// Provides a rndDouble() function that returns a random double value.
///
/// ()
/// () -> double
///
/// **Example**
/// ```js
/// var random = rndDouble();
/// print(random is Num); // true
/// print("Random: $random");
/// ```
double rndDouble(List args) {
  _arityCheck(0, args.length);
  return _random.nextDouble();
}

/// Provides a rndInt() function that returns a random integer value.
///
/// int
/// int -> int
///
/// **Example**
/// ```js
/// var random = rndInt(10);
/// print(random is Num); // true
/// print("Random: $random");
/// ```
int rndInt(List args) {
  _arityCheck(1, args.length);
  _numberTypeCheck(args[0]);
  final num value = args[0] as num;
  return _random.nextInt(value.toInt());
}

bool rndBool(List args) {
  _arityCheck(0, args.length);
  return _random.nextBool();
}

void _defineVmMathFunctions(VM vm) {
  vm.defineNative("rndDouble", rndDouble);
  vm.defineNative("rndInt", rndInt);
  vm.defineNative("rndBool", rndBool);
}

void _numberTypeCheck(Object value) {
  if (value is! num) throw RuntimeError("Number expected. Got $value.");
}

void _arityCheck(int expected, int actual) {
  if (expected != actual) throw RuntimeError("Arity mismatch. Expected $expected, got $actual.");
}

void _stringTypeCheck(Object arg) {
  if (arg is! String) {
    throw RuntimeError("Argument must be a string. Got $arg.");
  }
}
