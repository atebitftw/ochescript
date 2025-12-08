import 'package:oche_script/oche_script.dart';
import 'package:oche_script/src/runtime/chunk.dart';

class ExceptionHandler {
  final int catchIp;
  final int stackHeight;

  ExceptionHandler(this.catchIp, this.stackHeight);
}

class CallFrame {
  final ObjClosure closure;
  int ip = 0;
  final int slots; // Base index in stack for locals
  final List<ExceptionHandler> handlers = [];

  CallFrame(this.closure, this.slots);

  Chunk get chunk => closure.function.chunk;
}
