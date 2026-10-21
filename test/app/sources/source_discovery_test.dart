import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/book_source_service.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/app/sources/source_engine.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/book_source_queries.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';
import 'package:tometone/domain/sources/discovery/source_failure.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';

const ExploreCategory _category = ExploreCategory(
  name: '热门',
  urlTemplate: 'https://www.tingyou.fm/api/explore/hot?page={{page}}',
);

class _FakeEngine implements SourceEngine {
  Object? error;
  SourcePage<SourceBookSummary>? explorePage;
  SourcePage<SourceBookSummary>? searchPage;
  SourceBookInfo? info;
  SourceToc? tocResult;
  SourceTestReport? testReport;
  int exploreCalls = 0;
  int searchCalls = 0;
  int bookInfoCalls = 0;
  int tocCalls = 0;
  int testCalls = 0;

  SourcePage<SourceBookSummary> _emptyPage() {
    return SourcePage<SourceBookSummary>(
      items: const <SourceBookSummary>[],
      hasMore: false,
      finalUrl: Uri.parse('https://www.tingyou.fm/api'),
    );
  }

  @override
  Future<SourcePage<SourceBookSummary>> explore(
    BookSource source,
    ExploreCategory category,
    int page,
  ) async {
    exploreCalls++;
    if (error != null) {
      throw error!;
    }
    return explorePage ?? _emptyPage();
  }

  @override
  Future<SourcePage<SourceBookSummary>> search(
    BookSource source,
    String keyword,
    int page,
  ) async {
    searchCalls++;
    if (error != null) {
      throw error!;
    }
    return searchPage ?? _emptyPage();
  }

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) async {
    bookInfoCalls++;
    if (error != null) {
      throw error!;
    }
    return info ??
        SourceBookInfo(
          title: '书名',
          bookUrl: bookUrl,
          tocUrl: 'https://www.tingyou.fm/api/chapters/1',
        );
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) async {
    tocCalls++;
    if (error != null) {
      throw error!;
    }
    return tocResult ??
        const SourceToc(chapters: <SourceChapter>[], complete: true);
  }

  @override
  Future<SourceTestReport> test(BookSource source) async {
    testCalls++;
    if (error != null) {
      throw error!;
    }
    return testReport ??
        const SourceTestReport(
          latency: Duration(milliseconds: 5),
          resultCount: 0,
        );
  }
}

void main() {
  late TomeToneDatabase db;
  late DriftBookSourceQueries queries;
  late BookSource source;
  late DateTime importedAt;

  setUp(() async {
    db = TomeToneDatabase(NativeDatabase.memory());
    queries = DriftBookSourceQueries(db);
    importedAt = DateTime.utc(2026, 10, 21, 10);
    final importer = BookSourceService(
      database: db,
      queries: queries,
      idGenerator: UlidIdGenerator(random: Random(1), clock: () => importedAt),
      clock: () => importedAt,
    );
    final outcomes = await importer.importText(
      File('test/fixtures/sources/tingyou/source.json').readAsStringSync(),
    );
    source = (await queries.sourceById(outcomes.single.sourceId!))!;
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftBookSourceQueries.recordProbe', () {
    test('失败累加、成功清零，且不更新 updatedAt', () async {
      final first = DateTime.utc(2026, 10, 22, 8);
      final second = DateTime.utc(2026, 10, 22, 9);
      final third = DateTime.utc(2026, 10, 22, 10);

      await queries.recordProbe(
        source.id,
        ok: false,
        error: '网络不可用',
        checkedAt: first,
      );
      var updated = (await queries.sourceById(source.id))!;
      expect(updated.lastTestAt!.toUtc(), first);
      expect(updated.lastTestOk, isFalse);
      expect(updated.lastError, '网络不可用');
      expect(updated.consecutiveFailures, 1);
      expect(updated.updatedAt.toUtc(), importedAt);

      await queries.recordProbe(
        source.id,
        ok: false,
        error: '请求超时',
        checkedAt: second,
      );
      updated = (await queries.sourceById(source.id))!;
      expect(updated.lastTestAt!.toUtc(), second);
      expect(updated.lastError, '请求超时');
      expect(updated.consecutiveFailures, 2);
      expect(updated.updatedAt.toUtc(), importedAt);

      await queries.recordProbe(source.id, ok: true, checkedAt: third);
      updated = (await queries.sourceById(source.id))!;
      expect(updated.lastTestAt!.toUtc(), third);
      expect(updated.lastTestOk, isTrue);
      expect(updated.lastError, isNull);
      expect(updated.consecutiveFailures, 0);
      expect(updated.updatedAt.toUtc(), importedAt);
    });

    test('未知 sourceId 抛 StateError', () async {
      await expectLater(
        queries.recordProbe('missing', ok: true),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('SourceDiscoveryService 健康记录', () {
    late _FakeEngine engine;
    late SourceDiscoveryService service;
    late DateTime probeAt;

    setUp(() {
      engine = _FakeEngine();
      probeAt = DateTime.utc(2026, 10, 23, 12);
      service = SourceDiscoveryService(
        engine: engine,
        sources: queries,
        clock: () => probeAt,
      );
    });

    test('explore / search / test 成功写成功探测', () async {
      await service.explore(source, _category, 1);
      var updated = (await queries.sourceById(source.id))!;
      expect(updated.lastTestAt!.toUtc(), probeAt);
      expect(updated.lastTestOk, isTrue);
      expect(updated.lastError, isNull);
      expect(updated.consecutiveFailures, 0);
      expect(updated.updatedAt.toUtc(), importedAt);

      await service.search(source, '关键词', 1);
      updated = (await queries.sourceById(source.id))!;
      expect(updated.lastTestAt!.toUtc(), probeAt);
      expect(updated.lastTestOk, isTrue);

      await service.test(source);
      updated = (await queries.sourceById(source.id))!;
      expect(updated.lastTestAt!.toUtc(), probeAt);
      expect(updated.lastTestOk, isTrue);
      expect(engine.exploreCalls, 1);
      expect(engine.searchCalls, 1);
      expect(engine.testCalls, 1);
    });

    test('失败连续累加，且错误文案归一化', () async {
      engine.error = const SourceFailure(
        kind: SourceFailureKind.network,
        stage: SourceStage.explore,
        message: '底层细节不应泄露',
      );
      await expectLater(
        service.explore(source, _category, 1),
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.message,
            'message',
            '网络不可用',
          ),
        ),
      );
      var updated = (await queries.sourceById(source.id))!;
      expect(updated.lastTestOk, isFalse);
      expect(updated.lastError, '网络不可用');
      expect(updated.consecutiveFailures, 1);

      engine.error = const SourceFailure(
        kind: SourceFailureKind.timeout,
        stage: SourceStage.explore,
        message: '底层细节不应泄露',
      );
      await expectLater(
        service.explore(source, _category, 1),
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.message,
            'message',
            '请求超时',
          ),
        ),
      );
      updated = (await queries.sourceById(source.id))!;
      expect(updated.lastError, '请求超时');
      expect(updated.consecutiveFailures, 2);
    });

    test('错误分类文案完整且 HTTP 只保留 code', () async {
      final expected = <SourceFailureKind, String>{
        SourceFailureKind.network: '网络不可用',
        SourceFailureKind.timeout: '请求超时',
        SourceFailureKind.authRequired: '需要登录或会话已失效',
        SourceFailureKind.vipRequired: '该内容需要会员',
        SourceFailureKind.json: '返回内容不是有效 JSON',
        SourceFailureKind.rule: '书源规则无法解析',
        SourceFailureKind.encoding: '文本编码无法识别',
        SourceFailureKind.empty: '没有结果',
        SourceFailureKind.aborted: '已取消',
      };

      for (final entry in expected.entries) {
        engine.error = SourceFailure(
          kind: entry.key,
          stage: SourceStage.explore,
          message: 'raw ${entry.key.name}',
        );
        await expectLater(
          service.explore(source, _category, 1),
          throwsA(
            isA<SourceFailure>().having(
              (failure) => failure.message,
              'message',
              entry.value,
            ),
          ),
          reason: entry.key.name,
        );
        final updated = (await queries.sourceById(source.id))!;
        expect(updated.lastError, entry.value);
      }

      engine.error = const SourceFailure(
        kind: SourceFailureKind.httpStatus,
        stage: SourceStage.explore,
        message: '服务端响应 body',
        statusCode: 503,
      );
      await expectLater(
        service.explore(source, _category, 1),
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.message,
            'message',
            '服务返回 HTTP 503',
          ),
        ),
      );
      final updated = (await queries.sourceById(source.id))!;
      expect(updated.lastError, '服务返回 HTTP 503');
    });

    test('非 SourceFailure 包成 rule，不泄露原始消息', () async {
      engine.error = StateError('session=secret');
      await expectLater(
        service.explore(source, _category, 1),
        throwsA(
          isA<SourceFailure>()
              .having((failure) => failure.kind, 'kind', SourceFailureKind.rule)
              .having((failure) => failure.message, 'message', '书源规则无法解析'),
        ),
      );
      final updated = (await queries.sourceById(source.id))!;
      expect(updated.lastError, '书源规则无法解析');
      expect(updated.lastError, isNot(contains('secret')));
    });

    test('test 失败记录为 test stage', () async {
      engine.error = const SourceFailure(
        kind: SourceFailureKind.authRequired,
        stage: SourceStage.test,
        message: 'raw',
      );
      await expectLater(
        service.test(source),
        throwsA(
          isA<SourceFailure>()
              .having((failure) => failure.stage, 'stage', SourceStage.test)
              .having((failure) => failure.message, 'message', '需要登录或会话已失效'),
        ),
      );
      final updated = (await queries.sourceById(source.id))!;
      expect(updated.lastTestOk, isFalse);
      expect(updated.lastError, '需要登录或会话已失效');
    });

    test('bookInfo / toc 成功和失败都不写健康', () async {
      final info = await service.bookInfo(
        source,
        'https://www.tingyou.fm/book/1',
      );
      final toc = await service.toc(source, info);
      expect(toc.complete, isTrue);

      var updated = (await queries.sourceById(source.id))!;
      expect(updated.lastTestAt, isNull);
      expect(updated.lastTestOk, isNull);
      expect(updated.consecutiveFailures, 0);
      expect(updated.updatedAt.toUtc(), importedAt);

      engine.error = const SourceFailure(
        kind: SourceFailureKind.network,
        stage: SourceStage.bookInfo,
        message: 'raw',
      );
      await expectLater(
        service.bookInfo(source, 'https://www.tingyou.fm/book/1'),
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.message,
            'message',
            '网络不可用',
          ),
        ),
      );
      await expectLater(
        service.toc(source, info),
        throwsA(isA<SourceFailure>()),
      );
      updated = (await queries.sourceById(source.id))!;
      expect(updated.lastTestAt, isNull);
      expect(updated.lastTestOk, isNull);
      expect(updated.consecutiveFailures, 0);
      expect(updated.updatedAt.toUtc(), importedAt);
    });
  });
}
