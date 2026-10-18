import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/app_info.dart';
import 'package:tometone/app/library/library_root_service.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/library_root_providers.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/library/scan/scan_report.dart';
import 'package:tometone/ui/pages/settings/settings_page.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

import 'ui_test_harness.dart';

/// 假的书库根服务：记录调用，扫描用 Completer 控制完成时机。
class _FakeLibraryRootService implements LibraryRootService {
  final List<({String path, String? name})> addCalls =
      <({String path, String? name})>[];
  final List<String> scannedRootIds = <String>[];
  final Map<String, Completer<ScanReport>> scanCompleters =
      <String, Completer<ScanReport>>{};
  final Map<String, Object> scanErrors = <String, Object>{};

  /// 添加成功时的回调（测试用来模拟「重新查询后多了一条根」）。
  void Function(String path, String? name)? onAdd;

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
    addCalls.add((path: treeUri, name: displayName));
    onAdd?.call(treeUri, displayName);
    return 'root-${addCalls.length}';
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
  DateTime? lastScanAt,
}) {
  return LibraryRootView(
    id: id,
    type: 'local',
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

  /// 把设置页塞进最小应用，并注入假的服务与可变的书库根列表。
  Future<ProviderContainer> pumpSettings(
    WidgetTester tester, {
    required List<LibraryRootView> Function() roots,
    String? suggestedPath,
  }) async {
    usePhoneViewport(tester);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRootsProvider.overrideWith((Ref ref) async => roots()),
        booksProvider.overrideWith((Ref ref) async => const <BookSummary>[]),
        libraryRootServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      testApp(
        container,
        Scaffold(body: SettingsPage(suggestedRootPath: suggestedPath)),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('空态：说明支持格式并直接给出添加入口', (WidgetTester tester) async {
    await pumpSettings(tester, roots: () => const <LibraryRootView>[]);

    expect(find.byKey(SettingsPage.rootsEmptyKey), findsOneWidget);
    expect(find.text('还没有书库根'), findsOneWidget);
    expect(find.textContaining('支持 mp3'), findsOneWidget);
    expect(find.byKey(SettingsPage.addRootKey), findsOneWidget);
    expect(find.text('0 个'), findsOneWidget);
    expect(find.text('系统偏好'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('列表：展示名、单行中间省略的路径、最近扫描时间与扫描按钮', (WidgetTester tester) async {
    const String longPath =
        '/data/user/0/com.tometone.app/files/books/library-tooooo-long';
    await pumpSettings(
      tester,
      roots: () => <LibraryRootView>[
        _root(uri: longPath, lastScanAt: DateTime(2026, 10, 18, 14, 32)),
        _root(id: 'root-2', uri: '/mnt/media/audio', displayName: '外置声库'),
      ],
    );

    expect(find.byKey(SettingsPage.rootsListKey), findsOneWidget);
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
      tester.getSize(find.byKey(SettingsPage.scanKey(testRootId))).height,
      greaterThanOrEqualTo(AppSizes.minTouchTarget),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('添加根成功：预填建议路径、写入后重新查询列表', (WidgetTester tester) async {
    final Directory temp = Directory.systemTemp.createTempSync(
      'tometone-settings-',
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

    final ProviderContainer container = await pumpSettings(
      tester,
      roots: () => roots,
      suggestedPath: temp.path,
    );
    expect(container.read(libraryRootsProvider).value, hasLength(1));

    await tester.tap(find.byKey(SettingsPage.addRootKey));
    await tester.pumpAndSettle();

    final TextFormField pathField = tester.widget<TextFormField>(
      find.byKey(SettingsPage.pathFieldKey),
    );
    expect(pathField.controller?.text, temp.path);

    await tester.enterText(find.byKey(SettingsPage.nameFieldKey), '我的书库');
    await tester.tap(find.byKey(SettingsPage.submitRootKey));
    await tester.pumpAndSettle();

    expect(service.addCalls, hasLength(1));
    expect(service.addCalls.single.path, temp.path);
    expect(service.addCalls.single.name, '我的书库');
    expect(find.byKey(SettingsPage.submitRootKey), findsNothing);
    expect(find.byKey(SettingsPage.addedNoticeKey), findsOneWidget);
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
    await pumpSettings(
      tester,
      roots: () => const <LibraryRootView>[testRoot],
      suggestedPath: '/definitely/not/here/books',
    );

    await tester.tap(find.byKey(SettingsPage.addRootKey));
    await tester.pumpAndSettle();
    expect(find.byKey(SettingsPage.submitRootKey), findsOneWidget);

    await tester.enterText(find.byKey(SettingsPage.pathFieldKey), '   ');
    await tester.tap(find.byKey(SettingsPage.submitRootKey));
    await tester.pumpAndSettle();
    expect(find.text('请输入书库根的绝对路径'), findsOneWidget);
    expect(service.addCalls, isEmpty);

    await tester.enterText(
      find.byKey(SettingsPage.pathFieldKey),
      '/definitely/not/here/books',
    );
    await tester.tap(find.byKey(SettingsPage.submitRootKey));
    await tester.pumpAndSettle();
    expect(find.text('目录不存在：/definitely/not/here/books'), findsOneWidget);
    expect(service.addCalls, isEmpty);
    expect(find.byKey(SettingsPage.submitRootKey), findsOneWidget);
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
      testApp(container, const Scaffold(body: SettingsPage())),
    );
    await tester.pumpAndSettle();
    expect(rootsQueries, 1);
    expect(booksQueries, 1);

    await tester.tap(find.byKey(SettingsPage.scanKey(testRootId)));
    await tester.pump();

    expect(service.scannedRootIds, <String>[testRootId]);
    expect(find.text('正在扫描…大书库可能需要几十秒。'), findsOneWidget);
    expect(find.text('扫描中'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(SettingsPage.scanKey(testRootId)))
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

    expect(find.byKey(SettingsPage.reportKey(testRootId)), findsOneWidget);
    expect(find.text('扫描完成 · 用时 1.8 秒'), findsOneWidget);
    expect(find.text('新增 3 册 · 12 卷 · 240 章'), findsOneWidget);
    expect(find.text('更新 1 册 · 更新 2 章'), findsOneWidget);
    expect(find.text('标记缺失 1 章 · 忽略 6 个非音频文件'), findsOneWidget);
    expect(find.text('上次扫描 · 2026-10-18 14:32'), findsOneWidget);
    expect(rootsQueries, 2, reason: '扫描成功必须失效书库根列表');
    expect(booksQueries, 2, reason: '扫描成功必须失效书架');
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(SettingsPage.scanKey(testRootId)))
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
      testApp(container, const Scaffold(body: SettingsPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(SettingsPage.scanKey(testRootId)));
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsPage.scanErrorKey(testRootId)), findsOneWidget);
    expect(find.text('扫描没有完成'), findsOneWidget);
    expect(find.text('目录不存在：/library/books'), findsOneWidget);
    expect(find.byKey(SettingsPage.reportKey(testRootId)), findsNothing);
    expect(booksQueries, 1, reason: '失败不应触发书架失效');
    expect(rootsQueries, 1, reason: '失败不应触发根列表失效');
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(SettingsPage.scanKey(testRootId)))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('关于：版本与通道来自 AppInfo，更新源未配置时如实说明', (WidgetTester tester) async {
    await pumpSettings(tester, roots: () => const <LibraryRootView>[testRoot]);

    expect(find.text('0.1.0-beta.1'), findsOneWidget);
    expect(find.text('发布通道 · beta'), findsOneWidget);

    if (!AppInfo.hasUpdateSource) {
      expect(find.text('更新源未配置，暂时无法检查更新'), findsOneWidget);
      expect(find.text('未配置'), findsOneWidget);
    }
    expect(find.text('检查更新'), findsOneWidget);
    expect(find.text('开源许可'), findsOneWidget);

    await tester.ensureVisible(find.byKey(SettingsPage.licensesKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsPage.licensesKey));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
