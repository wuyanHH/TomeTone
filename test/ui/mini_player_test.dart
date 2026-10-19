import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/providers/playback_providers.dart';
import 'package:tometone/contracts/playback/engine_error.dart';
import 'package:tometone/contracts/playback/engine_event.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/pages/player/player_page.dart';
import 'package:tometone/ui/widgets/book_cover.dart';
import 'package:tometone/ui/widgets/mini_player.dart';

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

  Future<ProviderContainer> pumpMini(WidgetTester tester) async {
    final BookSummary summary = testSummary();
    final BookDetail detail = testDetail(summary: summary);
    final ProviderContainer container = ProviderContainer(
      overrides: testOverrides(
        controller: controller,
        books: <BookSummary>[summary],
        detail: detail,
      ),
    );
    addTearDown(container.dispose);
    container.read(currentBookProvider.notifier).set(detail);
    await controller.open(testRequest(detail));

    await tester.pumpWidget(
      testApp(
        container,
        const Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('没有当前章节时不渲染任何内容', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final ProviderContainer container = ProviderContainer(
      overrides: testOverrides(controller: controller),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testApp(
        container,
        const Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(BookCover), findsNothing);
    expect(find.byKey(MiniPlayer.playPauseKey), findsNothing);
    expect(tester.getSize(find.byType(MiniPlayer)), Size.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('打开失败回滚（clearSession + 清当前书）后迷你播放器立刻消失', (
    WidgetTester tester,
  ) async {
    usePhoneViewport(tester);
    final ProviderContainer container = await pumpMini(tester);
    expect(find.byKey(MiniPlayer.playPauseKey), findsOneWidget);

    // 模拟 openBook 失败回滚：清当前书 + 清控制器会话。
    container.read(currentBookProvider.notifier).set(null);
    controller.clearSession();
    await tester.pump();

    expect(find.byType(BookCover), findsNothing);
    expect(find.byKey(MiniPlayer.playPauseKey), findsNothing);
    expect(
      tester.getSize(find.byType(MiniPlayer)),
      Size.zero,
      reason: '回滚后高度必须真正归零，不留幽灵条',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('有章节时渲染封面 / 标题，并随控制器切换播放与暂停', (WidgetTester tester) async {
    usePhoneViewport(tester);
    await pumpMini(tester);

    expect(find.byType(BookCover), findsOneWidget);
    expect(find.text('第一章 · 山门'), findsOneWidget);
    expect(find.text('山海夜航 · 沈砚'), findsOneWidget);
    expect(controller.state, EnginePlaybackState.ready);
    expect(find.byTooltip('播放'), findsOneWidget);

    await tester.tap(find.byKey(MiniPlayer.playPauseKey));
    await tester.pumpAndSettle();
    expect(controller.state, EnginePlaybackState.playing);
    expect(find.byTooltip('暂停'), findsOneWidget);

    await tester.tap(find.byKey(MiniPlayer.playPauseKey));
    await tester.pumpAndSettle();
    expect(controller.state, EnginePlaybackState.paused);
    expect(find.byTooltip('播放'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点击整条展开播放台（Hero 封面飞行）', (WidgetTester tester) async {
    usePhoneViewport(tester);
    await pumpMini(tester);

    await tester.tap(find.text('第一章 · 山门'));
    await tester.pumpAndSettle();

    expect(find.byType(PlayerPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切章加载失败：迷你播放器给出可判断的失败提示，不静默', (WidgetTester tester) async {
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

    final BookSummary summary = testSummary();
    final BookDetail detail = testDetail(
      summary: summary,
      volumes: testVolumes(secondChapterMissing: false),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: testOverrides(
        controller: failingController,
        books: <BookSummary>[summary],
        detail: detail,
      ),
    );
    addTearDown(container.dispose);
    container.read(currentBookProvider.notifier).set(detail);

    await failingController.open(testRequest(detail, startChapterId: 'c1'));
    await failingController.play();
    // 切到 c2：load 失败 → lastError 置位。
    await failingController.skipToNext();

    await tester.pumpWidget(
      testApp(
        container,
        const Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(MiniPlayer.errorKey), findsOneWidget);
    expect(find.textContaining('这一章打不开'), findsOneWidget);

    // 跳到可播放的 c3 后，失败提示必须消失（不留错误状态残留）。
    expect(await failingController.seekToChapter('c3'), isTrue);
    await tester.pump();
    expect(find.byKey(MiniPlayer.errorKey), findsNothing);
    expect(find.textContaining('这一章打不开'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
