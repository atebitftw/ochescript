import 'dart:io';

void main(List<String> args) {
  if (args.length != 1) {
    stdout.writeln("Usage: generate_ast <output directory>");
    exit(1);
  }
  final outputDir = args[0];

  defineAst(outputDir, "Expr", <String>[
    "Binary   : Expr left, Token operation, Expr right",
    "Grouping : Expr expression",
    "Literal  : Object value",
    "Unary    : Token operation, Expr right",
    "Variable : Token name",
    "Assign   : Token name, Expr value",
    "Logical  : Expr left, Token operation, Expr right",
    "Call     : Expr callee, Token operation, List<Expr> arguments",
    "Get      : Expr object, Token name",
    "Set      : Expr object, Token name, Expr value",
    "This     : Token keyword",
    "Super    : Token keyword, Token method",
    "ListLiteral : List<Expr> elements",
    "Index    : Expr object, Token bracket, Expr index",
    "SetIndex : Expr object, Token bracket, Expr index, Expr value",
    "MapLiteral : List<Expr> keys, List<Expr> values",
    "FunctionExpr : List<Token> params, List<Stmt> body, bool isAsync",
    "Postfix  : Expr left, Token operator",
    "Await    : Expr expression",
  ]);

  defineAst(outputDir, "Stmt", <String>[
    "ForIn : Token loopVariable, Expr iterable, Stmt body",
    "Print : Expr expression",
    "Const : Expr initializer",
    "Expression : Expr expression",
    "Var : Token name, Expr initializer",
    "Block : List<Stmt> statements",
    "If : Expr condition, Stmt thenBranch, Stmt? elseBranch",
    "While : Expr condition, Stmt body",
    "ScriptFunction : Token name, List<Token> params, List<Stmt> body, bool isAsync",
    "Return : Expr? value",
    "Class : Token name, Variable? superclass, List<ScriptFunction> methods",
    "Break:",
    "Continue:",
    "For : Stmt? initializer, Expr? condition, Expr? increment, Stmt body",
    "SwitchCase : Expr? value, List<Stmt> statements",
    "Switch : Expr expression, List<SwitchCase> cases",
    "Throw : Expr value",
    "Try : Stmt tryBlock, Stmt catchBlock, Token catchVariable",
  ]);
}

void defineAst(String outputDir, String baseName, List<String> types) async {
  final buffer = StringBuffer();
  String path =
      "${outputDir.toLowerCase()}${Platform.pathSeparator}${baseName.toLowerCase()}_gen.dart";
  print("Generating $path");

  buffer.writeln("// ignore_for_file: unused_import");
  buffer.writeln("import 'package:oche_script/src/compiler/expr.dart';");
  buffer.writeln("import 'package:oche_script/src/compiler/stmt.dart';");
  buffer.writeln("import 'package:oche_script/src/compiler/token.dart';");
  if (baseName == "Stmt") {
    buffer.writeln("import 'package:oche_script/src/compiler/expr_gen.dart';");
  }
  buffer.writeln("");
  buffer.writeln("// *** GENERATED CODE.  DO NOT MODIFY ***");
  buffer.writeln("");

  defineVisitor(buffer, baseName, types);

  // The AST classes.
  for (final type in types) {
    String className = type.split(":")[0].trim();
    String fields = type.split(":")[1].trim();
    defineType(buffer, baseName, className, fields);
  }

  buffer.writeln("");

  try {
    final writer = File(path);
    writer.writeAsStringSync(buffer.toString());
  } on FileSystemException catch (e) {
    stdout.writeln("File IO error occured: $e");
  }
}

void defineVisitor(StringBuffer buffer, String baseName, List<String> types) {
  buffer.writeln("abstract class ${baseName}Visitor<R> {");

  for (final type in types) {
    final typeName = type.split(":")[0].trim();
    buffer.writeln(
      "   R visit$typeName$baseName($typeName ${baseName.toLowerCase()});",
    );
  }

  buffer.writeln("}");
  buffer.writeln("");
}

String _fieldListToParams(List<String> fields) {
  final sb = StringBuffer();

  for (final f in fields) {
    if (f.trim().isEmpty) {
      continue;
    } else {
      final name = f.split(" ")[1].trim();

      //Dart allows dangling commas in lists, including constructor arguments apparently
      sb.write("this.$name, ");
    }
  }

  return sb.toString();
}

void defineType(
  StringBuffer buffer,
  String baseName,
  String className,
  String fieldList,
) {
  buffer.writeln("class $className extends $baseName {");

  // Store parameters in fields.
  final fields = fieldList.split(", ");

  // Constructor.
  buffer.writeln(
    "   $className (${_fieldListToParams(fields)}{required super.token});",
  );

  // Fields.
  buffer.writeln("");

  // buffer.writeln("   final int line;");
  for (String field in fields) {
    if (field.trim().isEmpty) continue;
    buffer.writeln("   final $field;");
  }

  // Visitor pattern.
  buffer.writeln("");
  buffer.writeln("   @override");
  buffer.writeln("   R accept<R>(${baseName}Visitor<R> visitor) {");
  buffer.writeln("      return visitor.visit$className$baseName(this);");
  buffer.writeln("   }");
  buffer.writeln("");
  buffer.writeln("   @override");
  buffer.writeln("   String toString() => \"$className\";");

  buffer.writeln("}");
  buffer.writeln("");
}
