# OcheScript
[![Dart CI](https://github.com/atebitftw/ochescript/actions/workflows/dart.yaml/badge.svg)](https://github.com/atebitftw/ochescript/actions/workflows/dart.yaml)

![OcheScript Logo](https://atebitftw.github.io/site/assets/oche_script_logo_640.png)

*Oche *(pronounced "ock-ee")*. The official name for the throwing line in a game of darts.*

#### Embedded script language for Flutter/Dart applications.

## Key Features
OcheScript is an extensible, lightweight yet powerful scripting language designed for embedding into Dart/Flutter applications.

*   **Convenient [Dart interop](https://github.com/atebitftw/ochescript/blob/main/doc/dart_interop.md) Features.**
    * **Initialize OcheScript globals from Dart.**
    * **Call Dart functions from OcheScript and get return values.**
    * **Send values from OcheScript to Dart at any time.**
*   **Extensible - Make It Your Own**
    * **Define [extension methods](https://github.com/atebitftw/ochescript/blob/main/doc/native_methods.md) bound to supported types (many already included).**
    * **Define [global functions](https://github.com/atebitftw/ochescript/blob/main/doc/native_functions.md) that can execute arbitrary Dart code (many already included).**
*   **Object-Oriented Programming Features (classes, methods, properties, etc.).**
*   **Closures and Lambdas.**
*   **String Interpolation.**
*   **Try/Catch Exception Handling.**
*   **Asynchronous Support (async/await).**
*   **Lightweight Preprocessor Directive Capabilities.**
*   **`.oche` Script File Syntax Highlighting Extension for VSCode/Antigravity.**
*   **Comprehensive API and Language Documentation.**

## Hello World In OcheScript
```dart
import 'package:oche_script/oche_script.dart' as oche;

Future<void> main() async {
  final result = await oche.compileAndRun(r"print("Hello World!");");
}

// Hello World!
```

## Getting Started
See the [Getting Started](https://github.com/atebitftw/ochescript/blob/main/doc/getting_started.md) document for more information.

## Language Specification
See the [Language Specification](https://github.com/atebitftw/ochescript/blob/main/doc/language_specification.md) document for more information.

## Library API
See the [API](https://pub.dev/documentation/oche_script/latest/) document for more information.  This is an HTML document generated from the Dartdoc comments in the source code.

## Dart Interop
See the [Dart Interop](https://github.com/atebitftw/ochescript/blob/main/doc/dart_interop.md) document for more information.

## Why Does This Exist?
I work on some very large-scale Flutter projects that sometimes require a bit of dynamic runtime automation, and I found that I needed execute arbitrary code at runtime in certain situations.  I built OcheScript to meet this need.  In the Flutter/Dart ecosystem, there are probably five people that need this kind of thing, and I am one of them.  To the other four, I say: "Hello World!".

*Side Note: Dart technically does have arbitrary code execution capability via `dart:mirrors`, but I personally do not consider it to be a viable approach for many production application scenarios, especially anything Flutter-based (mirrors disallowed).  Another reason to avoid mirrors: As soon as you bring in mirrors, you lose tree-shaking.*

## These Batteries Are Not Included
*   No module system (beyond `#INCLUDE` directive)
*   No operator overloading.
*   Map keys must be strings.
*   Currying is not supported.
*   No direct support for accessing file systems or assets.  This can be achieved via Dart interop.
*   No support for ternary operator.

## Roadmap Ideas
*   Adding try/catch exception handling will probably be my next effort.
*   Native method binding to user-defined class instances sounds intriguing.  Though at that point, I may as well just implement native extension method support within the language itself.
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