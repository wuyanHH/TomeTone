import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/source_discovery.dart';
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

  testWidgets('当前书源卡显示分组、健康与最近同步', (tester) async {
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

    expect(find.byKey(DiscoveryPageKeys.sourceCardKey), findsOneWidget);
    expect(find.text('听友听书'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(DiscoveryPageKeys.sourceCardKey),
        matching: find.text('听书'),
      ),
      findsOneWidget,
    );
    expect(find.text('正常'), findsOneWidget);
    expect(find.textContaining('最近同步'), findsOneWidget);
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
