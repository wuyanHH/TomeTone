import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/library_root_service.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/library_root_providers.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/contracts/storage/directory_picker.dart';
import 'package:tometone/contracts/storage/fake_storage_provider.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/library/scan/scan_report.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/ui/pages/library/library_browser_page.dart';
import 'package:tometone/ui/pages/library/library_page.dart';
import 'package:tometone/ui/pages/library/library_roots.dart';
import 'package:tometone/ui/pages/library/local_roots_section.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

import 'ui_test_harness.dart';

/// 假的书库根服务：记录调用，扫描用 Completer 控制完成时机。
class _FakeLibraryRootService implements LibraryRootService {
  final List<({String path, String? name})> addCalls =
      <({String path, String? name})>[];
  final List<({String treeUri, String name})> safCalls =
      <({String treeUri, String name})>[];
  final List<String> scannedRootIds = <String>[];
  final List<({String id, String name})> renameCalls =
      <({String id, String name})>[];
  final List<String> removedRootIds = <String>[];
  final Map<String, Completer<ScanReport>> scanCompleters =
      <String, Completer<ScanReport>>{};
  final Map<String, Object> scanErrors = <String, Object>{};

  /// 移除时的失败注入。
  Exception? removeFailure;

  /// 重命名时的失败注入。
  Exception? renameFailure;

  /// 添加成功时的回调（测试用来模拟「重新查询后多了一条根」）。
  void Function(String uri, String? name)? onAdd;

  /// 重命名成功时的回调（测试用来模拟写入后的那条根）。
  void Function(String id, String name)? onRename;

  /// 移除成功时的回调（测试用来模拟级联删掉之后剩下的根）。
  void Function(String id)? onRemove;

  @override
  Future<String> addLocalRoot({
    required String absolutePath,
    String? displayName,
  }) async {
    addCalls.add((path: absolutePath, name: displayName));
    onAdd?.call(absolutePath, displayName);
    return 'root-${addCalls.length}';
  }

  @override
  Future<String> addSafRoot({
    required String treeUri,
    required String displayName,
  }) async {
    safCalls.add((treeUri: treeUri, name: displayName));
    onAdd?.call(treeUri, displayName);
    return 'root-saf-${safCalls.length}';
  }

  @override
  Future<ScanReport> scan(String libraryRootId) {
    scannedRootIds.add(libraryRootId);
    final Object? error = scanErrors[libraryRootId];
    if (error != null) {
      return Future<ScanReport>.error(error);
    }
    return (scanCompleters[libraryRootId] ??= Completer<ScanReport>()).future;
  }

  @override
  Future<void> renameRoot(String id, String displayName) async {
    renameCalls.add((id: id, name: displayName));
    final Exception? failure = renameFailure;
    if (failure != null) {
      throw failure;
    }
    onRename?.call(id, displayName);
  }

  @override
  Future<void> removeRoot(String id) async {
    removedRootIds.add(id);
    final Exception? failure = removeFailure;
    if (failure != null) {
      throw failure;
    }
    onRemove?.call(id);
  }

  @override
  Future<DateTime?> lastScanAt(String libraryRootId) async => null;
}

/// 假的目录选择器：记录弹了几次，返回预设结果或预设异常。
class _FakeDirectoryPicker implements DirectoryPicker {
  int calls = 0;
  PickedDirectory? picked;
  Exception? failure;

  @override
  Future<PickedDirectory?> pickDirectory() async {
    calls++;
    final Exception? error = failure;
    if (error != null) {
      throw error;
    }
    return picked;
  }
}

/// 假的只读书库查询：移除前的「影响范围」统计走这里。
class _FakeLibraryQueries implements LibraryQueries {
  _FakeLibraryQueries({this.booksByRoot = const {}});

  /// 每个书库根下的书目。
  final Map<String, List<BookSummary>> booksByRoot;

  /// 查询失败注入（用来验证退回书架缓存的分支）。
  Exception? failure;

  /// 每次统计问过的书库根。
  final List<String> queriedRootIds = <String>[];

  @override
  Future<List<BookSummary>> listBooks({
    String? libraryRootId,
    int limit = 50,
    int offset = 0,
  }) async {
    final Exception? error = failure;
    if (error != null) {
      throw error;
    }
    queriedRootIds.add(libraryRootId ?? '');
    final List<BookSummary> all =
        booksByRoot[libraryRootId] ?? const <BookSummary>[];
    return all.skip(offset).take(limit).toList(growable: false);
  }

  @override
  Future<List<BookSummary>> listAllBooks() async {
    final Exception? error = failure;
    if (error != null) {
      throw error;
    }
    final List<BookSummary> all = <BookSummary>[
      for (final books in booksByRoot.values) ...books,
    ];
    return all;
  }

  @override
  Future<List<String>> listBookTags() async => const <String>[];

  @override
  Future<List<LibraryRootView>> libraryRoots() async =>
      const <LibraryRootView>[];

  @override
  Future<BookDetail?> bookDetail(String bookId) async => null;

  @override
  Future<void> saveProgress({
    required String bookId,
    required String chapterId,
    required Duration position,
    bool finished = false,
    DateTime? updatedAt,
  }) async {}

  @override
  Future<void> saveBookMetadata({
    required String bookId,
    required BookMetadataDraft metadata,
    bool manual = true,
    bool onlyFillEmpty = false,
    DateTime? updatedAt,
  }) async {}

  @override
  Future<void> savePreferences(
    String bookId,
    PerBookPrefsSnapshot preferences, {
    DateTime? updatedAt,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 在测试里临时关掉动效：滚动文本是无限循环动画，`pumpAndSettle` 等不到头。
class _ReduceMotion extends StatelessWidget {
  const _ReduceMotion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child,
    );
  }
}

ScanReport _report({
  int booksSeen = 24,
  int booksAdded = 3,
  int booksUpdated = 1,
  int volumesAdded = 12,
  int chaptersSeen = 480,
  int chaptersAdded = 240,
  int chaptersUpdated = 2,
  int chaptersMarkedMissing = 1,
  int chaptersRestored = 0,
  int ignoredFiles = 6,
  List<String> failedPaths = const <String>[],
  Duration elapsed = const Duration(milliseconds: 1840),
}) {
  return ScanReport(
    libraryRootId: testRootId,
    booksSeen: booksSeen,
    booksAdded: booksAdded,
    booksUpdated: booksUpdated,
    volumesAdded: volumesAdded,
    chaptersSeen: chaptersSeen,
    chaptersAdded: chaptersAdded,
    chaptersUpdated: chaptersUpdated,
    chaptersMarkedMissing: chaptersMarkedMissing,
    chaptersRestored: chaptersRestored,
    ignoredFiles: ignoredFiles,
    failedPaths: failedPaths,
    elapsed: elapsed,
  );
}

LibraryRootView _root({
  String id = testRootId,
  String uri = testRootUri,
  String displayName = '本机书库',
  String type = 'local',
  DateTime? lastScanAt,
}) {
  return LibraryRootView(
    id: id,
    type: type,
    uri: uri,
    displayName: displayName,
    lastScanAt: lastScanAt,
  );
}

void main() {
  late _FakeLibraryRootService service;

  setUp(() {
    service = _FakeLibraryRootService();
  });

  /// 把书库页塞进最小应用，并注入假的服务与可变的书库根列表。
  ///
  /// [reduceMotion] 只给「带超长本地路径」的用例用：长路径会触发滚动文本，
  /// 无限循环的动画会让 `pumpAndSettle` 永远等不到静止帧。
  Future<ProviderContainer> pumpLibrary(
    WidgetTester tester, {
    required List<LibraryRootView> Function() roots,
    String? suggestedPath,
    DirectoryPicker? picker,
    LibraryQueries? queries,
    void Function()? onRootsQuery,
    bool reduceMotion = false,
    double viewportWidth = 400,
  }) async {
    usePhoneViewport(tester);
    if (viewportWidth != 400) {
      tester.view.physicalSize = Size(viewportWidth, 800);
    }
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith((Ref ref) async {
          onRootsQuery?.call();
          return roots();
        }),
        booksProvider.overrideWith((Ref ref) async => const <BookSummary>[]),
        libraryRootServiceProvider.overrideWithValue(service),
        libraryQueriesProvider.overrideWithValue(
          queries ?? _FakeLibraryQueries(),
        ),
        directoryPickerProvider.overrideWithValue(
          picker ?? _FakeDirectoryPicker(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final Widget page = LocalRootsSection(suggestedRootPath: suggestedPath);
    await tester.pumpWidget(
      testApp(
        container,
        Scaffold(body: reduceMotion ? _ReduceMotion(child: page) : page),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// 打开「添加书库根」弹层（有根时点页首 `+`，空态点主按钮）。
  Future<void> openAddSheet(WidgetTester tester, {required Key entry}) async {
    await tester.tap(find.byKey(entry));
    await tester.pumpAndSettle();
  }

  testWidgets('空态：说明支持格式，只给一个主按钮，弹层里才分两个入口', (WidgetTester tester) async {
    await pumpLibrary(tester, roots: () => const <LibraryRootView>[]);

    expect(find.byKey(LibraryRootsKeys.rootsEmptyKey), findsOneWidget);
    expect(find.text('还没有书库根'), findsOneWidget);
    expect(find.textContaining('支持 mp3'), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.addRootKey), findsOneWidget);
    expect(
      find.byKey(LibraryRootsKeys.safPickKey),
      findsNothing,
      reason: '两个入口都收进弹层，不再常驻页面',
    );
    expect(find.text('高级：手动输入路径'), findsNothing);
    expect(find.text('本机目录'), findsOneWidget);

    await openAddSheet(tester, entry: LibraryRootsKeys.addRootKey);

    expect(find.byKey(LibraryRootsKeys.safPickKey), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.manualPathKey), findsOneWidget);
    expect(find.text('选择目录（SAF）'), findsOneWidget);
    expect(find.text('手动输入绝对路径'), findsOneWidget);
    expect(find.text('推荐'), findsOneWidget);
    // 原来挂在两个大按钮下面的说明段落，现在并进弹层。
    expect(find.textContaining('SAF 目录无法在添加时校验是否还能访问'), findsOneWidget);
    expect(find.textContaining('扫描只读取目录里的音频文件'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('列表：`+` 在页首右上角，两个入口都在弹层里', (WidgetTester tester) async {
    await pumpLibrary(tester, roots: () => <LibraryRootView>[testRoot]);

    expect(find.byKey(LibraryRootsKeys.rootsListKey), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.addRootButtonKey), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.addRootKey), findsNothing);
    expect(find.text('选择目录（SAF）'), findsNothing);
    expect(find.text('高级：手动输入路径'), findsNothing);
    expect(find.text('本机目录'), findsOneWidget);

    // `+` 的触控目标 ≥48dp，且在标题行的右侧。
    final Size size = tester.getSize(
      find.byKey(LibraryRootsKeys.addRootButtonKey),
    );
    expect(size.height, greaterThanOrEqualTo(AppSizes.minTouchTarget));
    expect(
      tester.getCenter(find.byKey(LibraryRootsKeys.addRootButtonKey)).dx,
      closeTo(400 - AppSpacing.lg - size.width / 2, 0.5),
    );

    await openAddSheet(tester, entry: LibraryRootsKeys.addRootButtonKey);

    expect(find.byKey(LibraryRootsKeys.safPickKey), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.manualPathKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('列表：名称下展示可读位置，原始 SAF URI 不再上列表', (WidgetTester tester) async {
    const String safUri =
        'content://com.android.externalstorage.documents/tree/primary%3AAudiobooks';
    await pumpLibrary(
      tester,
      roots: () => <LibraryRootView>[
        _root(
          uri: safUri,
          displayName: '本地书库',
          type: 'saf',
          lastScanAt: DateTime(2026, 10, 19, 7, 11),
        ),
        _root(
          id: 'root-2',
          uri: '/data/user/0/com.tometone.app',
          displayName: 'com.tometone.app',
        ),
      ],
      reduceMotion: true,
    );

    expect(find.byKey(LibraryRootsKeys.rootsListKey), findsOneWidget);
    expect(find.text('本地书库'), findsOneWidget);
    expect(find.text('com.tometone.app'), findsOneWidget);
    expect(find.text('上次扫描 · 2026-10-19 07:11'), findsOneWidget);
    expect(find.text('从未扫描'), findsOneWidget);

    // SAF 根翻成可读路径；本地根保留完整绝对路径（不只留末级目录）。
    expect(find.text('内部存储/Audiobooks'), findsOneWidget);
    expect(find.text('/data/user/0/com.tometone.app'), findsOneWidget);
    expect(find.textContaining('content://'), findsNothing);

    // 类型标签不再出现在列表上。
    expect(find.text('本地目录'), findsNothing);
    expect(find.text('saf'), findsNothing);

    // 触控目标 ≥48dp。
    expect(
      tester.getSize(find.byKey(LibraryRootsKeys.scanKey(testRootId))).height,
      greaterThanOrEqualTo(AppSizes.minTouchTarget),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄屏 320dp：长名称与长路径不溢出，扫描与菜单仍有完整触控目标', (WidgetTester tester) async {
    await pumpLibrary(
      tester,
      roots: () => <LibraryRootView>[
        _root(
          uri: r'E:\Projects\TomeTone\很长的目录\有声书\武侠\第二季\完整合集',
          displayName: '一个名字非常长的书库根用于确认窄屏不会把文字挤破',
        ),
      ],
      viewportWidth: 320,
      reduceMotion: true,
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(LibraryRootsKeys.scanKey(testRootId))).height,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester
          .getSize(find.byKey(LibraryRootsKeys.rootMenuKey(testRootId)))
          .width,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester
          .getSize(find.byKey(LibraryRootsKeys.rootCardKey(testRootId)))
          .width,
      lessThanOrEqualTo(320),
    );
  });

  testWidgets('点卡片进入只读浏览；扫描与 `⋮` 各自独立，不会误触发进入', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final FakeStorageProvider browserProvider = FakeStorageProvider.fromPaths(
      <String, int>{'001.mp3': 10},
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith(
          (Ref ref) async => const <LibraryRootView>[testRoot],
        ),
        booksProvider.overrideWith((Ref ref) async => const <BookSummary>[]),
        libraryRootServiceProvider.overrideWithValue(service),
        libraryQueriesProvider.overrideWithValue(_FakeLibraryQueries()),
        storageProviderFactoryProvider.overrideWithValue(
          (String uri) => browserProvider,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LocalRootsSection())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LibraryRootsKeys.scanKey(testRootId)));
    await tester.pump();
    expect(
      find.byType(LibraryBrowserPage),
      findsNothing,
      reason: '点扫描不能顺带进入浏览页',
    );
    // 结束扫描，避免不定长进度条让后面的 pumpAndSettle 永远等不到静止。
    service.scanCompleters[testRootId]!.complete(_report());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LibraryRootsKeys.rootMenuKey(testRootId)));
    await tester.pumpAndSettle();
    expect(
      find.byType(LibraryBrowserPage),
      findsNothing,
      reason: '点 `⋮` 不能顺带进入浏览页',
    );
    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LibraryRootsKeys.rootCardKey(testRootId)));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryBrowserPage), findsOneWidget);
    expect(find.text('001.mp3'), findsOneWidget);
    expect(find.text('/library'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LibraryBrowserPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('手动输入：从弹层第二个入口进表单，写入后重新查询列表', (WidgetTester tester) async {
    final Directory temp = Directory.systemTemp.createTempSync(
      'tometone-library-',
    );
    addTearDown(() {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    });

    List<LibraryRootView> roots = <LibraryRootView>[testRoot];
    service.onAdd = (String path, String? name) {
      // 服务端落库后，列表重新查询就应该看到这条根。
      roots = <LibraryRootView>[
        ...roots,
        _root(id: 'root-2', uri: path, displayName: name ?? '临时书库'),
      ];
    };

    final ProviderContainer container = await pumpLibrary(
      tester,
      roots: () => roots,
      suggestedPath: temp.path,
      reduceMotion: true,
    );
    expect(container.read(libraryRootsProvider).value, hasLength(1));

    await openAddSheet(tester, entry: LibraryRootsKeys.addRootButtonKey);
    await tester.tap(find.byKey(LibraryRootsKeys.manualPathKey));
    await tester.pumpAndSettle();

    final TextFormField pathField = tester.widget<TextFormField>(
      find.byKey(LibraryRootsKeys.pathFieldKey),
    );
    expect(pathField.controller?.text, temp.path);

    // 返回上一步：两个入口还在。
    await tester.tap(find.byKey(LibraryRootsKeys.addSheetBackKey));
    await tester.pumpAndSettle();
    expect(find.byKey(LibraryRootsKeys.manualPathKey), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.pathFieldKey), findsNothing);

    await tester.tap(find.byKey(LibraryRootsKeys.manualPathKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(LibraryRootsKeys.nameFieldKey), '我的书库');
    await tester.tap(find.byKey(LibraryRootsKeys.submitRootKey));
    await tester.pumpAndSettle();

    expect(service.addCalls, hasLength(1));
    expect(service.addCalls.single.path, temp.path);
    expect(service.addCalls.single.name, '我的书库');
    expect(find.byKey(LibraryRootsKeys.submitRootKey), findsNothing);
    expect(find.byKey(LibraryRootsKeys.noticeKey), findsOneWidget);
    expect(find.textContaining('已添加「我的书库」'), findsOneWidget);
    expect(find.text('我的书库'), findsOneWidget);
    expect(
      container.read(libraryRootsProvider).value,
      hasLength(2),
      reason: '添加成功后必须重新查询书库根',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('手动输入失败：空路径与不存在目录都用表单 errorText 就地提示', (
    WidgetTester tester,
  ) async {
    await pumpLibrary(
      tester,
      roots: () => const <LibraryRootView>[testRoot],
      suggestedPath: '/definitely/not/here/books',
    );

    await openAddSheet(tester, entry: LibraryRootsKeys.addRootButtonKey);
    await tester.tap(find.byKey(LibraryRootsKeys.manualPathKey));
    await tester.pumpAndSettle();
    expect(find.byKey(LibraryRootsKeys.submitRootKey), findsOneWidget);

    await tester.enterText(find.byKey(LibraryRootsKeys.pathFieldKey), '   ');
    await tester.tap(find.byKey(LibraryRootsKeys.submitRootKey));
    await tester.pumpAndSettle();
    expect(find.text('请输入书库根的绝对路径'), findsOneWidget);
    expect(service.addCalls, isEmpty);

    await tester.enterText(
      find.byKey(LibraryRootsKeys.pathFieldKey),
      '/definitely/not/here/books',
    );
    await tester.tap(find.byKey(LibraryRootsKeys.submitRootKey));
    await tester.pumpAndSettle();
    expect(find.text('目录不存在：/definitely/not/here/books'), findsOneWidget);
    expect(service.addCalls, isEmpty);
    expect(find.byKey(LibraryRootsKeys.submitRootKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('手动输入重复：同一路径已在书库时就地提示，不调用写入', (WidgetTester tester) async {
    final Directory temp = Directory.systemTemp.createTempSync(
      'tometone-library-dup-',
    );
    addTearDown(() {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    });

    await pumpLibrary(
      tester,
      roots: () => <LibraryRootView>[
        _root(uri: temp.path, displayName: '已有书库'),
      ],
      suggestedPath: temp.path,
      reduceMotion: true,
    );

    await openAddSheet(tester, entry: LibraryRootsKeys.addRootButtonKey);
    await tester.tap(find.byKey(LibraryRootsKeys.manualPathKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LibraryRootsKeys.submitRootKey));
    await tester.pumpAndSettle();

    expect(service.addCalls, isEmpty, reason: '同路径已存在时不应写入');
    expect(find.textContaining('这个目录已经在书库里'), findsOneWidget);
    expect(
      find.byKey(LibraryRootsKeys.submitRootKey),
      findsOneWidget,
      reason: '弹层保持打开，用户可以改路径',
    );
    expect(find.byKey(LibraryRootsKeys.noticeKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SAF：点入口只弹一次选择器，用户取消时静默', (WidgetTester tester) async {
    final _FakeDirectoryPicker picker = _FakeDirectoryPicker();
    int rootsQueries = 0;

    await pumpLibrary(
      tester,
      roots: () => const <LibraryRootView>[testRoot],
      picker: picker,
      onRootsQuery: () => rootsQueries++,
    );
    expect(rootsQueries, 1);

    await openAddSheet(tester, entry: LibraryRootsKeys.addRootButtonKey);
    await tester.tap(find.byKey(LibraryRootsKeys.safPickKey));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(service.safCalls, isEmpty, reason: '取消不应写入书库根');
    expect(find.byKey(LibraryRootsKeys.noticeKey), findsNothing);
    expect(
      find.byKey(LibraryRootsKeys.safErrorKey),
      findsNothing,
      reason: '取消不是错误',
    );
    expect(find.textContaining('已添加'), findsNothing);
    expect(rootsQueries, 1, reason: '取消不应刷新列表');
    // 取消后回到两个入口，按钮仍然可以再点。
    expect(find.byKey(LibraryRootsKeys.safPickKey), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.manualPathKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SAF：选中目录后原样写入 tree URI 与名称，并重新查询列表', (
    WidgetTester tester,
  ) async {
    const String treeUri =
        'content://com.android.externalstorage.documents/tree/primary%3ABooks';
    final _FakeDirectoryPicker picker = _FakeDirectoryPicker()
      ..picked = const PickedDirectory(uri: treeUri, name: 'Books');
    int rootsQueries = 0;
    List<LibraryRootView> roots = <LibraryRootView>[testRoot];
    service.onAdd = (String uri, String? name) {
      roots = <LibraryRootView>[
        ...roots,
        _root(
          id: 'root-saf',
          uri: uri,
          displayName: name ?? 'Books',
          type: 'saf',
        ),
      ];
    };

    final ProviderContainer container = await pumpLibrary(
      tester,
      roots: () => roots,
      picker: picker,
      onRootsQuery: () => rootsQueries++,
    );
    expect(rootsQueries, 1);

    await openAddSheet(tester, entry: LibraryRootsKeys.addRootButtonKey);
    await tester.tap(find.byKey(LibraryRootsKeys.safPickKey));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(service.safCalls, hasLength(1));
    expect(service.safCalls.single.treeUri, treeUri);
    expect(service.safCalls.single.name, 'Books');
    expect(service.addCalls, isEmpty, reason: 'SAF 不应走本地路径入口');

    expect(find.byKey(LibraryRootsKeys.noticeKey), findsOneWidget);
    expect(find.textContaining('已添加「Books」'), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.safErrorKey), findsNothing);
    expect(rootsQueries, 2, reason: '添加成功后必须重新查询书库根');
    expect(
      container.read(libraryRootsProvider).value,
      hasLength(2),
      reason: '列表以重新查询结果为准',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('SAF 重复：同一 tree URI 已在书库时不写入，弹层里就地提示', (
    WidgetTester tester,
  ) async {
    const String treeUri =
        'content://com.android.externalstorage.documents/tree/primary%3ABooks';
    final _FakeDirectoryPicker picker = _FakeDirectoryPicker()
      ..picked = const PickedDirectory(uri: treeUri, name: 'Books');
    int rootsQueries = 0;

    final ProviderContainer container = await pumpLibrary(
      tester,
      roots: () => <LibraryRootView>[
        _root(id: 'root-saf', uri: treeUri, displayName: 'Books', type: 'saf'),
      ],
      picker: picker,
      onRootsQuery: () => rootsQueries++,
    );
    expect(rootsQueries, 1);

    await openAddSheet(tester, entry: LibraryRootsKeys.addRootButtonKey);
    await tester.tap(find.byKey(LibraryRootsKeys.safPickKey));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(service.safCalls, isEmpty, reason: '同 tree URI 已存在时不应写入');
    expect(find.byKey(LibraryRootsKeys.duplicateNoticeKey), findsOneWidget);
    expect(find.textContaining('这个目录已经在书库里'), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.safErrorKey), findsNothing);
    expect(rootsQueries, 1, reason: '没有写入就不该刷新列表');
    expect(container.read(libraryRootsProvider).value, hasLength(1));
    // 弹层还开着，用户可以改用手动输入。
    expect(find.byKey(LibraryRootsKeys.manualPathKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SAF：平台未接线时就地说明，并指向手动输入路径', (WidgetTester tester) async {
    final _FakeDirectoryPicker picker = _FakeDirectoryPicker()
      ..failure = MissingPluginException(
        'No implementation found for method openDirectory on channel tometone/saf',
      );
    int rootsQueries = 0;
    await pumpLibrary(
      tester,
      roots: () => const <LibraryRootView>[testRoot],
      picker: picker,
      onRootsQuery: () => rootsQueries++,
    );

    await openAddSheet(tester, entry: LibraryRootsKeys.addRootButtonKey);
    await tester.tap(find.byKey(LibraryRootsKeys.safPickKey));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(service.safCalls, isEmpty);
    expect(find.byKey(LibraryRootsKeys.safErrorKey), findsOneWidget);
    expect(find.text('这里没有系统目录选择器'), findsOneWidget);
    expect(find.textContaining('当前平台没有接入目录选择'), findsOneWidget);
    expect(find.textContaining('MissingPluginException'), findsNothing);
    expect(find.byKey(LibraryRootsKeys.noticeKey), findsNothing);
    expect(rootsQueries, 1);
    expect(
      find.byKey(LibraryRootsKeys.safPickKey),
      findsOneWidget,
      reason: '失败后可以重试',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('SAF：busy 时就地说明「已有选择在进行」，不暴露原始异常', (WidgetTester tester) async {
    final _FakeDirectoryPicker picker = _FakeDirectoryPicker()
      ..failure = PlatformException(code: 'busy', message: '已有目录选择在进行');
    await pumpLibrary(
      tester,
      roots: () => const <LibraryRootView>[testRoot],
      picker: picker,
    );

    await openAddSheet(tester, entry: LibraryRootsKeys.addRootButtonKey);
    await tester.tap(find.byKey(LibraryRootsKeys.safPickKey));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(service.safCalls, isEmpty);
    expect(find.byKey(LibraryRootsKeys.safErrorKey), findsOneWidget);
    expect(find.text('目录选择器正在使用'), findsOneWidget);
    expect(find.textContaining('已经有一个目录选择在进行'), findsOneWidget);
    expect(find.textContaining('PlatformException'), findsNothing);
    expect(find.textContaining('busy'), findsNothing);
    expect(find.byKey(LibraryRootsKeys.noticeKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('扫描成功：先不确定进度，完成后出摘要并失效书架与根列表', (WidgetTester tester) async {
    usePhoneViewport(tester);
    int rootsQueries = 0;
    int booksQueries = 0;
    List<LibraryRootView> roots = <LibraryRootView>[testRoot];

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith((Ref ref) async {
          rootsQueries++;
          return roots;
        }),
        booksProvider.overrideWith((Ref ref) async {
          booksQueries++;
          return const <BookSummary>[];
        }),
        libraryRootServiceProvider.overrideWithValue(service),
        libraryQueriesProvider.overrideWithValue(_FakeLibraryQueries()),
      ],
    );
    addTearDown(container.dispose);
    // 书架在别处被监听：invalidate 之后应真的重新查询，而不是只丢缓存。
    final ProviderSubscription<AsyncValue<List<BookSummary>>> booksSub =
        container.listen(booksProvider, (_, _) {}, fireImmediately: true);
    addTearDown(booksSub.close);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LocalRootsSection())),
    );
    await tester.pumpAndSettle();
    expect(rootsQueries, 1);
    expect(booksQueries, 1);

    await tester.tap(find.byKey(LibraryRootsKeys.scanKey(testRootId)));
    await tester.pump();

    expect(service.scannedRootIds, <String>[testRootId]);
    expect(find.text('正在扫描…大书库可能需要几十秒。'), findsOneWidget);
    expect(find.text('扫描中'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(LibraryRootsKeys.scanKey(testRootId)),
          )
          .onPressed,
      isNull,
      reason: '扫描中必须禁用按钮',
    );
    expect(rootsQueries, 1, reason: '扫描完成前不应刷新列表');
    expect(booksQueries, 1);

    // 服务端在扫描结束时写入了 lastScanAt，重新查询后应反映出来。
    roots = <LibraryRootView>[
      _root(lastScanAt: DateTime(2026, 10, 18, 14, 32)),
    ];
    service.scanCompleters[testRootId]!.complete(_report());
    await tester.pumpAndSettle();

    expect(find.byKey(LibraryRootsKeys.reportKey(testRootId)), findsOneWidget);
    expect(find.text('扫描完成'), findsOneWidget);
    expect(find.text('新增 3 册 · 12 卷 · 240 章'), findsOneWidget);
    expect(find.text('更新 1 册 · 更新 2 章'), findsOneWidget);
    // 「忽略 N 个非音频文件」在正常扫到书时不再铺出来。
    expect(find.text('标记缺失 1 章'), findsOneWidget);
    expect(find.textContaining('忽略'), findsNothing);
    // 耗时不再展示。
    expect(find.textContaining('用时'), findsNothing);
    expect(find.text('上次扫描 · 2026-10-18 14:32'), findsOneWidget);
    expect(rootsQueries, 2, reason: '扫描成功必须失效书库根列表');
    expect(booksQueries, 2, reason: '扫描成功必须失效书架');
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(LibraryRootsKeys.scanKey(testRootId)),
          )
          .onPressed,
      isNotNull,
      reason: '扫描结束后按钮恢复可用',
    );
    expect(tester.takeException(), isNull);

    // 收尾：让成功面板的自动收起计时器走完，避免留下挂起的 Timer。
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
  });

  testWidgets('扫描失败：StateError 就地展示具体原因，不刷新书架', (WidgetTester tester) async {
    usePhoneViewport(tester);
    int rootsQueries = 0;
    int booksQueries = 0;
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith((Ref ref) async {
          rootsQueries++;
          return const <LibraryRootView>[testRoot];
        }),
        booksProvider.overrideWith((Ref ref) async {
          booksQueries++;
          return const <BookSummary>[];
        }),
        libraryRootServiceProvider.overrideWithValue(service),
        libraryQueriesProvider.overrideWithValue(_FakeLibraryQueries()),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<AsyncValue<List<BookSummary>>> booksSub =
        container.listen(booksProvider, (_, _) {}, fireImmediately: true);
    addTearDown(booksSub.close);

    service.scanErrors[testRootId] = StateError('目录不存在：/library/books');

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LocalRootsSection())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LibraryRootsKeys.scanKey(testRootId)));
    await tester.pumpAndSettle();

    expect(
      find.byKey(LibraryRootsKeys.scanErrorKey(testRootId)),
      findsOneWidget,
    );
    expect(find.text('扫描没有完成'), findsOneWidget);
    expect(find.text('目录不存在：/library/books'), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.reportKey(testRootId)), findsNothing);
    expect(booksQueries, 1, reason: '失败不应触发书架失效');
    expect(rootsQueries, 1, reason: '失败不应触发根列表失效');
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(LibraryRootsKeys.scanKey(testRootId)),
          )
          .onPressed,
      isNotNull,
    );

    // 失败面板常驻：过掉成功面板的自动收起时限后依然在，直到用户收起。
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(
      find.byKey(LibraryRootsKeys.scanErrorKey(testRootId)),
      findsOneWidget,
      reason: '失败原因不自动收起',
    );

    await tester.tap(find.byKey(LibraryRootsKeys.dismissResultKey(testRootId)));
    await tester.pumpAndSettle();
    expect(find.byKey(LibraryRootsKeys.scanErrorKey(testRootId)), findsNothing);
    expect(find.text('从未扫描'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('扫描成功：结果短暂提示后自动收起，卡片只留「上次扫描」', (WidgetTester tester) async {
    usePhoneViewport(tester);
    List<LibraryRootView> roots = <LibraryRootView>[testRoot];
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith((Ref ref) async => roots),
        booksProvider.overrideWith((Ref ref) async => const <BookSummary>[]),
        libraryRootServiceProvider.overrideWithValue(service),
        libraryQueriesProvider.overrideWithValue(_FakeLibraryQueries()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LocalRootsSection())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LibraryRootsKeys.scanKey(testRootId)));
    await tester.pump();
    roots = <LibraryRootView>[_root(lastScanAt: DateTime(2026, 10, 19, 7, 11))];
    service.scanCompleters[testRootId]!.complete(_report());
    await tester.pumpAndSettle();

    expect(find.byKey(LibraryRootsKeys.reportKey(testRootId)), findsOneWidget);

    // 约 6 秒后自动收起；收起后卡片只剩一行「上次扫描」。
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.byKey(LibraryRootsKeys.reportKey(testRootId)), findsNothing);
    expect(find.text('扫描完成'), findsNothing);
    expect(find.text('上次扫描 · 2026-10-19 07:11'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('扫描成功：结果面板可手动收起，收起后不再自动弹出', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith(
          (Ref ref) async => const <LibraryRootView>[testRoot],
        ),
        booksProvider.overrideWith((Ref ref) async => const <BookSummary>[]),
        libraryRootServiceProvider.overrideWithValue(service),
        libraryQueriesProvider.overrideWithValue(_FakeLibraryQueries()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LocalRootsSection())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LibraryRootsKeys.scanKey(testRootId)));
    await tester.pump();
    service.scanCompleters[testRootId]!.complete(_report());
    await tester.pumpAndSettle();

    expect(find.byKey(LibraryRootsKeys.reportKey(testRootId)), findsOneWidget);

    await tester.tap(find.byKey(LibraryRootsKeys.dismissResultKey(testRootId)));
    await tester.pumpAndSettle();
    expect(find.byKey(LibraryRootsKeys.reportKey(testRootId)), findsNothing);

    // 收起是记在 provider 里的：再等一会儿也不会自己冒回来。
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.byKey(LibraryRootsKeys.reportKey(testRootId)), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('扫描成功：一个音频都没扫到时补一句解释（忽略的其它文件）', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith(
          (Ref ref) async => const <LibraryRootView>[testRoot],
        ),
        booksProvider.overrideWith((Ref ref) async => const <BookSummary>[]),
        libraryRootServiceProvider.overrideWithValue(service),
        libraryQueriesProvider.overrideWithValue(_FakeLibraryQueries()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LocalRootsSection())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LibraryRootsKeys.scanKey(testRootId)));
    await tester.pump();
    service.scanCompleters[testRootId]!.complete(
      _report(
        booksSeen: 0,
        booksAdded: 0,
        booksUpdated: 0,
        volumesAdded: 0,
        chaptersSeen: 0,
        chaptersAdded: 0,
        chaptersUpdated: 0,
        chaptersMarkedMissing: 0,
        ignoredFiles: 9,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('目录内没有音频文件'), findsOneWidget);
    expect(find.text('已忽略 9 个其它文件'), findsOneWidget);
    expect(find.text('没有发现新增或变更'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
  });

  testWidgets('移除：先给出影响范围与「不会删除文件」，确认后才级联清理', (WidgetTester tester) async {
    usePhoneViewport(tester);
    int rootsQueries = 0;
    int booksQueries = 0;
    List<LibraryRootView> roots = <LibraryRootView>[testRoot];
    final _FakeLibraryQueries queries = _FakeLibraryQueries(
      booksByRoot: <String, List<BookSummary>>{
        testRootId: <BookSummary>[
          testSummary(id: 'b1', totalChapters: 4),
          testSummary(id: 'b2', totalChapters: 6),
          testSummary(id: 'b3', totalChapters: 2),
        ],
        'root-other': <BookSummary>[testSummary(id: 'b9', totalChapters: 99)],
      },
    );
    service.onRemove = (String id) {
      roots = roots.where((LibraryRootView root) => root.id != id).toList();
    };

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith((Ref ref) async {
          rootsQueries++;
          return roots;
        }),
        booksProvider.overrideWith((Ref ref) async {
          booksQueries++;
          return const <BookSummary>[];
        }),
        libraryRootServiceProvider.overrideWithValue(service),
        libraryQueriesProvider.overrideWithValue(queries),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<AsyncValue<List<BookSummary>>> booksSub =
        container.listen(booksProvider, (_, _) {}, fireImmediately: true);
    addTearDown(booksSub.close);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LocalRootsSection())),
    );
    await tester.pumpAndSettle();
    expect(rootsQueries, 1);

    // 卡片的 `⋮` 里同时有重命名与移除；扫描留在卡片上，不在菜单里重复。
    await tester.tap(find.byKey(LibraryRootsKeys.rootMenuKey(testRootId)));
    await tester.pumpAndSettle();
    expect(
      find.byKey(LibraryRootsKeys.renameRootKey(testRootId)),
      findsOneWidget,
    );
    expect(
      find.byKey(LibraryRootsKeys.removeRootKey(testRootId)),
      findsOneWidget,
    );
    expect(find.text('重命名'), findsOneWidget);
    expect(find.text('移除书库根'), findsOneWidget);
    expect(find.text('重新扫描'), findsNothing);

    await tester.tap(find.byKey(LibraryRootsKeys.removeRootKey(testRootId)));
    await tester.pumpAndSettle();

    // 影响范围来自「移除前查一次」，只算这一条根。
    expect(queries.queriedRootIds, <String>[testRootId]);
    expect(find.byKey(LibraryRootsKeys.removeDialogKey), findsOneWidget);
    expect(find.textContaining('将移除 3 册 · 12 章的书目记录'), findsOneWidget);
    expect(find.textContaining('不会删除文件'), findsOneWidget);
    expect(find.textContaining('也不会改动目录里的任何内容'), findsOneWidget);
    // 手填的本地目录没有系统授权，不该出现「一并放弃授权」那句。
    expect(find.textContaining('系统授权'), findsNothing);
    expect(service.removedRootIds, isEmpty, reason: '确认之前不能动手');

    await tester.tap(find.byKey(LibraryRootsKeys.removeConfirmKey));
    await tester.pumpAndSettle();

    expect(service.removedRootIds, <String>[testRootId]);
    expect(rootsQueries, 2, reason: '移除后列表必须重新查询');
    expect(booksQueries, 2, reason: '级联删掉了书目，书架必须一起失效');
    expect(find.byKey(LibraryRootsKeys.rootsEmptyKey), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.noticeKey), findsOneWidget);
    expect(find.textContaining('已移除「本机书库」'), findsOneWidget);
    expect(find.textContaining('目录里的文件没有任何改动'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('移除：取消就什么都不做；统计不出来时也不拦着用户', (WidgetTester tester) async {
    usePhoneViewport(tester);
    int rootsQueries = 0;
    final _FakeLibraryQueries queries = _FakeLibraryQueries(
      booksByRoot: <String, List<BookSummary>>{
        testRootId: <BookSummary>[testSummary(id: 'b1', totalChapters: 4)],
      },
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith((Ref ref) async {
          rootsQueries++;
          return const <LibraryRootView>[testRoot];
        }),
        booksProvider.overrideWith((Ref ref) async => const <BookSummary>[]),
        libraryRootServiceProvider.overrideWithValue(service),
        libraryQueriesProvider.overrideWithValue(queries),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LocalRootsSection())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LibraryRootsKeys.rootMenuKey(testRootId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LibraryRootsKeys.removeRootKey(testRootId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LibraryRootsKeys.removeCancelKey));
    await tester.pumpAndSettle();

    expect(service.removedRootIds, isEmpty, reason: '取消不应移除');
    expect(rootsQueries, 1, reason: '取消不应刷新列表');
    expect(find.byKey(LibraryRootsKeys.noticeKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('移除：统计查询失败时退回书架缓存，数字照样给出来', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final _FakeLibraryQueries queries = _FakeLibraryQueries()
      ..failure = Exception('查询挂了');
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith(
          (Ref ref) async => const <LibraryRootView>[testRoot],
        ),
        booksProvider.overrideWith(
          (Ref ref) async => <BookSummary>[
            testSummary(id: 'b1', totalChapters: 3),
            testSummary(id: 'b2', totalChapters: 4),
            testSummary(
              id: 'b9',
              libraryRootId: 'root-other',
              totalChapters: 99,
            ),
          ],
        ),
        libraryRootServiceProvider.overrideWithValue(service),
        libraryQueriesProvider.overrideWithValue(queries),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LocalRootsSection())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LibraryRootsKeys.rootMenuKey(testRootId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LibraryRootsKeys.removeRootKey(testRootId)));
    await tester.pumpAndSettle();

    // testSummary 默认挂在 testRootId 下，第三条是别的根，不该算进来。
    expect(find.textContaining('将移除 2 册 · 7 章的书目记录'), findsOneWidget);
    expect(find.textContaining('不会删除文件'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('移除：服务失败时就地提示，不刷新列表', (WidgetTester tester) async {
    usePhoneViewport(tester);
    int rootsQueries = 0;
    service.removeFailure = Exception('数据库忙');
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith((Ref ref) async {
          rootsQueries++;
          return const <LibraryRootView>[testRoot];
        }),
        booksProvider.overrideWith((Ref ref) async => const <BookSummary>[]),
        libraryRootServiceProvider.overrideWithValue(service),
        libraryQueriesProvider.overrideWithValue(_FakeLibraryQueries()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LocalRootsSection())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LibraryRootsKeys.rootMenuKey(testRootId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LibraryRootsKeys.removeRootKey(testRootId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LibraryRootsKeys.removeConfirmKey));
    await tester.pumpAndSettle();

    expect(find.textContaining('没有移除成功'), findsOneWidget);
    expect(rootsQueries, 1, reason: '没删成功就不该当作列表变了');
    expect(find.text('本机书库'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('移除：系统授权目录会说明一并放弃系统授权', (WidgetTester tester) async {
    usePhoneViewport(tester);
    const String safUri =
        'content://com.android.externalstorage.documents/tree/primary%3ABooks';
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith(
          (Ref ref) async => <LibraryRootView>[
            _root(uri: safUri, displayName: 'Books', type: 'saf'),
          ],
        ),
        booksProvider.overrideWith((Ref ref) async => const <BookSummary>[]),
        libraryRootServiceProvider.overrideWithValue(service),
        libraryQueriesProvider.overrideWithValue(_FakeLibraryQueries()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LocalRootsSection())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LibraryRootsKeys.rootMenuKey(testRootId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LibraryRootsKeys.removeRootKey(testRootId)));
    await tester.pumpAndSettle();

    expect(find.byKey(LibraryRootsKeys.removeDialogKey), findsOneWidget);
    expect(find.textContaining('一并放弃对它的系统授权'), findsOneWidget);
    expect(find.textContaining('下次要重新选择并授权'), findsOneWidget);
    expect(find.textContaining('不会删除文件'), findsOneWidget);

    await tester.tap(find.byKey(LibraryRootsKeys.removeCancelKey));
    await tester.pumpAndSettle();
    expect(service.removedRootIds, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('手动输入：不预填（空），并把手填指向系统选择器', (WidgetTester tester) async {
    usePhoneViewport(tester);
    await pumpLibrary(
      tester,
      roots: () => const <LibraryRootView>[testRoot],
      // 显式传空串 = 移动端「不预填」的形态。
      suggestedPath: '',
    );

    await openAddSheet(tester, entry: LibraryRootsKeys.addRootButtonKey);
    await tester.tap(find.byKey(LibraryRootsKeys.manualPathKey));
    await tester.pumpAndSettle();

    final TextFormField pathField = tester.widget<TextFormField>(
      find.byKey(LibraryRootsKeys.pathFieldKey),
    );
    expect(pathField.controller?.text, isEmpty, reason: '不预填必然扫不出东西的私有目录');
    expect(find.textContaining('系统选择器'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('重命名：弹窗预填当前名字，保存后列表出现新名字', (WidgetTester tester) async {
    usePhoneViewport(tester);
    int rootsQueries = 0;
    List<LibraryRootView> roots = <LibraryRootView>[testRoot];
    service.onRename = (String id, String name) {
      roots = <LibraryRootView>[
        for (final LibraryRootView root in roots)
          if (root.id == id) _root(displayName: name) else root,
      ];
    };
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith((Ref ref) async {
          rootsQueries++;
          return roots;
        }),
        booksProvider.overrideWith((Ref ref) async => const <BookSummary>[]),
        libraryRootServiceProvider.overrideWithValue(service),
        libraryQueriesProvider.overrideWithValue(_FakeLibraryQueries()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LocalRootsSection())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LibraryRootsKeys.rootMenuKey(testRootId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LibraryRootsKeys.renameRootKey(testRootId)));
    await tester.pumpAndSettle();

    final TextField field = tester.widget<TextField>(
      find.byKey(LibraryRootsKeys.renameFieldKey),
    );
    expect(field.controller?.text, '本机书库');
    expect(find.textContaining('只改这里显示的名字'), findsOneWidget);

    // 空名字不提交。
    await tester.enterText(find.byKey(LibraryRootsKeys.renameFieldKey), '   ');
    await tester.tap(find.byKey(LibraryRootsKeys.renameSubmitKey));
    await tester.pumpAndSettle();
    expect(find.text('名字不能为空'), findsOneWidget);
    expect(service.renameCalls, isEmpty);

    // 名字没变也不写库。
    await tester.enterText(find.byKey(LibraryRootsKeys.renameFieldKey), '本机书库');
    await tester.tap(find.byKey(LibraryRootsKeys.renameSubmitKey));
    await tester.pumpAndSettle();
    expect(service.renameCalls, isEmpty, reason: '名字没变就不该写库');
    expect(find.byKey(LibraryRootsKeys.renameFieldKey), findsNothing);

    await tester.tap(find.byKey(LibraryRootsKeys.rootMenuKey(testRootId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LibraryRootsKeys.renameRootKey(testRootId)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(LibraryRootsKeys.renameFieldKey), ' 书房 ');
    await tester.tap(find.byKey(LibraryRootsKeys.renameSubmitKey));
    await tester.pumpAndSettle();

    expect(service.renameCalls, <({String id, String name})>[
      (id: testRootId, name: '书房'),
    ]);
    expect(find.text('书房'), findsOneWidget, reason: '列表以重新查询为准');
    expect(find.text('本机书库'), findsNothing);
    expect(rootsQueries, 2, reason: '重命名后必须重新查询列表');
    expect(tester.takeException(), isNull);
  });

  testWidgets('重命名：服务失败时就地提示，不刷新列表', (WidgetTester tester) async {
    usePhoneViewport(tester);
    int rootsQueries = 0;
    service.renameFailure = Exception('数据库忙');
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith((Ref ref) async {
          rootsQueries++;
          return const <LibraryRootView>[testRoot];
        }),
        booksProvider.overrideWith((Ref ref) async => const <BookSummary>[]),
        libraryRootServiceProvider.overrideWithValue(service),
        libraryQueriesProvider.overrideWithValue(_FakeLibraryQueries()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LocalRootsSection())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LibraryRootsKeys.rootMenuKey(testRootId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LibraryRootsKeys.renameRootKey(testRootId)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(LibraryRootsKeys.renameFieldKey), '书房');
    await tester.tap(find.byKey(LibraryRootsKeys.renameSubmitKey));
    await tester.pumpAndSettle();

    expect(find.textContaining('重命名没有成功'), findsOneWidget);
    expect(find.text('本机书库'), findsOneWidget);
    expect(rootsQueries, 1);
    expect(tester.takeException(), isNull);
  });

  group('hasLibraryRootWithUri', () {
    test('同一来源（忽略末尾分隔符）判为已存在，不同目录与空值不误报', () {
      expect(
        hasLibraryRootWithUri(<LibraryRootView>[
          _root(uri: '/library/books/'),
        ], '/library/books'),
        isTrue,
      );
      expect(
        hasLibraryRootWithUri(<LibraryRootView>[
          _root(uri: '/library/books'),
        ], '/library/books/'),
        isTrue,
      );
      expect(
        hasLibraryRootWithUri(<LibraryRootView>[
          _root(uri: testRootUri),
        ], '/library/books'),
        isFalse,
      );
      expect(
        hasLibraryRootWithUri(<LibraryRootView>[_root(uri: testRootUri)], '  '),
        isFalse,
      );
    });

    testWidgets('LibraryPage 纯净来源管理面板整合：包含顶部统计、本地目录和在线书源卡片', (WidgetTester tester) async {
      usePhoneViewport(tester);
      final container = ProviderContainer(
        overrides: <Override>[
          libraryRootsProvider.overrideWith((Ref ref) async => <LibraryRootView>[testRoot]),
          booksProvider.overrideWith((Ref ref) async => const <BookSummary>[]),
          libraryRootServiceProvider.overrideWithValue(service),
          libraryQueriesProvider.overrideWithValue(_FakeLibraryQueries()),
          directoryPickerProvider.overrideWithValue(_FakeDirectoryPicker()),
          bookSourcesProvider.overrideWith((Ref ref) async => <BookSource>[
            BookSource(
              id: 'source-1',
              libraryRootId: 'root-1',
              name: '我的书源',
              sourceUrl: 'https://source.example.com',
              sourceType: 1,
              rawJson: '{}',
              header: const <String, String>{},
              enabled: true,
              enabledExplore: true,
              customOrder: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        testApp(container, const Scaffold(body: LibraryPage())),
      );
      await tester.pumpAndSettle();

      // 顶部统计
      expect(find.text('我的书库'), findsOneWidget);
      expect(find.text('共 0 册 · 本地 0 · 在线 0'), findsOneWidget);

      // 本地目录段
      expect(find.text('本机目录'), findsOneWidget);
      expect(find.text('本机书库'), findsOneWidget);

      // 在线书源卡片
      expect(find.byKey(LibraryKeys.onlineSourcesCardKey), findsOneWidget);
      expect(find.textContaining('共 1 个书源 · 1 个已启用'), findsOneWidget);
      expect(find.byKey(LibraryKeys.manageSourcesKey), findsOneWidget);
    });
  });
}
