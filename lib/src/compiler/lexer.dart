import 'package:oche_script/src/compiler/token.dart';
import 'package:oche_script/src/compiler/token_type.dart';

class Lexer {
  final String _source;
  final List<Token> _tokens = <Token>[];
  static const _keywords = <String, TokenType>{
    "else": TokenType.ELSE,
    "false": TokenType.FALSE,
    "true": TokenType.TRUE,
    "for": TokenType.FOR,
    "fun": TokenType.FUN,
    "if": TokenType.IF,
    "return": TokenType.RETURN,
    "var": TokenType.VAR,
    "while": TokenType.WHILE,
    "continue": TokenType.CONTINUE,
    "break": TokenType.BREAK,
    "print": TokenType.PRINT,
    // "out": TokenType.OUT,
    // "dart": TokenType.DART,
    "class": TokenType.CLASS,
    "this": TokenType.THIS,
    "super": TokenType.SUPER,
    "extends": TokenType.EXTENDS,
    "switch": TokenType.SWITCH,
    "case": TokenType.CASE,
    "default": TokenType.DEFAULT,
    "is": TokenType.IS,
    // ensure the parser doesn't recognize these and
    // the scanner won't treat them as identifiers.
    "include": TokenType.DISALLOWED,
    "Num": TokenType.NUMBER,
    "Bool": TokenType.BOOL,
    "List": TokenType.LIST,
    "Map": TokenType.MAP,
    "Date": TokenType.DATE,
    "Duration": TokenType.DURATION,
    "String": TokenType.STRING,
    "async": TokenType.ASYNC,
    "await": TokenType.AWAIT,
    "in": TokenType.IN,
    "try": TokenType.TRY,
    "catch": TokenType.CATCH,
    "throw": TokenType.THROW,
  };

  int _start = 0;
  int _current = 0;
  int _line = 1;

  // Interpolation state
  int _braceDepth = 0;
  final List<int> _interpolationStack = [];

  Lexer(this._source);

  /// Peforms the scan and tokenization of the script.
  ///
  /// Returns a [List<Token>] of tokens.
  List<Token> scan() {
    while (!_isAtEnd()) {
      // We are at the beginning of the next lexeme.
      _start = _current;
      _scanToken();
    }
    _tokens.add(Token(TokenType.EOF, "", _line));
    return _tokens;
  }

  bool _isAtEnd() => _current >= _source.length;

  String _advance() {
    _current++;
    return _source[_current - 1];
  }

  void _addToken(TokenType type, {Object? literal}) {
    var lexeme = _source.substring(_start, _current);

    // removes the quotes from the string if it's a standard string scan
    if (type == TokenType.STRING) {
      if (lexeme.startsWith('"') && lexeme.endsWith('"')) {
        lexeme = lexeme.substring(1, lexeme.length - 1);
      }
    }

    _tokens.add(Token(type, lexeme, _line, literal: literal));
  }

  void _addSyntheticToken(TokenType type, String lexeme, Object? literal) {
    _tokens.add(Token(type, lexeme, _line, literal: literal));
  }

  String _peek() {
    if (_isAtEnd()) return '0';
    return _source[_current];
  }

  String _peekNext() {
    if (_current + 1 >= _source.length) return '0';
    return _source[_current + 1];
  }

  bool _match(String expected) {
    if (_isAtEnd()) return false;
    if (_source[_current] != expected) return false;

    _current++;
    return true;
  }

  void _string({bool isResuming = false}) {
    bool isInterpolated = isResuming;
    StringBuffer buffer = StringBuffer();

    // We are inside the string content (opening quote consumed by caller or we are resuming).

    while (!_isAtEnd()) {
      String c = _peek();

      if (c == '"') {
        _advance(); // Consume closing quote
        String text = buffer.toString();

        if (isInterpolated) {
          if (text.isEmpty) {
            // Optimization: If the buffer is empty, it means we ended directly after
            // a variable or expression which emitted a trailing PLUS.
            // We can remove that PLUS to avoid a trailing empty string or invalid syntax.
            if (_tokens.isNotEmpty && _tokens.last.type == TokenType.PLUS) {
              _tokens.removeLast();
            }
          } else {
            // Use unquoted text for lexeme to match standard STRING token behavior
            _addSyntheticToken(TokenType.STRING, text, text);
          }
          _addSyntheticToken(TokenType.RIGHT_PAREN, ")", null);
        } else {
          // Use unquoted text for lexeme here as well
          _addSyntheticToken(TokenType.STRING, text, text);
        }
        return;
      }

      if (c == '\n') {
        _line++;
        _advance();
        buffer.write(c);
        continue;
      }

      if (c == '\\') {
        // Escape sequence
        _advance(); // consume backslash
        if (_isAtEnd()) {
          _reportError(line: _line, message: "Unterminated string escape.");
          return;
        }
        String unescaped = _advance();
        switch (unescaped) {
          case 'n':
            buffer.write('\n');
            break;
          case 'r':
            buffer.write('\r');
            break;
          case 't':
            buffer.write('\t');
            break;
          case '"':
            buffer.write('"');
            break;
          case '\\':
            buffer.write('\\');
            break;
          case '\$':
            buffer.write('\$');
            break;
          default:
            buffer.write('\\');
            buffer.write(unescaped);
            break;
        }
        continue;
      }

      if (c == '\$') {
        _advance(); // consume $

        if (!isInterpolated) {
          _addSyntheticToken(TokenType.LEFT_PAREN, "(", null);
          isInterpolated = true;
        }

        // Emit the buffered string part
        String text = buffer.toString();
        // Use unquoted text for lexeme to match standard STRING token behavior
        _addSyntheticToken(TokenType.STRING, text, text);
        buffer.clear();

        // Emit PLUS
        _addSyntheticToken(TokenType.PLUS, "+", null);

        if (_peek() == '{') {
          _advance(); // consume {

          // Expression interpolation: ${ ... }
          _addSyntheticToken(TokenType.LEFT_PAREN, "(", null);

          _braceDepth++;
          _interpolationStack.add(_braceDepth);

          return; // Return to main scan loop
        } else {
          // Variable interpolation: $var
          if (!_isAlpha(_peek())) {
            _reportError(line: _line, message: "Expect identifier after \$.");
            return;
          }

          int idStart = _current;
          while (_isAlphaNumeric(_peek())) {
            _advance();
          }
          String idName = _source.substring(idStart, _current);
          _addSyntheticToken(TokenType.IDENTIFIER, idName, idName);

          // Emit PLUS for the next part
          _addSyntheticToken(TokenType.PLUS, "+", null);

          continue;
        }
      }

      buffer.write(_advance());
    }

    _reportError(line: _line, message: "Unterminated string.");
  }

  bool _isAlpha(String c, {bool allowUnderscore = true}) {
    if (c.isEmpty || c.length > 1) {
      return false;
    }

    final cua = c.codeUnitAt(0);
    const cuaa = 97;
    const cuaz = 122;
    const cuaA = 65;
    const cuaZ = 90;
    const cua_ = 95;

    return ((cua >= cuaa && cua <= cuaz) ||
        (cua >= cuaA && cua <= cuaZ) ||
        (allowUnderscore && cua == cua_));
  }

  bool _isAlphaNumeric(String c, {bool allowAlphaUnderscore = true}) {
    return _isAlpha(c, allowUnderscore: allowAlphaUnderscore) || _isDigit(c);
  }

  void _hexNumber() {
    while (_isAlphaNumeric(_peek(), allowAlphaUnderscore: false)) {
      _advance();
    }

    String value = _source.substring(_start, _current);

    _addToken(
      TokenType.NUMBER,
      literal: int.parse(value.replaceFirst("0x", ""), radix: 16),
    );
  }

  void _number() {
    if (_peek().toLowerCase() == 'x') {
      _advance();
      // hexidecimal number
      _hexNumber();
      return;
    }

    while (_isDigit(_peek())) {
      _advance();
    }

    if (_peek() == '.' && _isDigit(_peekNext())) {
      _advance();

      while (!_isAtEnd() && _isDigit(_peek())) {
        _advance();
      }
    }

    _addToken(
      TokenType.NUMBER,
      literal: num.parse(_source.substring(_start, _current)),
    );
  }

  bool _isDigit(String c) {
    if (c.isEmpty || c.length > 1) {
      return false;
    }

    final digit = int.tryParse(c);

    if (digit == null) return false;
    return digit >= 0 && digit <= 9;
  }

  void _identifier() {
    while (!_isAtEnd() && _isAlphaNumeric(_peek())) {
      _advance();
    }

    final text = _source.substring(_start, _current);
    if (!_keywords.containsKey(text)) {
      _addToken(TokenType.IDENTIFIER, literal: text);
      if (text.length > 64) {
        _reportError(
          line: _line,
          token: _tokens.last,
          message: "Identifier exceeds max length of 64.",
        );
      }
    } else {
      //keywords
      _addToken(_keywords[text]!);
    }
  }

  void _comment() {
    while (_peek() != '\n' && !_isAtEnd()) {
      _advance();
    }
  }

  void _scanToken() {
    final c = _advance();
    switch (c) {
      case ' ':
      case '\r':
      case '\t':
        break;
      case '\n':
        _line++;
        break;
      case '%':
        _addToken(TokenType.PERCENT);
        break;
      case '(':
        _addToken(TokenType.LEFT_PAREN);
        break;
      case ')':
        _addToken(TokenType.RIGHT_PAREN);
        break;
      case '{':
        _braceDepth++;
        _addToken(TokenType.LEFT_BRACE);
        break;
      case '}':
        if (_interpolationStack.isNotEmpty &&
            _braceDepth == _interpolationStack.last) {
          _interpolationStack.removeLast();
          _braceDepth--;

          _addSyntheticToken(TokenType.RIGHT_PAREN, ")", null);
          _addSyntheticToken(TokenType.PLUS, "+", null);

          _string(isResuming: true);
        } else {
          _braceDepth--;
          _addToken(TokenType.RIGHT_BRACE);
        }
        break;
      case '[':
        _addToken(TokenType.LEFT_BRACKET);
        break;
      case ']':
        _addToken(TokenType.RIGHT_BRACKET);
        break;
      case ',':
        _addToken(TokenType.COMMA);
        break;
      case '-':
        if (_match('-')) {
          _addToken(TokenType.DEC);
        } else {
          _addToken(TokenType.MINUS);
        }
        break;
      case '+':
        if (_match('+')) {
          _addToken(TokenType.INC);
        } else {
          _addToken(TokenType.PLUS);
        }
        break;
      case '~':
        _addToken(TokenType.BITNOT);
        break;
      case '*':
        _addToken(TokenType.STAR);
        break;
      case ';':
        _addToken(TokenType.SEMICOLON);
        break;
      case ':':
        _addToken(TokenType.COLON);
        break;
      case '?':
        _addToken(TokenType.QUESTION);
        break;
      case '|':
        if (_match('|')) {
          _addToken(TokenType.OR);
        } else {
          _addToken(TokenType.BITOR);
        }
        break;
      case '&':
        if (_match('&')) {
          _addToken(TokenType.AND);
        } else {
          _addToken(TokenType.AMP);
        }
        break;
      case '#':
        _comment();
        break;
      case '/':
        if (_match('/')) {
          _comment();
        } else {
          _addToken(TokenType.SLASH);
        }
        break;
      case '.':
        _addToken(TokenType.DOT);
        break;
      case '!':
        _addToken(_match('=') ? TokenType.BANG_EQUAL : TokenType.BANG);
        break;
      case '=':
        _addToken(_match('=') ? TokenType.EQUAL_EQUAL : TokenType.EQUAL);
        break;
      case '^':
        _addToken(TokenType.BITXOR);
        break;
      case '<':
        if (_match('=')) {
          _addToken(TokenType.LESS_EQUAL);
        } else if (_match('<')) {
          _addToken(TokenType.BITSHIFTLEFT);
        } else {
          _addToken(TokenType.LESS);
        }
        break;
      case '>':
        if (_match('=')) {
          _addToken(TokenType.GREATER_EQUAL);
        } else if (_match('>')) {
          _addToken(TokenType.BITSHIFTRIGHT);
        } else {
          _addToken(TokenType.GREATER);
        }
        break;
      case '"':
        _string();
        break;
      default:
        if (_isDigit(c)) {
          _number();
        } else if (_isAlpha(c)) {
          _identifier();
        } else {
          _reportError(line: _line, message: "Unexpected character.");
        }
        break;
    }
  }

  void _reportError({int line = 1, Token? token, String message = ""}) {
    _addToken(
      TokenType.ERROR,
      literal: "[line: $line] Error at token $token. $message.",
    );
  }
}
