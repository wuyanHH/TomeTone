import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/pages/discovery/discovery_page.dart';
import 'package:tometone/ui/pages/discovery/online_book_preview_page.dart';

import '../sources/source_ui_test_support.dart';

class _MembershipDiscovery implements SourceDiscovery {
  _MembershipDiscovery({
    this.exploreHandler,
  });

  final Future<SourcePage<SourceBookSummary>> Function(
    BookSource source,
    ExploreCategory category,
    int page,
  )? exploreHandler;

  @override
  Future<SourcePage<SourceBookSummary>> explore(
    BookSource source,
    ExploreCategory category,
    int page,
  ) {
    return exploreHandler?.call(source, category, page) ??
        Future.value(
          SourcePage<SourceBookSummary>(
            items: const <SourceBookSummary>[],
            hasMore: false,
            finalUrl: Uri.parse('https://example.com/explore'),
          ),
        );
  }

  @override
  Future<SourcePage<SourceBookSummary>> search(
    BookSource source,
    String keyword,
    int page,
  ) {
    return Future.value(
      SourcePage<SourceBookSummary>(
        items: const <SourceBookSummary>[],
        hasMore: false,
        finalUrl: Uri.parse('https://example.com/search'),
      ),
    );
  }

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) {
    return Future.value(
      SourceBookInfo(
        title: '预览书名',
        bookUrl: bookUrl,
        tocUrl: '$bookUrl/toc',
      ),
    );
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) {
    return Future.value(
      const SourceToc(complete: true, chapters: <SourceChapter>[]),
    );
  }

  @override
  Future<ResolvedAudio> resolveAudio(
    BookSource source,
    SourceChapter chapter,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<SourceTestReport> test(BookSource source) {
    throw UnimplementedError();
  }
}

SourceBookSummary _book(String title, String url) {
  return SourceBookSummary(
    title: title,
    bookUrl: url,
    author: '作者',
    narrator: '主播',
  );
}

SourcePage<SourceBookSummary> _page(
  List<SourceBookSummary> items, {
  bool hasMore = false,
}) {
  return SourcePage<SourceBookSummary>(
    items: items,
    hasMore: hasMore,
    finalUrl: Uri.parse('https://example.com/page'),
  );
}

Future<(String, String)> _seedCategorySource(TomeToneDatabase db) async {
  final id = await seedSource(
    db,
    extra: <String, Object?>{
      'exploreUrl': '玄幻::https://www.tingyou.fm/explore/xuanhuan_{{page}}.html',
    },
  );
  final source = await db.select(db.bookSources).getSingle();
  return (id, source.libraryRootId);
}

void main() {
  testWidgets('搜索与分类结果中根据 bookUrl 命中状态展示「已在书架」与「已在书库」，未命中不展示', (
    WidgetTester tester,
  ) async {
    final TomeToneDatabase db = openSourceTestDatabase();
    final (sourceId, libraryRootId) = await _seedCategorySource(db);

    await seedOnlineBook(
      db,
      sourceId: sourceId,
      libraryRootId: libraryRootId,
      id: 'book-shelf',
      title: '书架上的书',
      sourceUri: 'https://www.tingyou.fm/book/shelf',
      onShelf: true,
    );

    await seedOnlineBook(
      db,
      sourceId: sourceId,
      libraryRootId: libraryRootId,
      id: 'book-library',
      title: '仅书库的书',
      sourceUri: 'https://www.tingyou.fm/book/library',
      onShelf: false,
    );

    final _MembershipDiscovery discovery = _MembershipDiscovery(
      exploreHandler: (BookSource s, ExploreCategory c, int page) async {
        return _page(<SourceBookSummary>[
          _book('书架上的书', 'https://www.tingyou.fm/book/shelf'),
          _book('仅书库的书', 'https://www.tingyou.fm/book/library'),
          _book('新发现的书', 'https://www.tingyou.fm/book/fresh'),
        ]);
      },
    );

    await pumpSourceUi(
      tester,
      db: db,
      discovery: discovery,
      home: const Scaffold(body: DiscoveryPage()),
    );

    expect(find.text('书架上的书'), findsOneWidget);
    expect(find.text('仅书库的书'), findsOneWidget);
    expect(find.text('新发现的书'), findsOneWidget);

    expect(find.text('已在书架'), findsOneWidget);
    expect(find.text('已在书库'), findsOneWidget);

    // 确认「已在书架」属于第一个卡片，「已在书库」属于第二个卡片
    expect(
      find.descendant(
        of: find.byKey(
          DiscoveryPageKeys.resultTileKey('https://www.tingyou.fm/book/shelf'),
        ),
        matching: find.text('已在书架'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          DiscoveryPageKeys.resultTileKey('https://www.tingyou.fm/book/library'),
        ),
        matching: find.text('已在书库'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          DiscoveryPageKeys.resultTileKey('https://www.tingyou.fm/book/fresh'),
        ),
        matching: find.text('已在书架'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(
          DiscoveryPageKeys.resultTileKey('https://www.tingyou.fm/book/fresh'),
        ),
        matching: find.text('已在书库'),
      ),
      findsNothing,
    );
  });

  testWidgets('从发现页进入预览并加入书架后返回，对应项状态从无更新为「已在书架」', (
    WidgetTester tester,
  ) async {
    final TomeToneDatabase db = openSourceTestDatabase();
    final (sourceId, libraryRootId) = await _seedCategorySource(db);

    const String bookUrl = 'https://www.tingyou.fm/book/fresh';
    final _MembershipDiscovery discovery = _MembershipDiscovery(
      exploreHandler: (BookSource s, ExploreCategory c, int page) async {
        return _page(<SourceBookSummary>[_book('新发现的书', bookUrl)]);
      },
    );

    await pumpSourceUi(
      tester,
      db: db,
      discovery: discovery,
      home: const Scaffold(body: DiscoveryPage()),
    );

    expect(find.text('新发现的书'), findsOneWidget);
    expect(find.text('已在书架'), findsNothing);

    // 点卡片进入只读预览页
    await tester.tap(find.byKey(DiscoveryPageKeys.resultTileKey(bookUrl)));
    await tester.pumpAndSettle();
    expect(find.byType(OnlineBookPreviewPage), findsOneWidget);

    // 在数据库中插入已上架书目（模拟加入书架完成）
    await seedOnlineBook(
      db,
      sourceId: sourceId,
      libraryRootId: libraryRootId,
      id: 'fresh-id',
      title: '新发现的书',
      sourceUri: bookUrl,
      onShelf: true,
    );

    // 返回发现页
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(DiscoveryPage), findsOneWidget);
    expect(find.text('已在书架'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(DiscoveryPageKeys.resultTileKey(bookUrl)),
        matching: find.text('已在书架'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('分页追加结果时查询新增项状态，已有项状态不丢失', (WidgetTester tester) async {
    final TomeToneDatabase db = openSourceTestDatabase();
    final (sourceId, libraryRootId) = await _seedCategorySource(db);

    await seedOnlineBook(
      db,
      sourceId: sourceId,
      libraryRootId: libraryRootId,
      id: 'book-p1',
      title: '第一页已上架',
      sourceUri: 'https://www.tingyou.fm/book/p1',
      onShelf: true,
    );

    await seedOnlineBook(
      db,
      sourceId: sourceId,
      libraryRootId: libraryRootId,
      id: 'book-p2',
      title: '第二页在书库',
      sourceUri: 'https://www.tingyou.fm/book/p2',
      onShelf: false,
    );

    final _MembershipDiscovery discovery = _MembershipDiscovery(
      exploreHandler: (BookSource s, ExploreCategory c, int page) async {
        if (page == 1) {
          return _page(
            <SourceBookSummary>[
              _book('第一页已上架', 'https://www.tingyou.fm/book/p1'),
            ],
            hasMore: true,
          );
        }
        return _page(<SourceBookSummary>[
          _book('第二页在书库', 'https://www.tingyou.fm/book/p2'),
        ]);
      },
    );

    await pumpSourceUi(
      tester,
      db: db,
      discovery: discovery,
      home: const Scaffold(body: DiscoveryPage()),
    );

    expect(find.text('第一页已上架'), findsOneWidget);
    expect(find.text('已在书架'), findsOneWidget);
    expect(find.text('已在书库'), findsNothing);

    // 触发翻页
    await tester.tap(find.text('加载更多'));
    await tester.pumpAndSettle();

    expect(find.text('第二页在书库'), findsOneWidget);
    // 第一页的状态没有丢失，第二页的状态也加载出来
    expect(find.text('已在书架'), findsOneWidget);
    expect(find.text('已在书库'), findsOneWidget);
  });

  testWidgets('320dp + 2.0 字号 + 深色模式下结果行与状态标签不溢出', (
    WidgetTester tester,
  ) async {
    final TomeToneDatabase db = openSourceTestDatabase();
    final (sourceId, libraryRootId) = await _seedCategorySource(db);

    await seedOnlineBook(
      db,
      sourceId: sourceId,
      libraryRootId: libraryRootId,
      id: 'overflow-test',
      title: '超长标题测试超长标题测试超长标题测试超长标题测试',
      sourceUri: 'https://www.tingyou.fm/book/overflow',
      onShelf: true,
    );

    final _MembershipDiscovery discovery = _MembershipDiscovery(
      exploreHandler: (BookSource s, ExploreCategory c, int page) async {
        return _page(<SourceBookSummary>[
          _book(
            '超长标题测试超长标题测试超长标题测试超长标题测试',
            'https://www.tingyou.fm/book/overflow',
          ),
        ]);
      },
    );

    await pumpSourceUi(
      tester,
      db: db,
      discovery: discovery,
      size: const Size(320, 600),
      textScale: 2.0,
      brightness: Brightness.dark,
      home: const Scaffold(body: DiscoveryPage()),
    );

    expect(find.text('已在书架'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
