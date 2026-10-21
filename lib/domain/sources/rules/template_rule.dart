import 'dart:convert';

/// 模板替换结果的转义方式。
enum TemplateOutputMode { url, jsonBody, text }

typedef TemplateResolver = Future<Object?> Function(String expression);
typedef SyncTemplateResolver = Object? Function(String expression);

/// 将 `{{ expression }}` 替换为 [resolve] 的结果。
///
/// 只做一次替换，不会递归解析替换结果里的占位符。
class TemplateRenderer {
  const TemplateRenderer({required this.resolve});

  final TemplateResolver resolve;

  static final RegExp _placeholder = RegExp(r'\{\{\s*(.*?)\s*\}\}');

  Future<String> render(
    String template, {
    required TemplateOutputMode mode,
  }) async {
    final matches = _placeholder.allMatches(template).toList(growable: false);
    if (matches.isEmpty) {
      return template;
    }

    final buffer = StringBuffer();
    var cursor = 0;
    for (final match in matches) {
      buffer.write(template.substring(cursor, match.start));
      final value = await resolve(match.group(1) ?? '');
      buffer.write(_formatTemplateValue(value, mode));
      cursor = match.end;
    }
    buffer.write(template.substring(cursor));
    return buffer.toString();
  }
}

/// [TemplateRenderer] 的同步版本，供构建请求等同步 API 使用。
class SyncTemplateRenderer {
  const SyncTemplateRenderer({required this.resolve});

  final SyncTemplateResolver resolve;

  static final RegExp _placeholder = RegExp(r'\{\{\s*(.*?)\s*\}\}');

  String render(String template, {required TemplateOutputMode mode}) {
    final matches = TemplateRenderer._placeholder
        .allMatches(template)
        .toList(growable: false);
    if (matches.isEmpty) {
      return template;
    }

    final buffer = StringBuffer();
    var cursor = 0;
    for (final match in matches) {
      buffer.write(template.substring(cursor, match.start));
      buffer.write(_formatTemplateValue(resolve(match.group(1) ?? ''), mode));
      cursor = match.end;
    }
    buffer.write(template.substring(cursor));
    return buffer.toString();
  }
}

String _formatTemplateValue(Object? value, TemplateOutputMode mode) {
  if (value == null) {
    return '';
  }
  if (mode == TemplateOutputMode.text) {
    return value is String ? value : jsonEncode(value);
  }

  final encoded = value is String ? value : jsonEncode(value);
  if (mode == TemplateOutputMode.url) {
    return Uri.encodeComponent(encoded);
  }

  // jsonBody：值放进 JSON 字符串字面量里。jsonEncode(String) 自带引号，
  // 去掉首尾引号后保留内部的转义；数字/布尔等保持原样。
  final json = jsonEncode(encoded);
  return json.length >= 2 && json.startsWith('"') && json.endsWith('"')
      ? json.substring(1, json.length - 1)
      : json;
}
