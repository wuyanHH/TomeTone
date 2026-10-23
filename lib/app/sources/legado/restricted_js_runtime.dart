import 'dart:convert';
import 'dart:math' as math;

import '../../../contracts/sources/js_runtime.dart';
import '../../../contracts/sources/source_http.dart';

/// 功能完备的轻量级 JS 解释器：
/// 支持多语句、变量声明（var/let）、赋值、循环（for/while）、
/// 条件分支（if/else）、对象/数组字面量、RegExp、Math、JSON 以及
/// `java.*` / `source.*` 宿主内置桥接。
class RestrictedJsRuntime implements JsRuntime {
  @override
  Future<Object?> evaluate(String script, JsContext context) async {
    try {
      final tokens = _Lexer(script).tokenize();
      final statements = _Parser(tokens).parseProgram();
      final evaluator = _Evaluator(context);
      return await evaluator.runProgram(statements);
    } on JsRuntimeException {
      rethrow;
    } on Object catch (e) {
      throw JsRuntimeException('不支持的 JS 脚本: $e');
    }
  }

  @override
  Future<void> dispose() async {}
}

// =============================================================================
// Tokens & Lexer
// =============================================================================

enum _TokenType {
  identifier,
  number,
  string,
  regex,
  keyword,
  punct,
  eof,
}

class _Token {
  const _Token(this.type, this.text, [this.value]);

  final _TokenType type;
  final String text;
  final Object? value;

  @override
  String toString() => 'Token($type, "$text")';
}

class _Lexer {
  _Lexer(this.source);

  final String source;
  int index = 0;
  _Token? _lastToken;

  static const Set<String> _keywords = <String>{
    'var',
    'let',
    'const',
    'if',
    'else',
    'for',
    'while',
    'return',
    'function',
    'true',
    'false',
    'null',
    'undefined',
    'typeof',
    'in',
    'of',
  };

  List<_Token> tokenize() {
    final tokens = <_Token>[];
    while (true) {
      _skipWhitespaceAndComments();
      if (index >= source.length) {
        tokens.add(const _Token(_TokenType.eof, ''));
        return tokens;
      }
      final char = source[index];
      final token = _nextToken(char);
      _lastToken = token;
      tokens.add(token);
    }
  }

  void _skipWhitespaceAndComments() {
    while (index < source.length) {
      final char = source[index];
      if (char == ' ' || char == '\t' || char == '\r' || char == '\n') {
        index++;
        continue;
      }
      // 单行注释 //
      if (char == '/' && index + 1 < source.length && source[index + 1] == '/') {
        index += 2;
        while (index < source.length && source[index] != '\n') {
          index++;
        }
        continue;
      }
      // 多行注释 /* ... */
      if (char == '/' && index + 1 < source.length && source[index + 1] == '*') {
        index += 2;
        while (index + 1 < source.length &&
            !(source[index] == '*' && source[index + 1] == '/')) {
          index++;
        }
        index = math.min(source.length, index + 2);
        continue;
      }
      break;
    }
  }

  _Token _nextToken(String char) {
    if (_isIdentifierStart(char)) {
      return _identifier();
    }
    if (_isDigit(char)) {
      return _number();
    }
    if (char == "'" || char == '"' || char == '`') {
      return _string(char);
    }
    if (char == '/') {
      // 区分正则与除号：前一个 Token 是表达式开头/操作符时是正则
      if (_canBeRegexStart(_lastToken)) {
        return _regex();
      }
    }
    return _punct();
  }

  static bool _canBeRegexStart(_Token? last) {
    if (last == null) return true;
    if (last.type == _TokenType.punct) {
      final t = last.text;
      return t == '(' ||
          t == '=' ||
          t == ',' ||
          t == ';' ||
          t == ':' ||
          t == '[' ||
          t == '!' ||
          t == '&' ||
          t == '|' ||
          t == '?' ||
          t == '{' ||
          t == '=>';
    }
    if (last.type == _TokenType.keyword) {
      final k = last.text;
      return k == 'return' || k == 'typeof' || k == 'else';
    }
    return false;
  }

  _Token _identifier() {
    final start = index;
    index++;
    while (index < source.length && _isIdentifierPart(source[index])) {
      index++;
    }
    final text = source.substring(start, index);
    if (_keywords.contains(text)) {
      return _Token(_TokenType.keyword, text);
    }
    return _Token(_TokenType.identifier, text);
  }

  _Token _number() {
    final start = index;
    while (index < source.length && _isDigit(source[index])) {
      index++;
    }
    if (index < source.length && source[index] == '.') {
      index++;
      while (index < source.length && _isDigit(source[index])) {
        index++;
      }
    }
    final text = source.substring(start, index);
    return _Token(_TokenType.number, text, num.parse(text));
  }

  _Token _string(String quote) {
    index++;
    final buffer = StringBuffer();
    while (index < source.length) {
      final char = source[index++];
      if (char == quote) {
        return _Token(_TokenType.string, buffer.toString(), buffer.toString());
      }
      if (char != r'\') {
        buffer.write(char);
        continue;
      }
      if (index >= source.length) {
        throw const JsRuntimeException('JS 字符串未闭合');
      }
      final escaped = source[index++];
      switch (escaped) {
        case 'n':
          buffer.write('\n');
        case 'r':
          buffer.write('\r');
        case 't':
          buffer.write('\t');
        case 'b':
          buffer.write('\b');
        case 'f':
          buffer.write('\f');
        case 'v':
          buffer.write('\v');
        case '0':
          buffer.write('\x00');
        case 'u':
          if (index + 4 > source.length) {
            throw const JsRuntimeException('JS Unicode 转义无效');
          }
          final hex = source.substring(index, index + 4);
          final code = int.tryParse(hex, radix: 16);
          if (code == null) {
            throw const JsRuntimeException('JS Unicode 转义无效');
          }
          buffer.writeCharCode(code);
          index += 4;
        default:
          buffer.write(escaped);
      }
    }
    throw const JsRuntimeException('JS 字符串未闭合');
  }

  _Token _regex() {
    index++;
    final buffer = StringBuffer();
    var escaped = false;
    while (index < source.length) {
      final char = source[index++];
      if (!escaped && char == '/') {
        final startFlags = index;
        while (index < source.length && _isIdentifierPart(source[index])) {
          index++;
        }
        final flags = source.substring(startFlags, index);
        return _Token(_TokenType.regex, buffer.toString(), (
          pattern: buffer.toString(),
          flags: flags,
        ));
      }
      if (!escaped && char == r'\') {
        escaped = true;
        buffer.write(char);
        continue;
      }
      escaped = false;
      buffer.write(char);
    }
    throw const JsRuntimeException('JS 正则未闭合');
  }

  _Token _punct() {
    final start = index;
    final char = source[index++];

    // 尝试匹配双字符/三字符操作符
    if (index < source.length) {
      final next = source[index];
      final two = '$char$next';
      if (index + 1 < source.length) {
        final next2 = source[index + 1];
        final three = '$two$next2';
        if (three == '===' || three == '!==') {
          index += 2;
          return _Token(_TokenType.punct, three);
        }
      }
      if (two == '==' ||
          two == '!=' ||
          two == '<=' ||
          two == '>=' ||
          two == '&&' ||
          two == '||' ||
          two == '??' ||
          two == '+=' ||
          two == '-=' ||
          two == '++' ||
          two == '--' ||
          two == '=>') {
        index++;
        return _Token(_TokenType.punct, two);
      }
    }

    const single = <String>{
      '+',
      '-',
      '*',
      '/',
      '%',
      '.',
      ',',
      '(',
      ')',
      '[',
      ']',
      '{',
      '}',
      ':',
      '?',
      ';',
      '=',
      '<',
      '>',
      '!',
      '&',
      '|',
    };
    if (!single.contains(char)) {
      throw const JsRuntimeException('不支持的 JS 字符');
    }
    return _Token(_TokenType.punct, source.substring(start, index));
  }

  static bool _isDigit(String char) =>
      char.codeUnitAt(0) >= 0x30 && char.codeUnitAt(0) <= 0x39;

  static bool _isIdentifierStart(String char) {
    final code = char.codeUnitAt(0);
    return char == r'$' ||
        char == '_' ||
        (code >= 0x41 && code <= 0x5a) ||
        (code >= 0x61 && code <= 0x7a);
  }

  static bool _isIdentifierPart(String char) =>
      _isIdentifierStart(char) || _isDigit(char);
}

// =============================================================================
// AST Nodes
// =============================================================================

abstract class _AstNode {}

abstract class _Statement extends _AstNode {}

class _VarDeclStmt extends _Statement {
  _VarDeclStmt(this.declarations);
  final List<({String name, _Expr? init})> declarations;
}

class _ExprStmt extends _Statement {
  _ExprStmt(this.expr);
  final _Expr expr;
}

class _BlockStmt extends _Statement {
  _BlockStmt(this.statements);
  final List<_Statement> statements;
}

class _IfStmt extends _Statement {
  _IfStmt(this.condition, this.thenBranch, this.elseBranch);
  final _Expr condition;
  final _Statement thenBranch;
  final _Statement? elseBranch;
}

class _ForStmt extends _Statement {
  _ForStmt({this.init, this.test, this.update, required this.body});
  final _Statement? init;
  final _Expr? test;
  final _Expr? update;
  final _Statement body;
}

class _WhileStmt extends _Statement {
  _WhileStmt(this.condition, this.body);
  final _Expr condition;
  final _Statement body;
}

class _ReturnStmt extends _Statement {
  _ReturnStmt(this.expr);
  final _Expr? expr;
}

class _EmptyStmt extends _Statement {}

abstract class _Expr extends _AstNode {}

class _LiteralExpr extends _Expr {
  _LiteralExpr(this.value);
  final Object? value;
}

class _IdentifierExpr extends _Expr {
  _IdentifierExpr(this.name);
  final String name;
}

class _ArrayLiteralExpr extends _Expr {
  _ArrayLiteralExpr(this.elements);
  final List<_Expr> elements;
}

class _ObjectLiteralExpr extends _Expr {
  _ObjectLiteralExpr(this.properties);
  final List<({String key, _Expr value})> properties;
}

class _BinaryExpr extends _Expr {
  _BinaryExpr(this.left, this.op, this.right);
  final _Expr left;
  final String op;
  final _Expr right;
}

class _UnaryExpr extends _Expr {
  _UnaryExpr(this.op, this.expr, {this.isPrefix = true});
  final String op;
  final _Expr expr;
  final bool isPrefix;
}

class _AssignExpr extends _Expr {
  _AssignExpr(this.target, this.op, this.value);
  final _Expr target;
  final String op;
  final _Expr value;
}

class _ConditionalExpr extends _Expr {
  _ConditionalExpr(this.condition, this.thenExpr, this.elseExpr);
  final _Expr condition;
  final _Expr thenExpr;
  final _Expr elseExpr;
}

class _MemberExpr extends _Expr {
  _MemberExpr(this.target, this.property);
  final _Expr target;
  final String property;
}

class _IndexExpr extends _Expr {
  _IndexExpr(this.target, this.index);
  final _Expr target;
  final _Expr index;
}

class _CallExpr extends _Expr {
  _CallExpr(this.callee, this.args);
  final _Expr callee;
  final List<_Expr> args;
}

// =============================================================================
// Parser
// =============================================================================

class _Parser {
  _Parser(this.tokens);

  final List<_Token> tokens;
  int index = 0;

  _Token get _peek => tokens[index];

  bool get _isAtEnd => _peek.type == _TokenType.eof;

  _Token _advance() {
    if (!_isAtEnd) index++;
    return tokens[index - 1];
  }

  bool _check(Object expected) {
    if (_isAtEnd) return false;
    return _peek.text == expected;
  }

  bool _match(Object expected) {
    if (_check(expected)) {
      _advance();
      return true;
    }
    return false;
  }

  _Token _consume(Object expected, String message) {
    if (_check(expected)) return _advance();
    throw JsRuntimeException(message);
  }

  void _skipSemicolons() {
    while (_match(';')) {}
  }

  List<_Statement> parseProgram() {
    final list = <_Statement>[];
    _skipSemicolons();
    while (!_isAtEnd) {
      list.add(_declaration());
      _skipSemicolons();
    }
    return list;
  }

  _Statement _declaration() {
    if (_match('var') || _match('let') || _match('const')) {
      return _varDeclaration();
    }
    return _statement();
  }

  _Statement _varDeclaration() {
    final decls = <({String name, _Expr? init})>[];
    do {
      if (_peek.type != _TokenType.identifier) {
        throw const JsRuntimeException('缺少变量名');
      }
      final name = _advance().text;
      _Expr? init;
      if (_match('=')) {
        init = _expression();
      }
      decls.add((name: name, init: init));
    } while (_match(','));

    _match(';');
    return _VarDeclStmt(decls);
  }

  _Statement _statement() {
    if (_match('if')) {
      return _ifStatement();
    }
    if (_match('for')) {
      return _forStatement();
    }
    if (_match('while')) {
      return _whileStatement();
    }
    if (_match('return')) {
      _Expr? expr;
      if (!_check(';') && !_isAtEnd && !_check('}')) {
        expr = _expression();
      }
      _match(';');
      return _ReturnStmt(expr);
    }
    if (_match('{')) {
      final stmts = <_Statement>[];
      _skipSemicolons();
      while (!_check('}') && !_isAtEnd) {
        stmts.add(_declaration());
        _skipSemicolons();
      }
      _consume('}', '缺少 "}"');
      return _BlockStmt(stmts);
    }
    if (_match(';')) {
      return _EmptyStmt();
    }

    final expr = _expression();
    _match(';');
    return _ExprStmt(expr);
  }

  _Statement _ifStatement() {
    _consume('(', 'if 缺少 "("');
    final condition = _expression();
    _consume(')', 'if 缺少 ")"');
    final thenBranch = _statement();
    _Statement? elseBranch;
    if (_match('else')) {
      elseBranch = _statement();
    }
    return _IfStmt(condition, thenBranch, elseBranch);
  }

  _Statement _forStatement() {
    _consume('(', 'for 缺少 "("');
    _Statement? init;
    if (_match(';')) {
      init = null;
    } else if (_match('var') || _match('let')) {
      init = _varDeclaration();
    } else {
      init = _ExprStmt(_expression());
      _match(';');
    }

    _Expr? test;
    if (!_check(';')) {
      test = _expression();
    }
    _consume(';', 'for 缺少 ";"');

    _Expr? update;
    if (!_check(')')) {
      update = _expression();
    }
    _consume(')', 'for 缺少 ")"');

    final body = _statement();
    return _ForStmt(init: init, test: test, update: update, body: body);
  }

  _Statement _whileStatement() {
    _consume('(', 'while 缺少 "("');
    final condition = _expression();
    _consume(')', 'while 缺少 ")"');
    final body = _statement();
    return _WhileStmt(condition, body);
  }

  _Expr _expression() => _assignment();

  _Expr _assignment() {
    final expr = _conditional();
    if (_match('=') || _match('+=') || _match('-=')) {
      final op = tokens[index - 1].text;
      final value = _assignment();
      if (expr is _IdentifierExpr || expr is _MemberExpr || expr is _IndexExpr) {
        return _AssignExpr(expr, op, value);
      }
      throw const JsRuntimeException('无效的赋值目标');
    }
    return expr;
  }

  _Expr _conditional() {
    final expr = _logicalOr();
    if (_match('?')) {
      final thenExpr = _expression();
      _consume(':', '三元表达式缺少 ":"');
      final elseExpr = _conditional();
      return _ConditionalExpr(expr, thenExpr, elseExpr);
    }
    return expr;
  }

  _Expr _logicalOr() {
    var expr = _logicalAnd();
    while (_match('||') || _match('??')) {
      final op = tokens[index - 1].text;
      final right = _logicalAnd();
      expr = _BinaryExpr(expr, op, right);
    }
    return expr;
  }

  _Expr _logicalAnd() {
    var expr = _equality();
    while (_match('&&')) {
      final op = tokens[index - 1].text;
      final right = _equality();
      expr = _BinaryExpr(expr, op, right);
    }
    return expr;
  }

  _Expr _equality() {
    var expr = _relational();
    while (_match('==') || _match('!=') || _match('===') || _match('!==')) {
      final op = tokens[index - 1].text;
      final right = _relational();
      expr = _BinaryExpr(expr, op, right);
    }
    return expr;
  }

  _Expr _relational() {
    var expr = _additive();
    while (_match('<') || _match('<=') || _match('>') || _match('>=')) {
      final op = tokens[index - 1].text;
      final right = _additive();
      expr = _BinaryExpr(expr, op, right);
    }
    return expr;
  }

  _Expr _additive() {
    var expr = _multiplicative();
    while (_match('+') || _match('-')) {
      final op = tokens[index - 1].text;
      final right = _multiplicative();
      expr = _BinaryExpr(expr, op, right);
    }
    return expr;
  }

  _Expr _multiplicative() {
    var expr = _unary();
    while (_match('*') || _match('/') || _match('%')) {
      final op = tokens[index - 1].text;
      final right = _unary();
      expr = _BinaryExpr(expr, op, right);
    }
    return expr;
  }

  _Expr _unary() {
    if (_match('!') || _match('-') || _match('+') || _match('typeof')) {
      final op = tokens[index - 1].text;
      final right = _unary();
      return _UnaryExpr(op, right);
    }
    if (_match('++') || _match('--')) {
      final op = tokens[index - 1].text;
      final right = _unary();
      return _UnaryExpr(op, right, isPrefix: true);
    }
    return _postfix();
  }

  _Expr _postfix() {
    var expr = _primary();
    while (true) {
      if (_match('.')) {
        if (_peek.type != _TokenType.identifier &&
            _peek.type != _TokenType.keyword) {
          throw const JsRuntimeException('缺少属性名');
        }
        final name = _advance().text;
        expr = _MemberExpr(expr, name);
      } else if (_match('[')) {
        final indexExpr = _expression();
        _consume(']', '缺少 "]"');
        expr = _IndexExpr(expr, indexExpr);
      } else if (_match('(')) {
        final args = <_Expr>[];
        if (!_check(')')) {
          do {
            args.add(_expression());
          } while (_match(','));
        }
        _consume(')', '缺少 ")"');
        expr = _CallExpr(expr, args);
      } else if (_match('++') || _match('--')) {
        final op = tokens[index - 1].text;
        expr = _UnaryExpr(op, expr, isPrefix: false);
      } else {
        break;
      }
    }
    return expr;
  }

  _Expr _primary() {
    if (_peek.type == _TokenType.number ||
        _peek.type == _TokenType.string ||
        _peek.type == _TokenType.regex) {
      final tok = _advance();
      if (tok.type == _TokenType.regex) {
        final regex = tok.value! as ({String pattern, String flags});
        return _LiteralExpr(RegExp(
          regex.pattern,
          multiLine: regex.flags.contains('m'),
          caseSensitive: !regex.flags.contains('i'),
        ));
      }
      return _LiteralExpr(tok.value);
    }

    if (_match('true')) return _LiteralExpr(true);
    if (_match('false')) return _LiteralExpr(false);
    if (_match('null')) return _LiteralExpr(null);
    if (_match('undefined')) return _LiteralExpr(null);

    if (_peek.type == _TokenType.identifier) {
      final name = _advance().text;
      return _IdentifierExpr(name);
    }

    if (_match('(')) {
      final expr = _expression();
      _consume(')', '缺少 ")"');
      return expr;
    }

    if (_match('[')) {
      final elements = <_Expr>[];
      if (!_check(']')) {
        do {
          if (_check(']')) break;
          elements.add(_expression());
        } while (_match(','));
      }
      _consume(']', '缺少 "]"');
      return _ArrayLiteralExpr(elements);
    }

    if (_match('{')) {
      final props = <({String key, _Expr value})>[];
      if (!_check('}')) {
        do {
          if (_check('}')) break;
          final String key;
          if (_peek.type == _TokenType.identifier ||
              _peek.type == _TokenType.keyword ||
              _peek.type == _TokenType.string) {
            key = _advance().text;
          } else {
            throw const JsRuntimeException('无效的对象属性名');
          }
          _consume(':', '对象字面量缺少 ":"');
          final val = _expression();
          props.add((key: key, value: val));
        } while (_match(','));
      }
      _consume('}', '缺少 "}"');
      return _ObjectLiteralExpr(props);
    }

    throw const JsRuntimeException('不支持的 JS 表达式');
  }
}

// =============================================================================
// Environment & Evaluator
// =============================================================================

class _ReturnException implements Exception {
  const _ReturnException(this.value);
  final Object? value;
}

class _Scope {
  _Scope([this.parent]);

  final _Scope? parent;
  final Map<String, Object?> values = <String, Object?>{};

  Object? get(String name) {
    if (values.containsKey(name)) return values[name];
    if (parent != null) return parent!.get(name);
    throw JsRuntimeException('未知 JS 标识符: $name');
  }

  bool has(String name) {
    if (values.containsKey(name)) return true;
    if (parent != null) return parent!.has(name);
    return false;
  }

  void set(String name, Object? value) {
    if (values.containsKey(name)) {
      values[name] = value;
      return;
    }
    if (parent != null && parent!.has(name)) {
      parent!.set(name, value);
      return;
    }
    values[name] = value;
  }

  void define(String name, Object? value) {
    values[name] = value;
  }
}

class _Evaluator {
  _Evaluator(this.context) {
    _initGlobals();
  }

  final JsContext context;
  late final _Scope _rootScope;
  late _Scope _currentScope;

  void _initGlobals() {
    _rootScope = _Scope();
    _currentScope = _rootScope;

    _rootScope.define('result', context.result);
    _rootScope.define(r'$', context.result);
    _rootScope.define('src', context.result);
    _rootScope.define('baseUrl', context.baseUrl);
    _rootScope.define('page', context.page);
    _rootScope.define('key', context.key);

    // source
    final sourceMap = <String, Object?>{
      ...context.source,
      'get': (List<Object?> args) {
        if (args.isEmpty) return null;
        final k = args[0]?.toString() ?? '';
        return context.source[k] ?? context.variables[k];
      },
      'put': (List<Object?> args) {
        if (args.length < 2) return null;
        final k = args[0]?.toString() ?? '';
        final v = args[1];
        try {
          (context.variables as dynamic)[k] = v;
        } catch (_) {}
        return v;
      },
    };
    _rootScope.define('source', sourceMap);

    // java
    final javaMap = <String, Object?>{
      'get': (List<Object?> args) {
        if (args.isEmpty) return null;
        final k = args[0]?.toString() ?? '';
        return context.variables[k];
      },
      'put': (List<Object?> args) {
        if (args.length < 2) return null;
        final k = args[0]?.toString() ?? '';
        final v = args[1];
        try {
          (context.variables as dynamic)[k] = v;
        } catch (_) {}
        return v;
      },
      'ajax': (List<Object?> args) async {
        if (args.isEmpty) return '';
        final urlStr = args[0]?.toString() ?? '';
        if (context.http == null) {
          throw const JsRuntimeException('java.ajax 不可用：未提供 http 客户端');
        }
        final uri = Uri.parse(urlStr);
        final res = await context.http!.send(SourceHttpRequest(url: uri));
        return utf8.decode(res.bytes, allowMalformed: true);
      },
      'log': (List<Object?> args) {
        return null;
      },
      'getString': (List<Object?> args) {
        if (args.isEmpty) return '';
        return args[0]?.toString() ?? '';
      },
      'timeFormatUTC': (List<Object?> args) {
        if (args.isEmpty) return '';
        final ms = int.tryParse(args[0]?.toString() ?? '') ?? 0;
        final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
        return dt.toIso8601String();
      },
      'longToast': (List<Object?> args) => null,
    };
    _rootScope.define('java', javaMap);

    // JSON
    final jsonMap = <String, Object?>{
      'parse': (List<Object?> args) {
        if (args.isEmpty || args[0] == null) return null;
        return jsonDecode(args[0].toString());
      },
      'stringify': (List<Object?> args) {
        if (args.isEmpty) return 'null';
        return jsonEncode(args[0]);
      },
    };
    _rootScope.define('JSON', jsonMap);

    // Math
    final mathMap = <String, Object?>{
      'ceil': (List<Object?> args) {
        final n = args.isNotEmpty && args[0] is num ? args[0] as num : 0;
        return n.ceil();
      },
      'floor': (List<Object?> args) {
        final n = args.isNotEmpty && args[0] is num ? args[0] as num : 0;
        return n.floor();
      },
      'round': (List<Object?> args) {
        final n = args.isNotEmpty && args[0] is num ? args[0] as num : 0;
        return n.round();
      },
      'abs': (List<Object?> args) {
        final n = args.isNotEmpty && args[0] is num ? args[0] as num : 0;
        return n.abs();
      },
      'max': (List<Object?> args) {
        if (args.isEmpty) return double.negativeInfinity;
        return args.whereType<num>().reduce(math.max);
      },
      'min': (List<Object?> args) {
        if (args.isEmpty) return double.infinity;
        return args.whereType<num>().reduce(math.min);
      },
    };
    _rootScope.define('Math', mathMap);
  }

  Future<Object?> runProgram(List<_Statement> statements) async {
    Object? lastValue;
    try {
      for (final stmt in statements) {
        lastValue = await _exec(stmt);
      }
    } on _ReturnException catch (ret) {
      return ret.value;
    }
    return lastValue;
  }

  Future<Object?> _exec(_Statement stmt) async {
    if (stmt is _VarDeclStmt) {
      for (final decl in stmt.declarations) {
        Object? initVal;
        if (decl.init != null) {
          initVal = await _eval(decl.init!);
        }
        _currentScope.define(decl.name, initVal);
      }
      return null;
    }
    if (stmt is _ExprStmt) {
      return await _eval(stmt.expr);
    }
    if (stmt is _BlockStmt) {
      final prev = _currentScope;
      _currentScope = _Scope(prev);
      Object? result;
      try {
        for (final s in stmt.statements) {
          result = await _exec(s);
        }
      } finally {
        _currentScope = prev;
      }
      return result;
    }
    if (stmt is _IfStmt) {
      final cond = await _eval(stmt.condition);
      if (_isTruthy(cond)) {
        return await _exec(stmt.thenBranch);
      } else if (stmt.elseBranch != null) {
        return await _exec(stmt.elseBranch!);
      }
      return null;
    }
    if (stmt is _ForStmt) {
      final prev = _currentScope;
      _currentScope = _Scope(prev);
      try {
        if (stmt.init != null) await _exec(stmt.init!);
        Object? last;
        while (true) {
          if (stmt.test != null) {
            final cond = await _eval(stmt.test!);
            if (!_isTruthy(cond)) break;
          }
          last = await _exec(stmt.body);
          if (stmt.update != null) {
            await _eval(stmt.update!);
          }
        }
        return last;
      } finally {
        _currentScope = prev;
      }
    }
    if (stmt is _WhileStmt) {
      Object? last;
      while (_isTruthy(await _eval(stmt.condition))) {
        last = await _exec(stmt.body);
      }
      return last;
    }
    if (stmt is _ReturnStmt) {
      final val = stmt.expr != null ? await _eval(stmt.expr!) : null;
      throw _ReturnException(val);
    }
    if (stmt is _EmptyStmt) {
      return null;
    }
    throw const JsRuntimeException('未知语句');
  }

  Future<Object?> _eval(_Expr expr) async {
    if (expr is _LiteralExpr) {
      return expr.value;
    }
    if (expr is _IdentifierExpr) {
      return _currentScope.get(expr.name);
    }
    if (expr is _ArrayLiteralExpr) {
      final list = <Object?>[];
      for (final e in expr.elements) {
        list.add(await _eval(e));
      }
      return list;
    }
    if (expr is _ObjectLiteralExpr) {
      final map = <String, Object?>{};
      for (final p in expr.properties) {
        map[p.key] = await _eval(p.value);
      }
      return map;
    }
    if (expr is _BinaryExpr) {
      final left = await _eval(expr.left);
      // 短路逻辑运算
      if (expr.op == '&&') {
        if (!_isTruthy(left)) return left;
        return await _eval(expr.right);
      }
      if (expr.op == '||') {
        if (_isTruthy(left)) return left;
        return await _eval(expr.right);
      }
      if (expr.op == '??') {
        if (left != null) return left;
        return await _eval(expr.right);
      }

      final right = await _eval(expr.right);
      return _evalBinary(left, expr.op, right);
    }
    if (expr is _UnaryExpr) {
      final val = await _eval(expr.expr);
      return _evalUnary(expr.op, val, expr.expr);
    }
    if (expr is _AssignExpr) {
      final value = await _eval(expr.value);
      return _evalAssign(expr.target, expr.op, value);
    }
    if (expr is _ConditionalExpr) {
      final cond = await _eval(expr.condition);
      if (_isTruthy(cond)) {
        return await _eval(expr.thenExpr);
      } else {
        return await _eval(expr.elseExpr);
      }
    }
    if (expr is _MemberExpr) {
      final target = await _eval(expr.target);
      return _getMember(target, expr.property);
    }
    if (expr is _IndexExpr) {
      final target = await _eval(expr.target);
      final index = await _eval(expr.index);
      return _getIndex(target, index);
    }
    if (expr is _CallExpr) {
      return await _evalCall(expr);
    }

    throw const JsRuntimeException('未知表达式');
  }

  static bool _isTruthy(Object? val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val != 0 && !val.isNaN;
    if (val is String) return val.isNotEmpty;
    return true;
  }

  Object? _evalBinary(Object? left, String op, Object? right) {
    switch (op) {
      case '+':
        if (left is String || right is String) {
          return '${_jsString(left)}${_jsString(right)}';
        }
        if (left is num && right is num) return left + right;
        if (left == null && right is num) return right;
        if (left is num && right == null) return left;
        throw const JsRuntimeException('不支持的 JS 加法');
      case '-':
        if (left is num && right is num) return left - right;
        throw const JsRuntimeException('减法操作数必须是数字');
      case '*':
        if (left is num && right is num) return left * right;
        throw const JsRuntimeException('乘法操作数必须是数字');
      case '/':
        if (left is num && right is num) {
          if (right == 0) return double.infinity;
          return left / right;
        }
        throw const JsRuntimeException('除法操作数必须是数字');
      case '%':
        if (left is num && right is num) return left % right;
        throw const JsRuntimeException('模操作数必须是数字');
      case '==':
      case '===':
        return left == right || (left?.toString() == right?.toString());
      case '!=':
      case '!==':
        return left != right && (left?.toString() != right?.toString());
      case '<':
        if (left is num && right is num) return left < right;
        if (left is String && right is String) return left.compareTo(right) < 0;
        return false;
      case '<=':
        if (left is num && right is num) return left <= right;
        if (left is String && right is String) return left.compareTo(right) <= 0;
        return false;
      case '>':
        if (left is num && right is num) return left > right;
        if (left is String && right is String) return left.compareTo(right) > 0;
        return false;
      case '>=':
        if (left is num && right is num) return left >= right;
        if (left is String && right is String) return left.compareTo(right) >= 0;
        return false;
      default:
        throw JsRuntimeException('不支持的操作符: $op');
    }
  }

  Object? _evalUnary(String op, Object? val, _Expr expr) {
    switch (op) {
      case '!':
        return !_isTruthy(val);
      case '-':
        if (val is num) return -val;
        throw const JsRuntimeException('负号操作数必须是数字');
      case '+':
        if (val is num) return val;
        if (val is String) return num.tryParse(val) ?? double.nan;
        return double.nan;
      case 'typeof':
        if (val == null) return 'undefined';
        if (val is bool) return 'boolean';
        if (val is num) return 'number';
        if (val is String) return 'string';
        if (val is List) return 'object';
        if (val is Map) return 'object';
        if (val is Function) return 'function';
        return 'object';
      case '++':
        final n = (val as num?) ?? 0;
        _evalAssign(expr, '=', n + 1);
        return n + 1;
      case '--':
        final n = (val as num?) ?? 0;
        _evalAssign(expr, '=', n - 1);
        return n - 1;
      default:
        throw JsRuntimeException('不支持的一元操作符: $op');
    }
  }

  Object? _evalAssign(_Expr target, String op, Object? value) {
    if (op == '+=') {
      final current = _evalSync(target);
      value = _evalBinary(current, '+', value);
    } else if (op == '-=') {
      final current = _evalSync(target);
      value = _evalBinary(current, '-', value);
    }

    if (target is _IdentifierExpr) {
      _currentScope.set(target.name, value);
      return value;
    }
    if (target is _MemberExpr) {
      final obj = _evalSync(target.target);
      if (obj is Map) {
        obj[target.property] = value;
        return value;
      }
      throw const JsRuntimeException('无法给非对象设置属性');
    }
    if (target is _IndexExpr) {
      final obj = _evalSync(target.target);
      final idx = _evalSync(target.index);
      if (obj is List && idx is num) {
        final i = idx.toInt();
        if (i >= 0 && i < obj.length) {
          obj[i] = value;
          return value;
        }
      } else if (obj is Map) {
        obj[idx] = value;
        return value;
      }
      throw const JsRuntimeException('无效的下标赋值');
    }
    throw const JsRuntimeException('无效的赋值目标');
  }

  Object? _evalSync(_Expr expr) {
    if (expr is _IdentifierExpr) return _currentScope.get(expr.name);
    if (expr is _MemberExpr) {
      final t = _evalSync(expr.target);
      return _getMember(t, expr.property);
    }
    if (expr is _IndexExpr) {
      final t = _evalSync(expr.target);
      final i = _evalSync(expr.index);
      return _getIndex(t, i);
    }
    if (expr is _LiteralExpr) return expr.value;
    return null;
  }

  Object? _getMember(Object? target, String property) {
    if (target == null) return null;
    if (target is Map) {
      return target[property];
    }
    if (target is List) {
      if (property == 'length') return target.length;
      return null;
    }
    if (target is String) {
      if (property == 'length') return target.length;
      return null;
    }
    return null;
  }

  Object? _getIndex(Object? target, Object? index) {
    if (target == null) return null;
    if (target is List) {
      if (index is! num) return null;
      final i = index.toInt();
      if (i < 0 || i >= target.length) return null;
      return target[i];
    }
    if (target is String) {
      if (index is! num) return null;
      final i = index.toInt();
      if (i < 0 || i >= target.length) return null;
      return target[i];
    }
    if (target is Map) {
      return target[index];
    }
    return null;
  }

  Future<Object?> _evalCall(_CallExpr call) async {
    final args = <Object?>[];
    for (final a in call.args) {
      args.add(await _eval(a));
    }

    // 1. 如果是对成员方法的调用：target.method(...)
    if (call.callee is _MemberExpr) {
      final memberExpr = call.callee as _MemberExpr;
      final target = await _eval(memberExpr.target);
      final methodName = memberExpr.property;
      return await _invokeMethod(target, methodName, args);
    }

    // 2. 直接对函数标识符或表达式的调用：fn(...)
    final callee = await _eval(call.callee);
    if (callee is Function) {
      return await _invokeFunction(callee, args);
    }
    throw JsRuntimeException('不可调用的对象: $callee');
  }

  Future<Object?> _invokeMethod(
      Object? target, String name, List<Object?> args) async {
    // String 方法
    if (target is String) {
      switch (name) {
        case 'toString':
          return target;
        case 'trim':
          return target.trim();
        case 'toLowerCase':
          return target.toLowerCase();
        case 'toUpperCase':
          return target.toUpperCase();
        case 'match':
          return _stringMatch(target, args);
        case 'split':
          final sep = args.isNotEmpty ? args[0]?.toString() ?? '' : '';
          return target.split(sep);
        case 'indexOf':
          final needle = args.isNotEmpty ? args[0]?.toString() ?? '' : '';
          return target.indexOf(needle);
        case 'includes':
          final needle = args.isNotEmpty ? args[0]?.toString() ?? '' : '';
          return target.contains(needle);
        case 'substring':
        case 'slice':
          final start = args.isNotEmpty && args[0] is num ? (args[0] as num).toInt() : 0;
          final end = args.length > 1 && args[1] is num ? (args[1] as num).toInt() : target.length;
          return target.substring(
            start.clamp(0, target.length),
            end.clamp(start, target.length),
          );
        case 'replace':
        case 'replaceAll':
          if (args.length < 2) return target;
          final pattern = args[0];
          final rep = args[1]?.toString() ?? '';
          if (pattern is RegExp) {
            return target.replaceAll(pattern, rep);
          }
          return target.replaceAll(pattern?.toString() ?? '', rep);
        default:
          throw JsRuntimeException('不支持的字符串方法: $name');
      }
    }

    // List 方法
    if (target is List) {
      switch (name) {
        case 'push':
          target.addAll(args);
          return target.length;
        case 'pop':
          return target.isNotEmpty ? target.removeLast() : null;
        case 'shift':
          return target.isNotEmpty ? target.removeAt(0) : null;
        case 'unshift':
          target.insertAll(0, args);
          return target.length;
        case 'join':
          final sep = args.isNotEmpty ? args[0]?.toString() ?? ',' : ',';
          return target.join(sep);
        case 'slice':
          final start = args.isNotEmpty && args[0] is num ? (args[0] as num).toInt() : 0;
          final end = args.length > 1 && args[1] is num ? (args[1] as num).toInt() : target.length;
          final s = start.clamp(0, target.length);
          final e = end.clamp(s, target.length);
          return target.sublist(s, e);
        case 'concat':
          final result = List<Object?>.from(target);
          for (final a in args) {
            if (a is List) {
              result.addAll(a);
            } else {
              result.add(a);
            }
          }
          return result;
        case 'indexOf':
          final needle = args.isNotEmpty ? args[0] : null;
          return target.indexOf(needle);
        case 'includes':
          final needle = args.isNotEmpty ? args[0] : null;
          return target.contains(needle);
        default:
          throw JsRuntimeException('不支持的数组方法: $name');
      }
    }

    // Map 中的函数方法（如 source.get, java.ajax, JSON.stringify）
    if (target is Map && target[name] != null) {
      final fn = target[name];
      if (fn is Function) {
        return await _invokeFunction(fn, args);
      }
    }

    throw JsRuntimeException('在 $target 上找不到方法 $name');
  }

  Future<Object?> _invokeFunction(Function fn, List<Object?> args) async {
    try {
      final dynamic result = Function.apply(fn, [args]);
      if (result is Future) {
        return await result;
      }
      return result;
    } catch (e) {
      if (e is JsRuntimeException) rethrow;
      throw JsRuntimeException('调用函数失败: $e');
    }
  }

  List<String?>? _stringMatch(String target, List<Object?> args) {
    if (args.isEmpty || args.first is! RegExp) {
      throw const JsRuntimeException('match 只接受正则参数');
    }
    final regex = args.first as RegExp;
    final match = regex.firstMatch(target);
    if (match == null) return null;
    final list = <String?>[match.group(0)];
    for (var i = 1; i <= match.groupCount; i++) {
      list.add(match.group(i));
    }
    return list;
  }

  static String _jsString(Object? value) {
    if (value == null) return 'null';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return jsonEncode(value);
  }
}
