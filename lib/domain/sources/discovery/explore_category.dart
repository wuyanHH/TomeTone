import 'dart:convert';

import '../../../contracts/sources/js_runtime.dart';

/// 发现页的一个分类入口。
class ExploreCategory {
  const ExploreCategory({required this.name, required this.urlTemplate});

  final String name;
  final String urlTemplate;
}

/// 异步解析 Legado `exploreUrl`：支持 `@js:` / `<js>` 动态脚本求值、宽松 JSON 数组及文本行。
Future<List<ExploreCategory>> resolveExploreCategories({
  required String? exploreUrl,
  required bool enabledExplore,
  JsRuntime? jsRuntime,
  JsContext? context,
}) async {
  if (!enabledExplore) {
    return const <ExploreCategory>[];
  }
  var raw = exploreUrl?.trim();
  if (raw == null || raw.isEmpty) {
    return const <ExploreCategory>[];
  }

  // 1. 检查并执行 @js: / <js> 动态脚本
  if (raw.startsWith('@js:') || raw.startsWith('<js>')) {
    String script = raw;
    if (script.startsWith('@js:')) {
      script = script.substring(4).trim();
    } else if (script.startsWith('<js>')) {
      final end = script.lastIndexOf('</js>');
      script = end > 0 ? script.substring(4, end).trim() : script.substring(4).trim();
    }

    if (jsRuntime != null && context != null) {
      try {
        final result = await jsRuntime.evaluate(script, context);
        if (result is List) {
          return _parseList(result);
        }
        if (result is String) {
          raw = result.trim();
        }
      } catch (_) {
        // JS 执行失败降级
      }
    }
  }

  final safeRaw = raw;
  if (safeRaw != null && safeRaw.contains('[') && safeRaw.contains(']')) {
    final start = safeRaw.indexOf('[');
    final end = safeRaw.lastIndexOf(']');
    if (end > start) {
      final jsonPart = safeRaw.substring(start, end + 1);
      final fromJson = _tryParseJsonArray(jsonPart);
      if (fromJson.isNotEmpty) {
        return fromJson;
      }
    }
  }

  // 3. 回退到标准同步解析
  return parseExploreCategories(exploreUrl: raw, enabledExplore: enabledExplore);
}

List<ExploreCategory> _tryParseJsonArray(String jsonStr) {
  // 尝试直接严格解析
  try {
    final decoded = jsonDecode(jsonStr);
    if (decoded is List) {
      return _parseList(decoded);
    }
  } catch (_) {
    // 宽松修复
  }

  // 宽松修复：替换单引号、给无引号的标识符 key 加上双引号
  try {
    final fixed = jsonStr
        .replaceAllMapped(
          RegExp(r'(?<=[{,]\s*)([a-zA-Z_$][a-zA-Z0-9_$]*)\s*:'),
          (m) => '"${m[1]}":',
        )
        .replaceAllMapped(
          RegExp(r"'([^']*)'"),
          (m) => '"${m[1]}"',
        );
    final decoded = jsonDecode(fixed);
    if (decoded is List) {
      return _parseList(decoded);
    }
  } catch (_) {
    // 修复依然失败
  }

  // 正则提取每一个 { ... title/name ... url ... }
  final categories = <ExploreCategory>[];
  final itemRegex = RegExp(r'\{[^{}]*\}');
  final titleRegex = RegExp(r'''(?:title|name|category)\s*[:=]\s*['"]?([^'",}]+)['"]?''');
  final urlRegex = RegExp(r'''url\s*[:=]\s*['"]?([^'",}]+)['"]?''');

  for (final match in itemRegex.allMatches(jsonStr)) {
    final block = match.group(0)!;
    final tMatch = titleRegex.firstMatch(block);
    final uMatch = urlRegex.firstMatch(block);
    if (tMatch != null && uMatch != null) {
      final name = tMatch.group(1)?.trim();
      final url = uMatch.group(1)?.trim();
      if (name != null && name.isNotEmpty && url != null && url.isNotEmpty) {
        categories.add(ExploreCategory(name: name, urlTemplate: url));
      }
    }
  }
  return List<ExploreCategory>.unmodifiable(categories);
}

List<ExploreCategory> _parseList(List<dynamic> list) {
  final categories = <ExploreCategory>[];
  for (final item in list) {
    if (item is Map) {
      final name = _string(item['title'] ?? item['name'] ?? item['category'])?.trim();
      final url = _string(item['url'])?.trim();
      if (name != null && name.isNotEmpty && url != null && url.isNotEmpty) {
        categories.add(ExploreCategory(name: name, urlTemplate: url));
      }
    }
  }
  return List<ExploreCategory>.unmodifiable(categories);
}

/// 解析 Legado `exploreUrl`：支持 JSON 数组，或每行 / `&&` 分隔的 `名称::URL 模板`。
List<ExploreCategory> parseExploreCategories({
  required String? exploreUrl,
  required bool enabledExplore,
}) {
  if (!enabledExplore) {
    return const <ExploreCategory>[];
  }
  final raw = exploreUrl?.trim();
  if (raw == null || raw.isEmpty) {
    return const <ExploreCategory>[];
  }

  if (raw.contains('[') && raw.contains(']')) {
    final start = raw.indexOf('[');
    final end = raw.lastIndexOf(']');
    if (end > start) {
      final jsonPart = raw.substring(start, end + 1);
      final fromJson = _tryParseJsonArray(jsonPart);
      if (fromJson.isNotEmpty) {
        return fromJson;
      }
    }
  }

  final categories = <ExploreCategory>[];
  for (final part in raw.split(RegExp(r'\r?\n|&&'))) {
    final entry = part.trim();
    if (entry.isEmpty) {
      continue;
    }
    final separator = entry.indexOf('::');
    if (separator <= 0) {
      continue;
    }
    final name = entry.substring(0, separator).trim();
    final url = entry.substring(separator + 2).trim();
    if (name.isEmpty || url.isEmpty) {
      continue;
    }
    categories.add(ExploreCategory(name: name, urlTemplate: url));
  }
  return List<ExploreCategory>.unmodifiable(categories);
}

String? _string(Object? value) => value is String ? value : null;
