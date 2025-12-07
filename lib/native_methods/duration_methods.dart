import 'package:oche_script/oche_script.dart';

/// Registers native methods for the Duration type.
/// These are registere automatically by the VM.
void registerDurationExtensions() {
  registerNativeMethod(InYears());
  registerNativeMethod(InHours());
  registerNativeMethod(InMinutes());
  registerNativeMethod(InSeconds());
  registerNativeMethod(InMilliseconds());
  registerNativeMethod(IsNegative());
  registerNativeMethod(Abs());
  registerNativeMethod(CompareTo());
}

/// Compares the duration to another duration and returns the result of the comparison.
/// Returns 0 if the durations are equal, a negative number if the duration is less than
/// the other duration, and a positive number if the duration is greater than the other duration.
/// ```js
/// var foo = duration(0, 0, 0, 2, 0); //seconds
/// var bar = duration(0, 0, 0, 1, 0); //seconds
/// var baz = foo.compareTo(bar);
class CompareTo extends NativeMethodDefinition<Duration, int> {
  CompareTo()
    : super(
        methodName: "compareTo",
        targetType: .duration,
        arity: 1,
        function: (target, interpreter, arguments) {
          return target.compareTo(arguments[0]);
        },
      );
}

/// Returns the absolute value of the duration.
/// ```js
/// var foo = duration(0, 0, 0, -2, 0); //seconds
/// var bar = foo.abs();
class Abs extends NativeMethodDefinition<Duration, Duration> {
  Abs()
    : super(
        methodName: "abs",
        targetType: .duration,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.abs();
        },
      );
}

/// Returns true if the duration is negative.
/// ```js
/// var foo = duration(0, 0, 0, -2, 0); //seconds
/// var bar = foo.isNegative();
class IsNegative extends NativeMethodDefinition<Duration, bool> {
  IsNegative()
    : super(
        methodName: "isNegative",
        targetType: .duration,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.isNegative;
        },
      );
}

/// Returns the number of years in the duration.
/// ```js
/// var foo = duration(500, 0, 0, 0, 0); //days
/// var bar = foo.inYears();
class InYears extends NativeMethodDefinition<Duration, num> {
  InYears()
    : super(
        methodName: "inYears",
        targetType: .duration,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.inDays / 365;
        },
      );
}

/// Returns the number of hours in the duration.
/// ```js
/// var foo = duration(12, 0, 0, 0, 0); //days
/// var bar = foo.inHours();
class InHours extends NativeMethodDefinition<Duration, int> {
  InHours()
    : super(
        methodName: "inHours",
        targetType: .duration,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.inHours;
        },
      );
}

/// Returns the number of minutes in the duration.
/// ```js
/// var foo = duration(12, 0, 0, 0, 0); //days
/// var bar = foo.inMinutes();
class InMinutes extends NativeMethodDefinition<Duration, int> {
  InMinutes()
    : super(
        methodName: "inMinutes",
        targetType: .duration,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.inMinutes;
        },
      );
}

/// Returns the number of seconds in the duration.
/// ```js
/// var foo = duration(12, 0, 0, 0, 0); //days
/// var bar = foo.inSeconds();
class InSeconds extends NativeMethodDefinition<Duration, int> {
  InSeconds()
    : super(
        methodName: "inSeconds",
        targetType: .duration,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.inSeconds;
        },
      );
}

/// Returns the number of milliseconds in the duration.
/// ```js
/// var foo = duration(12, 0, 0, 0, 0); //days
/// var bar = foo.inMilliseconds();
class InMilliseconds extends NativeMethodDefinition<Duration, int> {
  InMilliseconds()
    : super(
        methodName: "inMilliseconds",
        targetType: .duration,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.inMilliseconds;
        },
      );
}
