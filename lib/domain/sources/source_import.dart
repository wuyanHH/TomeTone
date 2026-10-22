import 'dart:convert';

import 'book_source.dart';
import 'url_normalizer.dart';

enum SourceImportErrorCode {
  invalidJson,
  emptyBatch,
  notObject,
  missingName,
  missingUrl,
  invalidUrl,
  unsupportedType,
  invalidHeader,
  missingRule,
  malformedRule,
  noDiscoveryOrSearch,
}

class SourceImportIssue {
  const SourceImportIssue({
    required this.index,
    required this.message,
    this.code,
  });

  final int index;
  final String message;
  final SourceImportErrorCode? code;
}

class SourceImportCandidate {
  const SourceImportCandidate({required this.index, required this.draft});

  final int index;
  final BookSourceDraft draft;
}

class SourceImportParseResult {
  const SourceImportParseResult({
    required this.candidates,
    required this.issues,
  });

  final List<SourceImportCandidate> candidates;
  final List<SourceImportIssue> issues;

  bool get hasCandidates => candidates.isNotEmpty;
  bool get hasIssues => issues.isNotEmpty;
}

abstract interface class SourceImportParser {
  SourceImportParseResult parse(String text);
}

/// 把 Legado 书源 JSON（单对象或数组）转换为 [BookSourceDraft]。
///
/// 只接受 `bookSourceType == 1` 的听书源；不做网络请求，也不会执行规则里的
/// JavaScript。未知字段原样保留在 [BookSourceDraft.rawJson]，供后续规则引擎读取。
class LegadoSourceImportParser implements SourceImportParser {
  const LegadoSourceImportParser();

  @override
  SourceImportParseResult parse(String text) {
    var input = text;
    if (input.startsWith('\uFEFF')) {
      input = input.substring(1);
    }
    input = input.trim();
    if (input.isEmpty) {
      return const SourceImportParseResult(
        candidates: <SourceImportCandidate>[],
        issues: <SourceImportIssue>[
          SourceImportIssue(
            index: 0,
            message: '导入内容为空',
            code: SourceImportErrorCode.invalidJson,
          ),
        ],
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(input);
    } on FormatException {
      return const SourceImportParseResult(
        candidates: <SourceImportCandidate>[],
        issues: <SourceImportIssue>[
          SourceImportIssue(
            index: 0,
            message: '不是合法的 JSON',
            code: SourceImportErrorCode.invalidJson,
          ),
        ],
      );
    }

    if (decoded is Map<String, dynamic>) {
      return _parseItems(<Object?>[decoded]);
    }
    if (decoded is List) {
      if (decoded.isEmpty) {
        return const SourceImportParseResult(
          candidates: <SourceImportCandidate>[],
          issues: <SourceImportIssue>[
            SourceImportIssue(
              index: 0,
              message: 'JSON 数组为空',
              code: SourceImportErrorCode.emptyBatch,
            ),
          ],
        );
      }
      return _parseItems(decoded);
    }

    return const SourceImportParseResult(
      candidates: <SourceImportCandidate>[],
      issues: <SourceImportIssue>[
        SourceImportIssue(
          index: 0,
          message: '顶层必须是 JSON 对象或数组',
          code: SourceImportErrorCode.notObject,
        ),
      ],
    );
  }

  SourceImportParseResult _parseItems(List<Object?> items) {
    final candidates = <SourceImportCandidate>[];
    final issues = <SourceImportIssue>[];

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (item is! Map) {
        issues.add(
          SourceImportIssue(
            index: index,
            message: '第 ${index + 1} 项不是 JSON 对象',
            code: SourceImportErrorCode.notObject,
          ),
        );
        continue;
      }

      final map = Map<String, dynamic>.from(item);
      final parsed = _parseOne(map, index);
      if (parsed.draft != null) {
        candidates.add(
          SourceImportCandidate(index: index, draft: parsed.draft!),
        );
      } else {
        issues.add(parsed.issue!);
      }
    }

    return SourceImportParseResult(candidates: candidates, issues: issues);
  }

  _ParsedItem _parseOne(Map<String, dynamic> map, int index) {
    final name = _nonEmptyString(map['bookSourceName']);
    if (name == null) {
      return _issue(
        index,
        '缺少书源名 bookSourceName',
        SourceImportErrorCode.missingName,
      );
    }

    final rawUrl = _nonEmptyString(map['bookSourceUrl']);
    if (rawUrl == null) {
      return _issue(
        index,
        '缺少书源地址 bookSourceUrl',
        SourceImportErrorCode.missingUrl,
      );
    }

    final String sourceUrl;
    try {
      sourceUrl = normalizeNetworkUrl(rawUrl);
    } on FormatException {
      return _issue(
        index,
        '书源地址必须是 http(s) 且包含 host',
        SourceImportErrorCode.invalidUrl,
      );
    }

    final sourceType = _asInt(map['bookSourceType']);
    if (sourceType != 1) {
      return _issue(
        index,
        '只支持 bookSourceType = 1 的听书源',
        SourceImportErrorCode.unsupportedType,
      );
    }

    final searchUrl = _nonEmptyString(map['searchUrl']);
    final exploreUrl = _nonEmptyString(map['exploreUrl']);
    if (searchUrl == null && exploreUrl == null) {
      return _issue(
        index,
        '书源至少需要 searchUrl 或 exploreUrl',
        SourceImportErrorCode.noDiscoveryOrSearch,
      );
    }

    final Map<String, String> header;
    try {
      header = _parseHeader(map['header']);
    } on FormatException {
      return _issue(
        index,
        'header 必须是 JSON 对象或对象字符串',
        SourceImportErrorCode.invalidHeader,
      );
    }

    final bookInfo = map['ruleBookInfo'];
    if (bookInfo == null) {
      return _issue(
        index,
        '缺少 ruleBookInfo',
        SourceImportErrorCode.missingRule,
      );
    }
    if (bookInfo is! Map) {
      return _issue(
        index,
        'ruleBookInfo 必须是对象',
        SourceImportErrorCode.malformedRule,
      );
    }

    final toc = map['ruleToc'];
    if (toc is! Map ||
        !_hasRule(toc, 'chapterList') ||
        !_hasRule(toc, 'chapterName') ||
        !_hasRule(toc, 'chapterUrl')) {
      return _issue(
        index,
        'ruleToc 必须包含 chapterList / chapterName / chapterUrl',
        SourceImportErrorCode.malformedRule,
      );
    }

    final content = map['ruleContent'];
    if (content is! Map || !_hasRule(content, 'content')) {
      return _issue(
        index,
        'ruleContent 必须包含 content',
        SourceImportErrorCode.malformedRule,
      );
    }

    if (searchUrl != null) {
      final search = map['ruleSearch'];
      if (search is! Map ||
          !_hasRule(search, 'bookList') ||
          !_hasRule(search, 'name') ||
          !_hasRule(search, 'bookUrl')) {
        return _issue(
          index,
          '有 searchUrl 时 ruleSearch 必须包含 bookList / name / bookUrl',
          SourceImportErrorCode.malformedRule,
        );
      }
    }

    if (exploreUrl != null) {
      final explore = map['ruleExplore'];
      final search = map['ruleSearch'];
      final hasExploreRules = explore is Map &&
          _hasRule(explore, 'bookList') &&
          _hasRule(explore, 'name') &&
          _hasRule(explore, 'bookUrl');
      final canInheritFromSearch = search is Map &&
          _hasRule(search, 'bookList') &&
          _hasRule(search, 'name') &&
          _hasRule(search, 'bookUrl');

      if (!hasExploreRules && !canInheritFromSearch) {
        return _issue(
          index,
          '有 exploreUrl 时 ruleExplore（或继承 ruleSearch）必须包含 bookList / name / bookUrl',
          SourceImportErrorCode.malformedRule,
        );
      }
    }

    return _ParsedItem(
      draft: BookSourceDraft(
        name: name,
        sourceUrl: sourceUrl,
        sourceType: 1,
        rawJson: jsonEncode(map),
        header: header,
        groupName: _nonEmptyString(map['bookSourceGroup']),
        exploreUrl: exploreUrl,
        searchUrl: searchUrl,
        jsLib: _nonEmptyString(map['jsLib']),
        enabled: _asBool(map['enabled'], fallback: true),
        enabledExplore: _asBool(map['enabledExplore'], fallback: true),
        customOrder: _asInt(map['customOrder']) ?? 0,
        concurrentRate: _asInt(map['concurrentRate']),
      ),
    );
  }

  _ParsedItem _issue(int index, String message, SourceImportErrorCode code) {
    return _ParsedItem(
      issue: SourceImportIssue(index: index, message: message, code: code),
    );
  }

  Map<String, String> _parseHeader(Object? value) {
    if (value == null) {
      return const <String, String>{};
    }

    Object? decoded = value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return const <String, String>{};
      }
      decoded = jsonDecode(trimmed);
    }

    if (decoded is! Map) {
      throw const FormatException('header must be a JSON object');
    }

    final result = <String, String>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String) {
        throw const FormatException('header key must be a string');
      }
      final headerValue = entry.value;
      if (headerValue is Map || headerValue is List) {
        throw const FormatException('header value must be scalar');
      }
      result[entry.key as String] = headerValue?.toString() ?? '';
    }
    return result;
  }
}

class _ParsedItem {
  const _ParsedItem({this.draft, this.issue});

  final BookSourceDraft? draft;
  final SourceImportIssue? issue;
}

String? _nonEmptyString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

bool _asBool(Object? value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }
  }
  return fallback;
}

bool _hasRule(Map<dynamic, dynamic> rule, String key) {
  final value = rule[key];
  return value is String && value.trim().isNotEmpty;
}
