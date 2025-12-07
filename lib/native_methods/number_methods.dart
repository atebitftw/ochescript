import 'package:oche_script/oche_script.dart';
import 'dart:math' as math;

/// Registers all number extensions.
/// These are registered automatically by the VM.
void registerNumberExtensions() {
  registerNativeMethod(ToString());
  registerNativeMethod(IsOdd());
  registerNativeMethod(IsEven());
  registerNativeMethod(Truncate());
  registerNativeMethod(Floor());
  registerNativeMethod(Ceil());
  registerNativeMethod(Round());
  registerNativeMethod(Abs());
  registerNativeMethod(Exp());
  registerNativeMethod(Log());
  registerNativeMethod(Atan());
  registerNativeMethod(Atan2());
  registerNativeMethod(Asin());
  registerNativeMethod(Acos());
  registerNativeMethod(Mod());
  registerNativeMethod(Max());
  registerNativeMethod(Min());
  registerNativeMethod(CompareTo());
  registerNativeMethod(Sqrt());
  registerNativeMethod(Pow());
  registerNativeMethod(Cos());
  registerNativeMethod(Sin());
  registerNativeMethod(Tan());
}

/// Compares this number with another number.
///
/// ```js
/// var a = 1;
/// var b = 2;
/// var result = a.compareTo(b); // result = -1
/// ```
class CompareTo extends NativeMethodDefinition<num, int> {
  CompareTo()
    : super(
        methodName: "compareTo",
        targetType: NativeMethodTarget.number,
        arity: 1,
        function: (target, interpreter, arguments) {
          if (arguments[0] is! num) {
            throw RuntimeError("Argument must be a number.");
          }
          return target.compareTo(arguments[0]);
        },
      );
}

class Cos extends NativeMethodDefinition<num, num> {
  Cos()
    : super(
        methodName: "cos",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return math.cos(target);
        },
      );
}

class Sin extends NativeMethodDefinition<num, num> {
  Sin()
    : super(
        methodName: "sin",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return math.sin(target);
        },
      );
}

/// Returns the tangent of this number.
///
/// ```js
/// var foo = 1;
/// var bar = foo.tan();
/// ```
class Tan extends NativeMethodDefinition<num, num> {
  Tan()
    : super(
        methodName: "tan",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return math.tan(target);
        },
      );
}

/// Returns the square root of this number.
///
/// ```js
/// var foo = 25;
/// var bar = foo.sqrt();
/// ```
class Sqrt extends NativeMethodDefinition<num, num> {
  Sqrt()
    : super(
        methodName: "sqrt",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return math.sqrt(target);
        },
      );
}

/// Rounds this number to the nearest integer.
///
/// ```js
/// var foo = 1.5;
/// var bar = foo.round();
/// ```
class Round extends NativeMethodDefinition<num, num> {
  Round()
    : super(
        methodName: "round",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.round();
        },
      );
}

/// Raises this number to the power of another number.
///
/// ```js
/// var foo = 2;
/// var bar = foo.pow(3);
/// ```
class Pow extends NativeMethodDefinition<num, num> {
  Pow()
    : super(
        methodName: "pow",
        targetType: NativeMethodTarget.number,
        arity: 1,
        function: (target, interpreter, arguments) {
          return math.pow(target, arguments[0]);
        },
      );
}

/// Returns the remainder of this number divided by another number.
///
/// ```js
/// var foo = 2;
/// var bar = foo.mod(3);
/// ```
class Mod extends NativeMethodDefinition<num, num> {
  Mod()
    : super(
        methodName: "mod",
        targetType: NativeMethodTarget.number,
        arity: 1,
        function: (target, interpreter, arguments) {
          return target % arguments[0];
        },
      );
}

/// Returns the maximum of this number and another number.
///
/// ```js
/// var foo = 2;
/// var bar = foo.max(3);
/// ```
class Max extends NativeMethodDefinition<num, num> {
  Max()
    : super(
        methodName: "max",
        targetType: NativeMethodTarget.number,
        arity: 1,
        function: (target, interpreter, arguments) {
          return math.max(target, arguments[0]);
        },
      );
}

/// Returns the minimum of this number and another number.
///
/// ```js
/// var foo = 2;
/// var bar = foo.min(3);
/// ```
class Min extends NativeMethodDefinition<num, num> {
  Min()
    : super(
        methodName: "min",
        targetType: NativeMethodTarget.number,
        arity: 1,
        function: (target, interpreter, arguments) {
          return math.min(target, arguments[0]);
        },
      );
}

/// Returns the exponential of this number.
///
/// ```js
/// var foo = 2;
/// var bar = foo.exp();
/// ```
class Exp extends NativeMethodDefinition<num, num> {
  Exp()
    : super(
        methodName: "exp",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return math.exp(target);
        },
      );
}

/// Returns the natural logarithm of this number.
/// ```js
/// var foo = 2;
/// var bar = foo.log();
/// ```
class Log extends NativeMethodDefinition<num, num> {
  Log()
    : super(
        methodName: "log",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return math.log(target);
        },
      );
}

/// Returns the arctangent of this number.
/// ```js
/// var foo = 2;
/// var bar = foo.atan();
/// ```
class Atan extends NativeMethodDefinition<num, num> {
  Atan()
    : super(
        methodName: "atan",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return math.atan(target);
        },
      );
}

/// Returns the arctangent of this number and another number.
/// ```js
/// var foo = 2;
/// var bar = foo.atan2(3);
/// ```
class Atan2 extends NativeMethodDefinition<num, num> {
  Atan2()
    : super(
        methodName: "atan2",
        targetType: NativeMethodTarget.number,
        arity: 1,
        function: (target, interpreter, arguments) {
          return math.atan2(target, arguments[0]);
        },
      );
}

/// Returns the arcsine of this number.
/// ```js
/// var foo = 2;
/// var bar = foo.asin();
/// ```
class Asin extends NativeMethodDefinition<num, num> {
  Asin()
    : super(
        methodName: "asin",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return math.asin(target);
        },
      );
}

/// Returns the arccosine of this number.
/// ```js
/// var foo = 2;
/// var bar = foo.acos();
/// ```
class Acos extends NativeMethodDefinition<num, num> {
  Acos()
    : super(
        methodName: "acos",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return math.acos(target);
        },
      );
}

/// Returns the absolute value of this number.
/// ```js
/// var foo = -2;
/// var bar = foo.abs();
/// ```
class Abs extends NativeMethodDefinition<num, num> {
  Abs()
    : super(
        methodName: "abs",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.abs();
        },
      );
}

/// Returns the truncated value of this number.
/// ```js
/// var foo = 2.5;
/// var bar = foo.truncate();
/// ```
class Truncate extends NativeMethodDefinition<num, num> {
  Truncate()
    : super(
        methodName: "truncate",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.truncate();
        },
      );
}

/// Returns the floor value of this number.
/// ```js
/// var foo = 2.5;
/// var bar = foo.floor();
/// ```
class Floor extends NativeMethodDefinition<num, num> {
  Floor()
    : super(
        methodName: "floor",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.floor();
        },
      );
}

/// Returns the ceiling value of this number.
/// ```js
/// var foo = 2.5;
/// var bar = foo.ceil();
/// ```
class Ceil extends NativeMethodDefinition<num, num> {
  Ceil()
    : super(
        methodName: "ceil",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.ceil();
        },
      );
}

/// Returns true if this number is odd.
/// ```js
/// var foo = 2;
/// var bar = foo.isOdd();
/// ```
class IsOdd extends NativeMethodDefinition<num, bool> {
  IsOdd()
    : super(
        methodName: "isOdd",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target % 2 != 0;
        },
      );
}

/// Returns true if this number is even.
/// ```js
/// var foo = 2;
/// var bar = foo.isEven();
/// ```
class IsEven extends NativeMethodDefinition<num, bool> {
  IsEven()
    : super(
        methodName: "isEven",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target % 2 == 0;
        },
      );
}

/// Returns the string representation of this number.
/// ```js
/// var foo = 2;
/// var bar = foo.toString();
/// ```
class ToString extends NativeMethodDefinition<num, String> {
  ToString()
    : super(
        methodName: "toString",
        targetType: NativeMethodTarget.number,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.toString();
        },
      );
}
