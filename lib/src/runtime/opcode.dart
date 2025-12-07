/// Operation codes for the Bytecode VM.
enum OpCode {
  /// Load a constant value from the chunk's constant pool.
  /// Operand: 1 byte index into the constant pool.
  CONSTANT,

  /// Load null onto the stack.
  NIL,

  /// Load true onto the stack.
  TRUE,

  /// Load false onto the stack.
  FALSE,

  /// Pop the top value from the stack.
  POP,

  /// Get a local variable.
  /// Operand: 1 byte stack slot index.
  GET_LOCAL,

  /// Set a local variable.
  /// Operand: 1 byte stack slot index.
  SET_LOCAL,

  /// Get a global variable.
  /// Operand: 1 byte index into the constant pool (variable name).
  GET_GLOBAL,

  /// Set a global variable.
  /// Operand: 1 byte index into the constant pool (variable name).
  DEFINE_GLOBAL,

  /// Set a global variable.
  /// Operand: 1 byte index into the constant pool (variable name).
  SET_GLOBAL,

  /// Get an upvalue (captured variable).
  /// Operand: 1 byte upvalue index.
  GET_UPVALUE,

  /// Set an upvalue (captured variable).
  /// Operand: 1 byte upvalue index.
  SET_UPVALUE,

  /// Read a property from an instance.
  /// Operand: 1 byte index into the constant pool (property name).
  GET_PROPERTY,

  /// Set a property on an instance.
  /// Operand: 1 byte index into the constant pool (property name).
  SET_PROPERTY,

  /// Get the superclass method.
  /// Operand: 1 byte index into the constant pool (method name).
  GET_SUPER,

  /// Binary equality operator (==).
  EQUAL,

  /// Binary inequality operator (!=).
  NOT_EQUAL,

  /// Optimization for list.add(item).
  LIST_APPEND,

  /// Binary greater than operator (>).
  GREATER,

  /// Binary less than operator (<).
  LESS,

  /// Binary addition operator (+).
  ADD,

  /// Binary subtraction operator (-).
  SUBTRACT,

  /// Binary multiplication operator (*).
  MULTIPLY,

  /// Binary division operator (/).
  DIVIDE,

  /// Binary modulo operator (%).
  MODULO,

  /// Unary not operator (!).
  NOT,

  /// Unary negation operator (-).
  NEGATE,

  /// Bitwise AND (&).
  BIT_AND,

  /// Bitwise OR (|).
  BIT_OR,

  /// Bitwise XOR (^).
  BIT_XOR,

  /// Bitwise NOT (~).
  BIT_NOT,

  /// Bitwise Shift Left (<<).
  SHIFT_LEFT,

  /// Bitwise Shift Right (>>).
  SHIFT_RIGHT,

  /// Print the top value of the stack.
  PRINT,

  /// Output the top value of the stack to the external environment.
  /// Operand: 1 byte index into the constant pool (output name).
  OUT,

  /// Jump unconditionally.
  /// Operand: 2 byte offset.
  JUMP,

  /// Jump if the top value of the stack is false.
  /// Operand: 2 byte offset.
  JUMP_IF_FALSE,

  /// Loop back to a previous instruction.
  /// Operand: 2 byte offset.
  LOOP,

  /// Call a function.
  /// Operand: 1 byte argument count.
  CALL,

  /// Invoke a method.
  /// Operand: 1 byte index into the constant pool (method name).
  /// Operand: 1 byte argument count.
  INVOKE,

  /// Invoke a superclass method.
  /// Operand: 1 byte index into the constant pool (method name).
  /// Operand: 1 byte argument count.
  SUPER_INVOKE,

  /// Create a closure.
  /// Operand: 1 byte index into the constant pool (function prototype).
  CLOSURE,

  /// Close upvalues (used when returning from a function or scope).
  CLOSE_UPVALUE,

  /// Return from a function.
  RETURN,

  /// Create a class.
  /// Operand: 1 byte index into the constant pool (class name).
  CLASS,

  /// Inherit from a superclass.
  INHERIT,

  /// Define a method in a class.
  /// Operand: 1 byte index into the constant pool (method name).
  METHOD,

  /// Await a Future.
  AWAIT,

  /// Create a list.
  /// Operand: 1 byte element count.
  BUILD_LIST,

  /// Create a map.
  /// Operand: 1 byte entry count (key-value pairs).
  BUILD_MAP,

  /// Get a value from a list or map by index/key.
  INDEX_GET,

  /// Set a value in a list or map by index/key.
  INDEX_SET,

  /// Type check (is).
  IS,

  /// Increment a local variable in place (pushes nothing).
  /// Operand: 1 byte stack slot index.
  INC_LOCAL,

  /// Decrement a local variable in place (pushes nothing).
  /// Operand: 1 byte stack slot index.
  DEC_LOCAL,
}
