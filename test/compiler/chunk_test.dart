import 'package:test/test.dart';
import 'package:oche_script/src/runtime/chunk.dart';
import 'package:oche_script/src/runtime/opcode.dart';

void main() {
  group('Chunk', () {
    test('can write opcodes', () {
      final chunk = Chunk();
      chunk.writeOp(OpCode.RETURN, 123);
      expect(chunk.code, [OpCode.RETURN.index]);
      expect(chunk.lines, [123]);
    });

    test('can add constants', () {
      final chunk = Chunk();
      final index = chunk.addConstant(1.2);
      chunk.writeOp(OpCode.CONSTANT, 1);
      chunk.write(index, 1);

      expect(chunk.constants[0], 1.2);
      expect(chunk.code, [OpCode.CONSTANT.index, index]);
    });

    test('disassemble simple instruction', () {
      final chunk = Chunk();
      chunk.writeOp(OpCode.RETURN, 1);
      final debug = chunk.disassemble("test");
      expect(debug, contains("RETURN"));
      expect(debug, contains("0000")); // offset
      expect(debug, contains("   1")); // line number
    });

    test('disassemble constant instruction', () {
      final chunk = Chunk();
      final index = chunk.addConstant(42);
      chunk.writeOp(OpCode.CONSTANT, 1);
      chunk.write(index, 1);

      final debug = chunk.disassemble("test");
      expect(debug, contains("CONSTANT"));
      expect(debug, contains("42"));
    });
  });
}
