import 'opcode.dart';

/// A chunk of bytecode instructions and constants.
class Chunk {
  /// The bytecode instructions.
  final List<int> code = [];

  /// The constant pool.
  final List<Object?> constants = [];

  /// Line number information for each byte of code.
  /// Maps the index in [code] to the source line number.
  final List<int> lines = [];

  /// Writes a byte (opcode or operand) to the chunk.
  void write(int byte, int line) {
    code.add(byte);
    lines.add(line);
  }

  /// Writes an opcode to the chunk.
  void writeOp(OpCode op, int line) {
    write(op.index, line);
  }

  /// Adds a constant to the constant pool and returns its index.
  int addConstant(Object? value) {
    constants.add(value);
    return constants.length - 1;
  }

  /// Helper to disassemble the chunk for debugging.
  String disassemble(String name) {
    final buffer = StringBuffer();
    buffer.writeln("== $name ==");

    int offset = 0;
    while (offset < code.length) {
      offset = _disassembleInstruction(buffer, offset);
    }

    return buffer.toString();
  }

  int _disassembleInstruction(StringBuffer buffer, int offset) {
    buffer.write(offset.toString().padLeft(4, '0'));
    buffer.write(" ");

    if (offset > 0 && lines[offset] == lines[offset - 1]) {
      buffer.write("   | ");
    } else {
      buffer.write("${lines[offset].toString().padLeft(4)} ");
    }

    final instruction = code[offset];
    if (instruction >= OpCode.values.length) {
      buffer.writeln("Unknown opcode $instruction");
      return offset + 1;
    }

    final op = OpCode.values[instruction];

    switch (op) {
      case OpCode.constant:
      case OpCode.getGlobal:
      case OpCode.defineGlobal:
      case OpCode.setGlobal:
      case OpCode.getProperty:
      case OpCode.setProperty:
      case OpCode.getSuper:
      case OpCode.method:
      case OpCode.classOp:
      case OpCode.outOp:
        return _constantInstruction(buffer, op.name, offset);
      case OpCode.getLocal:
      case OpCode.setLocal:
      case OpCode.callOp:
      case OpCode.getUpValue:
      case OpCode.setUpValue:
      case OpCode.buildList:
      case OpCode.buildMap:
        return _byteInstruction(buffer, op.name, offset);
      case OpCode.jumpOp:
      case OpCode.jumpIfFalse:
      case OpCode.loop:
        return _jumpInstruction(
          buffer,
          op.name,
          offset,
          1,
        ); // Jump offsets are usually 2 bytes, but let's assume 1 for now or fix later
      case OpCode.invoke:
      case OpCode.superInvoke:
        return _invokeInstruction(buffer, op.name, offset);
      case OpCode.closure:
        // Closure is complex, treating as constant for now (prototype index)
        return _constantInstruction(buffer, op.name, offset);
      default:
        return _simpleInstruction(buffer, op.name, offset);
    }
  }

  int _simpleInstruction(StringBuffer buffer, String name, int offset) {
    buffer.writeln(name);
    return offset + 1;
  }

  int _byteInstruction(StringBuffer buffer, String name, int offset) {
    final slot = code[offset + 1];
    buffer.writeln("$name ${slot.toString().padLeft(4)}");
    return offset + 2;
  }

  int _jumpInstruction(StringBuffer buffer, String name, int offset, int sign) {
    // Assuming 2-byte jump offsets
    if (offset + 2 >= code.length) {
      buffer.writeln("$name <incomplete>");
      return offset + 1;
    }

    int jump = (code[offset + 1] << 8) | code[offset + 2];
    buffer.writeln("$name ${offset + 3 + sign * jump}");
    return offset + 3;
  }

  int _constantInstruction(StringBuffer buffer, String name, int offset) {
    final constant = code[offset + 1];
    buffer.write("$name ${constant.toString().padLeft(4)} '");
    buffer.write(constants[constant]);
    buffer.writeln("'");
    return offset + 2;
  }

  int _invokeInstruction(StringBuffer buffer, String name, int offset) {
    final constant = code[offset + 1];
    final argCount = code[offset + 2];
    buffer.write("$name ($argCount args) ${constant.toString().padLeft(4)} '");
    buffer.write(constants[constant]);
    buffer.writeln("'");
    return offset + 3;
  }
}
