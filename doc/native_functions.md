# Native Functions

Native functions are globally available functions that execute Dart code during script runtime execution.  This feature allows you to expose Dart code to OcheScript scripts in a canonical, reusable way, extending the script's functionality.

## Registering Custom Native Functions

You can register your own global native functions from Dart code using `registerNativeFunction`.

### Example

In your Dart code:
```dart
import 'package:oche_script/oche_script.dart' as AScript;

void main() {
  // Register a function that sums a list of numbers
  AScript.registerNativeFunction("sum", (args) {
    if (args.isEmpty) return 0;

    if (args[0] is! List) throw RuntimeError("sum expects a list of numbers");
    
    final list = args[0] as List;
    return list.fold(0, (a, b) => a + b);
  });

  // ... run your script using AScript.compileAndRun()
}
```

In your OcheScript:
```js
var myList = [1, 2, 3, 4];
var total = sum(myList);
print(total); // 10
```

# Included Native Functions

## System Functions

### `wait(milliseconds)`
Returns a Future that completes after the given number of milliseconds.
- **Args**: `int` milliseconds
- **Returns**: `Future`

```js
await wait(1000); // Waits for 1 second
```

### `quit(exitCode)`
Immediately halts script execution and exits with the given return code.
- **Args**: `int` exitCode
- **Returns**: `int` (the exit code)

```js
quit(0); // Success
quit(1); // Error
```

## Time Functions

### `clock()`
Returns the current time in milliseconds since the epoch.
- **Returns**: `int`

```js
var start = clock();
```

### `now()`
Returns the current date and time as a DateTime object.
- **Returns**: `Date`

```js
var current = now();
```

### `date(year, month, day, hour, minute, second, millisecond)`
Creates a new DateTime object.
- **Args**: `int` year, `int` month, `int` day, `int` hour, `int` minute, `int` second, `int` millisecond
- **Returns**: `Date`

```js
var d = date(2023, 1, 15, 12, 0, 0, 0);
```

### `duration(days, hours, minutes, seconds, milliseconds)`
Creates a new Duration object.
- **Args**: `int` days, `int` hours, `int` minutes, `int` seconds, `int` milliseconds
- **Returns**: `Duration`

```js
var d = duration(0, 5, 30, 0, 0); // 5 hours, 30 minutes
```

### `parseDateTime(dateString)`
Parses a string into a DateTime object.
- **Args**: `String` dateString (ISO 8601 format)
- **Returns**: `Date`

```js
var d = parseDateTime("2023-01-15T12:00:00Z");
```

## RNG Functions

### `rndDouble()`
Returns a random floating-point number between 0.0 (inclusive) and 1.0 (exclusive).
- **Returns**: `Num` (double)

```js
var r = rndDouble();
```

### `rndInt(max)`
Returns a random integer between 0 (inclusive) and max (exclusive).
- **Args**: `int` max
- **Returns**: `Num` (int)

```js
var r = rndInt(10); // 0-9
```

### `rndBool()`
Returns a random boolean value.
- **Returns**: `Bool`

```js
if (rndBool()) { ... }
```

## JSON Functions

### `jsonEncode(map)`
Encodes a Map into a JSON string. Supports basic types and DateTime (converted to ISO string).
- **Args**: `Map`
- **Returns**: `String`

```js
var jsonString = jsonEncode({"a": 1, "b": "hello"});
```

### `jsonDecode(jsonString)`
Decodes a JSON string into a Map. Attempts to parse strings as DateTime objects where possible.
- **Args**: `String`
- **Returns**: `Map`

```js
var map = jsonDecode(someStringifiedMap);
```

