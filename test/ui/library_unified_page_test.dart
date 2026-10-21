import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/ui/pages/library/library_page.dart';
import 'package:tometone/ui/theme/app_theme.dart';

import 'ui_test_harness.dart';

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

void main() {
  testWidgets('本地与在线书混排显示，包括 onShelf=false 的在线书', (tester) async {
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...testOverrides(
            controller: testController(FakePlaybackEngine()),
            books: books,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: LibraryPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('三国演义'), findsOneWidget);
    expect(find.text('斗破苍穹'), findsOneWidget);
    expect(find.text('听友听书'), findsOneWidget);
    expect(find.textContaining('共 2 册'), findsOneWidget);
  });

  testWidgets('来源 chips 筛选全部/本地/在线', (tester) async {
    usePhoneViewport(tester);

    final books = <BookSummary>[
      _makeBook(id: 'local-1', title: '本地评书', sourceType: 'local'),
      _makeBook(
        id: 'online-1',
        title: '网络小说',
        sourceType: 'online',
        sourceId: 'src-1',
        sourceName: '听友听书',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...testOverrides(
            controller: testController(FakePlaybackEngine()),
            books: books,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: LibraryPage())),
      ),
    );
    await tester.pumpAndSettle();

    // 默认全部
    expect(find.text('本地评书'), findsOneWidget);
    expect(find.text('网络小说'), findsOneWidget);

    // 过滤本地
    await tester.tap(find.byKey(LibraryKeys.sourceFilterLocal));
    await tester.pumpAndSettle();
    expect(find.text('本地评书'), findsOneWidget);
    expect(find.text('网络小说'), findsNothing);

    // 过滤在线
    await tester.tap(find.byKey(LibraryKeys.sourceFilterOnline));
    await tester.pumpAndSettle();
    expect(find.text('本地评书'), findsNothing);
    expect(find.text('网络小说'), findsOneWidget);

    // 回到全部
    await tester.tap(find.byKey(LibraryKeys.sourceFilterAll));
    await tester.pumpAndSettle();
    expect(find.text('本地评书'), findsOneWidget);
    expect(find.text('网络小说'), findsOneWidget);
  });

  testWidgets('搜索框匹配书名/作者/演播/简介/标签', (tester) async {
    usePhoneViewport(tester);

    final books = <BookSummary>[
      _makeBook(
        id: 'b1',
        title: '红楼梦',
        author: '曹雪芹',
        narrator: '张三',
        tags: const <String>['名著', '古典'],
      ),
      _makeBook(
        id: 'b2',
        title: '三体',
        author: '刘慈欣',
        description: '科幻巨作',
        tags: const <String>['科幻'],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...testOverrides(
            controller: testController(FakePlaybackEngine()),
            books: books,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: LibraryPage())),
      ),
    );
    await tester.pumpAndSettle();

    // 输入搜索
    await tester.enterText(find.byKey(LibraryKeys.searchFieldKey), '科幻');
    await tester.pumpAndSettle();

    expect(find.text('三体'), findsOneWidget);
    expect(find.text('红楼梦'), findsNothing);
  });

  testWidgets('异常与待刷新状态展示：已停用、已删除、目录待刷新', (tester) async {
    usePhoneViewport(tester);

    final books = <BookSummary>[
      _makeBook(
        id: 'b1',
        title: '停戏剧',
        sourceType: 'online',
        sourceId: 'src-1',
        sourceName: '停用源',
        sourceEnabled: false,
      ),
      _makeBook(
        id: 'b2',
        title: '删戏剧',
        sourceType: 'online',
        sourceId: 'src-2',
        sourceName: '已删源',
        sourceDeleted: true,
      ),
      _makeBook(
        id: 'b3',
        title: '无章书',
        sourceType: 'online',
        sourceId: 'src-3',
        sourceName: '新加源',
        sourceEnabled: true,
        totalChapters: 0,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...testOverrides(
            controller: testController(FakePlaybackEngine()),
            books: books,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: LibraryPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('来源已停用'), findsOneWidget);
    expect(find.text('来源已删除'), findsOneWidget);
    expect(find.text('目录待刷新'), findsOneWidget);
  });

  testWidgets('无书且无来源时展示导入书源与添加本机目录', (tester) async {
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

    expect(find.text('还没有书'), findsOneWidget);
    expect(find.byKey(LibraryKeys.importSourceKey), findsOneWidget);
    expect(find.byKey(LibraryKeys.addLocalRootKey), findsOneWidget);
  });

  testWidgets('有来源无书时展示去发现找书', (tester) async {
    usePhoneViewport(tester);

    final source = BookSource(
      id: 'src-1',
      libraryRootId: 'root-1',
      name: '听友听书',
      sourceUrl: 'https://tingyou.fm',
      sourceType: 1,
      rawJson: '{}',
      header: const <String, String>{},
      enabled: true,
      enabledExplore: true,
      customOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...testOverrides(
            controller: testController(FakePlaybackEngine()),
            books: const <BookSummary>[],
            roots: const <LibraryRootView>[],
          ),
          bookSourcesProvider.overrideWith((ref) => <BookSource>[source]),
        ],
        child: const MaterialApp(home: Scaffold(body: LibraryPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('还没有书'), findsOneWidget);
    expect(find.byKey(LibraryKeys.goToDiscoveryKey), findsOneWidget);
  });

  testWidgets('320dp + 2.0 大字号 + 深色无 overflow', (tester) async {
    final books = <BookSummary>[
      _makeBook(
        id: 'b1',
        title: '很长很长的书籍名称测试排版与换行不会产生溢出',
        sourceType: 'online',
        sourceId: 'src-1',
        sourceName: '有声小说听书源',
        sourceEnabled: true,
        author: '很长的作者名字',
        narrator: '很长的演播者名字',
        description: '这是一段很长的简介内容，用于测试小屏幕高字号下的布局表现。',
        tags: const <String>['悬疑', '灵异', '长篇故事'],
      ),
    ];

    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
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
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.build(),
          darkTheme: AppTheme.build(brightness: Brightness.dark),
          themeMode: ThemeMode.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2.0),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const Scaffold(body: LibraryPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('很长很长'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
