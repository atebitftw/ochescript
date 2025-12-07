import 'package:oche_script/src/runtime/chunk.dart';

abstract class Obj {}

class ObjFunction extends Obj {
  final Chunk chunk;
  final String? name;
  final int arity;
  final List<String> upvalues = []; // Names of upvalues for debugging/compiler

  ObjFunction(this.chunk, {this.name, this.arity = 0});

  @override
  String toString() => "<fn ${name ?? 'script'}>";
}

class ObjNative extends Obj {
  final Function function;
  final String name;

  ObjNative(this.name, this.function);

  @override
  String toString() => "<native fn $name>";
}

class ObjUpvalue extends Obj {
  int location; // Stack index (if open) or -1 (if closed)
  Object? closed; // The value if closed
  final int slot; // Original stack slot index (for debugging)
  bool isClosed = false;
  ObjUpvalue? next; // For the open upvalues list

  ObjUpvalue(this.slot) : location = slot;

  @override
  String toString() => "upvalue";
}

/// Defines a closure object, which is used by the VM at runtime to
/// execute a function with its enclosing environment.
class ObjClosure extends Obj {
  final ObjFunction function;
  final List<ObjUpvalue> upvalues;

  ObjClosure(this.function, this.upvalues);

  @override
  String toString() => function.toString();
}

class ObjClass extends Obj {
  final String name;
  ObjClass? superclass;
  final Map<String, ObjClosure> methods = {};

  ObjClass(this.name, {this.superclass});

  @override
  String toString() => name;
}

class ObjInstance extends Obj {
  final ObjClass klass;
  final Map<String, Object?> fields = {};

  ObjInstance(this.klass);

  @override
  String toString() => "${klass.name} instance";
}

class ObjBoundMethod extends Obj {
  final Object? receiver;
  final ObjClosure method;

  ObjBoundMethod(this.receiver, this.method);

  @override
  String toString() => method.toString();
}
