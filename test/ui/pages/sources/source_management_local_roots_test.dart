import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/library_root_service.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/library_root_providers.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/library/scan/scan_report.dart';
import 'package:tometone/ui/pages/library/library_roots.dart';
import 'package:tometone/ui/pages/sources/source_management_page.dart';

import 'source_ui_test_support.dart';

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

  void Function(String uri, String? name)? onAdd;
  void Function(String id, String name)? onRename;
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
    return (scanCompleters[libraryRootId] ??= Completer<ScanReport>()).future;
  }

  @override
  Future<void> renameRoot(String id, String displayName) async {
    renameCalls.add((id: id, name: displayName));
    onRename?.call(id, displayName);
  }

  @override
  Future<void> removeRoot(String id) async {
    removedRootIds.add(id);
    onRemove?.call(id);
  }

  @override
  Future<DateTime?> lastScanAt(String libraryRootId) async => null;
}

void main() {
  testWidgets('来源管理页显示本机目录空态并可打开添加弹层', (tester) async {
    final db = openSourceTestDatabase();
    final service = _FakeLibraryRootService();

    await pumpSourceUi(
      tester,
      db: db,
      home: const SourceManagementPage(),
      extra: <Override>[
        libraryRootServiceProvider.overrideWithValue(service),
      ],
    );

    expect(find.text('本机目录'), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.rootsEmptyKey), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.addRootButtonKey), findsOneWidget);

    await tester.tap(find.byKey(LibraryRootsKeys.addRootButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(LibraryRootsKeys.safPickKey), findsOneWidget);
  });

  testWidgets('网络书源和本机目录可同时显示', (tester) async {
    final db = openSourceTestDatabase();
    await seedSource(db, name: '有声书源');
    final service = _FakeLibraryRootService();

    const testRoot = LibraryRootView(
      id: 'local-root-1',
      type: 'local',
      uri: '/library',
      displayName: '本地听书',
    );

    await pumpSourceUi(
      tester,
      db: db,
      home: const SourceManagementPage(),
      extra: <Override>[
        libraryRootsProvider.overrideWith((ref) => <LibraryRootView>[testRoot]),
        libraryRootServiceProvider.overrideWithValue(service),
      ],
    );

    expect(find.text('有声书源'), findsOneWidget);
    expect(find.text('本机目录'), findsOneWidget);
    expect(find.text('本地听书'), findsOneWidget);
    expect(find.byKey(LibraryRootsKeys.rootsListKey), findsOneWidget);
  });

  testWidgets('本机目录支持扫描、重命名和移除', (tester) async {
    final db = openSourceTestDatabase();
    final service = _FakeLibraryRootService();

    final roots = <LibraryRootView>[
      const LibraryRootView(
        id: 'local-root-1',
        type: 'local',
        uri: '/library',
        displayName: '本地听书',
      ),
    ];

    await pumpSourceUi(
      tester,
      db: db,
      home: const SourceManagementPage(),
      extra: <Override>[
        libraryRootsProvider.overrideWith((ref) => roots),
        libraryRootServiceProvider.overrideWithValue(service),
      ],
    );

    // 扫描
    await tester.tap(find.byKey(LibraryRootsKeys.scanKey('local-root-1')));
    await tester.pump();
    expect(service.scannedRootIds, contains('local-root-1'));
    service.scanCompleters['local-root-1']!.complete(
      const ScanReport(
        libraryRootId: 'local-root-1',
        booksSeen: 1,
        booksAdded: 1,
        booksUpdated: 0,
        volumesAdded: 1,
        chaptersSeen: 1,
        chaptersAdded: 1,
        chaptersUpdated: 0,
        chaptersMarkedMissing: 0,
        chaptersRestored: 0,
        ignoredFiles: 0,
        failedPaths: <String>[],
        elapsed: Duration(seconds: 1),
      ),
    );
    await tester.pumpAndSettle();

    // 打开菜单重命名
    await tester.tap(find.byKey(LibraryRootsKeys.rootMenuKey('local-root-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LibraryRootsKeys.renameRootKey('local-root-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(LibraryRootsKeys.renameFieldKey), findsOneWidget);

    await tester.enterText(find.byKey(LibraryRootsKeys.renameFieldKey), '重命名后的书库');
    await tester.tap(find.byKey(LibraryRootsKeys.renameSubmitKey));
    await tester.pumpAndSettle();
    expect(service.renameCalls.any((c) => c.name == '重命名后的书库'), isTrue);

    // 打开菜单移除
    await tester.tap(find.byKey(LibraryRootsKeys.rootMenuKey('local-root-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LibraryRootsKeys.removeRootKey('local-root-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(LibraryRootsKeys.removeDialogKey), findsOneWidget);

    await tester.tap(find.byKey(LibraryRootsKeys.removeConfirmKey));
    await tester.pumpAndSettle();
    expect(service.removedRootIds, contains('local-root-1'));
  });

  testWidgets('320dp + 2.0 大字号 + 深色无 overflow', (tester) async {
    final db = openSourceTestDatabase();
    await seedSource(db, name: '有声书源');
    final service = _FakeLibraryRootService();

    const testRoot = LibraryRootView(
      id: 'local-root-1',
      type: 'local',
      uri: '/storage/audiobooks',
      displayName: '本地听书目录较长的一段文字测试显示效果',
    );

    await pumpSourceUi(
      tester,
      db: db,
      home: const SourceManagementPage(),
      disableAnimations: true,
      extra: <Override>[
        libraryRootsProvider.overrideWith((ref) => <LibraryRootView>[testRoot]),
        libraryRootServiceProvider.overrideWithValue(service),
      ],
      size: const Size(320, 600),
      textScale: 2.0,
      brightness: Brightness.dark,
    );

    expect(find.text('本机目录'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
