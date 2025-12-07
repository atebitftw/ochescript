# OcheScript

**Oche *(pronounced "ock-ee")*. The official name for the throwing line in a game of darts.**

Embedded script language for Flutter/Dart applications.

![OcheScript Logo](https://atebitftw.github.io/site/assets/oche_script_logo_640.png)

## Key Features
OcheScript is a lightweight, dynamically typed, object-oriented, scripting language designed for embedding into Dart applications.

*   Convenient Dart interop capabilities.
*   Extensible via native methods and functions.
*   Object-oriented programming features (classes, methods, properties, etc.).
*   Closures and lambdas.
*   (Limited) Asynchronous support (async/await).
*   String interpolation.
*   Lightweight preprocessor directive capabilities.
*   `.oche` script file syntax highlighting extension for VSCode/Antigravity.

## Why Does This Exist?
I work on some very large-scale Flutter projects that sometimes require a bit of dynamic runtime automation, and I found that I needed execute arbitrary code at runtime in certain situations.  I built OcheScript to meet this need.  In the Flutter/Dart ecosystem, there are probably five people that need this kind of thing, and I am one of them.  To the other four, I say: "Hello World!".

*Side Note: Dart technically does have arbitrary code execution capability via `dart:mirrors`, but I personally do not consider it to be a viable approach for many production application scenarios, especially anything Flutter-based (mirrors disallowed).  Another reason to avoid mirrors: As soon as you bring in mirrors, you lose tree-shaking.*

## Getting Started
See the [Getting Started](https://github.com/atebitftw/ochescript/blob/main/doc/getting_started.md) document for more information.

## Language Specification
See the [Language Specification](https://github.com/atebitftw/ochescript/blob/main/doc/language_specification.md) document for more information.

## Library API
See the [API](https://github.com/atebitftw/ochescript/tree/main/doc/api) document for more information.  This is an HTML document generated from the Dartdoc comments in the source code.

## Dart Interop
See the [Dart Interop](https://github.com/atebitftw/ochescript/blob/main/doc/dart_interop.md) document for more information.

## Error Handling
Runtime errors cause script execution to halt with an error message.

Errors are not emitted to stdout by default.  They are usually reported via the [Logging Package](https://pub.dev/packages/logging) at level WARNING and above.  To listen to these errors, you can use the `Logging` class from the `logging` package.

```dart
// (assumes you've added the logging package as a dependency in your pubspec.yaml)
import 'package:logging/logging.dart';
import 'package:oche_script/oche_script.dart' as oche;

Future<void> main() async {
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print("${record.level.name}: ${record.message}");
    // emits the error message and stack trace
  });

  final result = await oche.compileAndRun(r"print("Hello World!");");

  print("Return Code: ${result['return_code']}");
  if (result.containsKey('error')) {
    print("Error: ${result['error']}");
  }
}
```

Error messages are also placed in the return map of the `compileAndRun` function (without stack trace).  The map has the following structure:

```dart
{
  "error": "{error message}",
  "return_code": 1,
  // other stuff emitted by any out() functions in the script.
}
```

### Why not just print errors to stdout?
Since OcheScript is primarily designed for use as an embedded language in other Dart/Flutter applications, stdout is not reliably available on various platforms.  Using the logging package gives the developer more flexibility in how and where they receive error messages.

If you want the error message to be printed to stdout, you can use the `Logging` class from the `logging` package to listen to the `Logger` at level WARNING and above.

### Included Library Error Reporting
When using the `#include` directive to include other "library" files into your script, OcheScript tracks the original source file and line number.  If a runtime error occurs within an included file, the error message will be prefixed with the file name and line number, like so:

```
Runtime error: [my_lib:42] Undefined variable 'foo'.
```

This is useful for debugging scripts that are composed of multiple files.

## These Batteries Are Not Included
*   No try/catch exception handling.
*   No module system (beyond `#INCLUDE` directive)
*   No operator overloading.
*   Map keys must be strings.
*   Currying is not supported.
*   No direct support for accessing file systems or assets.  This can be achieved via Dart interop.
*   No support for ternary operator.

## Stack Size Limits
Since the scope of this language is to live embedded inside other Dart applications, the virtual machine stack is fixed to a size of 8192 elements.  This is to prevent memory exhaustion in the host Dart environment.  If the stack overflows, the virtual machine will throw a runtime error.

Most scripts will rarely come close to this limit (most will never exceed 100).  However there are some rare scenarios that could cause a stack overflow:
- Trying to implement a deep recursion algorithm.
- Defining a large static list (e.g. `var x = [1, 2, 3, ...]; // are you declaring 8192 static elements in a list?`) may cause a stack overflow because the compiler pushes each element of the list onto the stack before actually building the list.  Better to define the list dynamically (e.g. `var x = []; for (var i = 0; i < 10000; i++) x.add(i);`) as this only pushes one element onto the stack at a time.

## Roadmap Ideas
*   Adding try/catch exception handling will probably be my next effort.
*   Native method binding to user-defined class instances sounds intriguing.  Though at that point, I may as well just implement native extension method support withing the language.
*   Perhaps implement support for a Record type, and destructuring syntax.  It would be nice to pass anonymous records back and forth between Dart and OcheScript.
*   More robust support for Futures and async/await.  OcheScript currently doesn't have it's own microtask queue, so it can't run async code in the same way that Dart can.  It does have the capability to await futures, but it doesn't have it's own event loop.
*   I would like eventually to implement a LINQ-style query syntax for OcheScript, to make it more useful for data processing and manipulation.  Perhaps with some kind of provider interface to Dart-side data services like Firebase, REDIS, etc.
*   I'm open to other ideas.

## Syntax Highlighting Support in VSCode
In [VS Code Extension](https://github.com/atebitftw/ochescript/tree/main/tool/vs_code_syntax_highlighter/ochescript) there is a a VSCode extension project that provides basic syntax highlighting for OcheScript files (.oche). You can use this extension by importing the `.vsix` file into VSCode manually.

You can find the compiled .vsix extension file in the bin/ directory of this project: [here](https://github.com/atebitftw/ochescript/tree/main/bin)

## About Me
My name is John, and if you've been a Dart enthusiast prior to M1 (way before v1 release), then we are probably friends.

## Attributions and Gratitude
The bones of this project are adapted from the excellent work of Bob Nystrom ([Github](https://github.com/munificent), [BlueSky](https://bsky.app/profile/stuffwithstuff.com)) in his book: "[Crafting Interpreters](https://craftinginterpreters.com/)", portions of which are licensed under the MIT License [see here](https://github.com/munificent/craftinginterpreters/blob/master/LICENSE).

I **highly** recommend this book if you are interested in learning how to build an interpreter.  It is a great resource.

Thanks Bob!