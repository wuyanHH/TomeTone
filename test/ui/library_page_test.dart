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
import 'package:tometone/contracts/storage/directory_picker.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/library/scan/scan_report.dart';
import 'package:tometone/ui/pages/library/library_page.dart';
import 'package:tometone/ui/pages/library/library_roots.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

import 'ui_test_harness.dart';

/// 假的书库根服务：记录调用，扫描用 Completer 控制完成时机。
class _FakeLibraryRootService implements LibraryRootService {
  final List<({String path, String? name})> addCalls =
      <({String path, String? name})>[];
  final List<({String treeUri, String name})> safCalls =
      <({String treeUri, String name})>[];
  final List<String> scannedRootIds = <String>[];
  final Map<String, Completer<ScanReport>> scanCompleters =
      <String, Completer<ScanReport>>{};
  final Map<String, Object> scanErrors = <String, Object>{};

  /// 添加成功时的回调（测试用来模拟「重新查询后多了一条根」）。
  void Function(String uri, String? name)? onAdd;

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
  Future<ProviderContainer> pumpLibrary(
    WidgetTester tester, {
    required List<LibraryRootView> Function() roots,
    String? suggestedPath,
    DirectoryPicker? picker,
    void Function()? onRootsQuery,
  }) async {
    usePhoneViewport(tester);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith((Ref ref) async {
          onRootsQuery?.call();
          return roots();
        }),
        booksProvider.overrideWith((Ref ref) async => const <BookSummary>[]),
        libraryRootServiceProvider.overrideWithValue(service),
        directoryPickerProvider.overrideWithValue(
          picker ?? _FakeDirectoryPicker(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      testApp(
        container,
        Scaffold(body: LibraryPage(suggestedRootPath: suggestedPath)),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('空态：说明支持格式并直接给出添加入口', (WidgetTester tester) async {
    await pumpLibrary(tester, roots: () => const <LibraryRootView>[]);

    expect(find.byKey(LibraryRootsKeys.rootsEmptyKey), findsOneWidget);
    expect(find.text('还没有书库根'), findsOneWidget);
    expect(find.textContaining('支持 mp3'), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.addRootKey), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.safPickKey), findsOneWidget);
    expect(find.text('选择目录（SAF）'), findsOneWidget);
    expect(find.text('高级：手动输入路径'), findsOneWidget);
    expect(find.text('0 个'), findsOneWidget);
    // 独立成页后的页首：眉题 + 标题都在，说明来源职责只属于这里。
    expect(find.text('书库 · LIBRARY'), findsOneWidget);
    expect(find.text('书库根'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('列表：展示名、单行中间省略的路径、最近扫描时间与扫描按钮', (WidgetTester tester) async {
    const String longPath =
        '/data/user/0/com.tometone.app/files/books/library-tooooo-long';
    await pumpLibrary(
      tester,
      roots: () => <LibraryRootView>[
        _root(uri: longPath, lastScanAt: DateTime(2026, 10, 18, 14, 32)),
        _root(id: 'root-2', uri: '/mnt/media/audio', displayName: '外置声库'),
      ],
    );

    expect(find.byKey(LibraryRootsKeys.rootsListKey), findsOneWidget);
    expect(find.text('本机书库'), findsOneWidget);
    expect(find.text('外置声库'), findsOneWidget);
    expect(find.text('本地目录'), findsNWidgets(2));
    expect(find.text('2 个'), findsOneWidget);
    expect(find.text('上次扫描 · 2026-10-18 14:32'), findsOneWidget);
    expect(find.text('从未扫描'), findsOneWidget);

    // 长路径必须中间省略，并且仍然只有一行。
    final Finder pathText = find.textContaining('…');
    expect(pathText, findsOneWidget);
    final Text path = tester.widget<Text>(pathText);
    expect(path.maxLines, 1);
    expect(path.data, startsWith('…/'));
    expect(path.data, endsWith('library-tooooo-long'));

    // 触控目标 ≥48dp。
    expect(
      tester.getSize(find.byKey(LibraryRootsKeys.scanKey(testRootId))).height,
      greaterThanOrEqualTo(AppSizes.minTouchTarget),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('添加根成功：预填建议路径、写入后重新查询列表', (WidgetTester tester) async {
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
    );
    expect(container.read(libraryRootsProvider).value, hasLength(1));

    await tester.tap(find.byKey(LibraryRootsKeys.addRootKey));
    await tester.pumpAndSettle();

    final TextFormField pathField = tester.widget<TextFormField>(
      find.byKey(LibraryRootsKeys.pathFieldKey),
    );
    expect(pathField.controller?.text, temp.path);

    await tester.enterText(find.byKey(LibraryRootsKeys.nameFieldKey), '我的书库');
    await tester.tap(find.byKey(LibraryRootsKeys.submitRootKey));
    await tester.pumpAndSettle();

    expect(service.addCalls, hasLength(1));
    expect(service.addCalls.single.path, temp.path);
    expect(service.addCalls.single.name, '我的书库');
    expect(find.byKey(LibraryRootsKeys.submitRootKey), findsNothing);
    expect(find.byKey(LibraryRootsKeys.addedNoticeKey), findsOneWidget);
    expect(find.textContaining('已添加「我的书库」'), findsOneWidget);
    expect(find.text('我的书库'), findsOneWidget);
    expect(find.text('2 个'), findsOneWidget);
    expect(
      container.read(libraryRootsProvider).value,
      hasLength(2),
      reason: '添加成功后必须重新查询书库根',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('添加根失败：空路径与不存在目录都用表单 errorText 就地提示', (
    WidgetTester tester,
  ) async {
    await pumpLibrary(
      tester,
      roots: () => const <LibraryRootView>[testRoot],
      suggestedPath: '/definitely/not/here/books',
    );

    await tester.tap(find.byKey(LibraryRootsKeys.addRootKey));
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

  testWidgets('添加根重复：同一路径已在书库时就地提示，不调用写入', (WidgetTester tester) async {
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
    );

    await tester.tap(find.byKey(LibraryRootsKeys.addRootKey));
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
    expect(find.byKey(LibraryRootsKeys.addedNoticeKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SAF：点按钮只弹一次选择器，用户取消时静默', (WidgetTester tester) async {
    final _FakeDirectoryPicker picker = _FakeDirectoryPicker();
    int rootsQueries = 0;

    await pumpLibrary(
      tester,
      roots: () => const <LibraryRootView>[testRoot],
      picker: picker,
      onRootsQuery: () => rootsQueries++,
    );
    expect(rootsQueries, 1);

    expect(find.byKey(LibraryRootsKeys.safPickKey), findsOneWidget);
    expect(find.text('选择目录（SAF）'), findsOneWidget);
    expect(find.text('高级：手动输入路径'), findsOneWidget);

    await tester.tap(find.byKey(LibraryRootsKeys.safPickKey));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(service.safCalls, isEmpty, reason: '取消不应写入书库根');
    expect(find.byKey(LibraryRootsKeys.addedNoticeKey), findsNothing);
    expect(
      find.byKey(LibraryRootsKeys.safErrorKey),
      findsNothing,
      reason: '取消不是错误',
    );
    expect(find.textContaining('已添加'), findsNothing);
    expect(rootsQueries, 1, reason: '取消不应刷新列表');
    expect(
      tester
          .widget<FilledButton>(find.byKey(LibraryRootsKeys.safPickKey))
          .onPressed,
      isNotNull,
      reason: '取消后按钮要恢复可用',
    );
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

    await tester.tap(find.byKey(LibraryRootsKeys.safPickKey));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(service.safCalls, hasLength(1));
    expect(service.safCalls.single.treeUri, treeUri);
    expect(service.safCalls.single.name, 'Books');
    expect(service.addCalls, isEmpty, reason: 'SAF 不应走本地路径入口');

    expect(find.byKey(LibraryRootsKeys.addedNoticeKey), findsOneWidget);
    expect(find.textContaining('已添加「Books」'), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.safErrorKey), findsNothing);
    expect(find.text('2 个'), findsOneWidget);
    expect(rootsQueries, 2, reason: '添加成功后必须重新查询书库根');
    expect(
      container.read(libraryRootsProvider).value,
      hasLength(2),
      reason: '列表以重新查询结果为准',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('SAF 重复：同一 tree URI 已在书库时不写入，就地提示', (WidgetTester tester) async {
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

    await tester.tap(find.byKey(LibraryRootsKeys.safPickKey));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(service.safCalls, isEmpty, reason: '同 tree URI 已存在时不应写入');
    expect(find.byKey(LibraryRootsKeys.duplicateNoticeKey), findsOneWidget);
    expect(find.textContaining('这个目录已经在书库里'), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.addedNoticeKey), findsNothing);
    expect(find.byKey(LibraryRootsKeys.safErrorKey), findsNothing);
    expect(rootsQueries, 1, reason: '没有写入就不该刷新列表');
    expect(container.read(libraryRootsProvider).value, hasLength(1));
    expect(
      tester
          .widget<FilledButton>(find.byKey(LibraryRootsKeys.safPickKey))
          .onPressed,
      isNotNull,
      reason: '重复提示后按钮要恢复可用',
    );
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

    await tester.tap(find.byKey(LibraryRootsKeys.safPickKey));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(service.safCalls, isEmpty);
    expect(find.byKey(LibraryRootsKeys.safErrorKey), findsOneWidget);
    expect(find.text('这里没有系统目录选择器'), findsOneWidget);
    expect(find.textContaining('当前平台没有接入目录选择'), findsOneWidget);
    expect(find.textContaining('MissingPluginException'), findsNothing);
    expect(find.byKey(LibraryRootsKeys.addedNoticeKey), findsNothing);
    expect(rootsQueries, 1);
    expect(
      tester
          .widget<FilledButton>(find.byKey(LibraryRootsKeys.safPickKey))
          .onPressed,
      isNotNull,
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

    await tester.tap(find.byKey(LibraryRootsKeys.safPickKey));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(service.safCalls, isEmpty);
    expect(find.byKey(LibraryRootsKeys.safErrorKey), findsOneWidget);
    expect(find.text('目录选择器正在使用'), findsOneWidget);
    expect(find.textContaining('已经有一个目录选择在进行'), findsOneWidget);
    expect(find.textContaining('PlatformException'), findsNothing);
    expect(find.textContaining('busy'), findsNothing);
    expect(find.byKey(LibraryRootsKeys.addedNoticeKey), findsNothing);
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
      ],
    );
    addTearDown(container.dispose);
    // 书架在别处被监听：invalidate 之后应真的重新查询，而不是只丢缓存。
    final ProviderSubscription<AsyncValue<List<BookSummary>>> booksSub =
        container.listen(booksProvider, (_, _) {}, fireImmediately: true);
    addTearDown(booksSub.close);

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LibraryPage())),
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
    expect(find.text('扫描完成 · 用时 1.8 秒'), findsOneWidget);
    expect(find.text('新增 3 册 · 12 卷 · 240 章'), findsOneWidget);
    expect(find.text('更新 1 册 · 更新 2 章'), findsOneWidget);
    expect(find.text('标记缺失 1 章 · 忽略 6 个非音频文件'), findsOneWidget);
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
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<AsyncValue<List<BookSummary>>> booksSub =
        container.listen(booksProvider, (_, _) {}, fireImmediately: true);
    addTearDown(booksSub.close);

    service.scanErrors[testRootId] = StateError('目录不存在：/library/books');

    await tester.pumpWidget(
      testApp(container, const Scaffold(body: LibraryPage())),
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
  });
}
