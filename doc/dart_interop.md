# Dart Interop
OcheScript provides several ways to interop with the Dart runtime.

## Compile Time Interop
*"Compile Time"* refers to the script compile time phase, not the Dart compile time phase.

### Intializing Global State
The `initialGlobalState` parameter can be used to inject global variables into the script.  These are accessible from the script as if they were global variables.

If for example, we pass a map to the `initialGlobalState` parameter, it will be injected into the script as global variables.

Example:

In this example, we are passing in two global variables, `globalVar1` and `globalVar2`, into the script, which the script can mutate and use as needed, even passing them back out to the host application via the `out` function.

```dart
import 'package:oche_script/oche_script.dart' as oche;

final globalState = {
  "globalVar1": "value1",
  "globalVar2": "value2",
};

final source = r"""
// the injected global variables are accessible.
print(globalVar1); // value1
print(globalVar2); // value2
""";

Future<void> main() async {
  final result = await oche.compileAndRun(
    source,
    initialGlobalState: globalState,
  );

  print(result); // {return_code: 0}
}
```

### Native Functions
Native functions are pre-defined functions that can be called globally from the script.  They are registered ahead of time to the vm.

Example:
```js

/// clock() is a native function implemented in Dart and registered with the OcheScript vm at compile time.
var n = clock();

print(n); // milliseconds elapsed since epoch.
```

See [Native Functions](https://github.com/atebitftw/ochescript/blob/main/doc/native_functions.md) for more information.

### Native Methods
Native methods are akin to Dart extension methods, except that they are registered ahead of time to the vm.  These methods are always bound to a supported type, and are called on that type via dot notation.

```js
var n = -123;

/// abs() is a native method implemented in Dart and registered with OcheScript at compile time.
print(n.abs());
```

.abs() is a native method implemented in Dart and registered with OcheScript at compile time.  There are a bunch of these, but you can extend them by following the instructions in the API or in this document.

See [Native Methods](https://github.com/atebitftw/ochescript/blob/main/doc/native_methods.md) for more information.

## Runtime Interop
*"Runtime"* refers to the script runtime phase, not the Dart runtime phase.

### The out() function
The `out` function is used to write values to the output map, and to an optional callback function that is given to the vm.  The output map is returned by the vm when the script is finished.

```dart
import 'package:oche_script/oche_script.dart' as oche;

Future<void> main() async {
  final script = r"out("myValue", "Hello, World!");";

  final result = await oche.compileAndRun(script, outCallback: (key, value) {
    print("$key: $value"); // myValue: Hello, World!
  });

  print(result); // {"myValue": "Hello, World!", return_code: 0}
}
```

### The dart() function
The `dart` function is used to call Dart functions from OcheScript.  It must be called asynchronously.  It is up to the Dart code to handle the callback function.  In a sense the Dart function allows Dart to expose an API to the script.

```js
var result = await dart("dartFunctionName", [arg1, arg2, ...]);
```

Using the `dart` function requires a callback function to be provided to the interpreter.  This callback function should be a function that takes a string name and a list of arguments and returns the result of the call.  It's up to you to provide and handle that callback function, passing the values along to the appropriate Dart function and returning the result to the script.

All Dart functions exposed to the script must return a non-null value of a supported type.

Dart functions may be asynchronous, in which case the script will await the result.

```dart
import 'package:oche_script/oche_script.dart' as oche;

Future<void> main() async {
  final script = r"var result = await dart("myFunction", []);"; 

  final result = await oche.compileAndRun(script, 
    dartCallback: (name, args) {
      if (name == "myFunction") {
        return Future.delayed(Duration(seconds: 1), () => "Hello, World!");
      }
      return null;
    },
  );
}
```

### dart() vs Native Functions
Think of the `dart()` function as a general-purpose runtime cousin of Native Functions.

Implement Native Functions when you want OcheScript to have a canonical, reusable connection to your Dart/Flutter project(s).

Let's say you have some back-end AI service that you want to expose to your scripts.  You can implement a Native Function called `myAIPromptThing` that takes a string argument and returns a string result.  And then use it in your scripts like this:

```js
var result = await myAIPromptThing("Tell me a joke.");

print(result);
```

Use the `dart()` function when you just need to perform a targeted operation in a smaller scope of your project, or require a more dynamic connection to your Dart project.  You could still do the same example as above with the Native Function, but it would look like this in the script:

```js
// This works, but perhaps better to use a Native Function since we will probably call this
// function multiple times across multiple scripts.
var result = await dart("myAIPromptThing", ["Tell me a joke."]);
```

See `doc/native_functions.md` in the project source code for more information on how to extend OcheScript with Native Functions.

## A Full Interop Example
See the `/example` directory in the project source code for a full interop example.