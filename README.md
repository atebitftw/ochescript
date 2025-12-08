# OcheScript
[![Dart CI](https://github.com/atebitftw/ochescript/actions/workflows/dart.yaml/badge.svg)](https://github.com/atebitftw/ochescript/actions/workflows/dart.yaml)

![OcheScript Logo](https://atebitftw.github.io/site/assets/oche_script_logo_640.png)

*Oche *(pronounced "ock-ee")*. The official name for the throwing line in a game of darts.*

#### Embedded script language for Flutter/Dart applications.

## Key Features
*   **Convenient [Dart interop](https://github.com/atebitftw/ochescript/blob/main/doc/dart_interop.md) Features:**
    * **Initialize OcheScript globals from Dart.**
    * **Call Dart functions from OcheScript and get return values. Supports async calls.**
    * **Send values from OcheScript to Dart at any time.**
*   **Extensible - Make It Your Own:**
    * **[Native Methods](https://github.com/atebitftw/ochescript/blob/main/doc/native_methods.md) bound to supported types (many already included).**
    * **[Native Functions](https://github.com/atebitftw/ochescript/blob/main/doc/native_functions.md) that can execute arbitrary Dart code (many already included).**
*   **Object-Oriented Programming Features (classes, methods, properties, etc.).**
*   **Closures and Lambdas.**
*   **String Interpolation.**
*   **Try/Catch Exception Handling.**
*   **Asynchronous Support (async/await).**
*   **Lightweight Preprocessor Directive Capabilities.**
*   **`.oche` Script File Syntax Highlighting Extension for VSCode/Antigravity.**
*   **Comprehensive API and Language Documentation.**
*   **Backed by years of actual production use in real-world business applications.**

## Hello World In OcheScript
```dart
import 'package:oche_script/oche_script.dart' as oche;

Future<void> main() async {
  final result = await oche.compileAndRun(r"print("Hello World!");");
}

// Hello World!
```

## Getting Started
See the [Getting Started](https://github.com/atebitftw/ochescript/blob/main/doc/getting_started.md) document to get up and running quickly.

## Language Specification
See the [Language Specification](https://github.com/atebitftw/ochescript/blob/main/doc/language_specification.md) for a complete overview of the language features and capabilities.

## Library API
The API is comprised three main components:
1. Script running `compileAndRun`
2. Native Function registration `registerNativeFunction`
3. Native Method registration `registerNativeMethod`

The API also exposes built-in native functions and methods, for reference.

See the [API](https://pub.dev/documentation/oche_script/latest/).

## Dart Interop
See the [Dart Interop](https://github.com/atebitftw/ochescript/blob/main/doc/dart_interop.md) to learn about all the ways that OcheScript can interact with your Dart code.

## Why Does This Exist?
I built OcheScript a while back to meet a need that I have on my larger Flutter projects to store and execute arbitrary code at runtime.  In the Flutter/Dart ecosystem, there are probably five people that need this kind of thing, and I am one of them.  To the other four, I say: "Hello World!".

## These Batteries Are Not Included:
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
My name is John, and if you've been a Dart enthusiast prior to M1 (way before v1 release), then we are probably friends.  I've been using OcheScript in production for years now, and it is my pleasure to now share it with the other four of you who will need it.

## Attributions and Gratitude
The bones of this project are adapted from the excellent work of **Robert Nystrom** ([Github](https://github.com/munificent), [BlueSky](https://bsky.app/profile/stuffwithstuff.com)) in his book: **"[Crafting Interpreters](https://craftinginterpreters.com/)**", portions of which are licensed under the MIT License [see here](https://github.com/munificent/craftinginterpreters/blob/master/LICENSE).

I **highly** recommend this book if you are interested in learning how to build an interpreter.  It is a great resource.

Thanks Bob!