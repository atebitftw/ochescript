import 'package:oche_script/src/compiler/token.dart';

class Local {
  final Token? name;
  int depth = -1;
  Local(this.name, this.depth);

  @override
  String toString() => "${name!.lexeme}, depth: $depth";
}

// for debugger
class LocalRef {
  final String name;
  final int offset;
  LocalRef(this.name, this.offset);

  @override
  String toString() => "$name, offset: $offset";
}
