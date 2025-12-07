import 'package:oche_script/oche_script.dart' show RuntimeError;
import 'package:test/test.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/parser.dart';
import 'package:oche_script/src/compiler/compiler.dart';
import 'package:oche_script/src/runtime/chunk.dart';
import 'package:oche_script/src/runtime/opcode.dart';

void main() {
  group('BytecodeCompiler', () {
    late BytecodeCompiler compiler;

    setUp(() {
      compiler = BytecodeCompiler();
    });

    Chunk compile(String source) {
      final lexer = Lexer(source);
      final tokens = lexer.scan();
      final parser = Parser(tokens);
      final statements = parser.parse();
      return compiler.compile(statements);
    }

    test("redeclare global throws RuntimeError", () {
      expect(() => compile("var a = 10; var a = 20;"), throwsA(isA<RuntimeError>()));
    });

    test("redeclare local in same scope throws RuntimeError", () {
      expect(() => compile("{ var a = 10; var a = 20; }"), throwsA(isA<RuntimeError>()));
    });

    test("redeclare local in different scope returns normally", () {
      expect(() => compile('''{ var a = 10; { var a = 20; } }'''), returnsNormally);
    });

    test('compiles arithmetic', () {
      final chunk = compile("1 + 2;");
      // CONSTANT 1, CONSTANT 2, ADD, POP
      expect(
        chunk.code,
        containsAllInOrder([
          OpCode.constant.index,
          anything, // index of 1
          OpCode.constant.index,
          anything, // index of 2
          OpCode.add.index,
          OpCode.pop.index,
        ]),
      );
    });

    test('compiles global variables', () {
      final chunk = compile("var a = 10; print a;");
      // CONSTANT 10, DEFINE_GLOBAL 'a', GET_GLOBAL 'a', PRINT
      expect(
        chunk.code,
        containsAllInOrder([
          OpCode.constant.index,
          anything,
          OpCode.defineGlobal.index,
          anything,
          OpCode.getGlobal.index,
          anything,
          OpCode.printOp.index,
        ]),
      );
    });

    test('compiles local variables', () {
      final chunk = compile("{ var a = 10; print a; }");
      // CONSTANT 10, SET_LOCAL 0, GET_LOCAL 0, PRINT, POP (end scope)
      // Note: var declaration in block just pushes value, then we track it as local.
      // Actually, my implementation does: initializer -> accept (pushes 10).
      // Then _addLocal.
      // So it should be: CONSTANT 10, GET_LOCAL 0, PRINT, POP (local 0)

      // Wait, visitVarStmt for local:
      // initializer.accept() -> pushes 10.
      // _addLocal() -> marks stack slot 0 as 'a'.
      // No explicit SET_LOCAL needed for declaration if initializer leaves value on stack.
      // But wait, if initializer is null, we push NIL.

      // Let's check the disassembly in the test output if it fails.
      expect(
        chunk.code,
        containsAllInOrder([
          OpCode.constant.index,
          anything,
          // No DEFINE_GLOBAL or SET_LOCAL here, just value on stack
          OpCode.getLocal.index,
          1, // slot 1 (slot 0 is reserved)
          OpCode.printOp.index,
          OpCode.pop.index, // popping local 'a' at end of block
        ]),
      );
    });

    test('compiles if statement', () {
      final chunk = compile("if (true) print 1;");
      // TRUE, JUMP_IF_FALSE, offset, offset, POP, CONSTANT 1, PRINT, JUMP, offset, offset, POP
      expect(
        chunk.code,
        containsAllInOrder([
          OpCode.trueOp.index,
          OpCode.jumpIfFalse.index,
          anything,
          anything,
          OpCode.pop.index,
          OpCode.constant.index,
          anything,
          OpCode.printOp.index,
        ]),
      );
    });
  });
}
