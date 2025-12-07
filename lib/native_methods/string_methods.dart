import 'package:oche_script/oche_script.dart';

/// Registers all string extensions.
/// This is called automatically by the VM.
void registerStringExtensions() {
  registerNativeMethod(ToUpper());
  registerNativeMethod(ToLower());
  registerNativeMethod(IsNotEmpty());
  registerNativeMethod(IsEmpty());
  registerNativeMethod(Contains());
  registerNativeMethod(Split());
  registerNativeMethod(SubString());
  registerNativeMethod(Head());
  registerNativeMethod(Tail());
  registerNativeMethod(CompareTo());
  registerNativeMethod(Length());
  registerNativeMethod(Trim());
  registerNativeMethod(IsLowerCase());
  registerNativeMethod(IsUpperCase());
  registerNativeMethod(ReplaceAll());
  registerNativeMethod(CodeUnitAt());
}

/// Returns the code unit at the specified index.
/// ```js
/// var foo = "hello";
/// var bar = foo.codeUnitAt(0);
/// ```
class CodeUnitAt extends NativeMethodDefinition<String, int> {
  CodeUnitAt()
    : super(
        methodName: "codeUnitAt",
        arity: 1,
        targetType: NativeMethodTarget.string,
        function: (target, _, args) {
          final arg = args[0];
          if (arg is! int) {
            throw RuntimeError("codeUnitAt() takes an integer as an argument.");
          }
          return target.codeUnitAt(arg);
        },
      );
}

/// Replaces all occurrences of a specified substring with another substring.
/// ```js
/// var foo = "hello";
/// var bar = foo.replaceAll("l", "x");
/// ```
class ReplaceAll extends NativeMethodDefinition<String, String> {
  ReplaceAll()
    : super(
        methodName: "replaceAll",
        arity: 2,
        targetType: NativeMethodTarget.string,
        function: (target, _, args) {
          final arg = args[0];
          if (arg is! String) {
            throw RuntimeError("replaceAll() takes a string as an argument.");
          }
          final arg2 = args[1];
          if (arg2 is! String) {
            throw RuntimeError("replaceAll() takes a string as an argument.");
          }
          return target.replaceAll(arg, arg2);
        },
      );
}

/// Returns true if all letters in the string are lowercase, ignoring non-alphabetic characters.
/// ```js
/// var foo = "hello";
/// var bar = foo.isLowerCase();
/// ```
class IsLowerCase extends NativeMethodDefinition<String, bool> {
  IsLowerCase()
    : super(
        methodName: "isLowerCase",
        arity: 0,
        targetType: NativeMethodTarget.string,
        function: (target, _, _) {
          //regex to check if every letter in the string is lowercase, ignoring non-alphabetic characters
          final regex = RegExp(r"^[a-z]*$");
          return regex.hasMatch(target);
        },
      );
}

/// Returns true if all letters in the string are uppercase, ignoring non-alphabetic characters.
/// ```js
/// var foo = "HELLO";
/// var bar = foo.isUpperCase();
/// ```
class IsUpperCase extends NativeMethodDefinition<String, bool> {
  IsUpperCase()
    : super(
        methodName: "isUpperCase",
        arity: 0,
        targetType: NativeMethodTarget.string,
        function: (target, _, _) {
          //regex to check if every letter in the string is uppercase, ignoring non-alphabetic characters
          final regex = RegExp(r"^[A-Z]*$");
          return regex.hasMatch(target);
        },
      );
}

/// Returns the length of the string.
/// ```js
/// var foo = "hello";
/// var bar = foo.length();
/// ```
class Length extends NativeMethodDefinition<String, int> {
  Length()
    : super(
        methodName: "length",
        arity: 0,
        targetType: NativeMethodTarget.string,
        function: (target, _, _) {
          return target.length;
        },
      );
}

/// Compares the string to another string and returns the result of the comparison.
/// Returns 0 if the strings are equal, a negative number if the string is less than the other string, and a positive number if the string is greater than the other string.
/// ```js
/// var foo = "hello";
/// var bar = foo.compareTo("hello world");
/// ```
class CompareTo extends NativeMethodDefinition<String, int> {
  CompareTo()
    : super(
        methodName: "compareTo",
        arity: 1,
        targetType: NativeMethodTarget.string,
        function: (target, _, args) {
          final arg = args[0];
          if (arg is! String) {
            throw RuntimeError("compareTo() takes a string as an argument.");
          }
          return target.compareTo(arg);
        },
      );
}

/// Returns a new string with leading and trailing whitespace removed.
/// ```js
/// var foo = " hello ";
/// var bar = foo.trim();
class Trim extends NativeMethodDefinition<String, String> {
  Trim()
    : super(
        methodName: "trim",
        arity: 0,
        targetType: NativeMethodTarget.string,
        function: (target, _, _) {
          return target.trim();
        },
      );
}

/// Splits the string into a list of substrings separated by the specified separator.
/// ```js
/// var foo = "hello world";
/// var bar = foo.split(" ");
class Split extends NativeMethodDefinition<String, List<String>> {
  Split()
    : super(
        methodName: "split",
        arity: 1,
        targetType: NativeMethodTarget.string,
        function: (target, _, args) {
          final arg = args[0];
          if (arg is! String) {
            throw RuntimeError("split() takes a string as an argument.");
          }
          return target.split(arg);
        },
      );
}

/// Returns a new string that is a substring of the original string.
/// ```js
/// var foo = "hello world";
/// var bar = foo.substring(0, 5);
class SubString extends NativeMethodDefinition<String, String> {
  SubString()
    : super(
        methodName: "substring",
        arity: 2,
        targetType: .string,
        function: (target, _, args) {
          final from = args[0];
          final to = args[1];

          if (from is! int || to is! int) {
            throw RuntimeError("substring() takes two integers as arguments.");
          }

          if (from < 0 || to < 0 || from > target.length || to > target.length) {
            throw RuntimeError("substring() arguments must be between 0 and the length of the string.");
          }

          if (from > to) {
            throw RuntimeError("substring() arguments must be in the order from, to.");
          }

          return target.substring(from, to);
        },
      );
}

/// Returns the first character of the string.
/// ```js
/// var foo = "hello";
/// var bar = foo.head();
class Head extends NativeMethodDefinition<String, String> {
  Head()
    : super(
        methodName: "head",
        arity: 0,
        targetType: NativeMethodTarget.string,
        function: (target, _, _) {
          return target[0];
        },
      );
}

/// Returns a new string that is the original string without its first character.
/// ```js
/// var foo = "hello";
/// var bar = foo.tail();
class Tail extends NativeMethodDefinition<String, String> {
  Tail()
    : super(
        methodName: "tail",
        arity: 0,
        targetType: NativeMethodTarget.string,
        function: (target, _, _) {
          return target.substring(1);
        },
      );
}

/// Returns true if the string contains the specified substring.
/// ```js
/// var foo = "hello";
/// var bar = foo.contains("el");
class Contains extends NativeMethodDefinition<String, bool> {
  Contains()
    : super(
        methodName: "contains",
        arity: 1,
        targetType: NativeMethodTarget.string,
        function: (target, _, args) {
          final arg = args[0];
          if (arg is! String) {
            throw RuntimeError("contains() takes a string as an argument.");
          }
          return target.contains(arg);
        },
      );
}

/// Returns true if the string is not empty.
/// ```js
/// var foo = "hello";
/// var bar = foo.isNotEmpty();
class IsNotEmpty extends NativeMethodDefinition<String, bool> {
  IsNotEmpty()
    : super(
        methodName: "isNotEmpty",
        arity: 0,
        targetType: NativeMethodTarget.string,
        function: (target, _, _) {
          return target.isNotEmpty;
        },
      );
}

/// Returns true if the string is empty.
/// ```js
/// var foo = "hello";
/// var bar = foo.isEmpty();
class IsEmpty extends NativeMethodDefinition<String, bool> {
  IsEmpty()
    : super(
        methodName: "isEmpty",
        arity: 0,
        targetType: NativeMethodTarget.string,
        function: (target, _, _) {
          return target.isEmpty;
        },
      );
}

/// Returns a new string that is the original string in uppercase.
/// ```js
/// var foo = "hello";
/// var bar = foo.toUpper();
class ToUpper extends NativeMethodDefinition<String, String> {
  ToUpper()
    : super(
        methodName: "toUpper",
        arity: 0,
        targetType: NativeMethodTarget.string,
        function: (target, _, _) {
          return target.toUpperCase();
        },
      );
}

/// Returns a new string that is the original string in lowercase.
/// ```js
/// var foo = "hello";
/// var bar = foo.toLower();
class ToLower extends NativeMethodDefinition<String, String> {
  ToLower()
    : super(
        methodName: "toLower",
        arity: 0,
        targetType: NativeMethodTarget.string,
        function: (target, _, _) {
          return target.toLowerCase();
        },
      );
}
