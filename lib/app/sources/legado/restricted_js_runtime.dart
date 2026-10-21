import '../../../contracts/sources/js_runtime.dart';

/// M1 的保底 JS 求值器：只支持书源规则常见的表达式子集。
///
/// 不执行语句、赋值、循环或任意宿主调用；复杂脚本由 QuickJS 适配器接管。
class RestrictedJsRuntime implements JsRuntime {
  @override
  Future<Object?> evaluate(String script, JsContext context) async {
    try {
      final tokens = _Lexer(script).tokenize();
      return _Parser(tokens, context).parse();
    } on JsRuntimeException {
      rethrow;
    } on Object {
      throw const JsRuntimeException('不支持的 JS 表达式');
    }
  }

  @override
  Future<void> dispose() async {}
}

enum _TokenType { identifier, number, string, regex, punct, eof }

class _Token {
  const _Token(this.type, this.text, [this.value]);

  final _TokenType type;
  final String text;
  final Object? value;
}

class _Lexer {
  _Lexer(this.source);

  final String source;
  int index = 0;

  List<_Token> tokenize() {
    final tokens = <_Token>[];
    while (true) {
      _skipWhitespace();
      if (index >= source.length) {
        tokens.add(const _Token(_TokenType.eof, ''));
        return tokens;
      }
      final char = source[index];
      if (_isIdentifierStart(char)) {
        tokens.add(_identifier());
      } else if (_isDigit(char)) {
        tokens.add(_number());
      } else if (char == "'" || char == '"') {
        tokens.add(_string(char));
      } else if (char == '/') {
        tokens.add(_regex());
      } else {
        tokens.add(_punct());
      }
    }
  }

  _Token _identifier() {
    final start = index;
    index++;
    while (index < source.length && _isIdentifierPart(source[index])) {
      index++;
    }
    return _Token(_TokenType.identifier, source.substring(start, index));
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
    final char = source[index++];
    const supported = <String>{
      '+',
      '-',
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
      '%',
      '*',
    };
    if (!supported.contains(char)) {
      throw const JsRuntimeException('不支持的 JS 字符');
    }
    return _Token(_TokenType.punct, char);
  }

  void _skipWhitespace() {
    while (index < source.length && source[index].trim().isEmpty) {
      index++;
    }
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

class _Parser {
  _Parser(this.tokens, this.context);

  final List<_Token> tokens;
  final JsContext context;
  int index = 0;

  Object? parse() {
    final value = _expression();
    if (_peek.type != _TokenType.eof) {
      throw const JsRuntimeException('不支持的 JS 语句');
    }
    return value;
  }

  Object? _expression() {
    var value = _postfix();
    while (_matchPunct('+')) {
      final right = _postfix();
      if (value is String || right is String) {
        value = '${_jsString(value)}${_jsString(right)}';
      } else if (value is num && right is num) {
        value = value + right;
      } else if (value == null && right is num) {
        value = right;
      } else if (value is num && right == null) {
        value = value;
      } else {
        throw const JsRuntimeException('不支持的 JS 加法');
      }
    }
    return value;
  }

  Object? _postfix() {
    var value = _primary();
    while (true) {
      if (_matchPunct('.')) {
        final name = _consumeIdentifier();
        if (_matchPunct('(')) {
          final args = _arguments();
          value = _call(value, name, args);
        } else {
          value = _property(value, name);
        }
      } else if (_matchPunct('[')) {
        final key = _expression();
        _expectPunct(']');
        value = _index(value, key);
      } else {
        return value;
      }
    }
  }

  Object? _primary() {
    final token = _peek;
    if (token.type == _TokenType.number ||
        token.type == _TokenType.string ||
        token.type == _TokenType.regex) {
      index++;
      if (token.type == _TokenType.regex) {
        final regex = token.value! as ({String pattern, String flags});
        try {
          return RegExp(regex.pattern, multiLine: regex.flags.contains('m'));
        } on FormatException {
          throw const JsRuntimeException('JS 正则无效');
        }
      }
      return token.value;
    }
    if (token.type == _TokenType.identifier) {
      index++;
      return _identifier(token.text);
    }
    if (_matchPunct('(')) {
      final value = _expression();
      _expectPunct(')');
      return value;
    }
    if (_matchPunct('-')) {
      final value = _primary();
      if (value is num) {
        return -value;
      }
      throw const JsRuntimeException('JS 负号只能用于数字');
    }
    throw const JsRuntimeException('不支持的 JS 表达式');
  }

  Object? _identifier(String name) {
    return switch (name) {
      'true' => true,
      'false' => false,
      'null' => null,
      'result' => context.result,
      r'$' => context.result,
      'baseUrl' => context.baseUrl,
      'page' => context.page,
      'key' => context.key,
      'source' => context.source,
      _ => throw const JsRuntimeException('未知 JS 标识符'),
    };
  }

  List<Object?> _arguments() {
    final args = <Object?>[];
    if (_matchPunct(')')) {
      return args;
    }
    while (true) {
      args.add(_expression());
      if (_matchPunct(')')) {
        return args;
      }
      _expectPunct(',');
    }
  }

  Object? _property(Object? target, String name) {
    if (target == null) {
      throw const JsRuntimeException('JS 在 null 上取属性');
    }
    if (target is Map) {
      return target[name];
    }
    if (target is List && name == 'length') {
      return target.length;
    }
    if (target is String && name == 'length') {
      return target.length;
    }
    throw const JsRuntimeException('不支持的 JS 属性');
  }

  Object? _index(Object? target, Object? key) {
    if (target == null) {
      throw const JsRuntimeException('JS 在 null 上取下标');
    }
    if (target is List) {
      if (key is! num) {
        throw const JsRuntimeException('JS 数组下标必须是数字');
      }
      final int index = key.toInt();
      if (index < 0 || index >= target.length) {
        return null;
      }
      return target[index];
    }
    if (target is String) {
      if (key is! num) {
        throw const JsRuntimeException('JS 字符串下标必须是数字');
      }
      final int index = key.toInt();
      if (index < 0 || index >= target.length) {
        return null;
      }
      return target[index];
    }
    if (target is Map) {
      return target[key];
    }
    throw const JsRuntimeException('不支持的 JS 下标');
  }

  Object? _call(Object? target, String name, List<Object?> args) {
    if (target is String) {
      return switch (name) {
        'toString' => target,
        'trim' => target.trim(),
        'toLowerCase' => target.toLowerCase(),
        'toUpperCase' => target.toUpperCase(),
        'match' => _match(target, args),
        _ => throw const JsRuntimeException('不支持的 JS 字符串方法'),
      };
    }
    if (target == null) {
      throw const JsRuntimeException('JS 在 null 上调用方法');
    }
    throw const JsRuntimeException('不支持的 JS 方法');
  }

  List<String?>? _match(String target, List<Object?> args) {
    if (args.length != 1 || args.single is! RegExp) {
      throw const JsRuntimeException('match 只接受一个正则');
    }
    final match = (args.single as RegExp).firstMatch(target);
    if (match == null) {
      return null;
    }
    return <String?>[
      for (var i = 0; i <= match.groupCount; i++) match.group(i),
    ];
  }

  String _jsString(Object? value) => value == null ? 'null' : value.toString();

  _Token get _peek => tokens[index];

  bool _matchPunct(String text) {
    if (_peek.type == _TokenType.punct && _peek.text == text) {
      index++;
      return true;
    }
    return false;
  }

  void _expectPunct(String text) {
    if (!_matchPunct(text)) {
      throw const JsRuntimeException('JS 表达式缺少符号');
    }
  }

  String _consumeIdentifier() {
    final token = _peek;
    if (token.type != _TokenType.identifier) {
      throw const JsRuntimeException('JS 属性名无效');
    }
    index++;
    return token.text;
  }
}
