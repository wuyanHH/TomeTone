import '../../domain/sources/book_source.dart';
import '../../domain/sources/book_source_queries.dart';
import '../../domain/sources/discovery/explore_category.dart';
import '../../domain/sources/discovery/source_failure.dart';
import '../../domain/sources/discovery/source_models.dart';
import 'source_engine.dart';

/// 在线发现编排：在引擎之外记录源级健康，并统一错误文案。
abstract interface class SourceDiscovery implements SourceEngine {}

class SourceDiscoveryService implements SourceDiscovery {
  SourceDiscoveryService({
    required SourceEngine engine,
    required BookSourceQueries sources,
    DateTime Function()? clock,
  }) : _engine = engine,
       _sources = sources,
       _clock = clock ?? DateTime.now;

  final SourceEngine _engine;
  final BookSourceQueries _sources;
  final DateTime Function() _clock;

  @override
  Future<SourcePage<SourceBookSummary>> explore(
    BookSource source,
    ExploreCategory category,
    int page,
  ) async {
    try {
      final result = await _engine.explore(source, category, page);
      await _record(source, ok: true);
      return result;
    } on SourceFailure catch (failure) {
      final normalized = _normalize(failure);
      await _record(source, ok: false, error: normalized.message);
      throw normalized;
    } on Object {
      final failure = const SourceFailure(
        kind: SourceFailureKind.rule,
        stage: SourceStage.explore,
        message: '书源规则无法解析',
      );
      await _record(source, ok: false, error: failure.message);
      throw failure;
    }
  }

  @override
  Future<SourcePage<SourceBookSummary>> search(
    BookSource source,
    String keyword,
    int page,
  ) async {
    try {
      final result = await _engine.search(source, keyword, page);
      await _record(source, ok: true);
      return result;
    } on SourceFailure catch (failure) {
      final normalized = _normalize(failure);
      await _record(source, ok: false, error: normalized.message);
      throw normalized;
    } on Object {
      final failure = const SourceFailure(
        kind: SourceFailureKind.rule,
        stage: SourceStage.search,
        message: '书源规则无法解析',
      );
      await _record(source, ok: false, error: failure.message);
      throw failure;
    }
  }

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) async {
    try {
      return await _engine.bookInfo(source, bookUrl);
    } on SourceFailure catch (failure) {
      throw _normalize(failure);
    } on Object {
      throw const SourceFailure(
        kind: SourceFailureKind.rule,
        stage: SourceStage.bookInfo,
        message: '书源规则无法解析',
      );
    }
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) async {
    try {
      return await _engine.toc(source, info);
    } on SourceFailure catch (failure) {
      throw _normalize(failure);
    } on Object {
      throw const SourceFailure(
        kind: SourceFailureKind.rule,
        stage: SourceStage.toc,
        message: '书源规则无法解析',
      );
    }
  }

  @override
  Future<SourceTestReport> test(BookSource source) async {
    try {
      final result = await _engine.test(source);
      await _record(source, ok: true);
      return result;
    } on SourceFailure catch (failure) {
      final normalized = _normalize(failure);
      await _record(source, ok: false, error: normalized.message);
      throw normalized;
    } on Object {
      final failure = const SourceFailure(
        kind: SourceFailureKind.rule,
        stage: SourceStage.test,
        message: '书源规则无法解析',
      );
      await _record(source, ok: false, error: failure.message);
      throw failure;
    }
  }

  Future<void> _record(BookSource source, {required bool ok, String? error}) {
    return _sources.recordProbe(
      source.id,
      ok: ok,
      error: error,
      checkedAt: _clock(),
    );
  }

  SourceFailure _normalize(SourceFailure failure) {
    return SourceFailure(
      kind: failure.kind,
      stage: failure.stage,
      message: _message(failure),
      statusCode: failure.statusCode,
    );
  }

  String _message(SourceFailure failure) {
    switch (failure.kind) {
      case SourceFailureKind.network:
        return '网络不可用';
      case SourceFailureKind.timeout:
        return '请求超时';
      case SourceFailureKind.httpStatus:
        final code = failure.statusCode;
        return code == null ? '服务返回 HTTP' : '服务返回 HTTP $code';
      case SourceFailureKind.encoding:
        return '文本编码无法识别';
      case SourceFailureKind.json:
        return '返回内容不是有效 JSON';
      case SourceFailureKind.rule:
        return '书源规则无法解析';
      case SourceFailureKind.authRequired:
        return '需要登录或会话已失效';
      case SourceFailureKind.vipRequired:
        return '该内容需要会员';
      case SourceFailureKind.empty:
        return '没有结果';
      case SourceFailureKind.aborted:
        return '已取消';
    }
  }
}
