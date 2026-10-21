import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/app/sources/source_engine.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/book_source_queries.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';
import 'package:tometone/domain/sources/discovery/source_failure.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/pages/sources/source_management_page.dart';

import 'source_ui_test_support.dart';

void main() {
  testWidgets('无书源时显示空态与导入入口', (tester) async {
    final db = openSourceTestDatabase();

    await pumpSourceUi(tester, db: db, home: const SourceManagementPage());

    expect(find.text('书源'), findsOneWidget);
    expect(find.text('还没有书源'), findsOneWidget);
    expect(find.byKey(SourceManagementKeys.emptyStateKey), findsOneWidget);
    expect(find.text('导入书源'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('已有书源显示名称、分组、书目数与健康状态', (tester) async {
    final db = openSourceTestDatabase();
    await seedSource(db);

    await pumpSourceUi(tester, db: db, home: const SourceManagementPage());

    expect(find.text('听友听书'), findsOneWidget);
    expect(find.text('听书'), findsOneWidget);
    expect(find.text('书 0'), findsOneWidget);
    expect(find.text('未测试'), findsOneWidget);
  });

  testWidgets('启用开关写库后刷新为非乐观状态', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final row = await db.select(db.bookSources).getSingle();

    await pumpSourceUi(tester, db: db, home: const SourceManagementPage());

    await tester.tap(find.byKey(SourceManagementKeys.enabledSwitchKey(id)));
    await tester.pumpAndSettle();

    final after = await db.select(db.bookSources).getSingle();
    expect(after.enabled, isFalse);
    expect(
      tester
          .widget<Switch>(find.byKey(SourceManagementKeys.enabledSwitchKey(id)))
          .value,
      isFalse,
    );
    expect(row.enabled, isTrue);
  });

  testWidgets('删除默认保留该源书目', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final source = await db.select(db.bookSources).getSingle();
    await seedOnlineBook(db, sourceId: id, libraryRootId: source.libraryRootId);

    await pumpSourceUi(tester, db: db, home: const SourceManagementPage());

    await tester.tap(find.byKey(SourceManagementKeys.menuKey(id)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(find.byKey(SourceManagementKeys.deleteDialogKey), findsOneWidget);
    expect(
      find.byKey(SourceManagementKeys.deleteBooksCheckboxKey),
      findsOneWidget,
    );
    expect(find.text('同时删除该源的已存书目'), findsOneWidget);

    await tester.tap(find.byKey(SourceManagementKeys.deleteConfirmKey));
    await tester.pumpAndSettle();

    expect((await db.select(db.bookSources).getSingle()).deletedAt, isNotNull);
    expect(await db.select(db.books).get(), hasLength(1));
    expect(find.text('还没有书源'), findsOneWidget);
  });

  testWidgets('勾选同时删书后书目消失', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final source = await db.select(db.bookSources).getSingle();
    await seedOnlineBook(db, sourceId: id, libraryRootId: source.libraryRootId);

    await pumpSourceUi(tester, db: db, home: const SourceManagementPage());

    await tester.tap(find.byKey(SourceManagementKeys.menuKey(id)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SourceManagementKeys.deleteBooksCheckboxKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 本'), findsWidgets);

    await tester.tap(find.byKey(SourceManagementKeys.deleteConfirmKey));
    await tester.pumpAndSettle();

    expect((await db.select(db.bookSources).getSingle()).deletedAt, isNotNull);
    expect(await db.select(db.books).get(), isEmpty);
  });

  testWidgets('书数为 0 时删除弹层隐藏复选框', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);

    await pumpSourceUi(tester, db: db, home: const SourceManagementPage());

    await tester.tap(find.byKey(SourceManagementKeys.menuKey(id)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(SourceManagementKeys.deleteBooksCheckboxKey),
      findsNothing,
    );
  });

  testWidgets('测试成功显示结果、刷新卡片且不误触删除', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final before = await db.select(db.bookSources).getSingle();
    final engine = _TestSourceEngine(
      report: const SourceTestReport(
        latency: Duration(milliseconds: 250),
        resultCount: 3,
        sampleTitle: '测试书',
      ),
    );
    final discovery = SourceDiscoveryService(
      engine: engine,
      sources: DriftBookSourceQueries(db),
      clock: () => DateTime.utc(2026, 10, 21, 12),
    );

    await pumpSourceUi(
      tester,
      db: db,
      discovery: discovery,
      home: const SourceManagementPage(),
    );

    await tester.tap(find.byKey(SourceManagementKeys.menuKey(id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SourceManagementKeys.testActionKey(id)));
    await tester.pumpAndSettle();

    expect(find.byKey(SourceManagementKeys.testDialogKey), findsOneWidget);
    expect(find.text('成功 · 3 条 · 250 ms · 示例《测试书》'), findsOneWidget);
    expect(find.byKey(SourceManagementKeys.deleteDialogKey), findsNothing);

    await tester.tap(find.byKey(SourceManagementKeys.testDialogCloseKey));
    await tester.pumpAndSettle();

    final row = await db.select(db.bookSources).getSingle();
    expect(row.lastTestOk, isTrue);
    expect(row.lastTestAt, isNotNull);
    expect(row.updatedAt.toUtc(), before.updatedAt.toUtc());
    expect(find.text('上次测试成功'), findsOneWidget);
  });

  testWidgets('测试失败显示可读错误、刷新健康且不泄露会话', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final engine = _TestSourceEngine(
      failure: const SourceFailure(
        kind: SourceFailureKind.network,
        stage: SourceStage.test,
        message: '原始错误 https://example.com?token=test-session',
      ),
    );
    final discovery = SourceDiscoveryService(
      engine: engine,
      sources: DriftBookSourceQueries(db),
      clock: () => DateTime.utc(2026, 10, 21, 12),
    );

    await pumpSourceUi(
      tester,
      db: db,
      discovery: discovery,
      home: const SourceManagementPage(),
    );

    await tester.tap(find.byKey(SourceManagementKeys.menuKey(id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SourceManagementKeys.testActionKey(id)));
    await tester.pumpAndSettle();

    expect(find.text('失败 · 网络不可用'), findsOneWidget);
    expect(find.textContaining('test-session'), findsNothing);
    expect(find.textContaining('原始错误'), findsNothing);

    await tester.tap(find.byKey(SourceManagementKeys.testDialogCloseKey));
    await tester.pumpAndSettle();

    final row = await db.select(db.bookSources).getSingle();
    expect(row.lastTestOk, isFalse);
    expect(row.consecutiveFailures, 1);
    expect(find.text('连续失败 1 次'), findsOneWidget);
  });

  testWidgets('HTTP 书源显示明文标记，HTTPS 不显示', (tester) async {
    final db = openSourceTestDatabase();
    final httpsId = await seedSource(db);
    final httpId = await seedSource(
      db,
      name: '明文源',
      sourceUrl: 'http://example.com/source.json',
    );

    await pumpSourceUi(tester, db: db, home: const SourceManagementPage());

    expect(
      find.byKey(SourceManagementKeys.httpBadgeKey(httpId)),
      findsOneWidget,
    );
    expect(
      find.byKey(SourceManagementKeys.httpBadgeKey(httpsId)),
      findsNothing,
    );
    expect(find.text('HTTP 明文'), findsOneWidget);
  });

  testWidgets('320dp、大字体、深色下管理页不溢出', (tester) async {
    final db = openSourceTestDatabase();
    await seedSource(db);

    await pumpSourceUi(
      tester,
      db: db,
      home: const SourceManagementPage(),
      size: const Size(320, 700),
      textScale: 2,
      brightness: Brightness.dark,
    );

    expect(find.text('听友听书'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestSourceEngine implements SourceEngine {
  _TestSourceEngine({this.report, this.failure});

  final SourceTestReport? report;
  final SourceFailure? failure;

  @override
  Future<ResolvedAudio> resolveAudio(BookSource source, SourceChapter chapter) {
    throw UnimplementedError('测试未配置音频解析');
  }

  @override
  Future<SourceTestReport> test(BookSource source) async {
    final error = failure;
    if (error != null) {
      throw error;
    }
    return report!;
  }

  @override
  Future<SourcePage<SourceBookSummary>> explore(
    BookSource source,
    ExploreCategory category,
    int page,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<SourcePage<SourceBookSummary>> search(
    BookSource source,
    String keyword,
    int page,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) {
    throw UnimplementedError();
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) {
    throw UnimplementedError();
  }
}
