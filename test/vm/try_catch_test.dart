import 'package:test/test.dart';
import 'package:oche_script/src/compiler/compiler.dart';
import 'package:oche_script/src/compiler/lexer.dart';
import 'package:oche_script/src/compiler/parser.dart';
import 'package:oche_script/src/runtime/vm.dart';

void main() {
  group('Try/Catch', () {
    test('Basic catch', () async {
      final script = '''
        var result = "none";
        try {
          throw "oops";
          result = "failed";
        } catch (e) {
          result = e;
        }
        out("result", result);
      ''';

      final vm = VM();
      final state = await vm.interpret(BytecodeCompiler().compile(Parser(Lexer(script).scan()).parse()));

      expect(state['return_code'], 0);
      expect(state['result'], "oops");
    });

    test('Nested catch', () async {
      final script = '''
        var inner = "none";
        var outer = "none";
        try {
          try {
            throw "inner error";
          } catch (e) {
            inner = e;
            throw "outer error";
          }
        } catch (e) {
          outer = e;
        }
        out("inner", inner);
        out("outer", outer);
      ''';

      final vm = VM();
      final state = await vm.interpret(BytecodeCompiler().compile(Parser(Lexer(script).scan()).parse()));

      expect(state['return_code'], 0);
      expect(state['inner'], "inner error");
      expect(state['outer'], "outer error");
    });

    test('Unwinding stack functions', () async {
      final script = '''
        fun boom() {
          throw "boom";
        }
        
        fun wrapper() {
          boom();
        }

        var result = "none";
        try {
          wrapper();
        } catch (e) {
          result = e;
        }
        out("result", result);
      ''';

      final vm = VM();
      final state = await vm.interpret(BytecodeCompiler().compile(Parser(Lexer(script).scan()).parse()));

      expect(state['return_code'], 0);
      expect(state['result'], "boom");
    });

    test('Local variable cleanup', () async {
      final script = '''
         var outer = "outer";
         try {
           var inner = "inner";
           throw "error";
         } catch (e) {
           out("result", outer);
           // inner should be inaccessible here, but we can't test compile error easily here.
           // implicit verification: if stack wasn't reset, local variables might be messed up.
         }
      ''';

      final vm = VM();
      final state = await vm.interpret(BytecodeCompiler().compile(Parser(Lexer(script).scan()).parse()));

      expect(state['return_code'], 0);
      expect(state['result'], "outer");
    });

    test('Unhandled exception halts VM', () async {
      final script = '''
           throw "crash";
        ''';

      final vm = VM();
      final state = await vm.interpret(BytecodeCompiler().compile(Parser(Lexer(script).scan()).parse()));

      expect(state['return_code'], 1);
      expect(state['error'], contains("Unhandled exception: crash"));
    });
    test('Loop interaction - continue', () async {
      final script = '''
        var result = "";
        for (var i = 0; i < 3; i++) {
          try {
            if (i == 1) throw "skip";
            result = result + i;
          } catch (e) {
            result = result + "C";
            continue;
          }
        }
        out("result", result);
      ''';

      final vm = VM();
      final state = await vm.interpret(BytecodeCompiler().compile(Parser(Lexer(script).scan()).parse()));

      expect(state['return_code'], 0);
      expect(state['result'], "0C2");
    });

    test('Loop interaction - break', () async {
      final script = '''
        var result = "";
        for (var i = 0; i < 3; i++) {
          try {
             if (i == 1) throw "stop";
             result = result + i;
          } catch (e) {
             result = result + "B";
             break;
          }
        }
        out("result", result);
      ''';

      final vm = VM();
      final state = await vm.interpret(BytecodeCompiler().compile(Parser(Lexer(script).scan()).parse()));

      expect(state['return_code'], 0);
      expect(state['result'], "0B");
    });

    test('Closure interaction - caught inside closure', () async {
      final script = '''
          fun execute(callback) {
             callback();
          }
          
          var result = "none";
          execute(fun() {
             try {
                throw "caught";
             } catch (e) {
                result = e;
             }
          });
          out("result", result);
       ''';

      final vm = VM();
      final state = await vm.interpret(BytecodeCompiler().compile(Parser(Lexer(script).scan()).parse()));

      expect(state['return_code'], 0);
      expect(state['result'], "caught");
    });

    test('Closure interaction - thrown from closure, caught outside', () async {
      final script = '''
          fun execute(callback) {
             callback();
          }
          
          var result = "none";
          try {
             execute(fun() {
                throw "escaped";
             });
          } catch (e) {
             result = e;
          }
          out("result", result);
       ''';

      final vm = VM();
      final state = await vm.interpret(BytecodeCompiler().compile(Parser(Lexer(script).scan()).parse()));

      expect(state['return_code'], 0);
      expect(state['result'], "escaped");
    });
    test('Throwing non-string works', () async {
      final script = '''
          try {
             throw 123;
          } catch (e) {
             out("caught", e);
          }
       ''';

      final vm = VM();
      final state = await vm.interpret(BytecodeCompiler().compile(Parser(Lexer(script).scan()).parse()));

      expect(state['return_code'], 0);
      expect(state['caught'], 123);
    });
    test('Throwing interpolated string', () async {
      final script = r'''
          var code = 404;
          var message = "Not Found";
          try {
             throw "Error: $code - $message";
          } catch (e) {
             out("caught", e);
          }
       ''';

      final vm = VM();
      final state = await vm.interpret(BytecodeCompiler().compile(Parser(Lexer(script).scan()).parse()));

      expect(state['return_code'], 0);
      expect(state['caught'], "Error: 404 - Not Found");
    });
  });
}
