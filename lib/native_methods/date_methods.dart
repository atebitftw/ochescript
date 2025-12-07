import 'package:oche_script/oche_script.dart';

/// Registers all date extensions.
/// These are registered automatically by the VM.
void registerDateExtensions() {
  registerNativeMethod(Year());
  registerNativeMethod(Month());
  registerNativeMethod(Day());
  registerNativeMethod(Hour());
  registerNativeMethod(Minute());
  registerNativeMethod(Second());
  registerNativeMethod(Millisecond());
  registerNativeMethod(IsUtc());
  registerNativeMethod(CompareTo());
  registerNativeMethod(TimeZoneOffset());
  registerNativeMethod(TimeZoneName());
  registerNativeMethod(Weekday());
}

/// Returns the weekday of the date.
/// ```js
/// var foo = date(2025, 12, 5, 0, 0, 0, 0);
/// var bar = foo.weekday();
class Weekday extends NativeMethodDefinition<DateTime, int> {
  Weekday()
    : super(
        methodName: "weekday",
        targetType: .date,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.weekday;
        },
      );
}

/// Returns the time zone offset of the date.
/// ```js
/// var foo = date(2025, 12, 5, 0, 0, 0, 0);
/// var bar = foo.timeZoneOffset();
class TimeZoneOffset extends NativeMethodDefinition<DateTime, Duration> {
  TimeZoneOffset()
    : super(
        methodName: "timeZoneOffset",
        targetType: .date,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.timeZoneOffset;
        },
      );
}

/// Returns the time zone name of the date.
/// ```js
/// var foo = date(2025, 12, 5, 0, 0, 0, 0);
/// var bar = foo.timeZoneName();
class TimeZoneName extends NativeMethodDefinition<DateTime, String> {
  TimeZoneName()
    : super(
        methodName: "timeZoneName",
        targetType: .date,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.timeZoneName;
        },
      );
}

/// Returns true if the date is UTC.
/// ```js
/// var foo = date(2025, 12, 5, 0, 0, 0, 0);
/// var bar = foo.isUtc();
class IsUtc extends NativeMethodDefinition<DateTime, bool> {
  IsUtc()
    : super(
        methodName: "isUtc",
        targetType: .date,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.isUtc;
        },
      );
}

/// Compares the date to another date.
/// ```js
/// var foo = date(2025, 12, 5, 0, 0, 0, 0);
/// var bar = foo.compareTo(date(2025, 12, 6, 0, 0, 0, 0));
class CompareTo extends NativeMethodDefinition<DateTime, int> {
  CompareTo()
    : super(
        methodName: "compareTo",
        targetType: .date,
        arity: 1,
        function: (target, interpreter, arguments) {
          if (arguments[0] is! DateTime) {
            throw RuntimeError("CompareTo argument must be a date.");
          }
          return target.compareTo(arguments[0] as DateTime);
        },
      );
}

/// Returns the year of the date.
/// ```js
/// var foo = date(2025, 12, 5, 0, 0, 0, 0);
/// var bar = foo.year();
class Year extends NativeMethodDefinition<DateTime, int> {
  Year()
    : super(
        methodName: "year",
        targetType: .date,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.year;
        },
      );
}

/// Returns the month of the date.
/// ```js
/// var foo = date(2025, 12, 5, 0, 0, 0, 0);
/// var bar = foo.month();
class Month extends NativeMethodDefinition<DateTime, int> {
  Month()
    : super(
        methodName: "month",
        targetType: .date,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.month;
        },
      );
}

/// Returns the day of the date.
/// ```js
/// var foo = date(2025, 12, 5, 0, 0, 0, 0);
/// var bar = foo.day();
class Day extends NativeMethodDefinition<DateTime, int> {
  Day()
    : super(
        methodName: "day",
        targetType: .date,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.day;
        },
      );
}

/// Returns the hour of the date.
/// ```js
/// var foo = date(2025, 12, 5, 3, 0, 0, 0);
/// var bar = foo.hour();
class Hour extends NativeMethodDefinition<DateTime, int> {
  Hour()
    : super(
        methodName: "hour",
        targetType: .date,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.hour;
        },
      );
}

/// Returns the minute of the date.
/// ```js
/// var foo = date(2025, 12, 5, 3, 30, 0, 0);
/// var bar = foo.minute();
class Minute extends NativeMethodDefinition<DateTime, int> {
  Minute()
    : super(
        methodName: "minute",
        targetType: .date,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.minute;
        },
      );
}

/// Returns the second of the date.
/// ```js
/// var foo = date(2025, 12, 5, 3, 30, 45, 0);
/// var bar = foo.second();
class Second extends NativeMethodDefinition<DateTime, int> {
  Second()
    : super(
        methodName: "second",
        targetType: .date,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.second;
        },
      );
}

/// Returns the millisecond of the date.
/// ```js
/// var foo = date(2025, 12, 5, 3, 30, 0, 500);
/// var bar = foo.millisecond();
class Millisecond extends NativeMethodDefinition<DateTime, int> {
  Millisecond()
    : super(
        methodName: "millisecond",
        targetType: .date,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.millisecond;
        },
      );
}
