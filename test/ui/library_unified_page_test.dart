import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/batch_refresh_controller.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/domain/library/batch_refresh_state.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/ui/pages/library/library_page.dart';
import 'package:tometone/ui/pages/library/library_roots.dart';
import 'package:tometone/ui/theme/app_theme.dart';

import 'ui_test_harness.dart';

class _FakeBatchRefreshController extends BatchRefreshController {
  _FakeBatchRefreshController(this._initial);

  final BatchRefreshState _initial;

  @override
  BatchRefreshState build() => _initial;
}

BookSummary _makeBook({
  required String id,
  required String title,
  String sourceType = 'local',
  String? sourceId,
  String? sourceName,
  bool? sourceEnabled,
  bool? sourceDeleted,
  bool onShelf = true,
  int totalChapters = 10,
  int missingChapters = 0,
  String? author,
  String? narrator,
  String? description,
  List<String> tags = const <String>[],
  int? progressPositionMs,
  bool isFinished = false,
}) {
  return BookSummary(
    id: id,
    title: title,
    libraryRootId: 'root-1',
    rootPath: 'books/$id',
    coverSource: CoverSource.typography,
    totalChapters: totalChapters,
    totalDurationMs: 60000,
    missingChapters: missingChapters,
    sourceType: sourceType,
    sourceId: sourceId,
    sourceName: sourceName,
    sourceEnabled: sourceEnabled,
    sourceDeleted: sourceDeleted,
    onShelf: onShelf,
    author: author,
    narrator: narrator,
    description: description,
    tags: tags,
    progressPositionMs: progressPositionMs,
    isFinished: isFinished,
  );
}

BookSource _makeSource({
  required String id,
  required String name,
  bool enabled = true,
}) {
  return BookSource(
    id: id,
    libraryRootId: 'root-1',
    name: name,
    sourceUrl: 'https://example.com/$id',
    sourceType: 1,
    rawJson: '{}',
    header: const <String, String>{},
    enabled: enabled,
    enabledExplore: true,
    customOrder: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

LibraryRootView _makeRoot({
  String id = 'root-1',
  String displayName = '本地音频库',
  String uri = '/storage/audio',
}) {
  return LibraryRootView(
    id: id,
    type: 'local',
    uri: uri,
    displayName: displayName,
    lastScanAt: DateTime(2026, 10, 20),
  );
}

void main() {
  testWidgets('书库页展示来源管理面板，不再渲染单本书籍卡片及搜索框', (tester) async {
    usePhoneViewport(tester);

    final books = <BookSummary>[
      _makeBook(
        id: 'local-1',
        title: '三国演义',
        sourceType: 'local',
        author: '罗贯中',
      ),
      _makeBook(
        id: 'online-1',
        title: '斗破苍穹',
        sourceType: 'online',
        sourceId: 'src-1',
        sourceName: '听友听书',
        sourceEnabled: true,
        onShelf: false,
        author: '天蚕土豆',
      ),
    ];

    final roots = <LibraryRootView>[_makeRoot()];
    final sources = <BookSource>[_makeSource(id: 'src-1', name: '听友听书')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...testOverrides(
            controller: testController(FakePlaybackEngine()),
            books: books,
            roots: roots,
          ),
          bookSourcesProvider.overrideWith((ref) => sources),
        ],
        child: const MaterialApp(home: Scaffold(body: LibraryPage())),
      ),
    );
    await tester.pumpAndSettle();

    // 不再渲染具体书籍卡片与搜索框
    expect(find.text('三国演义'), findsNothing);
    expect(find.text('斗破苍穹'), findsNothing);
    expect(find.byKey(LibraryKeys.searchFieldKey), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(LibraryKeys.sourceFilterAll), findsNothing);

    // 顶部展示“我的书库 · 共 N 册 · 本地 X · 在线 Y”
    expect(find.text('我的书库'), findsOneWidget);
    expect(find.text('共 2 册 · 本地 1 · 在线 1'), findsOneWidget);
  });

  testWidgets('展示本地扫描目录卡片（包含路径、重新扫描、添加目录）', (tester) async {
    usePhoneViewport(tester);

    final roots = <LibraryRootView>[
      _makeRoot(
        id: 'root-audio',
        displayName: '相声评书集',
        uri: '/storage/audio',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...testOverrides(
            controller: testController(FakePlaybackEngine()),
            roots: roots,
          ),
          bookSourcesProvider.overrideWith((ref) => const <BookSource>[]),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: LibraryPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('本机目录'), findsOneWidget);
    expect(find.text('相声评书集'), findsOneWidget);
    expect(find.textContaining('storage/audio'), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.scanKey('root-audio')), findsOneWidget);
    expect(find.text('扫描'), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.addButtonKey), findsOneWidget);
  });

  testWidgets('展示在线书源卡片（包含书源数量、管理书源、导入新源）', (tester) async {
    usePhoneViewport(tester);

    final sources = <BookSource>[
      _makeSource(id: 's1', name: '酷听网', enabled: true),
      _makeSource(id: 's2', name: '备用源', enabled: false),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...testOverrides(
            controller: testController(FakePlaybackEngine()),
            roots: const <LibraryRootView>[],
          ),
          bookSourcesProvider.overrideWith((ref) => sources),
        ],
        child: const MaterialApp(home: Scaffold(body: LibraryPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LibraryKeys.onlineSourcesCardKey), findsOneWidget);
    expect(find.textContaining('共 2 个书源 · 1 个已启用'), findsOneWidget);
    expect(find.byKey(LibraryKeys.manageSourcesKey), findsOneWidget);
    expect(find.byKey(LibraryKeys.importSourceKey), findsOneWidget);
  });

  testWidgets('批量刷新胶囊在刷新状态下正常展示', (tester) async {
    usePhoneViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...testOverrides(
            controller: testController(FakePlaybackEngine()),
            roots: <LibraryRootView>[_makeRoot()],
          ),
          bookSourcesProvider.overrideWith((ref) => const <BookSource>[]),
          batchRefreshControllerProvider.overrideWith(
            () => _FakeBatchRefreshController(
              const BatchRefreshState(
                isRunning: true,
                total: 5,
                completed: 2,
                currentBookTitle: '三体',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: LibraryPage())),
      ),
    );
    await tester.pump();

    expect(find.textContaining('正在检查 2/5 本在线书更新...'), findsOneWidget);
  });

  testWidgets('无本地根和在线书源时展示友好指引空态', (tester) async {
    usePhoneViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...testOverrides(
            controller: testController(FakePlaybackEngine()),
            books: const <BookSummary>[],
            roots: const <LibraryRootView>[],
          ),
          bookSourcesProvider.overrideWith((ref) => const <BookSource>[]),
        ],
        child: const MaterialApp(home: Scaffold(body: LibraryPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LibraryKeys.emptyKey), findsOneWidget);
    expect(find.text('还没有书'), findsOneWidget);
    expect(find.byKey(LibraryKeys.importSourceKey), findsOneWidget);
    expect(find.byKey(LibraryKeys.addLocalRootKey), findsOneWidget);
    expect(find.byKey(LibraryKeys.goToDiscoveryKey), findsOneWidget);
  });

  testWidgets('320dp + 2.0 大字号 + 深色无 overflow', (tester) async {
    final books = <BookSummary>[
      _makeBook(id: 'b1', title: '短书', sourceType: 'local'),
      _makeBook(id: 'b2', title: '长书名测试长书名测试', sourceType: 'online'),
    ];
    final roots = <LibraryRootView>[_makeRoot()];
    final sources = <BookSource>[_makeSource(id: 's1', name: '源1')];

    tester.view.physicalSize = const Size(320 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...testOverrides(
            controller: testController(FakePlaybackEngine()),
            books: books,
            roots: roots,
          ),
          bookSourcesProvider.overrideWith((ref) => sources),
        ],
        child: MaterialApp(
          theme: AppTheme.build(brightness: Brightness.dark),
          home: const MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(2.0),
              disableAnimations: true,
            ),
            child: Scaffold(body: LibraryPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
