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

## String Methods
```js
"my string".codeUnitAt(0);
```
| Method | Returns | Description |
| :--- | :--- | :--- |
| `codeUnitAt(index)` | `Num` | Returns the code unit at the specified index. |
| `replaceAll(from, to)` | `String` | Replaces all occurrences of a specified substring with another substring. |
| `isLowerCase()` | `Bool` | Returns true if all letters in the string are lowercase. |
| `isUpperCase()` | `Bool` | Returns true if all letters in the string are uppercase. |
| `length()` | `Num` | Returns the length of the string. |
| `compareTo(other)` | `Num` | Compares the string to another string. |
| `trim()` | `String` | Returns a new string with leading and trailing whitespace removed. |
| `split(separator)` | `List` | Splits the string into a list of substrings separated by the specified separator. |
| `substring(from, to)` | `String` | Returns a new string that is a substring of the original string. |
| `head()` | `String` | Returns the first character of the string. |
| `tail()` | `String` | Returns a new string that is the original string without its first character. |
| `contains(substring)` | `Bool` | Returns true if the string contains the specified substring. |
| `isNotEmpty()` | `Bool` | Returns true if the string is not empty. |
| `isEmpty()` | `Bool` | Returns true if the string is empty. |
| `toUpper()` | `String` | Returns a new string that is the original string in uppercase. |
| `toLower()` | `String` | Returns a new string that is the original string in lowercase. |

## Number Methods
```js
1.compareTo(2);
```
| Method | Returns | Description |
| :--- | :--- | :--- |
| `compareTo(other)` | `Num` | Compares this number with another number. |
| `cos()` | `Num` | Returns the cosine of this number. |
| `sin()` | `Num` | Returns the sine of this number. |
| `tan()` | `Num` | Returns the tangent of this number. |
| `sqrt()` | `Num` | Returns the square root of this number. |
| `round()` | `Num` | Rounds this number to the nearest integer. |
| `pow(exponent)` | `Num` | Raises this number to the power of another number. |
| `mod(divisor)` | `Num` | Returns the remainder of this number divided by another number. |
| `max(other)` | `Num` | Returns the maximum of this number and another number. |
| `min(other)` | `Num` | Returns the minimum of this number and another number. |
| `exp()` | `Num` | Returns the exponential of this number. |
| `log()` | `Num` | Returns the natural logarithm of this number. |
| `atan()` | `Num` | Returns the arctangent of this number. |
| `atan2(other)` | `Num` | Returns the arctangent of this number and another number. |
| `asin()` | `Num` | Returns the arcsine of this number. |
| `acos()` | `Num` | Returns the arccosine of this number. |
| `abs()` | `Num` | Returns the absolute value of this number. |
| `truncate()` | `Num` | Returns the truncated value of this number. |
| `floor()` | `Num` | Returns the floor value of this number. |
| `ceil()` | `Num` | Returns the ceiling value of this number. |
| `isOdd()` | `Bool` | Returns true if this number is odd. |
| `isEven()` | `Bool` | Returns true if this number is even. |
| `toString()` | `String` | Returns the string representation of this number. |

## List Methods
```js
var list = [1, 2, 3];
list.forEach(fun(x) { print(x); });
```
| Method | Returns | Description |
| :--- | :--- | :--- |
| `forEach(callback)` | `Num` | Iterates over elements and calls the function for each. |
| `removeAt(index)` | `Num` | Removes the element at the specified index. |
| `reversed()` | `List` | Returns a new list with the elements in reverse order. |
| `sort(comparator)` | `Num` | Sorts the list using the provided comparison function. |
| `clear()` | `Num` | Clears the list. |
| `removeWhere(predicate)` | `Num` | Removes all elements that satisfy the test function. |
| `addAll(list)` | `Num` | Adds all elements from the provided list. |
| `join(separator)` | `String` | Joins the elements of the list into a string. |
| `fold(initial, combine)` | `{any}` | Reduces the list to a single value. |
| `every(predicate)` | `Bool` | Returns true if all elements satisfy the test function. |
| `any(predicate)` | `Bool` | Returns true if any element satisfies the test function. |
| `filter(predicate)` | `List` | Returns a list containing only elements that satisfy the function. |
| `map(transform)` | `List` | Returns a list of results from applying the function to each element. |
| `indexOf(element)` | `Num` | Returns the index of the first occurrence of the element. |
| `contains(element)` | `Bool` | Returns true if the list contains the element. |
| `isNotEmpty()` | `Bool` | Returns true if the list is not empty. |
| `isEmpty()` | `Bool` | Returns true if the list is empty. |
| `tail()` | `List` | Returns a new list containing all elements except the first. |
| `head()` | `{any}` | Returns the first element of the list. |
| `length()` | `Num` | Returns the number of elements in the list. |
| `toString()` | `String` | Returns a string representation of the list. |

## Map Methods
```js
var map = {"a": 1, "b": 2, "c": 3};
map.forEach(fun(key, value) { print("$key: $value"); });
```
| Method | Returns | Description |
| :--- | :--- | :--- |
| `forEach(callback)` | `Num` | Iterates over entries and calls the function for each. |
| `clear()` | `Map` | Clears all entries from the map. |
| `remove(key)` | `Map` | Removes the entry with the specified key. |
| `merge(otherMap)` | `Map` | Merges the specified map into this map. |
| `toString()` | `String` | Returns a string representation of the map. |
| `containsValue(value)` | `Bool` | Returns true if the map contains the specified value. |
| `isNotEmpty()` | `Bool` | Returns true if the map is not empty. |
| `isEmpty()` | `Bool` | Returns true if the map is empty. |
| `containsKey(key)` | `Bool` | Returns true if the map contains the specified key. |
| `values()` | `List` | Returns a list of the map's values. |
| `keys()` | `List` | Returns a list of the map's keys. |
| `length()` | `Num` | Returns the number of entries in the map. |

## Date Methods
```js
var myDate = now();
print(myDate.weekday());
```
| Method | Returns | Description |
| :--- | :--- | :--- |
| `weekday()` | `Num` | Returns the weekday of the date. |
| `timeZoneOffset()` | `Duration` | Returns the time zone offset of the date. |
| `timeZoneName()` | `String` | Returns the time zone name of the date. |
| `isUtc()` | `Bool` | Returns true if the date is UTC. |
| `compareTo(other)` | `Num` | Compares the date to another date. |
| `year()` | `Num` | Returns the year of the date. |
| `month()` | `Num` | Returns the month of the date. |
| `day()` | `Num` | Returns the day of the date. |
| `hour()` | `Num` | Returns the hour of the date. |
| `minute()` | `Num` | Returns the minute of the date. |
| `second()` | `Num` | Returns the second of the date. |
| `millisecond()` | `Num` | Returns the millisecond of the date. |

## Duration Methods
```js
var myDuration = duration(0, 0, 1, 0, 0);
print(myDuration.inMinutes()); // 1
```
| Method | Returns | Description |
| :--- | :--- | :--- |
| `compareTo(other)` | `Num` | Compares the duration to another duration. |
| `abs()` | `Duration` | Returns the absolute value of the duration. |
| `isNegative()` | `Bool` | Returns true if the duration is negative. |
| `inYears()` | `Num` | Returns the number of years in the duration. |
| `inHours()` | `Num` | Returns the number of hours in the duration. |
| `inMinutes()` | `Num` | Returns the number of minutes in the duration. |
| `inSeconds()` | `Num` | Returns the number of seconds in the duration. |
| `inMilliseconds()` | `Num` | Returns the number of milliseconds in the duration. |