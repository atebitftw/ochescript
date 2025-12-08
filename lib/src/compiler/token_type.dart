// ignore_for_file: constant_identifier_names

enum TokenType {
  // Single-character tokens.
  LEFT_PAREN,
  RIGHT_PAREN,
  LEFT_BRACE,
  RIGHT_BRACE,
  LEFT_BRACKET,
  RIGHT_BRACKET,
  COMMA,
  COLON,
  DOT,
  MINUS,
  PLUS,
  SEMICOLON,
  SLASH,
  STAR,
  AMP, // prefix: address of variable. infix: bitwise AND. && = Logical AND.
  PERCENT, // % operator for inline mod binary operation
  INC, // prefix/postfix ++
  DEC, // prefix/postfix ++
  BITOR, // |
  BITXOR, // ^
  BITSHIFTLEFT, // <<
  BITSHIFTRIGHT, // >>
  BITNOT, // ~
  // One or two character tokens.
  BANG,
  BANG_EQUAL,
  EQUAL,
  EQUAL_EQUAL,
  GREATER,
  GREATER_EQUAL,
  LESS,
  LESS_EQUAL,

  // Literals.
  IDENTIFIER,
  STRING,
  NUMBER,
  LIST,
  MAP,
  DATE,
  DURATION,
  BOOL,

  // Keywords.
  SUPER,
  EXTENDS,
  THIS,
  FUN,
  CLASS,
  AND,
  ELSE,
  FALSE,
  FOR,
  IF,
  OR,
  PRINT,
  OUT,
  RETURN,
  TRUE,
  VAR,
  WHILE,
  CONTINUE,
  BREAK,
  SWITCH,
  CASE,
  DEFAULT,
  IS,
  ASYNC,
  AWAIT,
  IN,
  TRY,
  CATCH,
  THROW,

  ERROR,
  EOF,
  NOP,
  INCLUDE,
  DISALLOWED,
}
