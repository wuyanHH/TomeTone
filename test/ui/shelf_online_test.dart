import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/ui/pages/shelf/shelf_page.dart';
import 'package:tometone/ui/widgets/network_cover.dart';

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

  testWidgets('书架只显示 onShelf=true 的书', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final container = ProviderContainer(
      overrides: testOverrides(
        controller: controller,
        books: <BookSummary>[
          testSummary(id: 'on', title: '上架书'),
          testSummary(id: 'off', title: '下架书', onShelf: false),
        ],
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: ShelfPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('上架书'), findsOneWidget);
    expect(find.text('下架书'), findsNothing);
  });

  testWidgets('在线书使用网络封面并显示来源状态', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final source = _source();
    final container = ProviderContainer(
      overrides: testOverrides(
        controller: controller,
        books: <BookSummary>[
          testSummary(
            id: 'online',
            title: '在线书',
            sourceType: 'online',
            sourceId: source.id,
            coverUrl: 'http://127.0.0.1:1/missing.jpg',
            sourceName: source.name,
            sourceEnabled: true,
            sourceDeleted: true,
          ),
        ],
        extra: <Override>[
          bookSourceByIdProvider.overrideWith((Ref ref, String id) async {
            return id == source.id ? source : null;
          }),
        ],
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: ShelfPage())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NetworkCover), findsOneWidget);
    expect(find.text('来源已删除'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

BookSource _source() {
  final now = DateTime.utc(2026, 10, 21);
  return BookSource(
    id: 'source-1',
    libraryRootId: 'online-root',
    name: '听友听书',
    sourceUrl: 'https://e.test',
    sourceType: 1,
    rawJson: '{}',
    header: const <String, String>{'User-Agent': 'TomeTone-Test'},
    enabled: true,
    enabledExplore: true,
    customOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
}
