import 'dart:async';

import 'package:oche_script/src/common.dart' show Common;
import 'package:oche_script/src/runtime/call_frame.dart';
import 'package:oche_script/src/runtime/chunk.dart';
import 'package:oche_script/src/runtime/obj.dart';
import 'package:oche_script/src/runtime/opcode.dart';
import 'package:oche_script/src/runtime/native_method.dart';
import 'package:oche_script/src/runtime/callable.dart';
import 'package:oche_script/src/runtime/runtime_error.dart';
import 'package:oche_script/src/source_mapper.dart';

/// The virtual machine that executes runtime bytecode.
class VM {
  // Stack size during runtimes rarely exceeds 8192.  We will consider this an overflow.
  // Since this is intended to be an embedded language, we will limit the stack size to 8192.
  // This should be more than enough for most use cases, and we want to protect the dart host
  // environment from a stack overflow.
  final List<Object?> _stack = List.filled(8192, null, growable: false);
  int _sp = 0;

  /// When true, the virtual machine will halt execution.
  bool halt = false;
  bool _isRunning = false;

  /// When true, the virtual machine is currently running a script.
  bool get isRunning => _isRunning;

  /// The return code of the virtual machine after a halt or script end.
  int returnCode = 0;

  final List<CallFrame> _frames = [];
  ObjUpvalue? _openUpvalues;

  // Global variables
  final Map<String, Object?> _globals = {};
  final Map<String, Object> _outState = {};

  // Callbacks
  Function(String, dynamic)? _outCallback;
  SourceMapper? sourceMapper;

  /// Register a callback for output.  Only one callback can be registered at a time.
  void registerOutCallback(Function(String, dynamic) callback) {
    if (_isRunning) {
      throw reportRuntimeError(getCurrentLine(), "Cannot register output callback while VM is running.");
    }
    _outCallback = callback;
  }

  /// Defines a native function in the global scope.
  void defineNative(String name, Function function) {
    if (_isRunning) {
      throw reportRuntimeError(getCurrentLine(), "Cannot define native function while VM is running.");
    }
    if (_globals.containsKey(name)) {
      Common.log.info("${getCurrentLine()}: Native function '$name' already defined.");
    }
    _globals[name] = ObjNative(name, function);
  }

  void defineGlobal(String name, Object? value, {bool override = false}) {
    if (_isRunning) {
      throw reportRuntimeError(getCurrentLine(), "Cannot define global variable while VM is running.");
    }

    if (!override && _globals.containsKey(name)) {
      throw reportRuntimeError(getCurrentLine(), "Global variable '$name' already defined.");
    }
    _globals[name] = value;
  }

  void _clearStack() {
    for (int i = 0; i < _stack.length; i++) {
      _stack[i] = null;
    }
  }

  /// Interprets a chunk of bytecode.
  Future<Map<String, Object>> interpret(Chunk chunk) async {
    _frames.clear();
    _clearStack();
    _sp = 0;
    _openUpvalues = null;
    _outState.clear();

    // Wrap the top-level chunk in a function and closure
    final scriptFunction = ObjFunction(chunk, name: "script");
    final scriptClosure = ObjClosure(scriptFunction, []);
    push(scriptClosure);
    _frames.add(CallFrame(scriptClosure, 0));

    try {
      await _run();
    } on RuntimeError catch (e, stack) {
      _isRunning = false;
      halt = true;
      Common.log.severe("Runtime Error: $e\n$stack");
      _outState["error"] = e.toString();
      _outState["return_code"] = returnCode > 0 ? returnCode : 1;

      return _outState;
    } catch (e, stack) {
      _isRunning = false;
      halt = true;
      Common.log.severe("Unhandled Runtime Exception: $e\n$stack");
      _outState["error"] = e.toString();
      _outState["return_code"] = returnCode > 0 ? returnCode : 1;
      return _outState;
    }

    _outState["return_code"] = returnCode;
    //_outState["max_stack"] = maxStack;
    return _outState;
  }

  RuntimeError reportRuntimeError(int line, String message) {
    if (sourceMapper != null) {
      final loc = sourceMapper!.map(line);
      return RuntimeError.withLine(loc.line, message, file: loc.file);
    }
    return RuntimeError.withLine(line, message);
  }

  Future<void> _run([int targetFrameCount = 0]) async {
    _isRunning = true;
    CallFrame frame = _frames.last;

    while (!halt && _frames.length > targetFrameCount) {
      // Fetch
      if (frame.ip >= frame.chunk.code.length) {
        // Implicit return if we run off the end
        if (_frames.length == 1) return;

        // Restore previous frame
        _frames.removeLast();
        if (_frames.length <= targetFrameCount) return;
        frame = _frames.last;
        continue;
      }

      final instruction = OpCode.values[frame.chunk.code[frame.ip++]];

      // Decode & Execute - inline for performance
      switch (instruction) {
        case OpCode.constant:
          final constantIndex = frame.chunk.code[frame.ip++];
          final constant = frame.chunk.constants[constantIndex];
          push(constant);
          break;

        case OpCode.nil:
          push(null);
          break;

        case OpCode.trueOp:
          push(true);
          break;

        case OpCode.falseOp:
          push(false);
          break;

        case OpCode.pop:
          pop();
          break;

        case OpCode.getLocal:
          final slot = frame.chunk.code[frame.ip++];
          push(_stack[frame.slots + slot]);
          break;

        case OpCode.setLocal:
          final slot = frame.chunk.code[frame.ip++];
          _stack[frame.slots + slot] = peek(0);
          break;

        case OpCode.incLocal:
          final slot = frame.chunk.code[frame.ip++];
          final val = _stack[frame.slots + slot];
          if (val is num) {
            _stack[frame.slots + slot] = val + 1;
          } else {
            throw reportRuntimeError(getCurrentLine(), "Operand must be a number.");
          }
          break;

        case OpCode.decLocal:
          final slot = frame.chunk.code[frame.ip++];
          final val = _stack[frame.slots + slot];
          if (val is num) {
            _stack[frame.slots + slot] = val - 1;
          } else {
            throw reportRuntimeError(getCurrentLine(), "Operand must be a number.");
          }
          break;

        case OpCode.getGlobal:
          final nameIndex = frame.chunk.code[frame.ip++];
          final name = frame.chunk.constants[nameIndex] as String;
          if (!_globals.containsKey(name)) {
            throw reportRuntimeError(getCurrentLine(), "Undefined variable '$name'.");
          }
          push(_globals[name]);
          break;

        case OpCode.defineGlobal:
          final nameIndex = frame.chunk.code[frame.ip++];
          final name = frame.chunk.constants[nameIndex] as String;
          _globals[name] = pop();
          break;

        case OpCode.setGlobal:
          final nameIndex = frame.chunk.code[frame.ip++];
          final name = frame.chunk.constants[nameIndex] as String;
          if (!_globals.containsKey(name)) {
            throw reportRuntimeError(getCurrentLine(), "Undefined variable '$name'.");
          }
          _globals[name] = peek(0);
          break;

        case OpCode.getUpValue:
          final slot = frame.chunk.code[frame.ip++];
          final upvalue = frame.closure.upvalues[slot];
          if (upvalue.isClosed) {
            push(upvalue.closed);
          } else {
            push(_stack[upvalue.location]);
          }
          break;

        case OpCode.setUpValue:
          final slot = frame.chunk.code[frame.ip++];
          final upvalue = frame.closure.upvalues[slot];
          if (upvalue.isClosed) {
            upvalue.closed = peek(0);
          } else {
            _stack[upvalue.location] = peek(0);
          }
          break;

        case OpCode.equal:
          final b = pop();
          final a = pop();
          push(a == b);
          break;

        case OpCode.notEqual:
          final b = pop();
          final a = pop();
          push(a != b);
          break;

        case OpCode.greater:
          final b = pop() as num;
          final a = pop() as num;
          push(a > b);
          break;

        case OpCode.less:
          final b = pop() as num;
          final a = pop() as num;
          push(a < b);
          break;

        case OpCode.add:
          final b = pop();
          final a = pop();
          if (a is num && b is num) {
            push(a + b);
          } else if (a is DateTime && b is Duration) {
            push(a.add(b));
          } else if (a is Duration && b is Duration) {
            push(a + b);
          } else if (a is String && b is String) {
            push(a + b);
          } else if (a is String) {
            push(a + b.toString());
          } else if (b is String) {
            push(a.toString() + b);
          } else if (a is List && b is List) {
            push([...a, ...b]);
          } else if (a is Map && b is Map) {
            a.addAll(b);
            push(a);
          } else {
            throw reportRuntimeError(getCurrentLine(), "ADD: Invalid operands: (${a.runtimeType}, ${b.runtimeType})");
          }
          break;

        case OpCode.subtract:
          final b = pop();
          final a = pop();
          if (a is num && b is num) {
            push(a - b);
          } else if (a is DateTime && b is DateTime) {
            push(a.difference(b));
          } else if (a is DateTime && b is Duration) {
            push(a.subtract(b));
          } else if (a is Duration && b is Duration) {
            push(a - b);
          } else {
            throw reportRuntimeError(
              getCurrentLine(),
              "SUBTRACT: Invalid operands: (${a.runtimeType}, ${b.runtimeType})",
            );
          }
          break;

        case OpCode.multiply:
          final b = pop() as num;
          final a = pop() as num;
          push(a * b);
          break;

        case OpCode.divide:
          final b = pop() as num;
          final a = pop() as num;
          push(a / b);
          break;

        case OpCode.modulo:
          final b = pop() as num;
          final a = pop() as num;
          push(a % b);
          break;

        case OpCode.not:
          push(_isFalsey(pop()));
          break;

        case OpCode.negate:
          final a = pop() as num;
          push(-a);
          break;

        case OpCode.printOp:
          print(pop());
          break;

        case OpCode.outOp:
          final nameIndex = frame.chunk.code[frame.ip++];
          final name = frame.chunk.constants[nameIndex] as String;
          final value = pop();

          if (value != null) {
            _outState[name] = value;
          }

          if (_outCallback != null) {
            _outCallback!(name, value);
          }
          break;

        case OpCode.jumpOp:
          final offset = (frame.chunk.code[frame.ip] << 8) | frame.chunk.code[frame.ip + 1];
          frame.ip += 2;
          frame.ip += offset;
          break;

        case OpCode.jumpIfFalse:
          final offset = (frame.chunk.code[frame.ip] << 8) | frame.chunk.code[frame.ip + 1];
          frame.ip += 2;
          if (_isFalsey(peek(0))) {
            frame.ip += offset;
          }
          break;

        case OpCode.loop:
          final offset = (frame.chunk.code[frame.ip] << 8) | frame.chunk.code[frame.ip + 1];
          frame.ip += 2;
          frame.ip -= offset;
          break;

        case OpCode.callOp:
          final argCount = frame.chunk.code[frame.ip++];
          await _callValue(peek(argCount), argCount);
          frame = _frames.last; // Frame might have changed
          break;

        case OpCode.invoke:
          final method = frame.chunk.constants[frame.chunk.code[frame.ip++]] as String;
          final argCount = frame.chunk.code[frame.ip++];
          await _invoke(method, argCount);
          frame = _frames.last; // Frame might have changed
          break;

        case OpCode.superInvoke:
          final method = frame.chunk.constants[frame.chunk.code[frame.ip++]] as String;
          final argCount = frame.chunk.code[frame.ip++];
          final superclass = pop() as ObjClass;
          await _invokeSuper(method, argCount, superclass);
          frame = _frames.last; // Frame might have changed
          break;

        case OpCode.listAppend:
          final item = peek(0);
          final receiver = peek(1);
          if (receiver is List) {
            receiver.add(item);
            pop(); // item
            pop(); // receiver
            push(receiver.length);
          } else {
            await _invoke("add", 1);
            frame = _frames.last; // Frame might have changed
          }
          break;

        case OpCode.closure:
          final constantIndex = frame.chunk.code[frame.ip++];
          final function = frame.chunk.constants[constantIndex] as ObjFunction;

          final upvalues = <ObjUpvalue>[];
          for (int i = 0; i < function.upvalues.length; i++) {
            final isLocal = frame.chunk.code[frame.ip++] == 1;
            final index = frame.chunk.code[frame.ip++];
            if (isLocal) {
              upvalues.add(_captureUpvalue(frame.slots + index));
            } else {
              upvalues.add(frame.closure.upvalues[index]);
            }
          }

          push(ObjClosure(function, upvalues));
          break;

        case OpCode.closeUpValue:
          _closeUpvalues(_sp - 1);
          pop();
          break;

        case OpCode.returnOp:
          final result = pop();
          _closeUpvalues(frame.slots);

          // Check if we're returning from an init method BEFORE removing the frame
          final isInit = frame.closure.function.name == "init";
          final returnSlots = frame.slots;

          _frames.removeLast();
          if (_frames.isEmpty) {
            pop(); // Pop the script closure
            return;
          }

          _sp = returnSlots; // Discard locals
          if (isInit) {
            // For init methods, return the instance (which is at slot 0)
            push(_stack[returnSlots]);
          } else {
            push(result);
          }

          if (_frames.length <= targetFrameCount) return;
          frame = _frames.last;
          break;

        case OpCode.buildList:
          final count = frame.chunk.code[frame.ip++];
          final list = <dynamic>[];
          for (int i = 0; i < count; i++) {
            list.insert(0, pop());
          }
          push(list);
          break;

        case OpCode.buildMap:
          final count = frame.chunk.code[frame.ip++];
          final map = <String, dynamic>{};
          for (int i = 0; i < count; i++) {
            final value = pop();
            final key = pop();
            map[key as String] = value;
          }
          push(map);
          break;

        case OpCode.indexGet:
          final index = pop();
          final target = pop();

          if (target is List) {
            if (index is! int) {
              throw reportRuntimeError(getCurrentLine(), "List index must be an integer.");
            }
            if (index < 0 || index >= target.length) {
              throw reportRuntimeError(getCurrentLine(), "List index out of bounds.");
            }
            push(target[index]);
          } else if (target is Map) {
            if (index is! String) {
              throw reportRuntimeError(getCurrentLine(), "Map key must be a string.");
            }
            if (!target.containsKey(index)) {
              throw reportRuntimeError(getCurrentLine(), "Map key '$index' not found.");
            }
            push(target[index]);
          } else if (target is String) {
            if (index is! int) {
              throw reportRuntimeError(getCurrentLine(), "String index must be an integer.");
            }
            if (index < 0 || index >= target.length) {
              throw reportRuntimeError(getCurrentLine(), "String index out of bounds.");
            }
            push(target[index]);
          } else {
            throw reportRuntimeError(getCurrentLine(), "Can only index lists, maps, and strings.");
          }
          break;

        case OpCode.indexSet:
          final value = pop();
          final index = pop();
          final target = pop();

          if (target is List) {
            if (index is! int) {
              throw reportRuntimeError(getCurrentLine(), "List index must be an integer.");
            }
            if (index < 0 || index >= target.length) {
              throw reportRuntimeError(getCurrentLine(), "List index out of bounds.");
            }
            target[index] = value;
          } else if (target is Map) {
            if (index is! String) {
              throw reportRuntimeError(getCurrentLine(), "Map key must be a string.");
            }
            target[index] = value;
          } else {
            throw reportRuntimeError(getCurrentLine(), "Can only set index on lists and maps.");
          }
          push(value); // Assignment expression evaluates to the assigned value
          break;

        case OpCode.classOp:
          final nameIndex = frame.chunk.code[frame.ip++];
          final name = frame.chunk.constants[nameIndex] as String;
          push(ObjClass(name));
          break;

        case OpCode.inherit:
          final superclass = peek(0);
          if (superclass is! ObjClass) {
            throw RuntimeError.withLine(getCurrentLine(), "Superclass must be a class.");
          }
          final subclass = peek(1) as ObjClass;
          subclass.superclass = superclass;
          subclass.methods.addAll(superclass.methods);
          // Don't pop superclass - it stays on stack as the "super" local value
          break;

        case OpCode.method:
          final nameIndex = frame.chunk.code[frame.ip++];
          final name = frame.chunk.constants[nameIndex] as String;
          final method = peek(0) as ObjClosure;
          // Find the class - it might be at peek(1) or peek(2) depending on whether
          // there's a superclass on the stack.
          // If we have [subclass, superclass, method], peek(1) is superclass and peek(2) is subclass.
          // We want to define the method on the subclass.
          ObjClass? klass;
          final p1 = peek(1);
          final p2 = _sp > 2 ? peek(2) : null;

          if (p2 is ObjClass && p1 is ObjClass && p2.superclass == p1) {
            klass = p2;
          } else if (p1 is ObjClass) {
            klass = p1;
          }

          if (klass == null) {
            throw RuntimeError.withLine(getCurrentLine(), "Could not find class for method definition.");
          }
          klass.methods[name] = method;
          pop(); // Pop method
          break;

        case OpCode.getProperty:
          final nameIndex = frame.chunk.code[frame.ip++];
          final name = frame.chunk.constants[nameIndex] as String;
          final receiver = peek(0);

          if (receiver is ObjInstance) {
            if (name == "fields") {
              pop();
              push(receiver.fields);
              break;
            }

            if (receiver.fields.containsKey(name)) {
              pop();
              push(receiver.fields[name]);
              break;
            }

            final method = receiver.klass.methods[name];
            if (method != null) {
              pop();
              push(ObjBoundMethod(receiver, method));
              break;
            }

            throw RuntimeError.withLine(getCurrentLine(), "Undefined property '$name'.");
          }

          final nativeMethod = _getNativeMethod(receiver, name);
          if (nativeMethod != null) {
            pop();
            push(nativeMethod);
            break;
          }

          throw RuntimeError.withLine(
            getCurrentLine(),
            "Only instances have properties. $receiver (${receiver.runtimeType})",
          );

        case OpCode.setProperty:
          final nameIndex = frame.chunk.code[frame.ip++];
          final name = frame.chunk.constants[nameIndex] as String;
          final value = pop();
          final receiver = peek(0);

          if (receiver is ObjInstance) {
            if (name == "fields") {
              throw reportRuntimeError(getCurrentLine(), "Cannot assign to reserved property 'fields'.");
            }
            receiver.fields[name] = value;
            pop();
            push(value);
            break;
          }

          throw reportRuntimeError(
            getCurrentLine(),
            "Only instances have fields. Got ${receiver.runtimeType} instead.",
          );

        case OpCode.getSuper:
          final nameIndex = frame.chunk.code[frame.ip++];
          final name = frame.chunk.constants[nameIndex] as String;
          final superValue = pop();
          if (superValue is! ObjClass) {
            throw reportRuntimeError(
              getCurrentLine(),
              "GET_SUPER expected ObjClass but got ${superValue.runtimeType}. Looking for method '$name'.",
            );
          }
          final superclass = superValue;
          final receiverValue = peek(0);
          if (receiverValue is! ObjInstance) {
            throw reportRuntimeError(
              getCurrentLine(),
              "GET_SUPER expected ObjInstance receiver but got ${receiverValue.runtimeType}.",
            );
          }
          final receiver = receiverValue;

          final method = superclass.methods[name];
          if (method == null) {
            throw reportRuntimeError(getCurrentLine(), "Undefined property '$name'.");
          }

          pop();
          push(ObjBoundMethod(receiver, method));
          break;

        case OpCode.awaitOp:
          final future = peek(0);
          if (future is Future) {
            final result = await future;
            pop();
            push(result);
          }
          break;

        case OpCode.isOp:
          final type = pop();
          final value = pop();
          if (type is String) {
            if (type == "num") {
              push(value is num);
            } else if (type == "bool") {
              push(value is bool);
            } else if (type == "string") {
              push(value is String);
            } else if (type == "list") {
              push(value is List);
            } else if (type == "map") {
              push(value is Map);
            } else if (type == "date") {
              push(value is DateTime);
            } else if (type == "duration") {
              push(value is Duration);
            } else {
              push(false);
            }
          } else if (type is ObjClass) {
            if (value is ObjInstance) {
              ObjClass? k = value.klass;
              bool found = false;
              while (k != null) {
                if (k == type) {
                  found = true;
                  break;
                }
                k = k.superclass;
              }
              push(found);
            } else {
              push(false);
            }
          } else {
            throw reportRuntimeError(getCurrentLine(), "Invalid type operand for 'is'.");
          }
          break;

        case OpCode.bitAnd:
          final b = pop();
          final a = pop();
          if (a is int && b is int) {
            push(a & b);
          } else {
            throw reportRuntimeError(getCurrentLine(), "Operands must be integers.");
          }
          break;

        case OpCode.bitOr:
          final b = pop();
          final a = pop();
          if (a is int && b is int) {
            push(a | b);
          } else {
            throw reportRuntimeError(getCurrentLine(), "Operands must be integers.");
          }
          break;

        case OpCode.bitXor:
          final b = pop();
          final a = pop();
          if (a is int && b is int) {
            push(a ^ b);
          } else {
            throw reportRuntimeError(getCurrentLine(), "Operands must be integers.");
          }
          break;

        case OpCode.bitNot:
          final a = pop();
          if (a is int) {
            push(~a);
          } else {
            throw reportRuntimeError(getCurrentLine(), "Operand must be an integer.");
          }
          break;

        case OpCode.shiftLeft:
          final b = pop();
          final a = pop();
          if (a is int && b is int) {
            push(a << b);
          } else {
            throw reportRuntimeError(getCurrentLine(), "Operands must be integers.");
          }
          break;

        case OpCode.shiftRight:
          final b = pop();
          final a = pop();
          if (a is int && b is int) {
            push(a >> b);
          } else {
            throw reportRuntimeError(getCurrentLine(), "Operands must be integers.");
          }
          break;

        // default:
        //   throw RuntimeError.withLine(_getCurrentLine(), "Unknown opcode $instruction");
      }
      _isRunning = false;
    }
  }

  Future<void> _callValue(Object? callee, int argCount) async {
    if (callee is ObjClosure) {
      if (argCount != callee.function.arity) {
        throw reportRuntimeError(getCurrentLine(), "Expected ${callee.function.arity} arguments but got $argCount.");
      }
      _frames.add(CallFrame(callee, _sp - argCount - 1));
      return;
    } else if (callee is ObjNative) {
      final args = <dynamic>[];
      for (int i = 0; i < argCount; i++) {
        args.insert(0, pop());
      }
      pop(); // Pop function

      final result = await callee.function(args);
      push(result);
      return;
    } else if (callee is Callable) {
      if (argCount != callee.arity) {
        throw reportRuntimeError(getCurrentLine(), "Expected ${callee.arity} arguments but got $argCount.");
      }
      final args = <dynamic>[];
      for (int i = 0; i < argCount; i++) {
        args.insert(0, pop());
      }
      pop(); // Pop callee

      final result = await callee.call(this, args);
      push(result);
      return;
    } else if (callee is ObjClass) {
      final instance = ObjInstance(callee);
      // Replace class on stack with instance, so it becomes slot 0 for the init method
      _stack[_sp - argCount - 1] = instance;

      if (callee.methods.containsKey("init")) {
        final initializer = callee.methods["init"]!;
        _frames.add(CallFrame(initializer, _sp - argCount - 1));
        return;
      } else if (argCount != 0) {
        throw reportRuntimeError(getCurrentLine(), "Expected 0 arguments but got $argCount.");
      }

      // No init method, instance is already on stack, just return
      return;
    } else if (callee is ObjBoundMethod) {
      // For ObjBoundMethod:
      // Stack is [BoundMethod, arg1, arg2, ...]
      // We need to replace BoundMethod with the receiver, then call the underlying method.
      // This is the same pattern as ObjClosure - don't pop args, just set up the frame.
      _stack[_sp - argCount - 1] = callee.receiver;
      _frames.add(CallFrame(callee.method, _sp - argCount - 1));
      return;
    }

    throw reportRuntimeError(getCurrentLine(), "Can only call functions and classes.");
  }

  ObjUpvalue _captureUpvalue(int local) {
    ObjUpvalue? prevUpvalue;
    ObjUpvalue? upvalue = _openUpvalues;

    while (upvalue != null && upvalue.location > local) {
      prevUpvalue = upvalue;
      upvalue = upvalue.next;
    }

    if (upvalue != null && upvalue.location == local) {
      return upvalue;
    }

    final createdUpvalue = ObjUpvalue(local);
    createdUpvalue.next = upvalue;

    if (prevUpvalue == null) {
      _openUpvalues = createdUpvalue;
    } else {
      prevUpvalue.next = createdUpvalue;
    }

    return createdUpvalue;
  }

  void _closeUpvalues(int last) {
    while (_openUpvalues != null && _openUpvalues!.location >= last) {
      final upvalue = _openUpvalues!;
      upvalue.closed = _stack[upvalue.location];
      upvalue.location = -1;
      upvalue.isClosed = true;
      _openUpvalues = upvalue.next;
    }
  }

  int maxStack = 0;
  void push(Object? value) {
    _stack[_sp++] = value;
    maxStack++;
  }

  Object? pop() {
    return _stack[--_sp];
  }

  Object? peek(int distance) {
    return _stack[_sp - 1 - distance];
  }

  bool _isFalsey(Object? value) {
    return value == null || value == false;
  }

  /// Gets the current source line number from the active frame
  int getCurrentLine() {
    if (_frames.isEmpty) return 0;
    final frame = _frames.last;
    if (frame.ip - 1 < 0 || frame.ip - 1 >= frame.chunk.lines.length) return 0;
    return frame.chunk.lines[frame.ip - 1];
  }

  NativeMethod? _getNativeMethod(Object? receiver, String name) {
    if (receiver is String) {
      if (NativeMethod.getNativeMethodsForType(NativeMethodTarget.string).containsKey(name)) {
        return NativeMethod(receiver, name);
      }
    } else if (receiver is List) {
      if (NativeMethod.getNativeMethodsForType(NativeMethodTarget.list).containsKey(name)) {
        return NativeMethod(receiver, name);
      }
    } else if (receiver is Map) {
      if (NativeMethod.getNativeMethodsForType(NativeMethodTarget.map).containsKey(name)) {
        return NativeMethod(receiver, name);
      }
    } else if (receiver is num) {
      if (NativeMethod.getNativeMethodsForType(NativeMethodTarget.number).containsKey(name)) {
        return NativeMethod(receiver, name);
      }
    } else if (receiver is bool) {
      if (NativeMethod.getNativeMethodsForType(NativeMethodTarget.boolean).containsKey(name)) {
        return NativeMethod(receiver, name);
      }
    } else if (receiver is DateTime) {
      if (NativeMethod.getNativeMethodsForType(NativeMethodTarget.date).containsKey(name)) {
        return NativeMethod(receiver, name);
      }
    } else if (receiver is Duration) {
      if (NativeMethod.getNativeMethodsForType(NativeMethodTarget.duration).containsKey(name)) {
        return NativeMethod(receiver, name);
      }
    } else if (receiver is Future) {
      print("got it");
      if (NativeMethod.getNativeMethodsForType(NativeMethodTarget.future).containsKey(name)) {
        return NativeMethod(receiver, name);
      }
    }
    return null;
  }

  /// Invokes an [ObjClosure] with the given arguments and returns the result.
  /// This method is intended for use by native methods that need to call
  /// script-defined closures (e.g., list.map, list.filter, etc.).
  ///
  /// Unlike a normal CALL opcode, this runs the closure to completion and
  /// returns the result synchronously (within the async context).
  Future<Object?> callClosure(ObjClosure closure, List<dynamic> arguments) async {
    // Validate arity
    if (arguments.length != closure.function.arity) {
      throw reportRuntimeError(
        getCurrentLine(),
        "Expected ${closure.function.arity} arguments but got ${arguments.length}.",
      );
    }

    // Remember the current frame count so we know when the closure returns
    final frameCountBefore = _frames.length;

    // Push the closure as the "callee" slot (slot 0 for the new frame)
    push(closure);

    // Push arguments onto the stack
    for (final arg in arguments) {
      push(arg);
    }

    // Create a new call frame for the closure
    _frames.add(CallFrame(closure, _sp - arguments.length - 1));

    // Run until this frame completes (frame count drops back to frameCountBefore)
    await _run(frameCountBefore);

    // The result should now be on top of the stack
    return pop();
  }

  Future<void> _invoke(String name, int argCount) async {
    final receiver = peek(argCount);

    if (receiver is ObjInstance) {
      if (receiver.fields.containsKey(name)) {
        final value = receiver.fields[name];
        _stack[_sp - argCount - 1] = value;
        await _callValue(value, argCount);
        return;
      }

      final method = receiver.klass.methods[name];
      if (method != null) {
        // Optimized call: don't create ObjBoundMethod, just call the closure
        // but set up the frame so 'this' (slot 0) is the receiver.
        // The receiver is already at peek(argCount), which becomes slot 0.
        await _callValue(method, argCount);
        return;
      }

      throw RuntimeError.withLine(getCurrentLine(), "Undefined property '$name'.");
    }

    final nativeMethod = _getNativeMethod(receiver, name);
    if (nativeMethod != null) {
      _stack[_sp - argCount - 1] = nativeMethod;
      await _callValue(nativeMethod, argCount);
      return;
    }

    throw RuntimeError.withLine(getCurrentLine(), "Only instances have methods. Name: $name, Receiver: $receiver");
  }

  Future<void> _invokeSuper(String name, int argCount, ObjClass superclass) async {
    final method = superclass.methods[name];
    if (method == null) {
      throw RuntimeError.withLine(getCurrentLine(), "Undefined property '$name'.");
    }

    // Receiver is at peek(argCount)
    // We just call the method. _callValue handles setting up the frame.
    // Since it's a super call, we are calling a method from the superclass
    // but on the same receiver.
    await _callValue(method, argCount);
  }
}
