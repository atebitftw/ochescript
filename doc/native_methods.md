# Native Methods
Native methods provide a way to extend the functionality of OcheScript supported types by adding new methods to them.

Think of native methods as something akin to Dart extension methods.

**Note: At this time native methods are not supported for class instances.  Only for the built-in types.**

To see a list of all the built-in native methods available, check the API documentation.

## How To Implement Your Own Native Method
Let's say we wanted a native method for strings called `toSnakeCase`, where we took any lowerCamelCase string can converted it to snake_case.

```dart
import 'package:oche_script/oche_script.dart';

registerNativeMethod(NativeMethodDefinition(
  // the name of the method, e.g. "foo".toSnakeCase();
  name: "toSnakeCase",

  // The target type that the method should bind to.
  target: NativeMethodTarget.string,

  // The implementation of the method when it is invoked.
  function: (target, _, _) {
    // you would want to add some error checking here.
    if (target.isEmpty) return "";

    if (target is! String) throw RuntimeError("toSnakeCase() requires a string argument");

    // convert all uppercase to snake_case
    return (target as String).replaceAllMapped(RegExp(r'([A-Z])'), (match) => "_${match.group(1)}").toLowerCase();
  },
));
```

Now, when in our scripts we can call our native method on any String type:
```js
var y = "helloWorld".toSnakeCase();
print(y); // hello_world
```

## Advanced Scenario: Callbacks
Some native methods require one or more callbacks to be passed in as arguments, in this case, you'll need to interact
with the VM a bit to address the callbacks properly.

To illustrate how this works, here is the built-in `.forEach(callback)` method for List types:

```dart
import 'package:oche_script/oche_script.dart';

class ForEach extends NativeMethodDefinition<List<Object>, int> {
  ForEach()
    : super(
        methodName: "forEach",
        targetType: .list,
        arity: 1,
        function: (target, interpreter, arguments) async {
          // We expect a function as the first argument
          if (arguments[0] is! ObjClosure){
            throw RuntimeError("forEach() requires a function as an argument");
          }
          
          // for each element in the list, we pass the function and the element (as argument to that function).
          for (var element in target) {
            await invokeScriptClosure(interpreter, arguments[0], [element]);
          }

          // return the length of the list
          return target.length;
        },
      );
}

registerNativeMethod(ForEach());
```


Here is an example of using the built-in `forEach` method in OcheScript:
```js
[1, 2, 3].forEach(fun(x) { print(x); });
```

