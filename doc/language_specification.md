# OcheScript Specification

*This document is not intended to be a classical computer science language specification.  It's meant to be a practical guide of the language features and capabilities.*

OcheScript is a dynamically-typed, interpreted scripting language designed for embedding in Dart applications. It is written in Dart, and features a familiar Dart-ish syntax, first-class functions, classes with inheritance, and helpful Dart interop capabilities.

# Table Of Contents
- [Entry](#entry)
- [Comments](#comments)
- [Reserved Keywords](#reserved-keywords)
- [Supported Types](#supported-types)
  - [Table Of Supported Types](#table-of-supported-types)
  - [Reference Types](#reference-types)
  - [About Null](#about-null)
- [Variables](#variables)
- [Operators](#operators)
- [Control Flow](#control-flow)
  - [If/Else](#if-else)
  - [Switch](#switch)
  - [Loops (for, while, for-in)](#loops)
- [Functions](#functions)
- [Classes](#classes)
- [Exception Handling (try/catch)](#exception-handling)
- [Async/Await](#async--await)
- [Native Methods](#native-methods)
- [Native Functions](#native-functions)
- [Dart Interop](#dart-interop)
- [Directives](#directives)
- [Runtime Stack Size Limits](#runtime-stack-size-limits)

## Entry
[Back To Table Of Contents](#table-of-contents)

OcheScript doesn't define a canonical entry point.

Code is executed at the top-level of the script wherever it is found.  However, it is recommended to place your code in a function and call it at the top-level.

```js
// declaring the entry function
fun main(){
    print("Hello, World!");
}

// invoking the entry function
main();
```

## Comments
[Back To Table Of Contents](#table-of-contents)

OcheScript supports single-line comments.
```js
// This is a comment
var x = 1; // Comment at end of line
```

## Reserved Keywords
[Back To Table Of Contents](#table-of-contents)

The following words are reserved (case-sensitive):
*   `class`
*   `super`
*   `this`
*   `extends`
*   `var`
*   `fun`
*   `if`
*   `else`
*   `while`
*   `for`
*   `return`
*   `break`
*   `continue`
*   `true`
*   `false`
*   `print`
*   `include`
*   `switch`
*   `case`
*   `default`
*   `is`
*   `in`
*   `try`
*   `catch`
*   `throw`
*   `async`
*   `await`

These are case-sensitive and are only used for type checking (e.g. `var n = 123; print(n is Num);`)
*   `List`
*   `Map`
*   `Date`
*   `Duration`
*   `String`
*   `Num`
*   `Bool`

This frees you to use the lowercase version of (some) them as variable names.
```js
// This is valid
var list = [1, 2, 3];

// This is not valid
var List = [1, 2, 3];
```

Not reserved in the language definition sense, these words are still reserved during runtime because they are used for built-in functions:

*   `now`
*   `date`
*   `duration`
*   `parseDateTime`
*   `dart`
*   `out`
*   `wait`
*   `quit`
*   `jsonEncode`
*   `jsonDecode`
*   `rndDouble`
*   `rndInt`
*   `rndBool`


## Supported Types
[Back To Table Of Contents](#table-of-contents)

The language is dynamically typed but supports runtime type checking.

### Table Of Supported Types
| Type | Description | Example |
|------|-------------|---------|
| `Num` | Numeric values (integers and floats) | `42`, `3.14`, `0xFF` |
| `Bool` | Boolean values | `true`, `false` |
| `String` | Text strings | `"Hello"`, `"World"` |
| `List` | Ordered collection of items | `[1, 2, "a"]` |
| `Map` | Key-value pairs (keys must be strings) | `{"key": value}` |
| `Date` | Timestamp values | `now()`, `date(2022, 1, 1, 0, 0, 0, 0)` |
| `Duration` | Time span values | `now() - start` |
| `{class instance}` | User-defined classes | `var x = Dog();` |

### Reference Types
Reference types to functions and classes are also supported.  However, these are not defined as types in the language, but rather as values that can be assigned to variables.

```js
fun main(){
    print("hi");
}

// x now is a reference to the main function.
var x = main;

x();
```
### About Null

Null (nullity) is not a supported concept in OcheScript.

While it is possible to assign a "null" to a variable (see below), if you try to use that variable as a value, it will throw an error.

```js
fun returnerOfNothing(){
    print("hi");
}

// assigning from a function that returns nothing to a variable is possible, but it will throw an error when used as a value.
var x = returnerOfNothing();

// You can print it.
print(x); // null

// if you tried this: runtime error
//var y = x++;

x = "hello";

print(x); // x is safe again.
```

Alternative: Use an empty list to represent the absence of a value.
```js
fun returnerOfNothingMaybe(){
    var r = rndBool();
    if(!r){
        return [];
    }else{
        return ["hello"];
    }
}

var x = returnerOfNothingMaybe();
switch(x.isEmpty()){
    case true:
        print("x is empty");
        break;
    case false:
        print("x is not empty");
        break;
}
```

## String Interpolation
[Back To Table Of Contents](#table-of-contents)

Strings support interpolation using `$` for variables and `${}` for expressions.

```js
var name = "World";
print("Hello $name!"); // "Hello World!"

var a = 10;
var b = 20;
print("Sum: ${a + b}"); // "Sum: 30"
```

## Variables
[Back To Table Of Contents](#table-of-contents)

Variables are declared using the `var` keyword. Initialization is mandatory.

```js
var name = "Oche";
var count = 0;
```

Scopes are block-based. Variables declared inside a block `{ ... }` are not accessible outside of it.

### Coercion
Variables are fully mutable and can be reassigned to any type.

```js
var x = 123;
print(x is Num); // true
x = "Hello";
print(x is String); // true
x = true;
print(x is Bool); // true
x = {};
print(x is Map); // true
x = [];
print(x is List); // true
x = now();
print(x is Date); // true
x = Dog();
print(x is Dog); // true
// congrats, you now have a dog.
```

### Multiple Declaration In Same Scope Is Not Allowed
```js
var x = 123;
var x = 456; // error
```

### Shadowing Is Allowed
```js
var x = 123;
{
  var x = 246;
  print(x); // 246
}
print(x); // 123
```

## Operators
[Back To Table Of Contents](#table-of-contents)

### Arithmetic
- `+`
- `-`
- `*`
- `/`
- `%` (modulo)
- `++` (increment)
- `--` (decrement)

#### `+` Overloading
The `+` operator is overloaded for several types:
- `Num + Num` (addition)
- `String + String` (concatenation, prefer interpolation)
- `List + List` (concatenation)
- `Map + Map` (merge)
- `Date + Duration` (addition)
- `Duration + Duration` (addition)

#### `-` Overloading
The `-` operator is overloaded for several types:
- `Num - Num` (subtraction)
- `Date - Date` (subtraction)
- `Duration - Duration` (subtraction)

### Comparison
- `==`
- `!=`
- `<`
- `<=`
- `>`
- `>=`

### Logical
- `&&` (AND)
- `||` (OR)
- `!` (NOT)

### Bitwise
- `&` (AND)
- `|` (OR)
- `^` (XOR)
- `~` (NOT)
- `<<` (Left Shift)
- `>>` (Right Shift)

### Type Checking
The `is` operator checks if an object is of a specific type.

#### Supported Types
You must use the type name exactly as it is defined in the table below (case-sensitive).

| Type | Description |
|------|-------------|
| `Num` | Numeric values (integers and floats) |
| `Bool` | Boolean values |
| `String` | Text strings |
| `List` | Ordered collection of items |
| `Map` | Key-value pairs (keys must be strings) |
| `Date` | Timestamp values |
| `Duration` | Time span values |
| `{class}` | Class instances |

```js
var x = 123;
print(x is Num); // true
print(x is String); // false

// classes
class Animal{}
class Dog extends Animal{}
class Cat extends Animal{}
var x = Dog();
print(x is Animal); // true
print(x is Dog); // true
print(x is Cat); // false
```

## Control Flow
[Back To Table Of Contents](#table-of-contents)

### If-Else

```js
if (condition) {
  // do something
} else if (condition) {
  // do something else
} else {
  // do something else
}
```

### Switch

```js
var x = 100;

switch(x){
    case 1:
        print("x is 1");
        break;
    case 2:
        print("x is 2");
        break;
    case 100:
        print("x is 100");
        break;
    default:
        print("x is not 1 or 2 or 100");
}

switch(x) {
  case 2 * 50:
    print("x is still 100. Even when using expressions in the case statement.");
    break;
  default:
    print("x is not 100");
}

switch(x < 50){
  case true:
    print("x is less than 50.");
    break;
  default:
    print("x is not less than 50.");
}
```

### Loops

**While Loop**
```js
while (condition) {
  // loop body
}
```

**For Loop**
```js
for (var i = 0; i < 10; i++) {
  print(i);
}
```

**For-In Loop**
```js
for (var item in [1, 2, 3]) {
  print(item);
}

for (var item in "hello") {
  print(item);
}

var funcList = [
  fun(){
    print("hello");
  },
  fun(){
    print("world");
  }
];

for (var item in funcList) {
  item();
}
```

**Control Statements**
- `break`: Exits the current loop immediately.  Also used in switch statements.
- `continue`: Skips the rest of the current iteration.

## Functions
[Back To Main Table Of Contents](#table-of-contents)

### Functions Table Of Contents

- [Function Declaration Order](#function-declaration-order)
- [Named Functions](#named-functions)
- [Anonymous Functions (Lambdas)](#anonymous-functions-lambdas)
- [Nesting](#nesting)
- [Returning Functions](#returning-functions)
- [Assigning Functions To Variables](#assigning-functions-to-variables)
- [Recursion](#recursion)
- [Private Classes In Functions](#private-classes-in-functions)

Functions are first-class citizens. They can be declared named or anonymous.

### Function Declaration Order
Functions must be declared before they are invoked.

This will throw a runtime error:
```js
fun main(){
  // add is not declared yet.
    print(add(1, 2));
}

fun add(a, b) {
    return a + b;
}

main();
```

This will work:
```js
fun add(a, b) {
    return a + b;
}

fun main(){
    print(add(1, 2));
}

main();
```

### Named Functions

```js
fun add(a, b) {
  return a + b;
}
```

### Anonymous Functions (Lambdas)

```js
var multiply = fun(a, b) {
  return a * b;
};

print(multiply(2, 3)); // 6
```

### Functions can be nested inside other functions.

```js
fun outer() {
  fun inner() {
    print("inner");
  }
  inner();
}
```

### Nesting
Functions can be nested inside other functions.

```js
// f() -> num -> num -> num
fun apply(func, a, b) {
  return func(a, b);
}

var add = fun(a, b) {
  return a + b;
};

var result = apply(add, 1, 2); // 3
```

### Returning Functions

Functions can be returned from other functions.

```js
fun createAdder(a) {
  // num -> num
  fun add(b) {
    return a + b;
  }
  return add;
}

var add5 = createAdder(5);
var result = add5(2); // 7
```

### Assigning Functions To Variables

Functions can be stored in variables.

```js
var add = fun(a, b) {
  return a + b;
};

var result = add(1, 2); // 3
```

### Recursion
Functions can call themselves.

```js
fun factorial(n) {
  if (n == 0) {
    return 1;
  }
  return n * factorial(n - 1);
}

var result = factorial(5); // 120
```

### Private Classes In Functions
Functions may declare classes that are only accessible within the function.

```js
fun aWorldAwaits(){
    class IOnlyExistInMyWorld {
        init(){
            this.name = "Lonely Class";
        }

        getName(){
            return this.name;
        }
    }
    var x = IOnlyExistInMyWorld();
    print(x.getName()); // "Lonely Class"
}

var x = aWorldAwaits();
```

Unless the function wants to expose it:
```js
fun iAmFree(){
    class IOnlyExistInMyWorld {
        init(){
            this.name = "Not So Lonely Class";
        }

        getName(){
            return this.name;
        }
    }
    return IOnlyExistInMyWorld;
}

var y = iAmFree(); // y is now a reference to the class

print(y().getName()); // "Not So Lonely Class"
```

## Classes
[Back To Main Table Of Contents](#table-of-contents)

OcheScript supports object-oriented programming with classes and single inheritance.

### Classes Table Of Contents

- [Declaring](#declaring)
- [Instantiating](#instantiating)
- [Inheritance](#inheritance)
- [Constructor](#constructor)
- [The `super` Keyword](#the-super-keyword)
- [The `this` Keyword](#the-this-keyword)
- [Class References](#class-references)
- [Nested Classes](#nested-classes)
- [Class Methods](#class-methods)
- [Class Fields](#class-fields)
- [The Special `.fields` Property](#the-special-fields-property)

### Declaring
Classes are declared using the `class` keyword.

```js
class Animal {}
```

### Referencing
```js
var animalReference = Animal;

var animal = animalReference();
```

### Instantiating
Classes are instantiated using the `()` operator, which in turn calls the constructor.  

```js
var animal = Animal();
```

### Inheritance
Classes can inherit from other classes using the `extends` keyword.  OcheScript only supports single inheritance.

```js
class Animal {}

class Dog extends Animal {}

var dog = Dog();
print(dog is Dog); // true
print(dog is Animal); // true
```

### Constructor
The `init()` method is the constructor for a class.  It is called when an instance of the class is created.

```js
class Animal {
  init(animalName) {
    // properties must be initialized in the constructor
    this.name = animalName;
  }
}

var animal = Animal("Animal");
print(animal.name); // "Animal"
```

### The `super` Keyword

The `super` keyword refers to the superclass of a class.

```js
class Animal {
  init(name) {
    this.name = name;
  }

  speak() {
    print(this.name + " makes a noise.");
  }
}

class Dog extends Animal {
  init(name) {
    super.init(name);
  }

  speak() {
    print(this.name + " barks.");
  }
}

var d = Dog("Rex");
d.speak(); // Rex barks.
```

### The `this` Keyword

The `this` keyword refers to the current instance of a class.

```js
class Animal {
  init(name) {
    this.name = name;
  }

  speak() {
    print(this.name + " makes a noise.");
  }
}

var d = Animal("Rex");
d.speak(); // Rex makes a noise.
```

### Class References
Class declarations can be assigned to a variable, passed as an argument, or returned from a function.

```js
class Dog extends Animal {
  init(name) {
    this.name = name;
  }

  speak() {
    print(this.name + " barks.");
  }
};

var dogClass = Dog; // reference to the class

var d = dogClass("Rex"); // "()" instantiates the class via it's constructor

print(d is Dog); // true
d.speak(); // Rex barks.
```

### Nested Classes
You can nest a class within another class provided that the nested class is inside the `init()` constructor, or any other method within the class.  Nesting a class directly inside the class body is not allowed.

```js
class A{
  class B{} // compile-time error
}
```

Arguably confusing, but this is allowed:
```js
class Animal {
  makeADog() {
    class Dog extends Animal {
      init(dogName) {
        this.name = dogName;
      }

      speak() {
        print(this.name + " barks.");
      }
    }
    return Dog;
  }
}

var d = Animal();
var rex = d.makeADog()("Rex");
rex.speak(); // Rex barks.
```

### Class Methods
Methods are functions that are defined in a class declaration.

Methods can be called on a class instance.

Class methods do not require the `fun` keyword.  Doing so will result in a compile-time error.

```js

class Animal {
  init(name) {
    this.name = name;
  }

  // void -> String
  speak() {
    print(this.name + " makes a noise.");
  }
}

var d = Animal("Rex");
d.speak(); // Rex makes a noise.
```

### Class Fields
Fields (properties) must be declared inside the init() constructor, or as a property on a class instance.  They may also be defined dynamically on an instance.

```js
class Animal {
  init(name) {
    // name is now a default field on any instance of this class.
    this.name = name;
  }

  speak() {
    print(this.name + " makes a noise.");
  }
}

var d = Animal("Rex");
d.foo = 42; //dynamically add a field to this instance.
d.speak(); // Rex makes a noise.
print(d.foo); // 42
```

### The Special `fields` Property
Each class instance has a `fields` property that contains a reference to the fields on the instance.  This gives a lightweight mutable introspection capability on the fields of an instance.

You cannot assign to the `fields` property.
```js
var d = Animal("Rex");
d.fields = {"foo": 42}; //error
```

You can modify the properties of the `fields` map.
```js
var d = Animal("Rex");

d.fields["foo"] = 42; // equivalent to d.foo = 42;
print(d.foo); // 42
```

**Use `.fields` with caution.**  It is not recommended to modify the `fields` map directly, except for advanced use-cases.

## Async / Await
[Back To Table Of Contents](#table-of-contents)

OcheScript provides limited support for asynchronous programming.  The `async` and `await` keywords are supported.  This is primarily in place for use with Dart interop.  The `Future` type is not supported natively.

```js
async fun fetchData() {
    // calling registered dart function via interop.
    var data = await dart("dart_func", [args]);
    return data;
}
```

## Exception Handling
[Back To Table Of Contents](#table-of-contents)

OcheScript provides basic exception handling support.

### Try / Catch Examples
```js
try {
    throw 42; // runtime error
} catch (e) {
    print(e); // 42
}
```

```js
try {
    var code = 404;
    var message = "Not Found";
    throw "Error: $code - $message";
} catch (e) {
    print(e); // Error: 404 - Not Found
}
```

### Unhandled Exceptions
Unhandled errors will cause the runtime to halt.  

Since this is an embedded language, errors are **not** emitted to Dart stdout by default.  They are reported via the [Logging Package](https://pub.dev/packages/logging) at level WARNING and above.  To listen to these errors, you can use the `Logging` class from the `logging` package. This approach gives you more control over how to handle script errors that are uncaught by your script.

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


## Native Methods
[Back To Table Of Contents](#table-of-contents)

Think of these as compile-time extension methods on supported types.

```js
var x = -10;
// abs is a native method on the Num type.
print(x.abs()); // 10
```

The OcheScript API provides the capability to register additional native methods at compile time.

See the [Native Methods](https://github.com/atebitftw/ochescript/blob/main/doc/native_methods.md) document for more information.

## Native Functions
[Back To Table Of Contents](#table-of-contents)

These are standalone global functions that can be called from any script.

```js
await wait(1000); // Waits for 1 second
```

The OcheScript API provides the capability to register additional native functions at compile time.

See the [Native Functions](https://github.com/atebitftw/ochescript/blob/main/doc/native_functions.md) document for more information.

## Dart Interop
[Back To Table Of Contents](#table-of-contents)

See the [Dart Interop](https://github.com/atebitftw/ochescript/blob/main/doc/dart_interop.md) document for more information.

## Directives
[Back To Table Of Contents](#table-of-contents)

Currently, OcheScript only supports the `#include` directive.

### Include
The `#include` directive allows you to split your code into multiple files.  This is not a package manager, it is simply a compile-time preprocessor operation.

If directives are supported by your implementation, you can use them to declare other script "libraries" that you want to include with your script.

Let's say you have a script library called `utils.oche` that you want to include with your script.  You can do this by adding the following line to the top of your script:
```js
#include utils
// The contets of 'utils.oche' in the 'includes' directory or relative path are inserted here.
```

Using include directives is a compile-time preprocessor operation, and is platform specific.  OcheScript provides an interface for writing your own preprocessor based on your platform.  For example on Windows, a preprocessor might use `dart:io` to find include files in the current directory and the /include sub-directory.  A Flutter implementation might look for include files in the flutter assets bundle.

See [Windows Example](http://github.com/atebitftw/ochescript/blob/main/lib/windows_preprocessor.dart).

## Runtime Stack Size Limits
[Back To Table Of Contents](#table-of-contents)

Since the scope of this language is to live embedded inside other Dart applications, the virtual machine stack is fixed to a size of 8192 elements.  This is to prevent memory exhaustion in the host Dart environment.  If the stack overflows, the virtual machine will throw a runtime error.

Most scripts will rarely come close to this limit (most will never exceed 100).  However there are some rare scenarios that could cause a stack overflow:

1. Trying to implement a deep recursion algorithm.

2. Defining a large static list.

```js
var x = [1, 2, 3, ..., 8192]; // are you really declaring 8192 static elements in a list??
```
This will cause a stack overflow because the compiler design pushes each element of the list onto the stack before actually building the list.  Better to define the list dynamically (e.g. `var x = []; for (var i = 0; i < 10000; i++) x.add(i);`) as this only pushes one element onto the stack at a time.