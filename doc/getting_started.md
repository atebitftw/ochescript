# Getting Started

## Requirements
*   **Dart SDK** Installed on your system. ([download](https://dart.dev/get-dart))

If you use **Flutter** ([flutter.dev](https://flutter.dev)), then you already have the Dart SDK installed.

## Using In Your Dart/Flutter Project

Reference This Package In Your pubspec.yaml file.
```yaml
dependencies:
  oche_script:
    git:
      url: git@github.com:atebitftw/oche_script.git
```

In your dart code, you can use it like this:
```dart
import 'package:oche_script/oche_script.dart' as oche;

Future<void> main() async {
  final script = r"print("Hello, World!");"; 

  final result = await oche.compileAndRun(script);
}
```
*The 'r' prefix on the string above is significant (a little Dart trick), because it allows you to use double quotes inside the string without escaping them.  You don't have to worry about this when you source your script files from files or asset bundles.*


## CLI Installation
You can install a simple script runner utility locally by running:
```bash
dart pub global activate --source git git@github.com:atebitftw/oche_script.git
```

This will install the `oche` command globally, which you can use to run scripts.

### Usage
```bash
oche {script_file}
```

### Hello World
Create a file in your favorite IDE: `hello.oche` with the following content:

```js
print("Hello, World!");
```

Then run it with:
```bash
oche hello.oche
```
*The `.oche` extension is not required, but it is recommended.*

There are more script examples in the `tool/scripts` directory of this project source code.

## VSCode Syntax Highlighting
If you want to take advantage of script syntax highlighting in VSCode, you can install the **OcheScript Syntax Highlighting Extension** (`tool/vs_code_syntax_highlighter/ochescript/ochescript-0.0.1.vsix`), which is included in the project source code.

You will have to load it manually.  In the extensions sidebar, load the vsix file from the path above.

Now any script files with the `.oche` extension will be syntax highlighted.

## More Resources
*   [Dart Interop](https://github.com/atebitftw/ochescript/blob/main/doc/dart_interop.md)
*   [Native Functions](https://github.com/atebitftw/ochescript/blob/main/doc/native_functions.md)
*   [Native Methods](https://github.com/atebitftw/ochescript/blob/main/doc/native_methods.md)
*   [Language Specification](https://github.com/atebitftw/ochescript/blob/main/doc/language_specification.md)