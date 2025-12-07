import 'dart:async';
import 'package:oche_script/src/runtime/callable.dart';
import 'package:oche_script/src/runtime/runtime_error.dart';
import 'package:oche_script/src/runtime/vm.dart';

class NativeMethod implements Callable {
  static final _stringRegistry = <String, NativeMethodDefinition<String, Object>>{};
  static final _listRegistry = <String, NativeMethodDefinition<List<Object>, Object>>{};
  static final _mapRegistry = <String, NativeMethodDefinition<Map<String, Object>, Object>>{};
  static final _numRegistry = <String, NativeMethodDefinition<num, Object>>{};
  static final _boolRegistry = <String, NativeMethodDefinition<bool, Object>>{};
  static final _dateRegistry = <String, NativeMethodDefinition<DateTime, Object>>{};
  static final _durationRegistry = <String, NativeMethodDefinition<Duration, Object>>{};
  static final _futureRegistry = <String, NativeMethodDefinition<Future<Object>, Object>>{};

  static Map<String, NativeMethodDefinition> getNativeMethodsForType(NativeMethodTarget target) {
    switch (target) {
      case NativeMethodTarget.string:
        return _stringRegistry;
      case NativeMethodTarget.list:
        return _listRegistry;
      case NativeMethodTarget.map:
        return _mapRegistry;
      case NativeMethodTarget.number:
        return _numRegistry;
      case NativeMethodTarget.boolean:
        return _boolRegistry;
      case NativeMethodTarget.date:
        return _dateRegistry;
      case NativeMethodTarget.duration:
        return _durationRegistry;
      case NativeMethodTarget.future:
        return _futureRegistry;
    }
  }

  /// Registers a native method to the global registry.
  static void registerNativeMethod<T extends Object, R extends Object>(NativeMethodDefinition<T, R> definition) {
    switch (definition.targetType) {
      case NativeMethodTarget.string:
        _stringRegistry[definition.methodName] = definition as NativeMethodDefinition<String, R>;
        break;
      case NativeMethodTarget.list:
        _listRegistry[definition.methodName] = definition as NativeMethodDefinition<List<Object>, R>;
        break;
      case NativeMethodTarget.map:
        _mapRegistry[definition.methodName] = definition as NativeMethodDefinition<Map<String, Object>, R>;
        break;
      case NativeMethodTarget.number:
        _numRegistry[definition.methodName] = definition as NativeMethodDefinition<num, R>;
        break;
      case NativeMethodTarget.boolean:
        _boolRegistry[definition.methodName] = definition as NativeMethodDefinition<bool, R>;
        break;
      case NativeMethodTarget.date:
        _dateRegistry[definition.methodName] = definition as NativeMethodDefinition<DateTime, R>;
        break;
      case NativeMethodTarget.duration:
        _durationRegistry[definition.methodName] = definition as NativeMethodDefinition<Duration, R>;
        break;
      case NativeMethodTarget.future:
        _futureRegistry[definition.methodName] = definition as NativeMethodDefinition<Future<Object>, R>;
        break;
    }
  }

  final Object target;
  final String methodName;

  NativeMethod(this.target, this.methodName);

  @override
  int get arity {
    // ... (implementation same as before) ...
    try {
      if (target is String) {
        return _stringRegistry[methodName]!.arity;
      }

      if (target is List) {
        return _listRegistry[methodName]!.arity;
      }

      if (target is Map) {
        return _mapRegistry[methodName]!.arity;
      }

      if (target is num) {
        return _numRegistry[methodName]!.arity;
      }

      if (target is bool) {
        return _boolRegistry[methodName]!.arity;
      }

      if (target is DateTime) {
        return _dateRegistry[methodName]!.arity;
      }

      if (target is Duration) {
        return _durationRegistry[methodName]!.arity;
      }

      if (target is Future) {
        return _futureRegistry[methodName]!.arity;
      }
    } catch (e) {
      throw RuntimeError(
        "NativeMethod -> Error while getting arity of method $methodName on $target. Is it registered?",
      );
    }
    return 0;
  }

  @override
  Future<Object?> call(dynamic interpreter, List<dynamic> arguments) async {
    if (target is num) {
      return await _numMethods(target as num, interpreter, arguments);
    }

    if (target is String) {
      return await _stringMethods(target as String, interpreter, arguments);
    }

    if (target is List) {
      return await _listMethods((target as List).cast<Object>(), interpreter, arguments);
    }

    if (target is Map) {
      return await _mapMethods((target as Map).cast<String, Object>(), interpreter, arguments);
    }

    if (target is bool) {
      return await _boolMethods(target as bool, interpreter, arguments);
    }

    if (target is DateTime) {
      return await _dateMethods(target as DateTime, interpreter, arguments);
    }

    if (target is Duration) {
      return await _durationMethods(target as Duration, interpreter, arguments);
    }

    if (target is Future<Object>) {
      return await _futureMethods(target as Future<Object>, interpreter, arguments);
    }

    throw RuntimeError("NativeMethod -> Unable to find method $methodName on $target");
  }

  @override
  String toString() => "<native method $methodName>";

  FutureOr<Object> _futureMethods(Future<Object> target, dynamic interpreter, List<dynamic> arguments) {
    if (_futureRegistry.containsKey(methodName)) {
      return _futureRegistry[methodName]!.function(target, interpreter, arguments);
    } else {
      throw RuntimeError("NativeMethod -> Unknown method $methodName on $target");
    }
  }

  FutureOr<Object> _boolMethods(bool target, dynamic interpreter, List<dynamic> arguments) {
    if (_boolRegistry.containsKey(methodName)) {
      return _boolRegistry[methodName]!.function(target, interpreter, arguments);
    } else {
      throw RuntimeError("NativeMethod -> Unknown method $methodName on $target");
    }
  }

  FutureOr<Object> _dateMethods(DateTime target, dynamic interpreter, List<dynamic> arguments) {
    if (_dateRegistry.containsKey(methodName)) {
      return _dateRegistry[methodName]!.function(target, interpreter, arguments);
    } else {
      throw RuntimeError("NativeMethod -> Unknown method $methodName on $target");
    }
  }

  FutureOr<Object> _durationMethods(Duration target, dynamic interpreter, List<dynamic> arguments) {
    if (_durationRegistry.containsKey(methodName)) {
      return _durationRegistry[methodName]!.function(target, interpreter, arguments);
    } else {
      throw RuntimeError("NativeMethod -> Unknown method $methodName on $target");
    }
  }

  FutureOr<Object> _numMethods(num target, dynamic interpreter, List<dynamic> arguments) {
    if (_numRegistry.containsKey(methodName)) {
      return _numRegistry[methodName]!.function(target, interpreter, arguments);
    } else {
      throw RuntimeError("NativeMethod -> Unknown method $methodName on $target");
    }
  }

  FutureOr<Object> _mapMethods(Map<String, Object> target, dynamic interpreter, List<dynamic> arguments) {
    if (_mapRegistry.containsKey(methodName)) {
      return _mapRegistry[methodName]!.function(target, interpreter, arguments);
    } else {
      throw RuntimeError("NativeMethod -> Unknown method $methodName on $target");
    }
  }

  FutureOr<Object?> _listMethods(List<Object> target, dynamic interpreter, List<dynamic> arguments) {
    if (_listRegistry.containsKey(methodName)) {
      return _listRegistry[methodName]!.function(target, interpreter, arguments);
    } else {
      throw RuntimeError("NativeMethod -> Unknown method $methodName on $target");
    }
  }

  FutureOr<Object?> _stringMethods(String target, dynamic interpreter, List<dynamic> arguments) {
    if (_stringRegistry.containsKey(methodName)) {
      return _stringRegistry[methodName]!.function(target, interpreter, arguments);
    } else {
      throw RuntimeError("NativeMethod -> Unknown method $methodName on $target");
    }
  }
}

/// Defines the signature of a native method function.
typedef NativeMethodFunction<T extends Object, R extends Object> =
    FutureOr<R> Function(T target, VM vm, List<dynamic> arguments);

/// Enumerates the types of objects that can have native methods registered.
enum NativeMethodTarget { string, number, list, map, boolean, date, duration, future }

/// Defines a native method that can be registered with the VM.
class NativeMethodDefinition<T extends Object, R extends Object> {
  final String methodName;
  final int arity;
  final NativeMethodFunction<T, R> function;
  final NativeMethodTarget targetType;

  NativeMethodDefinition({
    required this.targetType,
    required this.methodName,
    required this.arity,
    required this.function,
  });
}

/// Registers a native method with the runtime.
void registerNativeMethod(NativeMethodDefinition definition) {
  NativeMethod.registerNativeMethod(definition);
}
