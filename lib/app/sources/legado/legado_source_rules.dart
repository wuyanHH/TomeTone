import 'dart:convert';

import '../../../domain/sources/book_source.dart';
import '../source_rate_limiter.dart';

/// 从书源原始 JSON 中提取 M1 需要的规则字段。
///
/// 规则本身不在这里求值；保留原始字符串，交给 [LegadoRuleEvaluator]。
class LegadoSourceRules {
  const LegadoSourceRules({
    required this.exploreUrl,
    required this.searchUrl,
    required this.exploreFields,
    required this.searchFields,
    required this.bookInfoFields,
    required this.tocFields,
    required this.contentFields,
    required this.rateLimit,
  });

  final String? exploreUrl;
  final String? searchUrl;
  final Map<String, String> exploreFields;
  final Map<String, String> searchFields;
  final Map<String, String> bookInfoFields;
  final Map<String, String> tocFields;
  final Map<String, String> contentFields;
  final SourceRateLimit rateLimit;

  static LegadoSourceRules parse(BookSource source) {
    final decoded = jsonDecode(source.rawJson);
    if (decoded is! Map) {
      throw const FormatException('书源 rawJson 必须是 JSON 对象');
    }

    final rawRate = decoded.containsKey('concurrentRate')
        ? decoded['concurrentRate']
        : source.concurrentRate;

    final searchFields = _fields(decoded['ruleSearch']);
    final rawExplore = _fields(decoded['ruleExplore']);
    final exploreFields = Map<String, String>.unmodifiable(<String, String>{
      ...searchFields,
      ...rawExplore,
    });

    return LegadoSourceRules(
      exploreUrl: _string(decoded['exploreUrl']) ?? source.exploreUrl,
      searchUrl: _string(decoded['searchUrl']) ?? source.searchUrl,
      exploreFields: exploreFields,
      searchFields: searchFields,
      bookInfoFields: _fields(decoded['ruleBookInfo']),
      tocFields: _fields(decoded['ruleToc']),
      contentFields: _fields(decoded['ruleContent']),
      rateLimit: SourceRateLimit.parse(rawRate),
    );
  }

  static String? _string(Object? value) => value is String ? value : null;

  static Map<String, String> _fields(Object? raw) {
    if (raw is! Map) {
      return const <String, String>{};
    }
    final result = <String, String>{};
    raw.forEach((key, value) {
      if (key is String && value is String) {
        result[key] = value;
      }
    });
    return Map<String, String>.unmodifiable(result);
  }
}
