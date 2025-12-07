import 'package:oche_script/oche_script.dart';
import 'package:oche_script/src/runtime/closure_invoker.dart'
    show invokeScriptClosure;

/// Registers all native methods for the Map type.
/// This is called automatically by the VM.
void registerMapExtensions() {
  registerNativeMethod(Length());
  registerNativeMethod(Keys());
  registerNativeMethod(Values());
  registerNativeMethod(ContainsKey());
  registerNativeMethod(IsNotEmpty());
  registerNativeMethod(IsEmpty());
  registerNativeMethod(ContainsValue());
  registerNativeMethod(ToString());
  registerNativeMethod(Merge());
  registerNativeMethod(Remove());
  registerNativeMethod(Clear());
  registerNativeMethod(ForEach());
}

/// Iterates over the map entries and calls the provided function for each entry.
/// The function should take two arguments: the key and the value.
///
/// ```js
/// var mp = {"a": 1, "b": 2, "c": 3};
/// mp.forEach(fun(key, value) {
///     print(key + ": " + value);
/// });
/// ```
///
/// Async example:
/// ```js
/// var mp = {"a": 1, "b": 2, "c": 3};
/// mp.forEach(async fun(key, value) {
///     await wait(1000);
///     print(key + ": " + value);
/// });
/// ```
class ForEach extends NativeMethodDefinition<Map<String, Object>, int> {
  ForEach()
    : super(
        methodName: "forEach",
        targetType: .map,
        arity: 1,
        function: (target, vm, arguments) async {
          if (arguments[0] is! ObjClosure) {
            throw RuntimeError(
              "forEach arg must be a function: (key, value) {...}",
            );
          }
          for (final entry in target.entries) {
            await invokeScriptClosure(vm, arguments[0], [
              entry.key,
              entry.value,
            ]);
          }
          return target.length;
        },
      );
}

/// Clears all entries from the map.
///
/// ```js
/// var mp = {"a": 1, "b": 2, "c": 3};
/// mp.clear();
/// ```
class Clear
    extends NativeMethodDefinition<Map<String, Object>, Map<String, Object>> {
  Clear()
    : super(
        methodName: "clear",
        targetType: .map,
        arity: 0,
        function: (target, interpreter, arguments) {
          target.clear();
          return target;
        },
      );
}

/// Removes the entry with the specified key from the map.
///
/// ```js
/// var mp = {"a": 1, "b": 2, "c": 3};
/// mp.remove("b");
/// ```
class Remove
    extends NativeMethodDefinition<Map<String, Object>, Map<String, Object>> {
  Remove()
    : super(
        methodName: "remove",
        targetType: .map,
        arity: 1,
        function: (target, interpreter, arguments) {
          if (arguments[0] is! String) {
            throw RuntimeError("remove() requires a String argument");
          }
          target.remove(arguments[0]);
          return target;
        },
      );
}

/// Merges the specified map into this map.
///
/// ```js
/// var mp = {"a": 1, "b": 2, "c": 3};
/// mp.merge({"d": 4, "e": 5});
/// ```
class Merge
    extends NativeMethodDefinition<Map<String, Object>, Map<String, Object>> {
  Merge()
    : super(
        methodName: "merge",
        targetType: .map,
        arity: 1,
        function: (target, interpreter, arguments) {
          if (arguments[0] is! Map) {
            throw RuntimeError("merge() requires a Map argument");
          }
          target.addAll(arguments[0].cast<String, Object>());
          return target;
        },
      );
}

/// Returns a string representation of the map.  Simply printing a map yields the same result.
///
/// ```js
/// var mp = {"a": 1, "b": 2, "c": 3};
/// print(mp.toString());
/// print(mp); // also works
/// ```
class ToString extends NativeMethodDefinition<Map<String, Object>, String> {
  ToString()
    : super(
        methodName: "toString",
        targetType: .map,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.toString();
        },
      );
}

/// Returns true if the map contains the specified value.
///
/// ```js
/// var mp = {"a": 1, "b": 2, "c": 3};
/// print(mp.containsValue(2)); // true
/// ```
class ContainsValue extends NativeMethodDefinition<Map<String, Object>, bool> {
  ContainsValue()
    : super(
        methodName: "containsValue",
        targetType: .map,
        arity: 1,
        function: (target, interpreter, arguments) {
          return target.containsValue(arguments[0]);
        },
      );
}

/// Returns true if the map is not empty.
///
/// ```js
/// var mp = {"a": 1, "b": 2, "c": 3};
/// print(mp.isNotEmpty()); // true
/// ```
class IsNotEmpty extends NativeMethodDefinition<Map<String, Object>, bool> {
  IsNotEmpty()
    : super(
        methodName: "isNotEmpty",
        targetType: .map,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.isNotEmpty;
        },
      );
}

/// Returns true if the map is empty.
///
/// ```js
/// var mp = {};
/// print(mp.isEmpty()); // true
/// ```
class IsEmpty extends NativeMethodDefinition<Map<String, Object>, bool> {
  IsEmpty()
    : super(
        methodName: "isEmpty",
        targetType: .map,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.isEmpty;
        },
      );
}

/// Returns true if the map contains the specified key.
///
/// ```js
/// var mp = {"a": 1, "b": 2, "c": 3};
/// print(mp.containsKey("b")); // true
/// ```
class ContainsKey extends NativeMethodDefinition<Map<String, Object>, bool> {
  ContainsKey()
    : super(
        methodName: "containsKey",
        targetType: .map,
        arity: 1,
        function: (target, interpreter, arguments) {
          if (arguments[0] is! String) {
            throw RuntimeError("containsKey() requires a String argument");
          }
          return target.containsKey(arguments[0]);
        },
      );
}

/// Returns a list of the map's values.
///
/// ```js
/// var mp = {"a": 1, "b": 2, "c": 3};
/// print(mp.values()); // [1, 2, 3]
/// ```
class Values extends NativeMethodDefinition<Map<String, Object>, List<Object>> {
  Values()
    : super(
        methodName: "values",
        targetType: .map,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.values.toList();
        },
      );
}

/// Returns a list of the map's keys.
///
/// ```js
/// var mp = {"a": 1, "b": 2, "c": 3};
/// print(mp.keys()); // ["a", "b", "c"]
/// ```
class Keys extends NativeMethodDefinition<Map<String, Object>, List<String>> {
  Keys()
    : super(
        methodName: "keys",
        targetType: .map,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.keys.toList();
        },
      );
}

/// Returns the number of entries in the map.
///
/// ```js
/// var mp = {"a": 1, "b": 2, "c": 3};
/// print(mp.length()); // 3
/// ```
class Length extends NativeMethodDefinition<Map<String, Object>, int> {
  Length()
    : super(
        methodName: "length",
        targetType: .map,
        arity: 0,
        function: (target, interpreter, arguments) {
          return target.length;
        },
      );
}
