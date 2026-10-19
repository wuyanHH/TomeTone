import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/playback_providers.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/contracts/playback/engine_error.dart';
import 'package:tometone/contracts/playback/engine_event.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/app_tabs.dart';
import 'package:tometone/ui/pages/player/player_page.dart';
import 'package:tometone/ui/pages/shelf/shelf_page.dart';
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

  testWidgets('错误态：展示失败说明，重试会重新读取 provider', (WidgetTester tester) async {
    usePhoneViewport(tester);
    int attempts = 0;

    await pumpShelf(
      tester,
      overrides: <Override>[
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

  testWidgets('书架项：封面路径拼成绝对路径，进度 / 未听 / 缺失提示齐备', (WidgetTester tester) async {
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
    expect(find.text('未听 · 8 小时 20 分'), findsOneWidget);
    expect(find.text('2 章缺失'), findsOneWidget);

    final List<BookCover> covers = tester
        .widgetList<BookCover>(find.byType(BookCover))
        .toList();
    expect(covers, hasLength(2));
    expect(covers.first.coverPath, '/library/covers/one.jpg');
    expect(covers.last.coverPath, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点击书籍：openBook 打开队列并展开播放台', (WidgetTester tester) async {
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

    await tester.tap(find.text('山海夜航'));
    await tester.pumpAndSettle();

    expect(controller.current?.chapterId, 'c1');
    expect(controller.state, EnginePlaybackState.playing);
    expect(container.read(currentBookProvider)?.summary.id, 'book-1');
    expect(find.byType(PlayerPage), findsOneWidget);
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

    await tester.tap(find.text('山海夜航'));
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

    await tester.tap(find.text('山海夜航'));
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

    await tester.tap(find.text('空卷'));
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
}
