import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/online_providers.dart';
import 'package:tometone/app/providers/source_engine_providers.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/pages/shelf/book_detail_page.dart';

import 'ui_test_harness.dart';

class _FakeOnlineQueries implements OnlineLibraryQueries {
  String? lastBookId;
  bool? lastOnShelf;

  @override
  Future<void> setBookShelf(
    String bookId, {
    required bool onShelf,
    List<String> tags = const <String>[],
  }) async {
    lastBookId = bookId;
    lastOnShelf = onShelf;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDiscovery implements SourceDiscovery {
  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String url) async {
    return const SourceBookInfo(
      title: '在线完整书名',
      bookUrl: 'https://e.test/book/1',
      tocUrl: 'https://e.test/book/1/toc',
      intro: '在线简介',
    );
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) async {
    return const SourceToc(
      complete: true,
      chapters: <SourceChapter>[
        SourceChapter(
          index: 0,
          title: '第 1 章',
          rawUrl: 'https://e.test/c/1',
          url: 'https://e.test/c/1',
          isVip: false,
        ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakePlaybackEngine engine;
  late PlaybackController controller;

  setUp(() {
    engine = FakePlaybackEngine();
    controller = testController(engine);
  });

  tearDown(() async {
    await controller.dispose();
  });

  Future<ProviderContainer> pumpDetail(
    WidgetTester tester, {
    required BookSummary summary,
    BookDetail? detail,
    BookOpenAction? onOpen,
    List<Override> extra = const <Override>[],
    bool notFound = false,
  }) async {
    final ProviderContainer container = ProviderContainer(
      overrides: testOverrides(
        controller: controller,
        books: <BookSummary>[summary],
        detail: notFound ? null : (detail ?? testDetail(summary: summary)),
        extra: <Override>[
          if (notFound)
            bookDetailProvider.overrideWith((Ref ref, String id) async => null),
          ...extra,
        ],
      ),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      testApp(container, BookDetailPage(bookId: summary.id, onOpen: onOpen)),
    );
    return container;
  }

  testWidgets('完整元数据：系列 / 作者 / 演播 / 简介 / 标签 / 章节数', (
    WidgetTester tester,
  ) async {
    usePhoneViewport(tester);
    final BookSummary summary = testSummary(
      title: '山海夜航',
      author: '沈砚',
      narrator: '阿岚',
      seriesName: '山海',
      seriesIndex: 2,
      description: '夜航灯影下打捞旧事的航行。',
      tags: <String>['志怪', '长篇'],
      totalChapters: 4,
      progressChapterId: 'c3',
      progressChapterTitle: '第三章 · 潮声',
      progressChapterIndex: 2,
      progressPositionMs: 60 * 1000,
    );

    await pumpDetail(tester, summary: summary);
    await tester.pumpAndSettle();

    expect(find.text('山海夜航'), findsOneWidget);
    expect(find.text('山海 · 第 2 卷'), findsOneWidget);
    expect(find.text('沈砚 著 · 阿岚 演播'), findsOneWidget);
    expect(find.text('夜航灯影下打捞旧事的航行。'), findsOneWidget);
    expect(find.text('志怪'), findsOneWidget);
    expect(find.text('长篇'), findsOneWidget);
    expect(find.text('第 3 / 4 章'), findsWidgets);
    expect(find.text('从第 3 章继续收听'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('无进度 / 无简介：开始收听与暂无简介，继续动作不指定章', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final BookSummary summary = testSummary(title: '空山');
    BookDetail? opened;
    String? startChapterId;
    int calls = 0;

    await pumpDetail(
      tester,
      summary: summary,
      onOpen: (BookDetail detail, String? chapterId) async {
        calls++;
        opened = detail;
        startChapterId = chapterId;
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('暂无简介'), findsOneWidget);
    expect(find.text('开始收听'), findsOneWidget);
    await tester.tap(find.text('开始收听'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(opened?.summary.id, summary.id);
    expect(startChapterId, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('已完：主按钮变为重新收听，并从第一章开始', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final BookSummary summary = testSummary(
      title: '春山慢',
      isFinished: true,
      progressPositionMs: 1000,
      progressChapterIndex: 3,
    );
    String? startChapterId;
    int calls = 0;

    await pumpDetail(
      tester,
      summary: summary,
      onOpen: (BookDetail detail, String? chapterId) async {
        calls++;
        startChapterId = chapterId;
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('重新收听'), findsOneWidget);
    await tester.tap(find.text('重新收听'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(startChapterId, 'c1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('章节目录：按卷分组，缺失章不可点，正常章传对 chapterId', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final BookSummary summary = testSummary(
      title: '山海夜航',
      progressChapterId: 'c3',
      progressChapterIndex: 2,
      progressPositionMs: 1000,
    );
    final List<String?> openedChapterIds = <String?>[];
    int calls = 0;

    await pumpDetail(
      tester,
      summary: summary,
      onOpen: (BookDetail detail, String? chapterId) async {
        calls++;
        openedChapterIds.add(chapterId);
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('章节目录').first);
    await tester.pumpAndSettle();
    expect(find.text('第一卷 · 入山'), findsOneWidget);
    expect(find.text('第二卷 · 渡海'), findsOneWidget);

    // 第二章缺失：点击不触发起播。
    await tester.tap(find.text('第二章 · 夜航'));
    await tester.pumpAndSettle();
    expect(calls, 0);

    await tester.tap(find.text('第一章 · 山门'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(openedChapterIds, <String?>['c1']);
    expect(find.text('章节目录'), findsOneWidget, reason: '弹层已关闭，只剩入口卡');
    expect(tester.takeException(), isNull);
  });

  testWidgets('顶部菜单：编辑元数据能打开预填弹层', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final BookSummary summary = testSummary(
      title: '山海夜航',
      author: '沈砚',
      description: '旧简介',
      tags: <String>['志怪'],
    );

    await pumpDetail(tester, summary: summary);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();
    expect(find.text('从书根重新导入'), findsOneWidget);

    await tester.tap(find.text('编辑元数据'));
    await tester.pumpAndSettle();

    expect(find.text('编辑元数据'), findsOneWidget);
    expect(find.text('书名 *'), findsOneWidget);
    expect(find.text('沈砚'), findsOneWidget);
    expect(find.text('旧简介'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('不存在：给出可理解的文案，不抛异常', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final BookSummary summary = testSummary(title: '旧书');

    await pumpDetail(tester, summary: summary, notFound: true);
    await tester.pumpAndSettle();

    expect(find.text('这本书已经不在书架里了'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320dp + 大字号：详情页与章节入口不溢出', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final BookSummary summary = testSummary(
      title: '山海夜航：一段足够长的书名用来验证换行',
      author: '沈砚',
      narrator: '阿岚',
      seriesName: '山海',
      seriesIndex: 2,
      description: '夜航灯影下打捞旧事的航行，这句简介故意写得长一些。',
      tags: <String>['志怪', '长篇', '夜航'],
      progressPositionMs: 1000,
      progressChapterIndex: 2,
    );

    await pumpDetail(tester, summary: summary);
    await tester.pumpAndSettle();

    expect(find.byType(BookDetailPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('在线书籍详情双态 CTA：左侧移出书架，右侧继续收听，移出带二次确认', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final queries = _FakeOnlineQueries();
    final BookSummary summary = testSummary(
      title: '在线神魔志',
      sourceType: 'online',
      sourceId: 'src-1',
      onShelf: true,
      progressChapterIndex: 1,
      progressPositionMs: 5000,
    );

    await pumpDetail(
      tester,
      summary: summary,
      extra: <Override>[
        onlineLibraryQueriesProvider.overrideWithValue(queries),
      ],
    );
    await tester.pumpAndSettle();

    final removeFinder = find.byKey(BookDetailKeys.removeShelfKey);
    final listenFinder = find.byKey(BookDetailKeys.listenKey);

    expect(removeFinder, findsOneWidget);
    expect(listenFinder, findsOneWidget);
    expect(find.text('移出书架'), findsOneWidget);
    expect(find.text('从第 2 章继续收听'), findsOneWidget);

    // 验证左侧为移出书架，右侧为收听按钮
    final removeRect = tester.getRect(removeFinder);
    final listenRect = tester.getRect(listenFinder);
    expect(removeRect.left, lessThan(listenRect.left));

    // 点击移出书架触发二次确认弹窗
    await tester.tap(removeFinder);
    await tester.pumpAndSettle();

    expect(find.text('移出书架'), findsWidgets);
    expect(find.textContaining('确定要将《在线神魔志》移出书架吗？'), findsOneWidget);

    // 取消：不调用服务
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(queries.lastBookId, isNull);

    // 再次点击并确认
    await tester.tap(removeFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('移出'));
    await tester.pumpAndSettle();

    expect(queries.lastBookId, summary.id);
    expect(queries.lastOnShelf, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未持久化在线书统一预览：BookDetailPage.online 双按钮 CTA 与零写入', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final now = DateTime.utc(2026);
    final BookSource source = BookSource(
      id: 'src-1',
      libraryRootId: 'root-1',
      name: '测试书源',
      sourceUrl: 'https://e.test',
      sourceType: 1,
      rawJson: '{}',
      header: const <String, String>{},
      enabled: true,
      enabledExplore: true,
      customOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
    const SourceBookSummary item = SourceBookSummary(
      title: '在线未入库书',
      bookUrl: 'https://e.test/book/1',
    );

    final container = ProviderContainer(
      overrides: <Override>[
        sourceDiscoveryProvider.overrideWithValue(_FakeDiscovery()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: BookDetailPage.online(source: source, item: item),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('在线完整书名'), findsOneWidget);
    expect(find.text('在线简介'), findsOneWidget);
    expect(find.byKey(BookDetailKeys.addShelfKey), findsOneWidget);
    expect(find.byKey(BookDetailKeys.listenKey), findsOneWidget);
    expect(find.text('加入书架'), findsOneWidget);
    expect(find.text('立即收听'), findsOneWidget);

    // 左侧为加入书架，右侧为立即收听
    final addRect = tester.getRect(find.byKey(BookDetailKeys.addShelfKey));
    final listenRect = tester.getRect(find.byKey(BookDetailKeys.listenKey));
    expect(addRect.left, lessThan(listenRect.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('章节目录弹层：卷册支持折叠/展开与正倒序切换', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final BookSummary summary = testSummary(
      title: '山海夜航',
      progressChapterId: 'c1',
      progressChapterIndex: 0,
    );

    await pumpDetail(tester, summary: summary);
    await tester.pumpAndSettle();

    await tester.tap(find.text('章节目录').first);
    await tester.pumpAndSettle();

    // 验证初始正序与两卷均存在
    expect(find.text('第一卷 · 入山'), findsOneWidget);
    expect(find.text('第一章 · 山门'), findsOneWidget);
    expect(find.text('第二卷 · 渡海'), findsOneWidget);
    expect(find.text('第三章 · 潮声'), findsOneWidget);

    // 折叠第一卷
    await tester.tap(find.text('第一卷 · 入山'));
    await tester.pumpAndSettle();
    expect(find.text('第一章 · 山门'), findsNothing);
    expect(find.text('第二卷 · 渡海'), findsOneWidget);
    expect(find.text('第三章 · 潮声'), findsOneWidget);

    // 再次点击展开第一卷
    await tester.tap(find.text('第一卷 · 入山'));
    await tester.pumpAndSettle();
    expect(find.text('第一章 · 山门'), findsOneWidget);

    // 切换为倒序
    final sortButton = find.byTooltip('切换为倒序');
    expect(sortButton, findsOneWidget);
    await tester.tap(sortButton);
    await tester.pumpAndSettle();

    expect(find.byTooltip('切换为正序'), findsOneWidget);
  });
}
