class Stack<T> {
  final _stack = <T>[];

  /// Adds an element to the top of the stack.
  void push(T value) {
    _stack.add(value);
  }

  /// Removes and returns the last element of the stack.
  T pop() {
    return _stack.removeLast();
  }

  /// Returns the last element of the stack without removing it.
  T peek() {
    return _stack.last;
  }

  /// Removes all elements from the stack.
  void clear() {
    _stack.clear();
  }

  T operator [](int index) => _stack[index];

  void operator []=(int index, T value) => _stack[index] = value;

  List<T> get rawStack => _stack;

  int get length => _stack.length;

  bool get isEmpty => length == 0;

  bool get isNotEmpty => length > 0;

  @override
  String toString() => _stack.toString();
}
