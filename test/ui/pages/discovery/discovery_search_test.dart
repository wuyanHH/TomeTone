import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';
import 'package:tometone/domain/sources/discovery/source_failure.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/pages/discovery/discovery_page.dart';
import 'package:tometone/ui/pages/discovery/online_book_preview_page.dart';

import '../sources/source_ui_test_support.dart';

void main() {
  testWidgets('搜索提交显示搜索结果，清除恢复分类第一页', (tester) async {
    final db = openSourceTestDatabase();
    final fake = _FakeDiscovery(
      exploreHandler: (BookSource source, ExploreCategory category, int page) {
        return Future<SourcePage<SourceBookSummary>>.value(
          _page(<SourceBookSummary>[_book('分类书')]),
        );
      },
      searchHandler: (BookSource source, String keyword, int page) {
        return Future<SourcePage<SourceBookSummary>>.value(
          _page(<SourceBookSummary>[_book('搜索书')]),
        );
      },
    );
    await _seedCategorySource(db);

    await _pumpDiscovery(tester, db, fake);
    expect(find.text('分类书'), findsOneWidget);

    await tester.enterText(find.byKey(DiscoveryPageKeys.searchFieldKey), '关键词');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('搜索结果 · 来自 听友听书'), findsOneWidget);
    expect(find.text('搜索书'), findsOneWidget);
    expect(find.text('分类书'), findsNothing);
    expect(fake.searchCalls, <String>['听友听书:关键词:1']);

    await tester.tap(find.byKey(DiscoveryPageKeys.searchClearKey));
    await tester.pumpAndSettle();

    expect(find.text('分类书'), findsOneWidget);
    expect(find.text('搜索书'), findsNothing);
    expect(find.text('搜索结果 · 来自 听友听书'), findsNothing);
    expect(fake.exploreCalls, <String>['听友听书:1', '听友听书:1']);
  });

  testWidgets('翻页追加结果，并按 bookUrl 去重', (tester) async {
    final db = openSourceTestDatabase();
    final fake = _FakeDiscovery(
      exploreHandler: (BookSource source, ExploreCategory category, int page) {
        if (page == 1) {
          return Future<SourcePage<SourceBookSummary>>.value(
            _page(<SourceBookSummary>[_book('一'), _book('二')], hasMore: true),
          );
        }
        return Future<SourcePage<SourceBookSummary>>.value(
          _page(<SourceBookSummary>[_book('二'), _book('三')]),
        );
      },
    );
    await _seedCategorySource(db);

    await _pumpDiscovery(tester, db, fake);
    expect(find.text('一'), findsOneWidget);
    expect(find.text('二'), findsOneWidget);

    await tester.tap(find.text('加载更多'));
    await tester.pumpAndSettle();

    expect(find.text('二'), findsOneWidget);
    expect(find.text('三'), findsOneWidget);
    expect(find.text('已经到底了'), findsOneWidget);
    expect(fake.exploreCalls, <String>['听友听书:1', '听友听书:2']);
  });

  testWidgets('翻页失败保留已加载结果，重试仍请求同一页', (tester) async {
    final db = openSourceTestDatabase();
    var fail = true;
    final fake = _FakeDiscovery(
      exploreHandler: (BookSource source, ExploreCategory category, int page) {
        if (page == 1) {
          return Future<SourcePage<SourceBookSummary>>.value(
            _page(<SourceBookSummary>[_book('一'), _book('二')], hasMore: true),
          );
        }
        if (fail) {
          return Future<SourcePage<SourceBookSummary>>.error(
            const SourceFailure(
              kind: SourceFailureKind.network,
              stage: SourceStage.explore,
              message: '网络不可用',
            ),
          );
        }
        return Future<SourcePage<SourceBookSummary>>.value(
          _page(<SourceBookSummary>[_book('三')]),
        );
      },
    );
    await _seedCategorySource(db);

    await _pumpDiscovery(tester, db, fake);
    await tester.tap(find.text('加载更多'));
    await tester.pumpAndSettle();

    expect(find.text('一'), findsOneWidget);
    expect(find.text('加载下一页失败 · 网络不可用'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(find.text('三'), findsOneWidget);
    expect(fake.exploreCalls, <String>['听友听书:1', '听友听书:2', '听友听书:2']);
  });

  testWidgets('下拉刷新失败保留旧内容并显示顶部 banner', (tester) async {
    final db = openSourceTestDatabase();
    var fail = false;
    final fake = _FakeDiscovery(
      exploreHandler: (BookSource source, ExploreCategory category, int page) {
        if (fail) {
          return Future<SourcePage<SourceBookSummary>>.error(
            const SourceFailure(
              kind: SourceFailureKind.network,
              stage: SourceStage.explore,
              message: '网络不可用',
            ),
          );
        }
        return Future<SourcePage<SourceBookSummary>>.value(
          _page(<SourceBookSummary>[_book('一')]),
        );
      },
    );
    await _seedCategorySource(db);

    await _pumpDiscovery(tester, db, fake);
    expect(find.text('一'), findsOneWidget);

    fail = true;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byKey(DiscoveryPageKeys.errorBannerKey), findsOneWidget);
    expect(find.text('本次加载失败 · 网络不可用'), findsOneWidget);
    expect(find.text('一'), findsOneWidget);

    fail = false;
    await tester.tap(find.byKey(DiscoveryPageKeys.retryKey));
    await tester.pumpAndSettle();

    expect(find.byKey(DiscoveryPageKeys.errorBannerKey), findsNothing);
    expect(find.text('一'), findsOneWidget);
  });

  testWidgets('首屏失败显示全屏错误，重试后加载', (tester) async {
    final db = openSourceTestDatabase();
    var fail = true;
    final fake = _FakeDiscovery(
      exploreHandler: (BookSource source, ExploreCategory category, int page) {
        if (fail) {
          return Future<SourcePage<SourceBookSummary>>.error(
            const SourceFailure(
              kind: SourceFailureKind.timeout,
              stage: SourceStage.explore,
              message: '请求超时',
            ),
          );
        }
        return Future<SourcePage<SourceBookSummary>>.value(
          _page(<SourceBookSummary>[_book('一')]),
        );
      },
    );
    await _seedCategorySource(db);

    await _pumpDiscovery(tester, db, fake);
    expect(find.byKey(DiscoveryPageKeys.resultErrorKey), findsOneWidget);
    expect(find.text('加载失败 · 请求超时'), findsOneWidget);

    fail = false;
    await tester.tap(find.byKey(DiscoveryPageKeys.retryKey));
    await tester.pumpAndSettle();

    expect(find.text('一'), findsOneWidget);
    expect(find.byKey(DiscoveryPageKeys.resultErrorKey), findsNothing);
  });

  testWidgets('切源后旧搜索响应不覆盖新源', (tester) async {
    final db = openSourceTestDatabase();
    await _seedCategorySource(
      db,
      name: 'A源',
      sourceUrl: 'https://a.example',
      categoryName: 'A分类',
    );
    await _seedCategorySource(
      db,
      name: 'B源',
      sourceUrl: 'https://b.example',
      categoryName: 'B分类',
    );

    Completer<SourcePage<SourceBookSummary>>? pendingSearch;
    final fake = _FakeDiscovery(
      exploreHandler: (BookSource source, ExploreCategory category, int page) {
        return Future<SourcePage<SourceBookSummary>>.value(
          _page(<SourceBookSummary>[_book(source.name == 'A源' ? 'A书' : 'B书')]),
        );
      },
      searchHandler: (BookSource source, String keyword, int page) {
        pendingSearch = Completer<SourcePage<SourceBookSummary>>();
        return pendingSearch!.future;
      },
    );

    await _pumpDiscovery(tester, db, fake);
    expect(find.text('A书'), findsOneWidget);

    await tester.enterText(find.byKey(DiscoveryPageKeys.searchFieldKey), '慢搜索');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(pendingSearch, isNotNull);

    await tester.tap(find.byKey(DiscoveryPageKeys.switchKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('B源'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('B书'), findsOneWidget);
    pendingSearch!.complete(_page(<SourceBookSummary>[_book('旧搜索书')]));
    await tester.pumpAndSettle();

    expect(find.text('B书'), findsOneWidget);
    expect(find.text('旧搜索书'), findsNothing);
    expect(find.text('A书'), findsNothing);
  });

  testWidgets('点击结果打开只读预览', (tester) async {
    final db = openSourceTestDatabase();
    final fake = _FakeDiscovery(
      exploreHandler: (BookSource source, ExploreCategory category, int page) {
        return Future<SourcePage<SourceBookSummary>>.value(
          _page(<SourceBookSummary>[_book('一')]),
        );
      },
      bookInfoHandler: (BookSource source, String bookUrl) {
        return Future<SourceBookInfo>.value(
          SourceBookInfo(
            title: '详情书名',
            bookUrl: bookUrl,
            tocUrl: '$bookUrl/toc',
            author: '作者',
          ),
        );
      },
      tocHandler: (BookSource source, SourceBookInfo info) {
        return Future<SourceToc>.value(
          const SourceToc(complete: true, chapters: <SourceChapter>[]),
        );
      },
    );
    await _seedCategorySource(db);

    await _pumpDiscovery(tester, db, fake);
    await tester.tap(
      find.byKey(DiscoveryPageKeys.resultTileKey('https://example.com/book/一')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnlineBookPreviewPage), findsOneWidget);
    expect(find.text('详情书名'), findsOneWidget);
  });

  testWidgets('320dp、大字体、深色下结果列表不溢出', (tester) async {
    final db = openSourceTestDatabase();
    final fake = _FakeDiscovery(
      exploreHandler: (BookSource source, ExploreCategory category, int page) {
        return Future<SourcePage<SourceBookSummary>>.value(
          _page(<SourceBookSummary>[_book('一个非常长的结果书名用于验证窄屏下的换行与截断行为')]),
        );
      },
    );
    await _seedCategorySource(db);

    await _pumpDiscovery(
      tester,
      db,
      fake,
      size: const Size(320, 700),
      textScale: 2,
      brightness: Brightness.dark,
    );

    expect(find.textContaining('非常长的结果书名'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDiscovery(
  WidgetTester tester,
  TomeToneDatabase db,
  _FakeDiscovery fake, {
  Size size = const Size(360, 780),
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) {
  return pumpSourceUi(
    tester,
    db: db,
    discovery: fake,
    home: const Scaffold(body: DiscoveryPage()),
    size: size,
    textScale: textScale,
    brightness: brightness,
  );
}

Future<void> _seedCategorySource(
  TomeToneDatabase db, {
  String name = '听友听书',
  String sourceUrl = 'https://tingyou.example',
  String categoryName = '听书',
}) {
  return seedSource(
    db,
    name: name,
    sourceUrl: sourceUrl,
    extra: <String, Object?>{
      'exploreUrl': '$categoryName::$sourceUrl/list?page={{page}}',
    },
  );
}

SourceBookSummary _book(String title) {
  return SourceBookSummary(
    title: title,
    bookUrl: 'https://example.com/book/$title',
    author: '作者',
    narrator: '演播',
    kind: '有声书',
    wordCount: '10 万字',
  );
}

SourcePage<SourceBookSummary> _page(
  List<SourceBookSummary> items, {
  bool hasMore = false,
}) {
  return SourcePage<SourceBookSummary>(
    items: items,
    hasMore: hasMore,
    finalUrl: Uri.parse('https://example.com/list'),
  );
}

typedef _ExploreHandler = Future<SourcePage<SourceBookSummary>> Function(
  BookSource source,
  ExploreCategory category,
  int page,
);

typedef _SearchHandler = Future<SourcePage<SourceBookSummary>> Function(
  BookSource source,
  String keyword,
  int page,
);

typedef _BookInfoHandler = Future<SourceBookInfo> Function(
  BookSource source,
  String bookUrl,
);

typedef _TocHandler = Future<SourceToc> Function(
  BookSource source,
  SourceBookInfo info,
);

class _FakeDiscovery implements SourceDiscovery {
  _FakeDiscovery({
    this.exploreHandler,
    this.searchHandler,
    this.bookInfoHandler,
    this.tocHandler,
  });

  final _ExploreHandler? exploreHandler;
  final _SearchHandler? searchHandler;
  final _BookInfoHandler? bookInfoHandler;
  final _TocHandler? tocHandler;
  final List<String> exploreCalls = <String>[];
  final List<String> searchCalls = <String>[];

  @override
  Future<SourcePage<SourceBookSummary>> explore(
    BookSource source,
    ExploreCategory category,
    int page,
  ) {
    exploreCalls.add('${source.name}:$page');
    return exploreHandler!(source, category, page);
  }

  @override
  Future<SourcePage<SourceBookSummary>> search(
    BookSource source,
    String keyword,
    int page,
  ) {
    searchCalls.add('${source.name}:$keyword:$page');
    return searchHandler!(source, keyword, page);
  }

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) {
    return bookInfoHandler!(source, bookUrl);
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) {
    return tocHandler!(source, info);
  }

  @override
  Future<ResolvedAudio> resolveAudio(BookSource source, SourceChapter chapter) {
    throw UnimplementedError('测试未配置音频解析');
  }

  @override
  Future<SourceTestReport> test(BookSource source) {
    throw UnimplementedError();
  }
}
