/// Operation codes for the Bytecode VM.
enum OpCode {
  /// Load a constant value from the chunk's constant pool.
  /// Operand: 1 byte index into the constant pool.
  constant,

  /// Load null onto the stack.
  nil,

  /// Load true onto the stack.
  trueOp,

  /// Load false onto the stack.
  falseOp,

  /// Pop the top value from the stack.
  pop,

  /// Get a local variable.
  /// Operand: 1 byte stack slot index.
  getLocal,

  /// Set a local variable.
  /// Operand: 1 byte stack slot index.
  setLocal,

  /// Get a global variable.
  /// Operand: 1 byte index into the constant pool (variable name).
  getGlobal,

  /// Set a global variable.
  /// Operand: 1 byte index into the constant pool (variable name).
  defineGlobal,

  /// Set a global variable.
  /// Operand: 1 byte index into the constant pool (variable name).
  setGlobal,

  /// Get an upvalue (captured variable).
  /// Operand: 1 byte upvalue index.
  getUpValue,

  /// Set an upvalue (captured variable).
  /// Operand: 1 byte upvalue index.
  setUpValue,

  /// Read a property from an instance.
  /// Operand: 1 byte index into the constant pool (property name).
  getProperty,

  /// Set a property on an instance.
  /// Operand: 1 byte index into the constant pool (property name).
  setProperty,

  /// Get the superclass method.
  /// Operand: 1 byte index into the constant pool (method name).
  getSuper,

  /// Binary equality operator (==).
  equal,

  /// Binary inequality operator (!=).
  notEqual,

  /// Optimization for list.add(item).
  listAppend,

  /// Binary greater than operator (>).
  greater,

  /// Binary less than operator (<).
  less,

  /// Binary addition operator (+).
  add,

  /// Binary subtraction operator (-).
  subtract,

  /// Binary multiplication operator (*).
  multiply,

  /// Binary division operator (/).
  divide,

  /// Binary modulo operator (%).
  modulo,

  /// Unary not operator (!).
  not,

  /// Unary negation operator (-).
  negate,

  /// Bitwise AND (&).
  bitAnd,

  /// Bitwise OR (|).
  bitOr,

  /// Bitwise XOR (^).
  bitXor,

  /// Bitwise NOT (~).
  bitNot,

  /// Bitwise Shift Left (<<).
  shiftLeft,

  /// Bitwise Shift Right (>>).
  shiftRight,

  /// Print the top value of the stack.
  printOp,

  /// Output the top value of the stack to the external environment.
  /// Operand: 1 byte index into the constant pool (output name).
  outOp,

  /// Jump unconditionally.
  /// Operand: 2 byte offset.
  jumpOp,

  /// Jump if the top value of the stack is false.
  /// Operand: 2 byte offset.
  jumpIfFalse,

  /// Loop back to a previous instruction.
  /// Operand: 2 byte offset.
  loop,

  /// Call a function.
  /// Operand: 1 byte argument count.
  callOp,

  /// Invoke a method.
  /// Operand: 1 byte index into the constant pool (method name).
  /// Operand: 1 byte argument count.
  invoke,

  /// Invoke a superclass method.
  /// Operand: 1 byte index into the constant pool (method name).
  /// Operand: 1 byte argument count.
  superInvoke,

  /// Create a closure.
  /// Operand: 1 byte index into the constant pool (function prototype).
  closure,

  /// Close upvalues (used when returning from a function or scope).
  closeUpValue,

  /// Return from a function.
  returnOp,

  /// Create a class.
  /// Operand: 1 byte index into the constant pool (class name).
  classOp,

  /// Inherit from a superclass.
  inherit,

  /// Define a method in a class.
  /// Operand: 1 byte index into the constant pool (method name).
  method,

  /// Await a Future.
  awaitOp,

  /// Create a list.
  /// Operand: 1 byte element count.
  buildList,

  /// Create a map.
  /// Operand: 1 byte entry count (key-value pairs).
  buildMap,

  /// Get a value from a list or map by index/key.
  indexGet,

  /// Set a value in a list or map by index/key.
  indexSet,

  /// Type check (is).
  isOp,

  /// Increment a local variable in place (pushes nothing).
  /// Operand: 1 byte stack slot index.
  incLocal,

  /// Decrement a local variable in place (pushes nothing).
  /// Operand: 1 byte stack slot index.
  decLocal,
}
