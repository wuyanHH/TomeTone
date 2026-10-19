import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/policy/sleep_timer.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/playback_providers.dart';
import 'package:tometone/contracts/playback/engine_error.dart';
import 'package:tometone/contracts/playback/engine_event.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/pages/player/player_page.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

import 'ui_test_harness.dart';

void main() {
  late FakePlaybackEngine engine;
  late PlaybackController controller;
  late BookDetail detail;
  late ProviderContainer container;

  setUp(() async {
    engine = FakePlaybackEngine();
    controller = testController(engine);
    detail = testDetail();
    container = ProviderContainer(
      overrides: <Override>[
        booksProvider.overrideWith(
          (Ref ref) async => <BookSummary>[detail.summary],
        ),
        libraryRootsProvider.overrideWith(
          (Ref ref) async => const <LibraryRootView>[testRoot],
        ),
        playbackControllerProvider.overrideWithValue(controller),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(controller.dispose);
    container.read(currentBookProvider.notifier).set(detail);
    await controller.open(
      testRequest(
        detail,
        savedPosition: const Duration(minutes: 5),
        interruption: const Duration(minutes: 10),
      ),
    );
  });

  Future<void> pumpPlayer(WidgetTester tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(testApp(container, const PlayerPage()));
    await tester.pump();
  }

  testWidgets('五键齐全、顺序正确，触控目标均 ≥48dp', (WidgetTester tester) async {
    await pumpPlayer(tester);

    const List<Key> keys = <Key>[
      PlayerPage.previousKey,
      PlayerPage.rewindKey,
      PlayerPage.playPauseKey,
      PlayerPage.forwardKey,
      PlayerPage.nextKey,
    ];
    final List<double> centers = <double>[];
    for (final Key key in keys) {
      expect(find.byKey(key), findsOneWidget);
      final Size size = tester.getSize(find.byKey(key));
      expect(
        size.width,
        greaterThanOrEqualTo(AppSizes.minTouchTarget),
        reason: '$key 宽度',
      );
      expect(
        size.height,
        greaterThanOrEqualTo(AppSizes.minTouchTarget),
        reason: '$key 高度',
      );
      final double expected = key == PlayerPage.playPauseKey ? 72 : 56;
      expect(size, Size.square(expected), reason: '$key 在 400dp 下的实测尺寸');
      centers.add(tester.getCenter(find.byKey(key)).dx);
    }
    for (int index = 1; index < centers.length; index++) {
      expect(
        centers[index],
        greaterThan(centers[index - 1]),
        reason: '五键应从左到右按「上一曲 / 快退 / 播放 / 快进 / 下一曲」排列',
      );
    }

    expect(find.byTooltip('上一章'), findsOneWidget);
    expect(find.byTooltip('快退 15 秒'), findsOneWidget);
    expect(find.byTooltip('播放'), findsOneWidget);
    expect(find.byTooltip('快进 30 秒'), findsOneWidget);
    expect(find.byTooltip('下一章'), findsOneWidget);

    // 320dp 级窄屏：侧键收到 48dp、中央键 64dp，仍不溢出。
    tester.view.physicalSize = const Size(320, 720);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(PlayerPage.rewindKey)),
      const Size(48, 48),
    );
    expect(
      tester.getSize(find.byKey(PlayerPage.playPauseKey)),
      const Size(64, 64),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('播放 / 暂停与快退快进都直接落控制器', (WidgetTester tester) async {
    await pumpPlayer(tester);

    await tester.tap(find.byKey(PlayerPage.playPauseKey));
    await tester.pumpAndSettle();
    expect(controller.state, EnginePlaybackState.playing);
    expect(find.byTooltip('暂停'), findsOneWidget);

    final Duration before = controller.position;
    await tester.tap(find.byKey(PlayerPage.forwardKey));
    await tester.pumpAndSettle();
    expect(controller.position, before + const Duration(seconds: 30));

    await tester.tap(find.byKey(PlayerPage.rewindKey));
    await tester.pumpAndSettle();
    expect(controller.position, before + const Duration(seconds: 15));

    await tester.tap(find.byKey(PlayerPage.playPauseKey));
    await tester.pumpAndSettle();
    expect(controller.state, EnginePlaybackState.paused);
    expect(tester.takeException(), isNull);
  });

  testWidgets('引擎推进位置后时间轴即时更新', (WidgetTester tester) async {
    await pumpPlayer(tester);
    expect(find.text('04:52 / 10:00'), findsOneWidget);

    await tester.tap(find.byKey(PlayerPage.playPauseKey));
    await tester.pumpAndSettle();
    engine.advance(const Duration(seconds: 30));
    await tester.pump();
    await tester.pump();

    expect(controller.position, const Duration(minutes: 5, seconds: 22));
    expect(find.text('05:22 / 10:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('倍速面板改变控制器与引擎的倍速', (WidgetTester tester) async {
    await pumpPlayer(tester);
    expect(controller.preferences.speed, 1);

    await tester.tap(find.byKey(PlayerPage.speedKey));
    await tester.pumpAndSettle();
    expect(find.text('播放速度'), findsOneWidget);

    await tester.tap(find.text('1.5×'));
    await tester.pumpAndSettle();

    expect(controller.preferences.speed, closeTo(1.5, 0.001));
    expect(engine.speed, closeTo(1.5, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('撤销回退按钮随 canUndoRewind 出现，点击后恢复原位置', (WidgetTester tester) async {
    await pumpPlayer(tester);
    expect(controller.canUndoRewind, isTrue);
    expect(find.byKey(PlayerPage.undoRewindKey), findsOneWidget);
    expect(find.text('撤销回退'), findsOneWidget);

    await tester.tap(find.byKey(PlayerPage.undoRewindKey));
    await tester.pumpAndSettle();

    expect(controller.canUndoRewind, isFalse);
    expect(controller.position, const Duration(minutes: 5));
    expect(find.byKey(PlayerPage.undoRewindKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('睡眠三模式：倒计时 / 播完本章 / 关闭', (WidgetTester tester) async {
    await pumpPlayer(tester);

    await tester.tap(find.byKey(PlayerPage.sleepKey));
    await tester.pumpAndSettle();
    expect(find.text('睡眠守夜'), findsOneWidget);
    await tester.tap(find.text('15 分钟'));
    await tester.pumpAndSettle();
    expect(controller.sleep.mode, SleepMode.countdown);
    expect(
      controller.sleep.remaining,
      lessThanOrEqualTo(const Duration(minutes: 15)),
    );
    expect(find.textContaining('剩余'), findsOneWidget);

    await tester.tap(find.byKey(PlayerPage.sleepKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('播完本章即停'));
    await tester.pumpAndSettle();
    expect(controller.sleep.mode, SleepMode.endOfChapter);
    expect(find.text('本章后停'), findsOneWidget);

    await tester.tap(find.byKey(PlayerPage.sleepKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('关闭睡眠守夜'));
    await tester.pumpAndSettle();
    expect(controller.sleep.mode, SleepMode.off);
    expect(tester.takeException(), isNull);
  });

  testWidgets('章节目录：按卷分组、缺失章置灰、当前章高亮、可跳章', (WidgetTester tester) async {
    await pumpPlayer(tester);

    await tester.tap(find.byKey(PlayerPage.chaptersKey));
    await tester.pumpAndSettle();

    expect(find.text('章节目录'), findsOneWidget);
    expect(find.text('第一卷 · 入山'), findsOneWidget);
    expect(find.text('第二卷 · 渡海'), findsOneWidget);
    expect(find.text('文件缺失，暂不可播放'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ListTile), matching: find.text('正在播放')),
      findsOneWidget,
    );

    await tester.tap(find.text('第三章 · 潮声'));
    await tester.pumpAndSettle();

    expect(find.text('章节目录'), findsNothing);
    expect(
      controller.current?.title,
      '第三章 · 潮声',
      reason: '目录条目应真正跳章，而不是弹一条"只读"提示',
    );
    expect(controller.current?.chapterId, isNot('c1'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('切章加载失败：播放台显示「这一章打不开」，不静默卡住', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final FakePlaybackEngine failingEngine = FakePlaybackEngine(
      durations: <String, Duration>{
        'file:///library/books/book-1/chapter-1.mp3': const Duration(
          minutes: 10,
        ),
      },
      loadFailures: <String, EngineErrorCode>{
        'file:///library/books/book-1/chapter-2.mp3':
            EngineErrorCode.sourceNotFound,
      },
    );
    final PlaybackController failingController = testController(failingEngine);
    addTearDown(failingController.dispose);
    final BookSummary errorSummary = testSummary();
    final BookDetail errorDetail = testDetail(
      summary: errorSummary,
      volumes: testVolumes(secondChapterMissing: false),
    );
    final ProviderContainer errorContainer = ProviderContainer(
      overrides: testOverrides(
        controller: failingController,
        books: <BookSummary>[errorSummary],
        detail: errorDetail,
      ),
    );
    addTearDown(errorContainer.dispose);
    errorContainer.read(currentBookProvider.notifier).set(errorDetail);

    await failingController.open(
      testRequest(errorDetail, startChapterId: 'c1'),
    );
    await failingController.play();
    await failingController.skipToNext();

    await tester.pumpWidget(testApp(errorContainer, const PlayerPage()));
    await tester.pump();

    expect(find.byKey(PlayerPage.playbackErrorKey), findsOneWidget);
    expect(find.textContaining('这一章打不开'), findsOneWidget);

    // 跳到可播放的 c3 后，失败提示必须消失（不留错误状态残留）。
    expect(await failingController.seekToChapter('c3'), isTrue);
    await tester.pump();
    expect(find.byKey(PlayerPage.playbackErrorKey), findsNothing);
    expect(find.textContaining('这一章打不开'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
