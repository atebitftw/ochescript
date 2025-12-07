# OcheScript Language Overview

OcheScript is a dynamically-typed, interpreted scripting language designed for embedding in Dart applications. It is written in Dart, and features a familiar C-style-ish syntax, first-class functions, classes with inheritance, and helpful Dart interop capabilities.

## Comments
OcheScript supports single-line comments.
```js
// This is a comment
var x = 1; // Comment at end of line
```

## Reserved Keywords
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


## Data Types
The language is dynamically typed but supports runtime type checking.

| Type | Description | Example |
|------|-------------|---------|
| `Num` | Numeric values (integers and floats) | `42`, `3.14`, `0xFF` |
| `Bool` | Boolean values | `true`, `false` |
| `String` | Text strings | `"Hello"`, `"World"` |
| `List` | Ordered collection of items | `[1, 2, "a"]` |
| `Map` | Key-value pairs (keys must be strings) | `{"key": value}` |
| `Date` | Timestamp values | `now()`, `date(2022, 1, 1, 0, 0, 0, 0)` |
| `Duration` | Time span values | `now() - start` |
| `{class instance}` | User-defined classes |  |

### Null (nullity) is not a supported concept in OcheScript.
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

Strings support interpolation using `$` for variables and `${}` for expressions.

```js
var name = "World";
print("Hello $name!"); // "Hello World!"

var a = 10;
var b = 20;
print("Sum: ${a + b}"); // "Sum: 30"
```

## Variables

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

### Arithmetic
`+`, `-`, `*`, `/`, `%` (modulo), `++` (increment), `--` (decrement).
Note: `+` is also used for string concatenation.

### Comparison
`==`, `!=`, `<`, `<=`, `>`, `>=`.

### Logical
`&&` (AND), `||` (OR), `!` (NOT).

### Bitwise
`&` (AND), `|` (OR), `^` (XOR), `~` (NOT), `<<` (Left Shift), `>>` (Right Shift).

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
- `break`: Exits the current loop immediately.
- `continue`: Skips the rest of the current iteration.

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

## Functions

Functions are first-class citizens. They can be declared named or anonymous.

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

### Functions can be passed as arguments to other functions.

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

### Functions can be returned from other functions.

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

### Functions can be stored in variables.

```js
var add = fun(a, b) {
  return a + b;
};

var result = add(1, 2); // 3
```

### Functions support recursion.

```js
fun factorial(n) {
  if (n == 0) {
    return 1;
  }
  return n * factorial(n - 1);
}

var result = factorial(5); // 120
```

### Functions can contain private classes.
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

### But you can expose them if you want to.
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
OcheScript supports object-oriented programming with classes and single inheritance.

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

- `init()`: Constructor method.
- `this`: Refers to the current instance.
- `super`: Refers to the superclass.

### Classes are... first class.
Class declarations can be assigned to a variable, passed as an argument, or returned from a function.

```js
var dogClass = class Dog extends Animal {
  init(name) {
    this.name = name;
  }

  speak() {
    print(this.name + " barks.");
  }
};

var d = dogClass("Rex");
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

### Class Fields
Fields must be declared inside the init() constructor, or as a property on a class instance.

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
OcheScript provides limited support for asynchronous programming.  The `async` and `await` keywords are supported.  This is primarily in place for use with Dart interop.  The `Future` type is not supported natively.

```js
async fun fetchData() {
    // calling registered dart function via interop.
    var data = await dart("dart_func", [args]);
    return data;
}
```

## Directives
Currently, OcheScript only supports the `#include` directive.

### Include
The `#include` directive allows you to split your code into multiple files.  This is not a package manager, it is simply a compile-time preprocessor operation.

```js
#include utils
// The contets of 'utils.oche' in the 'includes' directory or relative path are inserted here.
```

Using include directives is a compile-time preprocessor operation, and is platform specific.  OcheScript provides an interface for writing your own preprocessor based on your platform.  For example on Windows, a preprocessor might use `dart:io` to find include files in the current directory and the /include sub-directory.  A Flutter implementation might look for include files in the flutter assets bundle.

See [Windows Example](http://github.com/atebitftw/ochescript/blob/main/lib/windows_preprocessor.dart).

## Native Methods (Compile-Time Capability)
Think of these as compile-time extension methods on supported types.

```js
var x = -10;
// abs is a native method on the Num type.
print(x.abs()); // 10
```

The vm provides the capability to register additional native methods at compile time.

See the [Native Methods](https://github.com/atebitftw/ochescript/blob/main/doc/native_methods.md) document for more information.

## Native Functions
These are standalone global functions that can be called from any script.

```js
await wait(1000); // Waits for 1 second
```

The vm provides the capability to register additional native functions at compile time.

See the [Native Functions](https://github.com/atebitftw/ochescript/blob/main/doc/native_functions.md) document for more information.

## The `out` Statement
The `out` statement is used to export values from the script to the host application's state. It is similar to `print`, but instead of writing to stdout, it writes to a keyed output map.

```js
var result = 42;
out("result", result);
```

On the host side, this can be accessed via the `CompileAndRun` return value or the `outCallback`.
