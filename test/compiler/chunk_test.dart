import 'package:test/test.dart';
import 'package:oche_script/src/runtime/chunk.dart';
import 'package:oche_script/src/runtime/opcode.dart';

void main() {
  group('Chunk', () {
    test('can write opcodes', () {
      final chunk = Chunk();
      chunk.writeOp(OpCode.returnOp, 123);
      expect(chunk.code, [OpCode.returnOp.index]);
      expect(chunk.lines, [123]);
    });

    test('can add constants', () {
      final chunk = Chunk();
      final index = chunk.addConstant(1.2);
      chunk.writeOp(OpCode.constant, 1);
      chunk.write(index, 1);

      expect(chunk.constants[0], 1.2);
      expect(chunk.code, [OpCode.constant.index, index]);
    });

    test('disassemble simple instruction', () {
      final chunk = Chunk();
      chunk.writeOp(OpCode.returnOp, 1);
      final debug = chunk.disassemble("test");
      expect(debug, contains("returnOp"));
      expect(debug, contains("0000")); // offset
      expect(debug, contains("   1")); // line number
    });

    test('disassemble constant instruction', () {
      final chunk = Chunk();
      final index = chunk.addConstant(42);
      chunk.writeOp(OpCode.constant, 1);
      chunk.write(index, 1);

      final debug = chunk.disassemble("test");
      expect(debug, contains("constant"));
      expect(debug, contains("42"));
    });
  });
}
