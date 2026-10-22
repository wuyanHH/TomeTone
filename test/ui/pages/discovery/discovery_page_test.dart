import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/online_providers.dart';
import 'package:tometone/app/providers/source_engine_providers.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/book_source_queries.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/pages/discovery/discovery_page.dart';
import 'package:tometone/ui/pages/sources/source_management_page.dart';

import '../sources/source_ui_test_support.dart';

void main() {
  testWidgets('无书源时显示空态与导入入口', (tester) async {
    final db = openSourceTestDatabase();

    await pumpSourceUi(
      tester,
      db: db,
      discovery: const _EmptyDiscovery(),
      home: const Scaffold(body: DiscoveryPage()),
    );

    expect(find.text('发现'), findsOneWidget);
    expect(find.byKey(DiscoveryPageKeys.emptyKey), findsOneWidget);
    expect(find.text('还没有书源'), findsOneWidget);
    expect(find.text('支持 Legado 听书源 JSON'), findsOneWidget);

    await tester.tap(find.byKey(DiscoveryPageKeys.importKey));
    await tester.pumpAndSettle();

    expect(find.byType(SourceManagementPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('当前书源在顶栏以胶囊展示并提供快捷切换与管理入口，正文不再渲染大卡片', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    await DriftBookSourceQueries(db)
        .recordProbe(id, ok: true, checkedAt: DateTime.utc(2026, 10, 21, 12));

    await pumpSourceUi(
      tester,
      db: db,
      discovery: const _EmptyDiscovery(),
      home: const Scaffold(body: DiscoveryPage()),
    );

    expect(find.byKey(DiscoveryPageKeys.headerSourcePillKey), findsOneWidget);
    expect(find.byKey(DiscoveryPageKeys.manageKey), findsOneWidget);
    expect(find.byKey(DiscoveryPageKeys.sourceCardKey), findsNothing);
    expect(find.text('听友听书'), findsOneWidget);

    await tester.tap(find.byKey(DiscoveryPageKeys.headerSourcePillKey));
    await tester.pumpAndSettle();
    expect(find.text('切换书源'), findsOneWidget);
  });

  testWidgets('连续失败显示失败次数', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    await DriftBookSourceQueries(db).recordProbe(
      id,
      ok: false,
      error: '网络不可用',
      checkedAt: DateTime.utc(2026, 10, 21, 12),
    );

    await pumpSourceUi(
      tester,
      db: db,
      discovery: const _EmptyDiscovery(),
      home: const Scaffold(body: DiscoveryPage()),
    );

    expect(find.text('连续失败 1 次'), findsOneWidget);
    expect(find.text('正常'), findsNothing);
  });

  testWidgets('切换书源后分类随之变化', (tester) async {
    final db = openSourceTestDatabase();
    await seedSource(
      db,
      name: 'A源',
      sourceUrl: 'https://a.example',
      extra: <String, Object?>{
        'exploreUrl': 'A分类::https://a.example/list?page={{page}}',
      },
    );
    await seedSource(
      db,
      name: 'B源',
      sourceUrl: 'https://b.example',
      extra: <String, Object?>{
        'exploreUrl': 'B分类::https://b.example/list?page={{page}}',
      },
    );

    await pumpSourceUi(
      tester,
      db: db,
      discovery: const _EmptyDiscovery(),
      home: const Scaffold(body: DiscoveryPage()),
    );

    expect(find.text('A源'), findsOneWidget);
    expect(find.byKey(DiscoveryPageKeys.categoryKey('A分类')), findsOneWidget);
    expect(find.byKey(DiscoveryPageKeys.categoryKey('B分类')), findsNothing);

    await tester.tap(find.byKey(DiscoveryPageKeys.switchKey));
    await tester.pumpAndSettle();
    expect(find.text('切换书源'), findsOneWidget);
    await tester.tap(find.text('B源'));
    await tester.pumpAndSettle();

    expect(find.text('B源'), findsOneWidget);
    expect(find.byKey(DiscoveryPageKeys.categoryKey('B分类')), findsOneWidget);
    expect(find.byKey(DiscoveryPageKeys.categoryKey('A分类')), findsNothing);
  });

  testWidgets('从管理页返回后重新加载书源', (tester) async {
    final db = openSourceTestDatabase();
    await seedSource(
      db,
      name: 'A源',
      sourceUrl: 'https://a.example',
      extra: <String, Object?>{
        'exploreUrl': 'A分类::https://a.example/list?page={{page}}',
      },
    );

    await pumpSourceUi(
      tester,
      db: db,
      discovery: const _EmptyDiscovery(),
      home: const Scaffold(body: DiscoveryPage()),
    );

    await tester.tap(find.byKey(DiscoveryPageKeys.manageKey));
    await tester.pumpAndSettle();
    expect(find.byType(SourceManagementPage), findsOneWidget);

    await seedSource(
      db,
      name: 'B源',
      sourceUrl: 'https://b.example',
      extra: <String, Object?>{
        'exploreUrl': 'B分类::https://b.example/list?page={{page}}',
      },
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DiscoveryPageKeys.switchKey));
    await tester.pumpAndSettle();
    expect(find.text('B源'), findsOneWidget);
  });

  testWidgets('无分类时显示搜索引导', (tester) async {
    final db = openSourceTestDatabase();
    await seedSource(db, extra: <String, Object?>{'exploreUrl': ''});

    await pumpSourceUi(
      tester,
      db: db,
      discovery: const _EmptyDiscovery(),
      home: const Scaffold(body: DiscoveryPage()),
    );

    expect(find.text('该源没有发现分类，试试搜索'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('320dp、大字体、深色下发现页不溢出', (tester) async {
    final db = openSourceTestDatabase();
    await seedSource(
      db,
      name: '一个非常长的书源名称用于验证窄屏换行',
      extra: <String, Object?>{
        'exploreUrl':
            '一个非常长的分类名称::https://example.com/list?page={{page}}\n'
            '第二个分类::https://example.com/list?page={{page}}\n'
            '第三个分类::https://example.com/list?page={{page}}',
      },
    );

    await pumpSourceUi(
      tester,
      db: db,
      discovery: const _EmptyDiscovery(),
      home: const Scaffold(body: DiscoveryPage()),
      size: const Size(320, 700),
      textScale: 2,
      brightness: Brightness.dark,
    );

    expect(find.text('发现'), findsOneWidget);
    expect(find.textContaining('非常长的书源'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('离开发现页再重新进入，从内存缓存恢复，不重复触发全量加载', (tester) async {
    final db = openSourceTestDatabase();
    await seedSource(
      db,
      name: 'A源',
      sourceUrl: 'https://a.example',
      extra: <String, Object?>{
        'exploreUrl': '玄幻::https://a.example/list?page={{page}}',
      },
    );

    int exploreCalls = 0;
    final discovery = _CountingDiscovery(
      onExplore: () => exploreCalls++,
      items: const <SourceBookSummary>[
        SourceBookSummary(title: '斗破苍穹', bookUrl: 'https://a.example/b/1'),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        bookSourceQueriesProvider.overrideWithValue(DriftBookSourceQueries(db)),
        sourceDiscoveryProvider.overrideWithValue(discovery),
        onlineLibraryQueriesProvider.overrideWithValue(
          DriftOnlineLibraryQueries(db, idGenerator: UlidIdGenerator()),
        ),
      ],
    );
    addTearDown(container.dispose);

    // 首次进入发现页
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: DiscoveryPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('斗破苍穹'), findsOneWidget);
    expect(exploreCalls, 1);

    // 模拟离开页面（切换到其他页面）
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: Text('其他页面')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('其他页面'), findsOneWidget);

    // 再次进入发现页
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: DiscoveryPage()),
        ),
      ),
    );
    // 首次 build 即可直接同步渲染出缓存书籍，无需出现 loading 菊花
    expect(find.text('斗破苍穹'), findsOneWidget);
    expect(find.byKey(DiscoveryPageKeys.loadingKey), findsNothing);
    await tester.pumpAndSettle();

    // explore 调用次数仍然为 1（未重复调用网络请求）
    expect(exploreCalls, 1);
  });
}

class _CountingDiscovery extends _EmptyDiscovery {
  const _CountingDiscovery({
    required this.onExplore,
    this.items = const <SourceBookSummary>[],
  });

  final VoidCallback onExplore;
  final List<SourceBookSummary> items;

  @override
  Future<SourcePage<SourceBookSummary>> explore(
    BookSource source,
    ExploreCategory category,
    int page,
  ) async {
    onExplore();
    return SourcePage<SourceBookSummary>(
      items: items,
      hasMore: false,
      finalUrl: Uri.parse('https://a.example/list'),
    );
  }
}

class _EmptyDiscovery implements SourceDiscovery {
  const _EmptyDiscovery();

  @override
  Future<SourcePage<SourceBookSummary>> explore(
    BookSource source,
    ExploreCategory category,
    int page,
  ) async {
    return _emptyPage();
  }

  @override
  Future<SourcePage<SourceBookSummary>> search(
    BookSource source,
    String keyword,
    int page,
  ) async {
    return _emptyPage();
  }

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) {
    throw UnimplementedError();
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) {
    throw UnimplementedError();
  }

  @override
  Future<ResolvedAudio> resolveAudio(BookSource source, SourceChapter chapter) {
    throw UnimplementedError('测试未配置音频解析');
  }

  @override
  Future<SourceTestReport> test(BookSource source) {
    throw UnimplementedError();
  }

  static SourcePage<SourceBookSummary> _emptyPage() {
    return SourcePage<SourceBookSummary>(
      items: const <SourceBookSummary>[],
      hasMore: false,
      finalUrl: Uri.parse('https://example.com/list'),
    );
  }
}
