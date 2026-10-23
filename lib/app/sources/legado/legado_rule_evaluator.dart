// Named constructor parameters stay public while the backing fields remain
// private; initializing formals would expose the fields.
// ignore_for_file: prefer_initializing_formals

import '../../../contracts/sources/js_runtime.dart';
import '../../../domain/sources/rules/json_path_rule.dart';
import '../../../domain/sources/rules/rule_context.dart';
import '../../../domain/sources/rules/rule_error.dart';
import '../../../domain/sources/rules/template_rule.dart';

/// 执行 Legado 规则子集。
///
/// 顺序：整段 JS -> 顶层 `||` -> `##` 清洗 -> `{{}}` 模板 -> JSONPath ->
/// 字面量。M1 明确拒绝 CSS/XPath/JSON/`&&`/`%%`/`#####`。
class LegadoRuleEvaluator {
  const LegadoRuleEvaluator({required JsRuntime jsRuntime})
    : _jsRuntime = jsRuntime;

  final JsRuntime _jsRuntime;

  Future<Object?> evaluate(String rule, RuleEvaluationContext context) async {
    var trimmed = rule.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    // 检查并剥离 @put:{...} 后缀
    String? putContent;
    final putIndex = trimmed.indexOf('@put:{');
    if (putIndex >= 0 && trimmed.endsWith('}')) {
      putContent = trimmed.substring(putIndex + 6, trimmed.length - 1).trim();
      trimmed = trimmed.substring(0, putIndex).trim();
    }

    if (putContent != null && putContent.isNotEmpty) {
      await _executePut(putContent, context);
      if (trimmed.isEmpty) {
        return null;
      }
    }

    if (trimmed.startsWith('@js:')) {
      return _evaluateJs(trimmed.substring(4).trim(), trimmed, context);
    }
    if (trimmed.startsWith('<js>')) {
      final end = trimmed.lastIndexOf('</js>');
      final script = end > 4
          ? trimmed.substring(4, end).trim()
          : trimmed.substring(4).trim();
      return _evaluateJs(script, trimmed, context);
    }

    if (trimmed.startsWith('@json:')) {
      trimmed = trimmed.substring(6).trim();
      if (trimmed.isEmpty) {
        return null;
      }
    }

    if (_isUnsupported(trimmed)) {
      throw RuleEvaluationException('M1 暂不支持该规则', rule: trimmed);
    }

    RuleEvaluationException? firstError;
    for (final alternative in _splitAlternatives(trimmed)) {
      try {
        final value = await _evaluateAlternative(alternative, context);
        if (_isNonEmpty(value)) {
          return value;
        }
      } on RuleEvaluationException catch (error) {
        firstError ??= error;
      }
    }

    if (firstError != null) {
      throw firstError;
    }
    return null;
  }

  Future<Object?> _evaluateAlternative(
    String alternative,
    RuleEvaluationContext context,
  ) async {
    final split = _splitCleanRule(alternative);
    var value = await _evaluateValue(split.source, context);
    final pattern = split.cleanPattern;
    if (pattern != null && value is String) {
      try {
        value = value.replaceAll(RegExp(pattern), '');
      } on FormatException {
        throw RuleEvaluationException('清洗正则无效', rule: pattern);
      }
    }
    return value;
  }

  Future<Object?> _evaluateValue(
    String rule,
    RuleEvaluationContext context,
  ) async {
    var trimmed = rule.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.startsWith('@json:')) {
      trimmed = trimmed.substring(6).trim();
    }
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.contains('{{')) {
      return _renderTemplate(trimmed, context);
    }
    if (trimmed == r'$' ||
        trimmed.startsWith(r'$.') ||
        trimmed.startsWith(r'$[')) {
      return jsonPathValue(trimmed, context.result);
    }
    final root = context.result;
    if (root is Map || root is List) {
      final candidatePath = trimmed.startsWith('[') ? '\$$trimmed' : '\$.$trimmed';
      try {
        final value = jsonPathValue(candidatePath, root);
        if (_isNonEmpty(value)) {
          return value;
        }
      } on RuleEvaluationException {
        // 不是合法 JSONPath 表达式时安全回退，走文本字面量
      }
    }
    return trimmed;
  }

  Future<String> _renderTemplate(
    String template,
    RuleEvaluationContext context,
  ) {
    final renderer = TemplateRenderer(
      resolve: (expression) => _resolveTemplate(expression, context),
    );
    return renderer.render(template, mode: TemplateOutputMode.text);
  }

  Future<Object?> _resolveTemplate(
    String expression,
    RuleEvaluationContext context,
  ) async {
    var trimmed = expression.trim();
    if (trimmed.startsWith('@json:')) {
      trimmed = trimmed.substring(6).trim();
    }
    if (trimmed == 'page') {
      return context.page;
    }
    if (trimmed == 'key') {
      return context.key;
    }
    if (trimmed == r'$' ||
        trimmed.startsWith(r'$.') ||
        trimmed.startsWith(r'$[')) {
      return jsonPathValue(trimmed, context.result);
    }
    final root = context.result;
    if (root is Map || root is List) {
      final candidatePath = trimmed.startsWith('[') ? '\$$trimmed' : '\$.$trimmed';
      try {
        final value = jsonPathValue(candidatePath, root);
        if (_isNonEmpty(value)) {
          return value;
        }
      } on RuleEvaluationException {
        // 尝试走 JS
      }
    }
    try {
      return await _jsRuntime.evaluate(
        trimmed,
        JsContext(
          result: context.result,
          baseUrl: context.baseUrl,
          page: context.page,
          key: context.key,
          source: context.source,
          variables: context.variables,
        ),
      );
    } on JsRuntimeException {
      throw RuleEvaluationException('JS 规则执行失败', rule: trimmed);
    }
  }

  Future<Object?> _evaluateJs(
    String script,
    String rule,
    RuleEvaluationContext context,
  ) async {
    try {
      return await _jsRuntime.evaluate(
        script,
        JsContext(
          result: context.result,
          baseUrl: context.baseUrl,
          page: context.page,
          key: context.key,
          source: context.source,
          variables: context.variables,
        ),
      );
    } on JsRuntimeException {
      throw RuleEvaluationException('JS 规则执行失败', rule: rule);
    }
  }

  Future<void> _executePut(
    String putContent,
    RuleEvaluationContext context,
  ) async {
    final pairs = _splitPutPairs(putContent);
    for (final pair in pairs) {
      final colon = pair.indexOf(':');
      if (colon <= 0) continue;
      final varName = pair.substring(0, colon).trim();
      final varRule = pair.substring(colon + 1).trim();
      if (varName.isEmpty || varRule.isEmpty) continue;
      final val = await evaluate(varRule, context);
      if (context.sourceVariables != null) {
        context.sourceVariables![varName] = val;
      }
    }
  }

  static List<String> _splitPutPairs(String content) {
    final result = <String>[];
    final buffer = StringBuffer();
    var braceDepth = 0;
    var bracketDepth = 0;
    var inSingleQuote = false;
    var inDoubleQuote = false;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
      } else if (char == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
      } else if (!inSingleQuote && !inDoubleQuote) {
        if (char == '{') braceDepth++;
        if (char == '}') braceDepth--;
        if (char == '[') bracketDepth++;
        if (char == ']') bracketDepth--;
        if (char == ',' && braceDepth == 0 && bracketDepth == 0) {
          result.add(buffer.toString().trim());
          buffer.clear();
          continue;
        }
      }
      buffer.write(char);
    }
    if (buffer.isNotEmpty) {
      result.add(buffer.toString().trim());
    }
    return result;
  }

  bool _isUnsupported(String rule) {
    return rule.startsWith('@css:') ||
        rule.startsWith('@xpath:') ||
        rule.contains('&&') ||
        rule.contains('%%') ||
        rule.contains('#####');
  }

  bool _isNonEmpty(Object? value) {
    if (value == null) {
      return false;
    }
    if (value is String) {
      return value.trim().isNotEmpty;
    }
    if (value is Iterable) {
      return value.isNotEmpty;
    }
    if (value is Map) {
      return value.isNotEmpty;
    }
    return true;
  }

  List<String> _splitAlternatives(String rule) {
    final result = <String>[];
    final buffer = StringBuffer();
    String? quote;
    var escaped = false;
    var templateDepth = 0;

    for (var i = 0; i < rule.length; i++) {
      final char = rule[i];
      if (quote != null) {
        buffer.write(char);
        if (escaped) {
          escaped = false;
        } else if (char == r'\') {
          escaped = true;
        } else if (char == quote) {
          quote = null;
        }
        continue;
      }

      if (char == "'" || char == '"') {
        quote = char;
        buffer.write(char);
        continue;
      }

      if (char == '{' && i + 1 < rule.length && rule[i + 1] == '{') {
        templateDepth++;
        buffer.write('{{');
        i++;
        continue;
      }
      if (templateDepth > 0 &&
          char == '}' &&
          i + 1 < rule.length &&
          rule[i + 1] == '}') {
        templateDepth--;
        buffer.write('}}');
        i++;
        continue;
      }

      if (templateDepth == 0 &&
          char == '|' &&
          i + 1 < rule.length &&
          rule[i + 1] == '|') {
        result.add(buffer.toString());
        buffer.clear();
        i++;
        continue;
      }

      buffer.write(char);
    }
    result.add(buffer.toString());
    return result;
  }

  _CleanRule _splitCleanRule(String rule) {
    final index = rule.indexOf('##');
    if (index < 0) {
      return _CleanRule(rule, null);
    }
    return _CleanRule(rule.substring(0, index), rule.substring(index + 2));
  }
}

class _CleanRule {
  const _CleanRule(this.source, this.cleanPattern);

  final String source;
  final String? cleanPattern;
}
