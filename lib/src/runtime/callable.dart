abstract class Callable {
  int get arity;
  Future<Object?> call(dynamic interpreter, List<dynamic> arguments);
}
