import 'package:oche_script/src/common.dart';
import 'package:oche_script/src/compiler/expr.dart';
import 'package:oche_script/src/compiler/expr_gen.dart';
import 'package:oche_script/src/compiler/parse_error.dart';
import 'package:oche_script/src/compiler/stmt.dart';
import 'package:oche_script/src/compiler/stmt_gen.dart';
import 'package:oche_script/src/compiler/token.dart';
import 'package:oche_script/src/compiler/token_type.dart';

class Parser {
  final List<Token> _tokens;
  List<Stmt> statements = [];

  Parser(this._tokens);
  bool hadError = false;

  int _current = 0;

  List<Stmt> parse() {
    while (!_isAtEnd()) {
      try {
        statements.add(_declaration());
      } on ParseError catch (pe) {
        Common.log.severe(pe);
        hadError = true;
        _synchronize();
      }
    }
    return statements;
  }

  Stmt _declaration() {
    if (_match([TokenType.VAR])) {
      return _varDeclaration();
    }
    return _statement();
  }

  Stmt _varDeclaration() {
    Token name = _consume(TokenType.IDENTIFIER, "Expect variable name.")!;
    _consume(TokenType.EQUAL, "Expect '=' after variable name.");
    Expr initializer = _expression();
    _consume(TokenType.SEMICOLON, "Expect ';' after variable expression.");
    return Var(name, initializer, token: name);
  }

  Stmt _statement() {
    if (_match([TokenType.CLASS])) {
      return _classDeclaration();
    }
    if (_match([TokenType.BREAK])) {
      return _breakStatement();
    }
    if (_match([TokenType.CONTINUE])) {
      return _continueStatement();
    }
    if (_match([TokenType.RETURN])) {
      return _returnStatement();
    }
    if (_match([TokenType.FUN])) {
      return _function("function");
    }
    if (_match([TokenType.ASYNC])) {
      if (_match([TokenType.FUN])) {
        return _function("function", isAsync: true);
      }
      _errorAt(_peek(), "Expect 'fun' after 'async'.");
    }
    if (_match([TokenType.FOR])) {
      return _forStatement();
    }
    if (_match([TokenType.IF])) {
      return _ifStatement();
    }
    if (_match([TokenType.WHILE])) {
      return _whileStatement();
    }
    if (_match([TokenType.PRINT])) {
      return _printStatement();
    }
    if (_match([TokenType.OUT])) {
      return _outStatement();
    }
    if (_match([TokenType.SWITCH])) {
      return _switchStatement();
    }

    if (_match([TokenType.LEFT_BRACE])) {
      return Block(_block(), token: _previous());
    }
    return _expressionStatement();
  }

  Stmt _outStatement() {
    _consume(TokenType.LEFT_PAREN, "Expect '(' after 'out'.");
    Token name = _consume(TokenType.STRING, "Expect string name.")!;
    _consume(TokenType.COMMA, "Expect ',' after string name.");
    Expr value = _expression();
    _consume(TokenType.RIGHT_PAREN, "Expect ')' after 'out'.");
    _consume(TokenType.SEMICOLON, "Expect ';' after 'out'.");
    return Out(name.lexeme, value, token: name);
  }

  Stmt _classDeclaration() {
    Token name = _consume(TokenType.IDENTIFIER, "Expect class name.")!;

    Variable? superclass;
    if (_match([TokenType.EXTENDS])) {
      superclass = Variable(
        _consume(TokenType.IDENTIFIER, "Expect superclass name.")!,
        token: _previous(),
      );
    }
    _consume(TokenType.LEFT_BRACE, "Expect '{' after class name.");
    List<ScriptFunction> methods = [];
    while (!_check(TokenType.RIGHT_BRACE) && !_isAtEnd()) {
      methods.add(_function("method") as ScriptFunction);
    }
    _consume(TokenType.RIGHT_BRACE, "Expect '}' after class body.");
    return Class(name, superclass, methods, token: name);
  }

  Stmt _returnStatement() {
    Token keyword = _previous();
    Expr? value;
    if (!_check(TokenType.SEMICOLON)) {
      value = _expression();
    }
    _consume(TokenType.SEMICOLON, "Expect ';' after return value.");
    return Return(value, token: keyword);
  }

  Stmt _breakStatement() {
    Token keyword = _previous();
    _consume(TokenType.SEMICOLON, "Expect ';' after 'break'.");
    return Break(token: keyword);
  }

  Stmt _continueStatement() {
    Token keyword = _previous();
    _consume(TokenType.SEMICOLON, "Expect ';' after 'continue'.");
    return Continue(token: keyword);
  }

  Stmt _function(String kind, {bool isAsync = false}) {
    Token name = _consume(TokenType.IDENTIFIER, "Expect $kind name.")!;
    _consume(TokenType.LEFT_PAREN, "Expect '(' after $kind name.");
    List<Token> params = [];
    if (!_check(TokenType.RIGHT_PAREN)) {
      do {
        params.add(_consume(TokenType.IDENTIFIER, "Expect parameter name.")!);
      } while (_match([TokenType.COMMA]));
    }
    _consume(TokenType.RIGHT_PAREN, "Expect ')' after parameters.");
    if (_match([TokenType.ASYNC])) {
      isAsync = true;
    }
    _consume(TokenType.LEFT_BRACE, "Expect '{' after function body.");
    List<Stmt> body = _block();
    return ScriptFunction(name, params, body, isAsync, token: name);
  }

  Expr _functionExpression({bool isAsync = false}) {
    Token keyword = _previous();
    _consume(TokenType.LEFT_PAREN, "Expect '(' after 'fun'.");
    List<Token> params = [];
    if (!_check(TokenType.RIGHT_PAREN)) {
      do {
        params.add(_consume(TokenType.IDENTIFIER, "Expect parameter name.")!);
      } while (_match([TokenType.COMMA]));
    }
    _consume(TokenType.RIGHT_PAREN, "Expect ')' after parameters.");
    if (_match([TokenType.ASYNC])) {
      isAsync = true;
    }
    _consume(TokenType.LEFT_BRACE, "Expect '{' after function body.");
    List<Stmt> body = _block();
    return FunctionExpr(params, body, isAsync, token: keyword);
  }

  Stmt _forStatement() {
    _consume(TokenType.LEFT_PAREN, "Expect '(' after 'for'.");

    // Check for 'for (var name in ...)'
    if (_check(TokenType.VAR)) {
      if (_peekNext().type == TokenType.IDENTIFIER) {
        _advance();

        Token name = _consume(TokenType.IDENTIFIER, "Expect variable name.")!;

        if (_match([TokenType.IN])) {
          Expr iterable = _expression();
          _consume(TokenType.RIGHT_PAREN, "Expect ')' after loop iterable.");
          Stmt body = _statement();
          return ForIn(name, iterable, body, token: _previous());
        }

        _consume(TokenType.EQUAL, "Expect '=' after variable name.");
        Expr initializer = _expression();
        _consume(TokenType.SEMICOLON, "Expect ';' after variable expression.");
        Stmt varStmt = Var(name, initializer, token: name);

        return _finishForLoop(varStmt);
      }
    }

    Stmt? initializer;
    if (_match([TokenType.SEMICOLON])) {
      initializer = null;
    } else if (_match([TokenType.VAR])) {
      initializer = _varDeclaration();
    } else {
      initializer = _expressionStatement();
    }

    return _finishForLoop(initializer);
  }

  Stmt _finishForLoop(Stmt? initializer) {
    Expr? condition;
    if (!_check(TokenType.SEMICOLON)) {
      condition = _expression();
    }
    _consume(TokenType.SEMICOLON, "Expect ';' after loop condition.");

    Expr? increment;
    if (!_check(TokenType.RIGHT_PAREN)) {
      increment = _expression();
    }
    _consume(TokenType.RIGHT_PAREN, "Expect ')' after loop increment.");

    Stmt body = _statement();

    return For(initializer, condition, increment, body, token: _previous());
  }

  Stmt _whileStatement() {
    _consume(TokenType.LEFT_PAREN, "Expect '(' after 'while'.");
    final condition = _expression();
    _consume(TokenType.RIGHT_PAREN, "Expect ')' after 'while'.");
    final body = _statement();
    return While(condition, body, token: _previous());
  }

  Stmt _ifStatement() {
    _consume(TokenType.LEFT_PAREN, "Expect '(' after 'if'.");
    final condition = _expression();
    _consume(TokenType.RIGHT_PAREN, "Expect ')' after 'if'.");

    final thenBranch = _statement();
    final elseBranch = _match([TokenType.ELSE]) ? _statement() : null;

    return If(condition, thenBranch, elseBranch, token: _previous());
  }

  Stmt _switchStatement() {
    Token switchKeyword = _previous();
    _consume(TokenType.LEFT_PAREN, "Expect '(' after 'switch'.");
    final expression = _expression();
    _consume(TokenType.RIGHT_PAREN, "Expect ')' after switch expression.");
    _consume(TokenType.LEFT_BRACE, "Expect '{' after switch expression.");

    List<SwitchCase> cases = [];

    while (!_check(TokenType.RIGHT_BRACE) && !_isAtEnd()) {
      Expr? value;
      Token? caseToken;

      if (_match([TokenType.CASE])) {
        caseToken = _previous();
        value = _expression();
      } else if (_match([TokenType.DEFAULT])) {
        caseToken = _previous();
        value = null;
      } else {
        _errorAt(_peek(), "Expect 'case' or 'default' inside switch.");
      }

      _consume(TokenType.COLON, "Expect ':' after case value.");

      List<Stmt> statements = [];
      while (!_check(TokenType.CASE) &&
          !_check(TokenType.DEFAULT) &&
          !_check(TokenType.RIGHT_BRACE) &&
          !_isAtEnd()) {
        statements.add(_declaration());
      }
      cases.add(SwitchCase(value, statements, token: caseToken!));
    }

    _consume(TokenType.RIGHT_BRACE, "Expect '}' after switch body.");
    return Switch(expression, cases, token: switchKeyword);
  }

  List<Stmt> _block() {
    List<Stmt> statements = [];
    while (!_check(TokenType.RIGHT_BRACE) && !_isAtEnd()) {
      statements.add(_declaration());
    }
    _consume(TokenType.RIGHT_BRACE, "Expect '}' after block.");
    return statements;
  }

  Stmt _printStatement() {
    Expr value = _expression();
    _consume(TokenType.SEMICOLON, "Expect ';' after value.");
    return Print(value, token: _previous());
  }

  Stmt _expressionStatement() {
    Expr value = _expression();
    _consume(TokenType.SEMICOLON, "Expect ';' after value.");
    return Expression(value, token: _previous());
  }

  Expr _expression() {
    return _assignment();
  }

  Expr _assignment() {
    Expr expr = _or();

    if (_match([TokenType.EQUAL])) {
      Token equals = _previous();
      Expr value = _assignment();

      if (expr is Variable) {
        final name = expr.name;
        return Assign(name, value, token: _previous());
      } else if (expr is Get) {
        final get = expr;
        return Set(get.object, get.name, value, token: _previous());
      } else if (expr is Index) {
        return SetIndex(
          expr.object,
          expr.bracket,
          expr.index,
          value,
          token: _previous(),
        );
      }
      _errorAt(equals, "Invalid assignment target.");
    }
    return expr;
  }

  Expr _or() {
    Expr expr = _and();

    while (_match([TokenType.OR])) {
      Token operator = _previous();
      Expr right = _and();
      expr = Logical(expr, operator, right, token: _previous());
    }
    return expr;
  }

  Expr _and() {
    Expr expr = _bitwiseOr();

    while (_match([TokenType.AND])) {
      Token operator = _previous();
      Expr right = _bitwiseOr();
      expr = Logical(expr, operator, right, token: _previous());
    }
    return expr;
  }

  Expr _bitwiseOr() {
    Expr expr = _bitwiseXor();

    while (_match([TokenType.BITOR])) {
      Token operator = _previous();
      Expr right = _bitwiseXor();
      expr = Binary(expr, operator, right, token: _previous());
    }
    return expr;
  }

  Expr _bitwiseXor() {
    Expr expr = _bitwiseAnd();

    while (_match([TokenType.BITXOR])) {
      Token operator = _previous();
      Expr right = _bitwiseAnd();
      expr = Binary(expr, operator, right, token: _previous());
    }
    return expr;
  }

  Expr _bitwiseAnd() {
    Expr expr = _equality();

    while (_match([TokenType.AMP])) {
      Token operator = _previous();
      Expr right = _equality();
      expr = Binary(expr, operator, right, token: _previous());
    }
    return expr;
  }

  Expr _equality() {
    Expr expr = _comparison();

    while (_match([TokenType.BANG_EQUAL, TokenType.EQUAL_EQUAL])) {
      Token operator = _previous();
      Expr right = _comparison();
      expr = Binary(expr, operator, right, token: _previous());
    }
    return expr;
  }

  Expr _comparison() {
    Expr expr = _shift();

    while (_match([
      TokenType.GREATER,
      TokenType.GREATER_EQUAL,
      TokenType.LESS,
      TokenType.LESS_EQUAL,
      TokenType.IS,
    ])) {
      Token operator = _previous();
      Expr right;
      if (operator.type == TokenType.IS) {
        if (_match([TokenType.NUMBER])) {
          right = Literal("num", token: _previous());
        } else if (_match([TokenType.BOOL])) {
          right = Literal("bool", token: _previous());
        } else if (_match([TokenType.LIST])) {
          right = Literal("list", token: _previous());
        } else if (_match([TokenType.MAP])) {
          right = Literal("map", token: _previous());
        } else if (_match([TokenType.DATE])) {
          right = Literal("date", token: _previous());
        } else if (_match([TokenType.DURATION])) {
          right = Literal("duration", token: _previous());
        } else if (_match([TokenType.STRING])) {
          right = Literal("string", token: _previous());
        } else if (_match([TokenType.IDENTIFIER])) {
          right = Variable(_previous(), token: _previous());
        } else {
          throw ParseError(_peek(), message: "Expect type name after 'is'.");
        }
      } else {
        right = _shift();
      }
      expr = Binary(expr, operator, right, token: _previous());
    }
    return expr;
  }

  Expr _shift() {
    Expr expr = _term();

    while (_match([TokenType.BITSHIFTLEFT, TokenType.BITSHIFTRIGHT])) {
      Token operator = _previous();
      Expr right = _term();
      expr = Binary(expr, operator, right, token: _previous());
    }
    return expr;
  }

  Expr _term() {
    Expr expr = _factor();

    while (_match([TokenType.MINUS, TokenType.PLUS, TokenType.PERCENT])) {
      Token operator = _previous();
      Expr right = _factor();
      expr = Binary(expr, operator, right, token: _previous());
    }
    return expr;
  }

  Expr _factor() {
    Expr expr = _unary();

    while (_match([TokenType.SLASH, TokenType.STAR, TokenType.PERCENT])) {
      Token operator = _previous();
      Expr right = _unary();
      expr = Binary(expr, operator, right, token: _previous());
    }
    return expr;
  }

  Expr _unary() {
    if (_match([
      TokenType.BANG,
      TokenType.INC,
      TokenType.DEC,
      TokenType.BITNOT,
    ])) {
      Token operator = _previous();
      Expr right = _unary();
      return Unary(operator, right, token: _previous());
    }

    if (_check(TokenType.MINUS)) {
      if (_peekNext().type != TokenType.NUMBER) {
        _advance();
        Token operator = _previous();
        Expr right = _unary();
        return Unary(operator, right, token: _previous());
      }
    }

    if (_match([TokenType.AWAIT])) {
      Token operator = _previous();
      Expr right = _unary();
      return Await(right, token: operator);
    }

    return _call();
  }

  Expr _call() {
    Expr expr = _primary();
    while (true) {
      if (_match([TokenType.LEFT_PAREN])) {
        expr = _finishCall(expr);
      } else if (_match([TokenType.DOT])) {
        Token name = _consume(
          TokenType.IDENTIFIER,
          "Expect property name after '.'.",
        )!;
        expr = Get(expr, name, token: _previous());
      } else if (_match([TokenType.LEFT_BRACKET])) {
        Token bracket = _previous();
        Expr index = _expression();
        _consume(TokenType.RIGHT_BRACKET, "Expect ']' after index.");
        expr = Index(expr, bracket, index, token: _previous());
      } else if (_match([TokenType.INC, TokenType.DEC])) {
        Token operator = _previous();
        expr = Postfix(expr, operator, token: _previous());
      } else {
        break;
      }
    }
    return expr;
  }

  Expr _finishCall(Expr callee) {
    List<Expr> arguments = [];
    if (!_check(TokenType.RIGHT_PAREN)) {
      do {
        if (arguments.length >= Common.maxFunctionArity) {
          _errorAt(_peek(), "Too many arguments.");
        }
        arguments.add(_expression());
      } while (_match([TokenType.COMMA]));
    }
    Token paren = _consume(
      TokenType.RIGHT_PAREN,
      "Expect ')' after arguments.",
    )!;
    return Call(callee, paren, arguments, token: _previous());
  }

  Expr _primary() {
    if (_check(TokenType.MINUS) && _peekNext().type == TokenType.NUMBER) {
      _advance();
      Token operator = _previous();
      Expr right = _primary();
      return Unary(operator, right, token: operator);
    }

    if (_match([TokenType.FALSE])) {
      return Literal(false, token: _previous());
    }
    if (_match([TokenType.TRUE])) {
      return Literal(true, token: _previous());
    }

    if (_match([TokenType.LEFT_PAREN])) {
      Expr expr = _expression();
      _consume(TokenType.RIGHT_PAREN, "Expect ')' after expression.");
      return Grouping(expr, token: _previous());
    }

    if (_match([TokenType.NUMBER, TokenType.STRING])) {
      return Literal(_previous().literal!, token: _previous());
    }

    if (_match([TokenType.LEFT_BRACKET])) {
      List<Expr> elements = [];
      if (!_check(TokenType.RIGHT_BRACKET)) {
        do {
          elements.add(_expression());
        } while (_match([TokenType.COMMA]));
      }
      _consume(TokenType.RIGHT_BRACKET, "Expect ']' after list elements.");
      return ListLiteral(elements, token: _previous());
    }

    if (_match([TokenType.LEFT_BRACE])) {
      List<Expr> keys = [];
      List<Expr> values = [];
      if (!_check(TokenType.RIGHT_BRACE)) {
        do {
          keys.add(_expression());
          _consume(TokenType.COLON, "Expect ':' after map key.");
          values.add(_expression());
        } while (_match([TokenType.COMMA]));
      }
      _consume(TokenType.RIGHT_BRACE, "Expect '}' after map entries.");
      return MapLiteral(keys, values, token: _previous());
    }

    if (_match([TokenType.SUPER])) {
      Token keyword = _previous();
      _consume(TokenType.DOT, "Expect '.' after 'super'.");
      Token method = _consume(
        TokenType.IDENTIFIER,
        "Expect superclass method name.",
      )!;
      return Super(keyword, method, token: _previous());
    }

    if (_match([TokenType.THIS])) {
      return This(_previous(), token: _previous());
    }

    if (_match([TokenType.FUN])) {
      return _functionExpression();
    }

    if (_match([TokenType.ASYNC])) {
      if (_match([TokenType.FUN])) {
        return _functionExpression(isAsync: true);
      }
      _errorAt(_peek(), "Expect 'fun' after 'async'.");
    }

    if (_match([TokenType.IDENTIFIER])) {
      return Variable(_previous(), token: _previous());
    }

    _errorAt(_tokens[_current], "Expect expression.");
    return Literal(-1, token: _previous());
  }

  Token? _consume(TokenType type, String message) {
    if (_check(type)) return _advance();

    _errorAt(_peek(), message);
    return null;
  }

  bool _match(List<TokenType> types) {
    for (final type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  bool _check(TokenType type) {
    if (_isAtEnd()) return false;
    return _peek().type == type;
  }

  bool _isAtEnd() => _peek().type == TokenType.EOF;

  Token _peek() => _tokens[_current];

  Token _peekNext() {
    if (_current + 1 >= _tokens.length) return _tokens.last;
    return _tokens[_current + 1];
  }

  Token _previous() => _tokens[_current - 1];

  Token _advance() {
    if (!_isAtEnd()) {
      _current++;
    }
    return _previous();
  }

  void _errorAt(Token token, String message) {
    hadError = true;
    throw ParseError(token, message: message);
  }

  void _synchronize() {
    _advance();
    while (!_isAtEnd()) {
      if (_previous().type == TokenType.SEMICOLON) {
        return;
      }
      switch (_peek().type) {
        case TokenType.CLASS:
        case TokenType.FUN:
        case TokenType.VAR:
        case TokenType.FOR:
        case TokenType.IF:
        case TokenType.WHILE:
        case TokenType.PRINT:
        case TokenType.OUT:
        case TokenType.SWITCH:
        case TokenType.RETURN:
        case TokenType.BREAK:
        case TokenType.CONTINUE:
        case TokenType.ASYNC:
          return;
        default:
          _advance();
      }
    }
  }
}
