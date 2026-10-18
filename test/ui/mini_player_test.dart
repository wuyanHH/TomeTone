import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/providers/playback_providers.dart';
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
}
