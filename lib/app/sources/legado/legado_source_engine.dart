import 'dart:convert';

import '../../../contracts/sources/js_runtime.dart';
import '../source_engine.dart';
import '../../../contracts/sources/source_http.dart';
import '../../../domain/sources/book_source.dart';
import '../../../domain/sources/discovery/explore_category.dart';
import '../../../domain/sources/discovery/source_failure.dart';
import '../../../domain/sources/discovery/source_models.dart';
import '../../../domain/sources/rules/rule_context.dart';
import '../../../domain/sources/rules/rule_error.dart';
import '../../../domain/sources/rules/template_rule.dart';
import '../../../domain/sources/url_normalizer.dart';
import '../source_rate_limiter.dart';
import 'legado_request.dart';
import 'legado_rule_evaluator.dart';
import 'legado_source_rules.dart';
import 'source_charset.dart';

/// Legado 听书源的 SourceEngine 实现。
class LegadoSourceEngine implements SourceEngine {
  LegadoSourceEngine({
    required SourceHttpClient http,
    required JsRuntime jsRuntime,
    required SourceRateLimiter rateLimiter,
  }) : _http = http,
       _jsRuntime = jsRuntime,
       _rateLimiter = rateLimiter;

  final SourceHttpClient _http;
  final JsRuntime _jsRuntime;
  final SourceRateLimiter _rateLimiter;

  @override
  Future<SourcePage<SourceBookSummary>> explore(
    BookSource source,
    ExploreCategory category,
    int page,
  ) async {
    final rules = _parseRules(source, SourceStage.explore);
    try {
      final rendered = SyncTemplateRenderer(
        resolve: (expression) => expression.trim() == 'page' ? page : null,
      ).render(category.urlTemplate, mode: TemplateOutputMode.url);
      final fetched = await _fetch(
        source: source,
        stage: SourceStage.explore,
        rules: rules,
        raw: rendered,
        baseUrl: _sourceUri(source),
        page: page,
      );
      final parsed = await _parseBookList(
        source: source,
        fields: rules.exploreFields,
        fetched: fetched,
        stage: SourceStage.explore,
        page: page,
      );
      return SourcePage<SourceBookSummary>(
        items: List<SourceBookSummary>.unmodifiable(parsed.items),
        hasMore: parsed.rawCount > 0,
        finalUrl: fetched.response.finalUrl,
        warnings: List<String>.unmodifiable(parsed.warnings),
      );
    } on SourceFailure {
      rethrow;
    } on Object catch (error) {
      throw _mapFailure(error, SourceStage.explore);
    }
  }

  @override
  Future<SourcePage<SourceBookSummary>> search(
    BookSource source,
    String keyword,
    int page,
  ) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      throw const SourceFailure(
        kind: SourceFailureKind.empty,
        stage: SourceStage.search,
        message: '没有结果',
      );
    }

    final rules = _parseRules(source, SourceStage.search);
    final raw = rules.searchUrl;
    if (raw == null || raw.trim().isEmpty) {
      throw const SourceFailure(
        kind: SourceFailureKind.rule,
        stage: SourceStage.search,
        message: '书源规则无法解析',
      );
    }

    try {
      final fetched = await _fetch(
        source: source,
        stage: SourceStage.search,
        rules: rules,
        raw: raw,
        baseUrl: _sourceUri(source),
        key: trimmed,
        page: page,
      );
      final parsed = await _parseBookList(
        source: source,
        fields: rules.searchFields,
        fetched: fetched,
        stage: SourceStage.search,
        page: page,
        key: trimmed,
      );
      return SourcePage<SourceBookSummary>(
        items: List<SourceBookSummary>.unmodifiable(parsed.items),
        hasMore: parsed.rawCount > 0,
        finalUrl: fetched.response.finalUrl,
        warnings: List<String>.unmodifiable(parsed.warnings),
      );
    } on SourceFailure {
      rethrow;
    } on Object catch (error) {
      throw _mapFailure(error, SourceStage.search);
    }
  }

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) async {
    final rules = _parseRules(source, SourceStage.bookInfo);
    try {
      final fetched = await _fetch(
        source: source,
        stage: SourceStage.bookInfo,
        rules: rules,
        raw: bookUrl,
        baseUrl: _sourceUri(source),
      );
      final context = _context(
        source: source,
        result: fetched.json,
        baseUrl: fetched.response.finalUrl.toString(),
      );
      final fields = rules.bookInfoFields;
      final title =
          _text(await _evaluateOptional(fields['name'], context)) ??
          _urlFallback(fetched.response.finalUrl);
      final normalizedBookUrl = _normalizeOrFallback(
        fetched.response.finalUrl,
        bookUrl,
      );
      final tocValue = _text(
        await _evaluateOptional(fields['tocUrl'], context),
      );
      final tocUrl = tocValue == null
          ? normalizedBookUrl
          : _normalizeOrFallback(
              fetched.response.finalUrl,
              _stripOptions(tocValue),
              fallback: normalizedBookUrl,
            );

      return SourceBookInfo(
        title: title,
        bookUrl: normalizedBookUrl,
        tocUrl: tocUrl,
        author: _text(await _evaluateOptional(fields['author'], context)),
        narrator: _text(await _evaluateOptional(fields['narrator'], context)),
        coverUrl: _resolveOptionalUrl(
          await _evaluateOptional(fields['coverUrl'], context),
          fetched.response.finalUrl,
        ),
        intro: _text(await _evaluateOptional(fields['intro'], context)),
        kind: _text(await _evaluateOptional(fields['kind'], context)),
        wordCount: _text(await _evaluateOptional(fields['wordCount'], context)),
        lastChapter: _text(
          await _evaluateOptional(fields['lastChapter'], context),
        ),
        status: _text(await _evaluateOptional(fields['status'], context)),
      );
    } on SourceFailure {
      rethrow;
    } on Object catch (error) {
      throw _mapFailure(error, SourceStage.bookInfo);
    }
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) async {
    final rules = _parseRules(source, SourceStage.toc);
    final chapters = <SourceChapter>[];
    final warnings = <String>[];
    final visited = <String>{};
    var current = info.tocUrl;
    var complete = true;

    for (var pageIndex = 0; pageIndex < 50; pageIndex++) {
      final normalizedCurrent = _normalizeOrNull(
        _stripOptions(current),
        _sourceUri(source),
      );
      if (normalizedCurrent != null && !visited.add(normalizedCurrent)) {
        complete = false;
        warnings.add('目录链接循环');
        break;
      }

      _Fetched fetched;
      try {
        fetched = await _fetch(
          source: source,
          stage: SourceStage.toc,
          rules: rules,
          raw: current,
          baseUrl: _sourceUri(source),
        );
      } on Object catch (error) {
        if (pageIndex == 0) {
          throw _mapFailure(error, SourceStage.toc);
        }
        complete = false;
        warnings.add('目录第 ${pageIndex + 1} 页加载失败');
        break;
      }

      try {
        final listRule = _requiredRule(
          rules.tocFields,
          'chapterList',
          SourceStage.toc,
        );
        final rawList = await _evaluate(
          listRule,
          _context(
            source: source,
            result: fetched.json,
            baseUrl: fetched.response.finalUrl.toString(),
          ),
        );
        final rawItems = _asItems(rawList);

        for (var itemIndex = 0; itemIndex < rawItems.length; itemIndex++) {
          final item = rawItems[itemIndex];
          final context = _context(
            source: source,
            result: item,
            baseUrl: fetched.response.finalUrl.toString(),
          );
          final rawUrl = _text(
            await _evaluateOptional(rules.tocFields['chapterUrl'], context),
          );
          if (rawUrl == null) {
            warnings.add('第 ${pageIndex + 1} 页第 ${itemIndex + 1} 章缺少地址');
            continue;
          }

          final normalized = _normalizeOrNull(
            _stripOptions(rawUrl),
            fetched.response.finalUrl,
          );
          if (normalized == null) {
            warnings.add('第 ${pageIndex + 1} 页第 ${itemIndex + 1} 章地址无效');
            continue;
          }

          final title =
              _text(
                await _evaluateOptional(
                  rules.tocFields['chapterName'],
                  context,
                ),
              ) ??
              '第 ${chapters.length + 1} 章';
          final vipValue = await _evaluateOptional(
            rules.tocFields['isVip'],
            context,
          );

          chapters.add(
            SourceChapter(
              index: chapters.length,
              title: title,
              rawUrl: rawUrl,
              url: normalized,
              isVip: _asBool(vipValue),
            ),
          );
        }
      } on SourceFailure {
        if (pageIndex == 0) {
          rethrow;
        }
        complete = false;
        warnings.add('目录第 ${pageIndex + 1} 页解析失败');
        break;
      } on Object catch (error) {
        if (pageIndex == 0) {
          throw _mapFailure(error, SourceStage.toc);
        }
        complete = false;
        warnings.add('目录第 ${pageIndex + 1} 页解析失败');
        break;
      }

      final Object? nextEvaluated;
      try {
        nextEvaluated = await _evaluateOptional(
          rules.tocFields['nextTocUrl'],
          _context(
            source: source,
            result: fetched.json,
            baseUrl: fetched.response.finalUrl.toString(),
          ),
        );
      } on Object catch (error) {
        if (pageIndex == 0) {
          throw _mapFailure(error, SourceStage.toc);
        }
        complete = false;
        warnings.add('目录第 ${pageIndex + 1} 页链接解析失败');
        break;
      }
      final nextValue = _text(nextEvaluated);
      if (nextValue == null) {
        complete = true;
        break;
      }

      final next = _normalizeOrNull(
        _stripOptions(nextValue),
        fetched.response.finalUrl,
      );
      if (next == null) {
        complete = false;
        warnings.add('目录下一页地址无效');
        break;
      }
      if (visited.contains(next)) {
        complete = false;
        warnings.add('目录链接循环');
        break;
      }
      if (pageIndex == 49) {
        complete = false;
        warnings.add('目录超过 50 页上限');
        break;
      }
      current = next;
    }

    return SourceToc(
      chapters: List<SourceChapter>.unmodifiable(chapters),
      complete: complete,
      warnings: List<String>.unmodifiable(warnings),
    );
  }

  @override
  Future<SourceTestReport> test(BookSource source) async {
    final stopwatch = Stopwatch()..start();
    try {
      final categories = parseExploreCategories(
        exploreUrl: source.exploreUrl,
        enabledExplore: source.enabledExplore,
      );
      final SourcePage<SourceBookSummary> page;
      if (categories.isNotEmpty) {
        page = await explore(source, categories.first, 1);
      } else {
        page = await search(source, '测试', 1);
      }
      stopwatch.stop();
      return SourceTestReport(
        latency: stopwatch.elapsed,
        resultCount: page.items.length,
        sampleTitle: page.items.isEmpty ? null : page.items.first.title,
      );
    } on SourceFailure catch (failure) {
      throw SourceFailure(
        kind: failure.kind,
        stage: SourceStage.test,
        message: failure.message,
        statusCode: failure.statusCode,
      );
    } on Object catch (error) {
      throw _mapFailure(error, SourceStage.test);
    }
  }

  LegadoSourceRules _parseRules(BookSource source, SourceStage stage) {
    try {
      return LegadoSourceRules.parse(source);
    } on Object {
      throw SourceFailure(
        kind: SourceFailureKind.rule,
        stage: stage,
        message: '书源规则无法解析',
      );
    }
  }

  Future<_Fetched> _fetch({
    required BookSource source,
    required SourceStage stage,
    required LegadoSourceRules rules,
    required String raw,
    required Uri baseUrl,
    String? key,
    int? page,
  }) async {
    LegadoRequest request;
    try {
      request = const LegadoRequestBuilder().build(
        raw: raw,
        baseUrl: baseUrl,
        sourceHeaders: source.header,
        key: key,
        page: page,
      );
    } on Object {
      throw SourceFailure(
        kind: SourceFailureKind.rule,
        stage: stage,
        message: '书源规则无法解析',
      );
    }

    try {
      await _rateLimiter.acquire(source.id, rules.rateLimit);
      final response = await _http.send(
        SourceHttpRequest(
          url: request.url,
          method: request.method,
          headers: request.headers,
          body: request.body,
        ),
      );
      _checkStatus(response.statusCode, stage);
      final text = _decode(response, request, stage);
      final Object? json;
      try {
        json = jsonDecode(text);
      } on FormatException {
        throw SourceFailure(
          kind: SourceFailureKind.json,
          stage: stage,
          message: '返回内容不是有效 JSON',
        );
      }
      return _Fetched(request: request, response: response, json: json);
    } on SourceFailure {
      rethrow;
    } on Object catch (error) {
      throw _mapFailure(error, stage);
    }
  }

  String _decode(
    SourceHttpResponse response,
    LegadoRequest request,
    SourceStage stage,
  ) {
    try {
      return decodeSourceBytes(
        response.bytes,
        declaredCharset: request.charset,
        contentType: response.headers['content-type'],
      );
    } on FormatException {
      throw SourceFailure(
        kind: SourceFailureKind.encoding,
        stage: stage,
        message: '文本编码无法识别',
      );
    }
  }

  void _checkStatus(int statusCode, SourceStage stage) {
    if (statusCode == 401 || statusCode == 403) {
      throw SourceFailure(
        kind: SourceFailureKind.authRequired,
        stage: stage,
        message: '需要登录或会话已失效',
        statusCode: statusCode,
      );
    }
    if (statusCode < 200 || statusCode >= 300) {
      throw SourceFailure(
        kind: SourceFailureKind.httpStatus,
        stage: stage,
        message: '服务返回 HTTP $statusCode',
        statusCode: statusCode,
      );
    }
  }

  Future<_ParsedBooks> _parseBookList({
    required BookSource source,
    required Map<String, String> fields,
    required _Fetched fetched,
    required SourceStage stage,
    int? page,
    String? key,
  }) async {
    try {
      final listRule = _requiredRule(fields, 'bookList', stage);
      final rawList = await _evaluate(
        listRule,
        _context(
          source: source,
          result: fetched.json,
          baseUrl: fetched.response.finalUrl.toString(),
          page: page,
          key: key,
        ),
      );
      final rawItems = _asItems(rawList);
      final warnings = <String>[];
      final seen = <String>{};
      final items = <SourceBookSummary>[];

      for (var index = 0; index < rawItems.length; index++) {
        final context = _context(
          source: source,
          result: rawItems[index],
          baseUrl: fetched.response.finalUrl.toString(),
          page: page,
          key: key,
        );
        final title = _text(await _evaluateOptional(fields['name'], context));
        final rawBookUrl = _text(
          await _evaluateOptional(fields['bookUrl'], context),
        );
        if (title == null || rawBookUrl == null) {
          warnings.add('第 ${index + 1} 条书目缺少标题或地址');
          continue;
        }
        final bookUrl = _normalizeOrNull(
          _stripOptions(rawBookUrl),
          fetched.response.finalUrl,
        );
        if (bookUrl == null) {
          warnings.add('第 ${index + 1} 条书目地址无效');
          continue;
        }
        if (!seen.add(bookUrl)) {
          continue;
        }

        items.add(
          SourceBookSummary(
            title: title,
            bookUrl: bookUrl,
            author: _text(await _evaluateOptional(fields['author'], context)),
            narrator: _text(
              await _evaluateOptional(fields['narrator'], context),
            ),
            coverUrl: _resolveOptionalUrl(
              await _evaluateOptional(fields['coverUrl'], context),
              fetched.response.finalUrl,
            ),
            intro: _text(await _evaluateOptional(fields['intro'], context)),
            kind: _text(await _evaluateOptional(fields['kind'], context)),
            wordCount: _text(
              await _evaluateOptional(fields['wordCount'], context),
            ),
            lastChapter: _text(
              await _evaluateOptional(fields['lastChapter'], context),
            ),
            status: _text(await _evaluateOptional(fields['status'], context)),
          ),
        );
      }

      return _ParsedBooks(
        items: items,
        rawCount: rawItems.length,
        warnings: warnings,
      );
    } on SourceFailure {
      rethrow;
    } on Object catch (error) {
      throw _mapFailure(error, stage);
    }
  }

  Future<Object?> _evaluate(String rule, RuleEvaluationContext context) {
    return LegadoRuleEvaluator(jsRuntime: _jsRuntime).evaluate(rule, context);
  }

  Future<Object?> _evaluateOptional(
    String? rule,
    RuleEvaluationContext context,
  ) {
    if (rule == null || rule.trim().isEmpty) {
      return Future<Object?>.value();
    }
    return _evaluate(rule, context);
  }

  RuleEvaluationContext _context({
    required BookSource source,
    required Object? result,
    required String baseUrl,
    int? page,
    String? key,
  }) {
    return RuleEvaluationContext(
      result: result,
      baseUrl: baseUrl,
      page: page,
      key: key,
      source: <String, Object?>{
        'name': source.name,
        'sourceUrl': source.sourceUrl,
      },
    );
  }

  String _requiredRule(
    Map<String, String> fields,
    String name,
    SourceStage stage,
  ) {
    final rule = fields[name];
    if (rule == null || rule.trim().isEmpty) {
      throw SourceFailure(
        kind: SourceFailureKind.rule,
        stage: stage,
        message: '书源规则无法解析',
      );
    }
    return rule;
  }

  List<Object?> _asItems(Object? value) {
    if (value is List) {
      return value;
    }
    if (value is Map) {
      return <Object?>[value];
    }
    return const <Object?>[];
  }

  String? _text(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  String? _resolveOptionalUrl(Object? value, Uri base) {
    final text = _text(value);
    if (text == null) {
      return null;
    }
    return _normalizeOrNull(_stripOptions(text), base);
  }

  String? _normalizeOrNull(String raw, Uri base) {
    try {
      return normalizeNetworkUrl(raw, baseUrl: base);
    } on FormatException {
      return null;
    }
  }

  String _normalizeOrFallback(Uri base, String raw, {String? fallback}) {
    return _normalizeOrNull(_stripOptions(raw), base) ??
        fallback ??
        _urlFallback(base);
  }

  String _urlFallback(Uri url) {
    final path = url.path == '/' ? '' : url.path;
    final host = url.host.isEmpty ? url.toString() : url.host;
    return '$host$path';
  }

  String _stripOptions(String raw) {
    final index = raw.lastIndexOf(',{');
    if (index >= 0) {
      try {
        final decoded = jsonDecode(raw.substring(index + 1));
        if (decoded is Map) {
          return raw.substring(0, index).trim();
        }
      } on FormatException {
        // 不是 options，按原 URL 处理。
      }
    }
    return raw.trim();
  }

  Uri _sourceUri(BookSource source) => Uri.parse(source.sourceUrl);

  bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == '是';
    }
    return false;
  }

  SourceFailure _mapFailure(Object error, SourceStage stage) {
    if (error is SourceFailure) {
      return error;
    }
    if (error is SourceTransportException) {
      switch (error.failure) {
        case SourceTransportFailure.timeout:
          return SourceFailure(
            kind: SourceFailureKind.timeout,
            stage: stage,
            message: '请求超时',
          );
        case SourceTransportFailure.invalidUrl:
          return SourceFailure(
            kind: SourceFailureKind.rule,
            stage: stage,
            message: '书源规则无法解析',
          );
        case SourceTransportFailure.network:
        case SourceTransportFailure.tooLarge:
        case SourceTransportFailure.redirect:
          return SourceFailure(
            kind: SourceFailureKind.network,
            stage: stage,
            message: '网络不可用',
          );
      }
    }
    if (error is RuleEvaluationException) {
      return SourceFailure(
        kind: SourceFailureKind.rule,
        stage: stage,
        message: '书源规则无法解析',
      );
    }
    if (error is FormatException) {
      return SourceFailure(
        kind: SourceFailureKind.encoding,
        stage: stage,
        message: '文本编码无法识别',
      );
    }
    if (error is JsRuntimeException) {
      return SourceFailure(
        kind: SourceFailureKind.rule,
        stage: stage,
        message: '书源规则无法解析',
      );
    }
    return SourceFailure(
      kind: SourceFailureKind.rule,
      stage: stage,
      message: '书源规则无法解析',
    );
  }
}

class _Fetched {
  const _Fetched({
    required this.request,
    required this.response,
    required this.json,
  });

  final LegadoRequest request;
  final SourceHttpResponse response;
  final Object? json;
}

class _ParsedBooks {
  const _ParsedBooks({
    required this.items,
    required this.rawCount,
    required this.warnings,
  });

  final List<SourceBookSummary> items;
  final int rawCount;
  final List<String> warnings;
}
