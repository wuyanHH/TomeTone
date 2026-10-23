import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/preferences/app_preferences_store.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/playback_providers.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/contracts/playback/engine_error.dart';
import 'package:tometone/contracts/playback/engine_event.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/app_tabs.dart';
import 'package:tometone/ui/pages/player/player_page.dart';
import 'package:tometone/ui/pages/shelf/book_detail_page.dart';
import 'package:tometone/ui/pages/shelf/shelf_book_card.dart';
import 'package:tometone/ui/pages/shelf/shelf_book_row.dart';
import 'package:tometone/ui/pages/shelf/shelf_filter.dart';
import 'package:tometone/ui/pages/shelf/shelf_page.dart';
import 'package:tometone/ui/pages/shelf/shelf_series_management_sheet.dart';
import 'package:tometone/ui/widgets/book_cover.dart';

import '../app/playback/fake_media_source_resolver.dart';
import 'ui_test_harness.dart';

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

  Future<ProviderContainer> pumpShelf(
    WidgetTester tester, {
    List<Override>? overrides,
  }) async {
    final ProviderContainer container = ProviderContainer(
      overrides: overrides ?? testOverrides(controller: controller),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      testApp(container, const Scaffold(body: ShelfPage())),
    );
    return container;
  }

  testWidgets('加载态：进度说明与骨架，不假装有书', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final Completer<List<BookSummary>> completer =
        Completer<List<BookSummary>>();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        preferencesStoreProvider.overrideWithValue(
          InMemoryAppPreferencesStore(),
        ),
        initialPreferencesProvider.overrideWithValue(AppPreferences.defaults),
        booksProvider.overrideWith((Ref ref) => completer.future),
        libraryRootsProvider.overrideWith(
          (Ref ref) async => const <LibraryRootView>[testRoot],
        ),
        playbackControllerProvider.overrideWithValue(controller),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: ShelfPage())),
    );
    await tester.pump();

    expect(find.text('正在整理书架…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(ShelfPage.loadingKey), findsOneWidget);
    expect(find.byType(BookCover), findsNothing);

    completer.complete(const <BookSummary>[]);
    await tester.pumpAndSettle();
    expect(find.byKey(ShelfPage.emptyKey), findsOneWidget);
  });

  testWidgets('空态：一句话指向「书库」，点击引导切到书库 tab', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final ProviderContainer container = await pumpShelf(
      tester,
      overrides: testOverrides(controller: controller),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ShelfPage.emptyKey), findsOneWidget);
    expect(find.text('还没有书库'), findsOneWidget);
    expect(find.textContaining('去「书库」添加一个目录'), findsOneWidget);
    expect(find.textContaining('「设置」'), findsNothing);
    expect(find.byKey(ShelfPage.goToDiscoveryKey), findsOneWidget);
    expect(find.text('去发现找书'), findsOneWidget);
    expect(find.text('重新读取书架'), findsOneWidget);
    expect(container.read(appTabProvider), AppTab.shelf);
    await tester.tap(find.byKey(ShelfPage.goToLibraryKey));
    await tester.pump();
    expect(
      container.read(appTabProvider),
      AppTab.library,
      reason: '空态引导必须切到书库 tab',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('顶栏规范化：紧凑单行题头，不再渲染双层眉题与冗余副文本', (WidgetTester tester) async {
    usePhoneViewport(tester);
    await pumpShelf(
      tester,
      overrides: testOverrides(controller: controller),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的书架'), findsOneWidget);
    expect(find.text('藏馆 · THE VAULT'), findsNothing);
    expect(find.text('点开一本，从上次停下的地方继续听。'), findsNothing);
  });

  testWidgets('书架设置与 2:3 护封：右上角更多菜单可切换列数与字段，卡片隐藏进度条', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final BookSummary book = testSummary(
      id: 'book-1',
      title: '长夜行舟',
      author: '沈砚',
      narrator: '白露',
      description: '夜航灯影下打捞旧事的航行',
      progressPositionMs: 60 * 1000,
      progressChapterIndex: 1,
      totalChapters: 4,
    );
    await pumpShelf(
      tester,
      overrides: testOverrides(
        controller: controller,
        books: <BookSummary>[book],
      ),
    );
    await tester.pumpAndSettle();

    // 默认展示书名与作者，不渲染进度条
    expect(find.text('长夜行舟'), findsOneWidget);
    expect(find.text('沈砚 著 · 白露 演播'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    // 点击右上角更多菜单
    expect(find.byKey(ShelfPage.moreMenuKey), findsOneWidget);
    await tester.tap(find.byKey(ShelfPage.moreMenuKey));
    await tester.pumpAndSettle();

    expect(find.text('2 列'), findsOneWidget);
    expect(find.text('3 列'), findsOneWidget);
    expect(find.text('4 列'), findsOneWidget);
    expect(find.text('显示书名'), findsOneWidget);
    expect(find.text('显示作者'), findsOneWidget);
    expect(find.text('显示演播'), findsOneWidget);

    // 切换隐藏书名
    await tester.tap(find.text('显示书名'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('长夜行舟'), findsNothing);
  });

  testWidgets('空态：点「去发现找书」切到发现 tab', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final ProviderContainer container = await pumpShelf(
      tester,
      overrides: testOverrides(controller: controller),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ShelfPage.goToDiscoveryKey));
    await tester.pump();

    expect(container.read(appTabProvider), AppTab.discovery);
    expect(tester.takeException(), isNull);
  });

  testWidgets('错误态：展示失败说明，重试会重新读取 provider', (WidgetTester tester) async {
    usePhoneViewport(tester);
    int attempts = 0;

    await pumpShelf(
      tester,
      overrides: <Override>[
        preferencesStoreProvider.overrideWithValue(
          InMemoryAppPreferencesStore(),
        ),
        initialPreferencesProvider.overrideWithValue(AppPreferences.defaults),
        booksProvider.overrideWith((Ref ref) async {
          attempts++;
          throw StateError('database not ready');
        }),
        libraryRootsProvider.overrideWith(
          (Ref ref) async => const <LibraryRootView>[testRoot],
        ),
        playbackControllerProvider.overrideWithValue(controller),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ShelfPage.errorKey), findsOneWidget);
    expect(find.text('书架读取失败'), findsOneWidget);
    expect(attempts, 1);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(ShelfPage.retryKey));
    await tester.pumpAndSettle();
    expect(attempts, 2, reason: '重试必须真的 invalidate booksProvider');
    expect(find.text('书架读取失败'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('书架项：封面路径拼成绝对路径，未听 / 缺失提示齐备', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final BookSummary first = testSummary(
      title: '山海夜航',
      coverPath: 'covers/one.jpg',
      totalDurationMs: 8 * 60 * 60 * 1000 + 20 * 60 * 1000,
    );
    final BookSummary second = testSummary(
      id: 'book-2',
      title: '北境旧事录',
      author: '闻笛',
      missingChapters: 2,
      totalDurationMs: 5 * 60 * 60 * 1000,
    );

    await pumpShelf(
      tester,
      overrides: testOverrides(
        controller: controller,
        books: <BookSummary>[first, second],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('山海夜航'), findsOneWidget);
    expect(find.text('北境旧事录'), findsOneWidget);
    expect(find.text('2 章缺失'), findsOneWidget);

    // 切换到列表视图验证未听与无简介提示
    await tester.tap(find.byKey(ShelfPage.layoutToggleKey));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(ShelfBookRow),
        matching: find.text('未听'),
      ),
      findsNWidgets(2),
    );
    expect(find.text('暂无简介'), findsNWidgets(2));

    final List<BookCover> covers = tester
        .widgetList<BookCover>(find.byType(BookCover))
        .toList();
    expect(covers, hasLength(2));
    expect(covers.first.coverPath, '/library/covers/one.jpg');
    expect(covers.last.coverPath, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点播放按钮：openBook 打开队列并展开播放台', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final BookSummary summary = testSummary(title: '山海夜航');
    final BookDetail detail = testDetail(summary: summary);

    final ProviderContainer container = await pumpShelf(
      tester,
      overrides: testOverrides(
        controller: controller,
        books: <BookSummary>[summary],
        detail: detail,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ShelfBookCard.playKeyOf('book-1')));
    await tester.pumpAndSettle();

    expect(controller.current?.chapterId, 'c1');
    expect(controller.state, EnginePlaybackState.playing);
    expect(container.read(currentBookProvider)?.summary.id, 'book-1');
    expect(find.byType(PlayerPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点卡片：进入书籍详情页，不直接起播', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final BookSummary summary = testSummary(title: '山海夜航');
    final BookDetail detail = testDetail(summary: summary);

    await pumpShelf(
      tester,
      overrides: testOverrides(
        controller: controller,
        books: <BookSummary>[summary],
        detail: detail,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('山海夜航'));
    await tester.pumpAndSettle();

    expect(find.byType(BookDetailPage), findsOneWidget);
    expect(find.byType(PlayerPage), findsNothing);
    expect(controller.current, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('再点已打开的书：只展开播放台，不重新 load', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final BookSummary summary = testSummary(title: '山海夜航');
    final BookDetail detail = testDetail(summary: summary);

    final ProviderContainer container = await pumpShelf(
      tester,
      overrides: testOverrides(
        controller: controller,
        books: <BookSummary>[summary],
        detail: detail,
      ),
    );
    await tester.pumpAndSettle();

    // 模拟「这本书已经在播放」。
    container.read(currentBookProvider.notifier).set(detail);
    await controller.open(testRequest(detail));
    final int loads = engine.emitted.whereType<EngineDurationChanged>().length;

    await tester.tap(find.byKey(ShelfBookCard.playKeyOf('book-1')));
    await tester.pumpAndSettle();

    expect(find.byType(PlayerPage), findsOneWidget);
    expect(
      engine.emitted.whereType<EngineDurationChanged>().length,
      loads,
      reason: 'alreadyOpen 必须短路，不得重建队列 / 重新 load',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('打开失败：SnackBar 给出可区分原因，不进入播放台', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final BookSummary summary = testSummary(title: '山海夜航');
    final BookDetail detail = testDetail(summary: summary);
    final String uri = LocalFileSource.fromPath(
      '/library/books/book-1/chapter-1.mp3',
    ).uri;
    final FakePlaybackEngine failingEngine = FakePlaybackEngine(
      loadFailures: <String, EngineErrorCode>{
        uri: EngineErrorCode.sourceNotFound,
      },
    );
    final PlaybackController failingController = testController(failingEngine);
    addTearDown(failingController.dispose);

    await pumpShelf(
      tester,
      overrides: testOverrides(
        controller: failingController,
        books: <BookSummary>[summary],
        detail: detail,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ShelfBookCard.playKeyOf('book-1')));
    await tester.pumpAndSettle();

    expect(find.textContaining('音频读取失败'), findsOneWidget);
    expect(find.byType(PlayerPage), findsNothing);
    expect(failingController.current, isNull, reason: '失败必须回滚会话');
    expect(tester.takeException(), isNull);
  });

  testWidgets('SAF 根封面走 coverImage，不把 content:// 拼给 Image.file', (
    WidgetTester tester,
  ) async {
    usePhoneViewport(tester);
    // 1×1 透明 PNG：合法的图片字节，避免解码器报「不是图片」的噪声。
    final Uint8List bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQAB'
      'DQottAAAAABJRU5ErkJggg==',
    );
    final FakeMediaSourceResolver resolver = FakeMediaSourceResolver(
      bytes: bytes,
    );
    const LibraryRootView safRoot = LibraryRootView(
      id: testRootId,
      type: 'saf',
      uri: 'content://tree/books',
      displayName: 'SAF 书库',
    );
    final BookSummary summary = testSummary(
      title: '山海夜航',
      coverPath: 'covers/one.jpg',
    );

    await pumpShelf(
      tester,
      overrides: testOverrides(
        controller: controller,
        books: <BookSummary>[summary],
        roots: <LibraryRootView>[safRoot],
        resolverFactory: testResolverFactory(resolver: resolver),
      ),
    );
    await tester.pumpAndSettle();

    final BookCover cover = tester.widget<BookCover>(find.byType(BookCover));
    expect(cover.coverImage, isA<MemoryImage>());
    expect(cover.coverPath, isNull);
    expect(resolver.readBytesCalls, contains('covers/one.jpg'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('整本缺文件：SnackBar 提示，不进入播放台', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final BookSummary summary = testSummary(title: '空卷');
    final BookDetail detail = testDetail(
      summary: summary,
      volumes: <VolumeView>[
        VolumeView(
          id: 'v1',
          title: '第一卷 · 缺卷',
          volumeIndex: 0,
          chapters: <ChapterView>[testChapter(0, missing: true)],
        ),
      ],
    );

    await pumpShelf(
      tester,
      overrides: testOverrides(
        controller: controller,
        books: <BookSummary>[summary],
        detail: detail,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ShelfBookCard.playKeyOf('book-1')));
    await tester.pumpAndSettle();

    expect(find.textContaining('没有可播放的章节'), findsOneWidget);
    expect(find.byType(PlayerPage), findsNothing);
    expect(controller.current, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏 3 列、超宽 4 列', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.view.physicalSize = const Size(800, 900);
    final BookSummary summary = testSummary();
    await pumpShelf(
      tester,
      overrides: testOverrides(
        controller: controller,
        books: <BookSummary>[summary],
      ),
    );
    await tester.pumpAndSettle();

    SliverGrid grid = tester.widget<SliverGrid>(find.byKey(ShelfPage.gridKey));
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      3,
    );

    tester.view.physicalSize = const Size(1100, 900);
    await tester.pumpAndSettle();
    grid = tester.widget<SliverGrid>(find.byKey(ShelfPage.gridKey));
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      4,
    );
    expect(tester.takeException(), isNull);
  });

  group('ShelfFilterState 筛选模型', () {
    /// 四本摘要：在听（长夜行舟）、未听（雾中灯塔）、已完（春山慢）、无简介（雪落长安）。
    List<BookSummary> shelfFixture() => <BookSummary>[
      testSummary(
        id: 'book-1',
        title: '长夜行舟',
        author: '沈砚',
        narrator: '白露',
        seriesName: '山海纪',
        description: '夜航灯影下打捞旧事的航行',
        tags: <String>['Wuxia'],
        progressPositionMs: 60 * 1000,
        progressChapterIndex: 1,
      ),
      testSummary(
        id: 'book-2',
        title: '雾中灯塔',
        author: '江照',
        narrator: 'Chen Yu',
        seriesName: '山海纪',
        description: '守塔人每晚写一封不会寄出的信',
        tags: <String>['悬疑'],
      ),
      testSummary(
        id: 'book-3',
        title: '春山慢',
        author: '温酒',
        narrator: '苏晚',
        description: '山寺的钟一天只响一次',
        tags: <String>['wuxia'],
        isFinished: true,
        progressPositionMs: 1000,
        progressChapterIndex: 9,
      ),
      testSummary(
        id: 'book-4',
        title: '雪落长安',
        author: '温酒',
        narrator: '苏晚',
        seriesName: '长安三夜',
      ),
    ];

    /// 只取书名，断言用。
    List<String> titles(List<BookSummary> books) => <String>[
      for (final BookSummary book in books) book.title,
    ];

    test('apply([]) 为空；默认状态不激活且原样返回', () {
      const ShelfFilterState filter = ShelfFilterState();
      final List<BookSummary> books = shelfFixture();

      expect(filter.apply(const <BookSummary>[]), isEmpty);
      expect(filter.isActive, isFalse);
      expect(titles(filter.apply(books)), <String>[
        '长夜行舟',
        '雾中灯塔',
        '春山慢',
        '雪落长安',
      ]);
    });

    test('搜索：书名 / 作者 / 演播 / 简介 / 系列关键词命中，大小写不敏感', () {
      const ShelfFilterState base = ShelfFilterState();
      final List<BookSummary> books = shelfFixture();

      expect(titles(base.copyWith(query: '长安').apply(books)), <String>['雪落长安']);
      expect(titles(base.copyWith(query: '沈砚').apply(books)), <String>['长夜行舟']);
      // 演播者大小写折叠：'Chen Yu' 能被 'chen yu' 命中。
      expect(titles(base.copyWith(query: 'chen yu').apply(books)), <String>[
        '雾中灯塔',
      ]);
      // 简介关键词。
      expect(titles(base.copyWith(query: '不会寄出').apply(books)), <String>[
        '雾中灯塔',
      ]);
      // 系列名也参与搜索。
      expect(titles(base.copyWith(query: '山海纪').apply(books)), <String>[
        '长夜行舟',
        '雾中灯塔',
      ]);
      expect(base.copyWith(query: '不存在的关键词').apply(books), isEmpty);
      // 空白搜索词等同未搜索。
      expect(base.copyWith(query: '   ').apply(books), hasLength(4));
    });

    test('状态筛选：在听 / 未听 / 已完 只留对应书', () {
      final List<BookSummary> books = shelfFixture();

      // 有进度但已听完的《春山慢》不算「在听」。
      expect(
        titles(
          const ShelfFilterState(status: ShelfStatusFilter.listening)
              .apply(books),
        ),
        <String>['长夜行舟'],
      );
      // 有进度的《春山慢》不算「未听」（即便已听完）。
      expect(
        titles(
          const ShelfFilterState(status: ShelfStatusFilter.unlistened)
              .apply(books),
        ),
        <String>['雾中灯塔', '雪落长安'],
      );
      expect(
        titles(
          const ShelfFilterState(status: ShelfStatusFilter.finished)
              .apply(books),
        ),
        <String>['春山慢'],
      );
    });

    test('标签大小写折叠、系列按原文比较，组合为 AND', () {
      final List<BookSummary> books = shelfFixture();

      // 'Wuxia' / 'wuxia' 视为同一标签。
      expect(
        titles(const ShelfFilterState(tag: 'WUXIA').apply(books)),
        <String>['长夜行舟', '春山慢'],
      );
      expect(
        titles(const ShelfFilterState(series: '山海纪').apply(books)),
        <String>['长夜行舟', '雾中灯塔'],
      );
      // 系列按原文：大小写不同不算命中。
      final BookSummary saga = testSummary(
        id: 'book-5',
        title: '雾都孤儿',
        seriesName: 'Saga',
      );
      expect(
        const ShelfFilterState(series: 'saga').apply(<BookSummary>[saga]),
        isEmpty,
      );
      // 标签 ∩ 系列。
      expect(
        titles(
          const ShelfFilterState(tag: 'wuxia', series: '山海纪').apply(books),
        ),
        <String>['长夜行舟'],
      );
      // 状态 ∩ 搜索。
      expect(
        titles(
          const ShelfFilterState(
            status: ShelfStatusFilter.unlistened,
            query: '温酒',
          ).apply(books),
        ),
        <String>['雪落长安'],
      );
    });

    test('isActive：任一维度偏离默认即激活，空白值不激活', () {
      expect(const ShelfFilterState().isActive, isFalse);
      expect(const ShelfFilterState(query: '夜').isActive, isTrue);
      expect(
        const ShelfFilterState(status: ShelfStatusFilter.listening).isActive,
        isTrue,
      );
      expect(const ShelfFilterState(tag: '武侠').isActive, isTrue);
      expect(const ShelfFilterState(series: '山海纪').isActive, isTrue);
      expect(const ShelfFilterState(query: '   ').isActive, isFalse);
      expect(const ShelfFilterState(tag: '').isActive, isFalse);
      expect(const ShelfFilterState(series: '').isActive, isFalse);
    });
  });

  group('书架筛选交互', () {
    List<BookSummary> shelfFixture() => <BookSummary>[
      testSummary(
        id: 'book-1',
        title: '长夜行舟',
        author: '沈砚',
        narrator: '白露',
        seriesName: '山海纪',
        description: '夜航灯影下打捞旧事的航行',
        tags: <String>['Wuxia'],
        progressPositionMs: 60 * 1000,
        progressChapterIndex: 1,
      ),
      testSummary(
        id: 'book-2',
        title: '雾中灯塔',
        author: '江照',
        narrator: 'Chen Yu',
        seriesName: '山海纪',
        description: '守塔人每晚写一封不会寄出的信',
        tags: <String>['悬疑'],
      ),
      testSummary(
        id: 'book-3',
        title: '春山慢',
        author: '温酒',
        narrator: '苏晚',
        description: '山寺的钟一天只响一次',
        tags: <String>['wuxia'],
        isFinished: true,
        progressPositionMs: 1000,
        progressChapterIndex: 9,
      ),
      testSummary(
        id: 'book-4',
        title: '雪落长安',
        author: '温酒',
        narrator: '苏晚',
        seriesName: '长安三夜',
      ),
    ];

    testWidgets('搜索：展开输入即时过滤，清除按钮一键恢复', (WidgetTester tester) async {
      usePhoneViewport(tester);
      await pumpShelf(
        tester,
        overrides: testOverrides(controller: controller, books: shelfFixture()),
      );
      await tester.pumpAndSettle();

      for (final String title in const <String>[
        '长夜行舟',
        '雾中灯塔',
        '春山慢',
        '雪落长安',
      ]) {
        expect(find.text(title), findsOneWidget);
      }

      await tester.tap(find.byKey(ShelfPage.searchToggleKey));
      await tester.pumpAndSettle();
      expect(find.byKey(ShelfPage.searchFieldKey), findsOneWidget);

      await tester.enterText(find.byKey(ShelfPage.searchFieldKey), '沈砚');
      await tester.pumpAndSettle();
      expect(find.text('长夜行舟'), findsOneWidget);
      expect(find.text('雾中灯塔'), findsNothing);

      // 有关键字时出现清除按钮；点它恢复全部。
      expect(find.byKey(ShelfPage.searchClearKey), findsOneWidget);
      await tester.tap(find.byKey(ShelfPage.searchClearKey));
      await tester.pumpAndSettle();
      expect(find.text('雾中灯塔'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('零结果：专用空态 + 清除筛选恢复全部', (WidgetTester tester) async {
      usePhoneViewport(tester);
      await pumpShelf(
        tester,
        overrides: testOverrides(controller: controller, books: shelfFixture()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ShelfPage.searchToggleKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(ShelfPage.searchFieldKey), '不存在的书名');
      await tester.pumpAndSettle();

      expect(find.byKey(ShelfPage.filteredEmptyKey), findsOneWidget);
      expect(find.text('没有符合条件的书'), findsOneWidget);
      expect(find.text('清除筛选'), findsOneWidget);

      await tester.tap(find.byKey(ShelfPage.clearFiltersKey));
      await tester.pumpAndSettle();

      expect(find.byKey(ShelfPage.filteredEmptyKey), findsNothing);
      expect(find.text('长夜行舟'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('状态 chips：在听只留对应书，切回全部恢复', (WidgetTester tester) async {
      usePhoneViewport(tester);
      await pumpShelf(
        tester,
        overrides: testOverrides(controller: controller, books: shelfFixture()),
      );
      await tester.pumpAndSettle();

      // 展开筛选面板
      await tester.tap(find.text('筛选'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(ShelfPage.statusChipKey(ShelfStatusFilter.listening)),
      );
      await tester.pumpAndSettle();
      expect(find.text('长夜行舟'), findsOneWidget);
      expect(find.text('雾中灯塔'), findsNothing);

      await tester.tap(
        find.byKey(ShelfPage.statusChipKey(ShelfStatusFilter.all)),
      );
      await tester.pumpAndSettle();
      expect(find.text('雪落长安'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('分类与系列选项派生自书单，组合过滤生效', (WidgetTester tester) async {
      usePhoneViewport(tester);
      await pumpShelf(
        tester,
        overrides: testOverrides(controller: controller, books: shelfFixture()),
      );
      await tester.pumpAndSettle();

      // 展开筛选面板，按分类标签过滤
      await tester.tap(find.text('筛选'));
      await tester.pumpAndSettle();

      expect(find.text('不限'), findsOneWidget);
      expect(find.text('悬疑'), findsOneWidget);
      await tester.tap(find.byKey(ShelfPage.tagChipKey('悬疑')));
      await tester.pumpAndSettle();
      expect(find.text('雾中灯塔'), findsOneWidget);
      expect(find.text('长夜行舟'), findsNothing);

      // 系列联动：切换到「长安三夜」Tab。《长安三夜》只包含《雪落长安》（无悬疑标签）
      await tester.ensureVisible(find.byKey(ShelfPage.seriesTabKey('长安三夜')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ShelfPage.seriesTabKey('长安三夜')));
      await tester.pumpAndSettle();
      // 悬疑 ∩ 长安三夜 = 空：出现专用零结果态
      expect(find.text('雾中灯塔'), findsNothing);
      expect(find.byKey(ShelfPage.filteredEmptyKey), findsOneWidget);

      // 选「不限」标签：系列筛选保留（《长安三夜》只含《雪落长安》）
      await tester.tap(find.byKey(ShelfPage.tagChipKey(null)));
      await tester.pumpAndSettle();
      expect(find.text('雪落长安'), findsOneWidget);
      expect(find.text('雾中灯塔'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('布局切换：网格与列表真实切换，不重建数据', (WidgetTester tester) async {
      usePhoneViewport(tester);
      await pumpShelf(
        tester,
        overrides: testOverrides(controller: controller, books: shelfFixture()),
      );
      await tester.pumpAndSettle();

      // 默认网格：用 ShelfBookCard。
      expect(find.byKey(ShelfPage.gridKey), findsOneWidget);
      expect(find.byKey(ShelfPage.listKey), findsNothing);
      expect(find.byType(ShelfBookCard), findsWidgets);
      expect(find.byType(ShelfBookRow), findsNothing);

      await tester.tap(find.byKey(ShelfPage.layoutToggleKey));
      await tester.pumpAndSettle();
      expect(find.byKey(ShelfPage.gridKey), findsNothing);
      expect(find.byKey(ShelfPage.listKey), findsOneWidget);
      expect(find.byType(ShelfBookRow), findsWidgets);
      expect(find.byType(ShelfBookCard), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320dp 宽 + 系统大字号：展开搜索与筛选行不溢出', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpShelf(
        tester,
        overrides: testOverrides(controller: controller, books: shelfFixture()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ShelfPage.searchToggleKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(ShelfPage.searchFieldKey), '沈砚');

      // 展开筛选并勾选状态
      await tester.tap(find.text('筛选'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ShelfPage.statusChipKey(ShelfStatusFilter.listening)),
      );
      await tester.pumpAndSettle();

      expect(find.text('长夜行舟'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('书架卡片与列表行', () {
    testWidgets('网格卡片：2:3 护封比例、书名与作者演播、卡片默认隐藏干扰进度条', (WidgetTester tester) async {
      usePhoneViewport(tester);
      final BookSummary book = testSummary(
        title: '长夜行舟',
        author: '沈砚',
        narrator: '白露',
        description: '夜航灯影下打捞旧事的航行',
        progressPositionMs: 60 * 1000,
        progressChapterIndex: 1,
        totalChapters: 4,
      );
      await pumpShelf(
        tester,
        overrides: testOverrides(
          controller: controller,
          books: <BookSummary>[book],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('长夜行舟'), findsOneWidget);
      expect(find.text('沈砚 著 · 白露 演播'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('列表行：两行简介与标签 chips，进度沿用同一口径', (WidgetTester tester) async {
      usePhoneViewport(tester);
      final BookSummary book = testSummary(
        title: '长夜行舟',
        author: '沈砚',
        narrator: '白露',
        description: '夜航灯影下打捞旧事的航行，一直讲到天亮。',
        tags: <String>['武侠', '夜航'],
        progressPositionMs: 60 * 1000,
        progressChapterIndex: 1,
        totalChapters: 4,
      );
      await pumpShelf(
        tester,
        overrides: testOverrides(
          controller: controller,
          books: <BookSummary>[book],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ShelfPage.layoutToggleKey));
      await tester.pumpAndSettle();

      expect(find.byType(ShelfBookRow), findsOneWidget);
      expect(find.text('长夜行舟'), findsOneWidget);
      expect(find.text('沈砚 著 · 白露 演播'), findsOneWidget);
      expect(find.text('夜航灯影下打捞旧事的航行，一直讲到天亮。'), findsOneWidget);
      expect(find.text('武侠'), findsOneWidget);
      expect(find.text('夜航'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('卡片回调分离：点卡片触发 onOpen，点播放只触发 onPlay', (
      WidgetTester tester,
    ) async {
      usePhoneViewport(tester);
      final BookSummary book = testSummary(title: '山海夜航');
      int opened = 0;
      int played = 0;
      final ProviderContainer container = ProviderContainer(
        overrides: testOverrides(
          controller: controller,
          books: <BookSummary>[book],
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        testApp(
          container,
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                child: ShelfBookCard(
                  book: book,
                  onOpen: () => opened++,
                  onPlay: () => played++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('山海夜航'));
      expect(opened, 1);
      expect(played, 0);

      await tester.tap(find.byKey(ShelfBookCard.playKeyOf('book-1')));
      expect(played, 1);
      expect(opened, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320dp + 大字号：网格卡片与列表行都不溢出', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final BookSummary book = testSummary(
        title: '长夜行舟',
        author: '沈砚',
        narrator: '白露',
        description: '夜航灯影下打捞旧事的航行',
        tags: <String>['武侠'],
        progressPositionMs: 60 * 1000,
        progressChapterIndex: 1,
        totalChapters: 4,
        missingChapters: 1,
      );
      await pumpShelf(
        tester,
        overrides: testOverrides(
          controller: controller,
          books: <BookSummary>[book],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('长夜行舟'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(ShelfPage.layoutToggleKey));
      await tester.pumpAndSettle();
      expect(find.byType(ShelfBookRow), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('书架系列导航与 SearchFilterBar 联动', () {
    List<BookSummary> multiSeriesFixture() => <BookSummary>[
      testSummary(
        id: 'book-1',
        title: '长夜行舟',
        author: '沈砚',
        seriesName: '山海纪',
        sourceType: 'local',
        progressPositionMs: 60 * 1000,
        progressChapterIndex: 1,
      ),
      testSummary(
        id: 'book-2',
        title: '海风沉寂',
        author: '江照',
        seriesName: '山海纪',
        sourceType: 'online',
        progressPositionMs: 60 * 1000,
        progressChapterIndex: 1,
      ),
      testSummary(
        id: 'book-3',
        title: '雪落长安',
        author: '温酒',
        seriesName: '长安三夜',
        sourceType: 'local',
      ),
      testSummary(
        id: 'book-4',
        title: '单本闲谈',
        author: '无名',
        seriesName: null,
        sourceType: 'local',
      ),
    ];

    testWidgets('1. Tab 模式切页：点击系列 Tab 与 PageView 左右滑动手势切换系列', (
      WidgetTester tester,
    ) async {
      usePhoneViewport(tester);
      await pumpShelf(
        tester,
        overrides: testOverrides(
          controller: controller,
          books: multiSeriesFixture(),
        ),
      );
      await tester.pumpAndSettle();

      // 默认在「全部」Tab，包含所有 4 本书
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('未分类'), findsOneWidget);
      expect(find.text('山海纪'), findsOneWidget);
      expect(find.text('长安三夜'), findsOneWidget);

      expect(find.text('长夜行舟'), findsOneWidget);
      expect(find.text('海风沉寂'), findsOneWidget);
      expect(find.text('雪落长安'), findsOneWidget);
      expect(find.text('单本闲谈'), findsOneWidget);

      // 点击「山海纪」Tab
      await tester.tap(find.text('山海纪'));
      await tester.pumpAndSettle();

      expect(find.text('长夜行舟'), findsOneWidget);
      expect(find.text('海风沉寂'), findsOneWidget);
      expect(find.text('雪落长安'), findsNothing);
      expect(find.text('单本闲谈'), findsNothing);

      // 通过 PageView 滑动手势滑动到下一个系列「长安三夜」
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('雪落长安'), findsOneWidget);
      expect(find.text('长夜行舟'), findsNothing);
      expect(find.text('海风沉寂'), findsNothing);
    });

    testWidgets('2. 选择框模式：在下拉模式下点击标题选择系列，成功切换内容', (
      WidgetTester tester,
    ) async {
      usePhoneViewport(tester);
      final AppPreferences dropdownPrefs = AppPreferences.defaults.copyWith(
        shelfSeriesNavMode: ShelfSeriesNavMode.dropdown,
      );
      await pumpShelf(
        tester,
        overrides: <Override>[
          preferencesStoreProvider.overrideWithValue(
            InMemoryAppPreferencesStore(),
          ),
          initialPreferencesProvider.overrideWithValue(dropdownPrefs),
          booksProvider.overrideWith((Ref ref) async => multiSeriesFixture()),
          libraryRootsProvider.overrideWith(
            (Ref ref) async => const <LibraryRootView>[testRoot],
          ),
          playbackControllerProvider.overrideWithValue(controller),
        ],
      );
      await tester.pumpAndSettle();

      // 初始显示全部
      expect(find.byKey(ShelfPage.seriesDropdownKey), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('长夜行舟'), findsOneWidget);
      expect(find.text('雪落长安'), findsOneWidget);

      // 点击下拉标题选择框
      await tester.tap(find.byKey(ShelfPage.seriesDropdownKey));
      await tester.pumpAndSettle();

      // 弹出系列列表，点击「山海纪」
      expect(
        find.byKey(ShelfPage.seriesDropdownItemKey('山海纪')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ShelfPage.seriesDropdownItemKey('山海纪')));
      await tester.pumpAndSettle();

      // 内容仅展示山海纪书籍
      expect(find.text('长夜行舟'), findsOneWidget);
      expect(find.text('海风沉寂'), findsOneWidget);
      expect(find.text('雪落长安'), findsNothing);
    });

    testWidgets('3. 一体化筛选与角标：在 SearchFilterBar 中展开卡片，勾选在听与本地音频，验证角标为 2 且正确过滤', (
      WidgetTester tester,
    ) async {
      usePhoneViewport(tester);
      await pumpShelf(
        tester,
        overrides: testOverrides(
          controller: controller,
          books: multiSeriesFixture(),
        ),
      );
      await tester.pumpAndSettle();

      // 点击筛选按钮展开折叠卡片
      expect(find.text('筛选'), findsOneWidget);
      await tester.tap(find.text('筛选'));
      await tester.pumpAndSettle();

      // 勾选「在听」
      await tester.tap(
        find.byKey(ShelfPage.statusChipKey(ShelfStatusFilter.listening)),
      );
      await tester.pumpAndSettle();

      // 勾选「本地音频」
      await tester.tap(
        find.byKey(ShelfPage.sourceChipKey(ShelfSourceFilter.local)),
      );
      await tester.pumpAndSettle();

      // 验证筛选角标显示为 "2"
      expect(
        find.descendant(
          of: find.byKey(ShelfPage.filterToggleKey),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );

      // 只有长夜行舟同时满足在听（hasProgress && !isFinished）且为本地音频（!isOnline）
      expect(find.text('长夜行舟'), findsOneWidget);
      expect(find.text('海风沉寂'), findsNothing); // online
      expect(find.text('雪落长安'), findsNothing); // unlistened
      expect(find.text('单本闲谈'), findsNothing); // unlistened
    });

    testWidgets('4. 防空兜底：当隐藏全部系列且书单无系列时，页面安全降级保底展示「全部」，不崩溃', (
      WidgetTester tester,
    ) async {
      usePhoneViewport(tester);
      final AppPreferences emptySeriesPrefs = AppPreferences.defaults.copyWith(
        shelfShowAllSeriesTab: false,
        shelfShowUncategorizedSeriesTab: false,
        shelfHiddenSeries: const <String>['山海纪', '长安三夜'],
      );
      await pumpShelf(
        tester,
        overrides: <Override>[
          preferencesStoreProvider.overrideWithValue(
            InMemoryAppPreferencesStore(),
          ),
          initialPreferencesProvider.overrideWithValue(emptySeriesPrefs),
          booksProvider.overrideWith((Ref ref) async => multiSeriesFixture()),
          libraryRootsProvider.overrideWith(
            (Ref ref) async => const <LibraryRootView>[testRoot],
          ),
          playbackControllerProvider.overrideWithValue(controller),
        ],
      );
      await tester.pumpAndSettle();

      // 必须安全兜底显示「全部」
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('长夜行舟'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. 更多菜单入口：右上角「⋮」菜单中提供「管理系列」条目，点击弹出管理抽屉', (
      WidgetTester tester,
    ) async {
      usePhoneViewport(tester);
      await pumpShelf(
        tester,
        overrides: testOverrides(
          controller: controller,
          books: multiSeriesFixture(),
        ),
      );
      await tester.pumpAndSettle();

      // 点击右上角更多菜单
      await tester.tap(find.byKey(ShelfPage.moreMenuKey));
      await tester.pumpAndSettle();

      expect(find.text('管理系列'), findsOneWidget);
      await tester.tap(find.text('管理系列'));
      await tester.pumpAndSettle();

      // 弹出 ShelfSeriesManagementSheet
      expect(find.byKey(ShelfSeriesManagementKeys.sheet), findsOneWidget);
      expect(find.text('导航模式'), findsOneWidget);
      expect(find.text('显示全部'), findsOneWidget);
    });
  });
}
