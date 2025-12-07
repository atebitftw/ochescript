import 'package:oche_script/oche_script.dart';
import 'package:oche_script/src/runtime/closure_invoker.dart' show invokeScriptClosure;

/// Registers all list extensions.
/// This is called automatically by the VM.
void registerListExtensions() {
  registerNativeMethod(ToString());
  registerNativeMethod(Head());
  registerNativeMethod(Tail());
  registerNativeMethod(Length());
  registerNativeMethod(IsEmpty());
  registerNativeMethod(IsNotEmpty());
  // registerNativeMethod(Add()); now handled by LIST_APPEND opcode
  registerNativeMethod(IndexOf());
  registerNativeMethod(Contains());
  registerNativeMethod(Map());
  registerNativeMethod(Filter());
  registerNativeMethod(Every());
  registerNativeMethod(Any());
  registerNativeMethod(Fold());
  registerNativeMethod(Join());
  registerNativeMethod(AddAll());
  registerNativeMethod(RemoveWhere());
  registerNativeMethod(Clear());
  registerNativeMethod(Sort());
  registerNativeMethod(Reversed());
  registerNativeMethod(RemoveAt());
  registerNativeMethod(ForEach());
}

/// Iterates over the list elements and calls the provided function for each element.
/// The function should take one argument: element.
///
/// ```js
/// var lst = [1, 2, 3];
/// lst.forEach(fun(element) {
///     print(element);
/// });
///
/// Async example:
/// ```js
/// var lst = [1, 2, 3];
/// lst.forEach(async fun(element) {
///     await wait(1000);
///     print(element);
/// });
/// ```
class ForEach extends NativeMethodDefinition<List<Object>, int> {
  ForEach()
    : super(
        methodName: "forEach",
        targetType: .list,
        arity: 1,
        function: (target, vm, arguments) async {
          if (arguments[0] is! ObjClosure) {
            throw RuntimeError("forEach() requires a function as an argument");
          }

          for (var element in target) {
            await invokeScriptClosure(vm, arguments[0], [element]);
          }
          return target.length;
        },
      );
}

/// Removes the element at the specified index.
///
/// ```js
/// var lst = [1, 2, 3];
/// lst.removeAt(1); // lst = [1, 3]
/// ```
class RemoveAt extends NativeMethodDefinition<List<Object>, int> {
  RemoveAt()
    : super(
        methodName: "removeAt",
        targetType: .list,
        arity: 1,
        function: (target, _, arguments) {
          if (arguments[0] is! int) {
            throw RuntimeError("RemoveAt index must be an integer.");
          }
          target.removeAt(arguments[0] as int);
          return target.length;
        },
      );
}

/// Returns a new list with the elements in reverse order.
///
/// ```js
/// var lst = [1, 2, 3];
/// var reversed = lst.reversed(); // reversed = [3, 2, 1]
/// ```
class Reversed extends NativeMethodDefinition<List<Object>, List> {
  Reversed()
    : super(
        methodName: "reversed",
        targetType: .list,
        arity: 0,
        function: (target, _, _) {
          return target.reversed.toList();
        },
      );
}

/// Sorts the list using the provided comparison function.
///
/// ```js
/// var lst = [3, 1, 2];
/// lst.sort(fun(a, b) => a - b); // lst = [1, 2, 3]
/// ```
class Sort extends NativeMethodDefinition<List<Object>, int> {
  Sort()
    : super(
        methodName: "sort",
        targetType: .list,
        arity: 1,
        function: (target, vm, arguments) async {
          if (arguments[0] is! ObjClosure) {
            throw RuntimeError("Sort function must be a function (a, b) => int.");
          }
          // Bubble sort for simplicity and async support
          for (int i = 0; i < target.length - 1; i++) {
            for (int j = 0; j < target.length - i - 1; j++) {
              int comparison = await invokeScriptClosure(vm, arguments[0], [target[j], target[j + 1]]) as int;
              if (comparison > 0) {
                var temp = target[j];
                target[j] = target[j + 1];
                target[j + 1] = temp;
              }
            }
          }
          return target.length;
        },
      );
}

/// Clears the list.
///
/// ```js
/// var lst = [1, 2, 3];
/// lst.clear(); // lst = []
/// ```
class Clear extends NativeMethodDefinition<List<Object>, int> {
  Clear()
    : super(
        methodName: "clear",
        targetType: .list,
        arity: 0,
        function: (target, _, _) {
          target.clear();
          return target.length;
        },
      );
}

/// Removes all elements from the list that satisfy the provided test function.
///
/// ```js
/// var lst = [1, 2, 3, 4, 5];
/// lst.removeWhere(fun(x) { return x % 2 == 0; }); // lst = [1, 3, 5]
/// ```
class RemoveWhere extends NativeMethodDefinition<List<Object>, int> {
  RemoveWhere()
    : super(
        methodName: "removeWhere",
        targetType: .list,
        arity: 1,
        function: (target, interpreter, arguments) async {
          if (arguments[0] is! ObjClosure) {
            throw RuntimeError("RemoveWhere function must be a function.");
          }
          for (int i = target.length - 1; i >= 0; i--) {
            bool remove = await invokeScriptClosure(interpreter, arguments[0], [target[i]]) as bool;
            if (remove) {
              target.removeAt(i);
            }
          }
          return target.length;
        },
      );
}

/// Adds all elements from the provided list to the target list.
///
/// ```js
/// var lst = [1, 2, 3];
/// lst.addAll([4, 5, 6]); // lst = [1, 2, 3, 4, 5, 6]
/// ```
class AddAll extends NativeMethodDefinition<List<Object>, int> {
  AddAll()
    : super(
        methodName: "addAll",
        targetType: .list,
        arity: 1,
        function: (target, _, arguments) {
          if (arguments[0] is! List) {
            throw RuntimeError("addAll argument must be a list.");
          }
          target.addAll(arguments[0].cast<Object>());
          return target.length;
        },
      );
}

/// Joins the elements of the list into a string using the provided separator.
///
/// ```js
/// var lst = ["a", "b", "c"];
/// var joined = lst.join(","); // joined = "a,b,c"
/// ```
class Join extends NativeMethodDefinition<List<Object>, String> {
  Join()
    : super(
        methodName: "join",
        targetType: .list,
        arity: 1,
        function: (target, _, arguments) {
          return target.join(arguments[0] as String);
        },
      );
}

/// Reduces the list to a single value by applying the provided function to each element.
///
/// ```js
/// var lst = [1, 2, 3];
/// var sum = lst.fold(0, fun(acc, x) { return acc + x; }); // sum = 6
/// ```
class Fold extends NativeMethodDefinition<List<Object>, Object> {
  Fold()
    : super(
        methodName: "fold",
        targetType: .list,
        arity: 2,
        function: (target, vm, arguments) async {
          if (arguments[1] is! ObjClosure) {
            throw RuntimeError("Fold function must be a function.");
          }
          var acc = arguments[0];
          for (var element in target) {
            acc = await invokeScriptClosure(vm, arguments[1], [element, acc]);
          }
          return acc;
        },
      );
}

/// Returns true if all elements in the list satisfy the provided test function.
///
/// ```js
/// var lst = [1, 2, 3];
/// var allEven = lst.every(fun(x) { return x % 2 == 0; }); // allEven = false
/// ```
class Every extends NativeMethodDefinition<List<Object>, bool> {
  Every()
    : super(
        methodName: "every",
        targetType: .list,
        arity: 1,
        function: (target, vm, arguments) async {
          if (arguments[0] is! ObjClosure) {
            throw RuntimeError("Every function must be a function.");
          }
          for (var element in target) {
            bool result = await invokeScriptClosure(vm, arguments[0], [element]) as bool;
            if (!result) return false;
          }
          return true;
        },
      );
}

/// Returns true if any element in the list satisfies the provided test function.
///
/// ```js
/// var lst = [1, 2, 3];
/// var anyEven = lst.any(fun(x) { return x % 2 == 0; }); // anyEven = true
/// ```
class Any extends NativeMethodDefinition<List<Object>, bool> {
  Any()
    : super(
        methodName: "any",
        targetType: .list,
        arity: 1,
        function: (target, vm, arguments) async {
          if (arguments[0] is! ObjClosure) {
            throw RuntimeError("Any function must be a function.");
          }
          for (var element in target) {
            bool result = await invokeScriptClosure(vm, arguments[0], [element]) as bool;
            if (result) return true;
          }
          return false;
        },
      );
}

/// Returns a new list containing only the elements that satisfy the provided test function.
///
/// ```js
/// var lst = [1, 2, 3];
/// var filtered = lst.filter(fun(x) { return x % 2 == 0; }); // filtered = [2]
/// ```
class Filter extends NativeMethodDefinition<List<Object>, List<Object>> {
  Filter()
    : super(
        methodName: "filter",
        targetType: .list,
        arity: 1,
        function: (target, vm, arguments) async {
          if (arguments[0] is! ObjClosure) {
            throw RuntimeError("Filter function must be a function.");
          }
          var result = <Object>[];
          for (var element in target) {
            bool keep = await invokeScriptClosure(vm, arguments[0], [element]) as bool;
            if (keep) result.add(element);
          }
          return result;
        },
      );
}

/// Returns a new list containing the results of applying the provided function to each element.
///
/// ```js
/// var lst = [1, 2, 3];
/// var mapped = lst.map(fun(x) { return x * 2; }); // mapped = [2, 4, 6]
/// ```
class Map extends NativeMethodDefinition<List<Object>, List> {
  Map()
    : super(
        methodName: "map",
        targetType: .list,
        arity: 1,
        function: (target, vm, arguments) async {
          if (arguments[0] is! ObjClosure) {
            throw RuntimeError("Map function must be a function. ${arguments[0].runtimeType}");
          }
          var result = [];
          for (var element in target) {
            result.add(await invokeScriptClosure(vm, arguments[0], [element]));
          }
          return result;
        },
      );
}

/// Returns the index of the first occurrence of the provided element in the list.
///
/// ```js
/// var lst = [1, 2, 3];
/// var index = lst.indexOf(2); // index = 1
/// ```
class IndexOf extends NativeMethodDefinition<List<Object>, int> {
  IndexOf()
    : super(
        methodName: "indexOf",
        targetType: .list,
        arity: 1,
        function: (target, _, arguments) {
          return target.indexOf(arguments[0]);
        },
      );
}

/// Returns true if the list contains the provided element.
///
/// ```js
/// var lst = [1, 2, 3];
/// var containsTwo = lst.contains(2); // containsTwo = true
/// ```
class Contains extends NativeMethodDefinition<List<Object>, bool> {
  Contains()
    : super(
        methodName: "contains",
        targetType: .list,
        arity: 1,
        function: (target, _, arguments) {
          return target.contains(arguments[0]);
        },
      );
}

/// Returns true if the list is not empty.
///
/// ```js
/// var lst = [1, 2, 3];
/// var isNotEmpty = lst.isNotEmpty(); // isNotEmpty = true
/// ```
class IsNotEmpty extends NativeMethodDefinition<List<Object>, bool> {
  IsNotEmpty()
    : super(
        methodName: "isNotEmpty",
        targetType: .list,
        arity: 0,
        function: (target, _, arguments) {
          return target.isNotEmpty;
        },
      );
}

/// Returns true if the list is empty.
///
/// ```js
/// var lst = [];
/// var isEmpty = lst.isEmpty(); // isEmpty = true
/// ```
class IsEmpty extends NativeMethodDefinition<List<Object>, bool> {
  IsEmpty()
    : super(
        methodName: "isEmpty",
        targetType: .list,
        arity: 0,
        function: (target, _, arguments) {
          return target.isEmpty;
        },
      );
}

/// Returns a new list containing all elements except the first.
///
/// ```js
/// var lst = [1, 2, 3];
/// var tail = lst.tail(); // tail = [2, 3]
/// ```
class Tail extends NativeMethodDefinition<List<Object>, List<Object>> {
  Tail()
    : super(
        methodName: "tail",
        targetType: .list,
        arity: 0,
        function: (target, _, arguments) {
          return target.sublist(1);
        },
      );
}

/// Returns the first element of the list.
///
/// ```js
/// var lst = [1, 2, 3];
/// var head = lst.head(); // head = 1
/// ```
class Head extends NativeMethodDefinition<List<Object>, Object> {
  Head()
    : super(
        methodName: "head",
        targetType: .list,
        arity: 0,
        function: (target, _, arguments) {
          return target.first;
        },
      );
}

/// Returns the number of elements in the list.
///
/// ```js
/// var lst = [1, 2, 3];
/// var length = lst.length(); // length = 3
/// ```
class Length extends NativeMethodDefinition<List<Object>, int> {
  Length()
    : super(
        methodName: "length",
        targetType: .list,
        arity: 0,
        function: (target, _, arguments) {
          return target.length;
        },
      );
}

/// Returns a string representation of the list.
///
/// ```js
/// var lst = [1, 2, 3];
/// var str = lst.toString(); // str = "[1, 2, 3]"
/// print(str);
/// print(lst); // same
/// ```
class ToString extends NativeMethodDefinition<List<Object>, String> {
  ToString()
    : super(
        methodName: "toString",
        targetType: .list,
        arity: 0,
        function: (target, vm, arguments) {
          return target.toString();
        },
      );
}
