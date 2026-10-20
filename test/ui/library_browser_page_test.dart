import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/providers/library_root_providers.dart';
import 'package:tometone/contracts/storage/fake_storage_provider.dart';
import 'package:tometone/contracts/storage/provider_capabilities.dart';
import 'package:tometone/contracts/storage/stat_info.dart';
import 'package:tometone/contracts/storage/storage_entry.dart';
import 'package:tometone/contracts/storage/storage_error.dart';
import 'package:tometone/contracts/storage/storage_provider.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/pages/library/library_browser_page.dart';

import 'ui_test_harness.dart';

const LibraryRootView _testRoot = LibraryRootView(
  id: 'root-1',
  type: 'local',
  uri: '/library',
  displayName: '本机书库',
);

/// 读取永远失败，用来验证 StorageError → 中文提示。
class _FailingStorageProvider implements StorageProvider {
  _FailingStorageProvider(this.error);

  final StorageError error;
  int listCalls = 0;
  bool disposed = false;

  @override
  Future<List<StorageEntry>> list(String path) async {
    listCalls++;
    throw error;
  }

  @override
  Future<StatInfo> stat(String path) async => throw error;

  @override
  Future<Stream<List<int>>> readRange(String path, int start, int? end) async {
    throw error;
  }

  @override
  Future<void> downloadTo(
    String path,
    File target, {
    void Function(int received, int total)? onProgress,
  }) async {
    throw error;
  }

  @override
  ProviderCapabilities get capabilities =>
      FakeStorageProvider.defaultCapabilities;

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

Future<ProviderContainer> _pumpBrowser(
  WidgetTester tester,
  StorageProvider provider, {
  Widget? home,
}) async {
  usePhoneViewport(tester);
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      storageProviderFactoryProvider.overrideWithValue(
        (String uri) => provider,
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    testApp(container, home ?? const LibraryBrowserPage(root: _testRoot)),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('目录：文件夹在前、文件在后，同类按名称不区分大小写', (WidgetTester tester) async {
    final FakeStorageProvider provider = FakeStorageProvider.fromPaths(
      <String, int>{
        'zeta/001.mp3': 10,
        'Audiobooks/002.m4b': 20,
        'beta.mp3': 30,
        'Alpha.mp3': 40,
        '封面.jpg': 50,
      },
    );
    await _pumpBrowser(tester, provider);

    final List<String> titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((ListTile tile) => (tile.title! as Text).data!)
        .toList();
    expect(titles, <String>[
      'Audiobooks',
      'zeta',
      'Alpha.mp3',
      'beta.mp3',
      '封面.jpg',
    ]);

    expect(find.byIcon(Icons.folder_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.audiotrack_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
    expect(find.text('只读'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('音频文件只给只读提示，不进入播放；文件夹可继续下钻', (WidgetTester tester) async {
    final FakeStorageProvider provider = FakeStorageProvider.fromPaths(
      <String, int>{'Audiobooks/002.m4b': 20, 'Alpha.mp3': 40},
    );
    await _pumpBrowser(tester, provider);

    await tester.tap(find.byKey(LibraryBrowserKeys.entryKey('Alpha.mp3')));
    await tester.pump();
    expect(find.text('这里只读浏览，不能播放；听书请回到书架。'), findsOneWidget);
    expect(find.byKey(LibraryBrowserKeys.listKey), findsOneWidget);

    await tester.tap(find.byKey(LibraryBrowserKeys.entryKey('Audiobooks')));
    await tester.pumpAndSettle();
    expect(provider.calls, contains('list:Audiobooks'));
    expect(find.byKey(LibraryBrowserKeys.entryKey('002.m4b')), findsOneWidget);
    expect(find.byKey(LibraryBrowserKeys.entryKey('Alpha.mp3')), findsNothing);

    // 面包屑同时更新，仍然能读到根位置与当前文件夹。
    expect(find.text('Audiobooks'), findsWidgets);
    expect(find.text('/library'), findsOneWidget);

    // 系统返回键先回上一层，而不是直接退出浏览页。
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(LibraryBrowserKeys.entryKey('Audiobooks')),
      findsOneWidget,
    );
    expect(
      find.byKey(LibraryBrowserKeys.entryKey('Alpha.mp3')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('错误态：权限失败翻成中文说明，重试会再读一次', (WidgetTester tester) async {
    final _FailingStorageProvider provider = _FailingStorageProvider(
      const StorageError(code: StorageErrorCode.permission),
    );
    await _pumpBrowser(tester, provider);

    expect(find.byKey(LibraryBrowserKeys.errorKey), findsOneWidget);
    expect(find.text('没有读取这个文件夹的权限'), findsOneWidget);
    expect(find.textContaining('重新添加并确认授权'), findsOneWidget);
    expect(find.byKey(LibraryBrowserKeys.retryKey), findsOneWidget);
    expect(provider.listCalls, 1);

    await tester.tap(find.byKey(LibraryBrowserKeys.retryKey));
    await tester.pumpAndSettle();
    expect(provider.listCalls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('错误态：目录不存在给出可执行的下一步', (WidgetTester tester) async {
    await _pumpBrowser(tester, FakeStorageProvider());

    expect(find.byKey(LibraryBrowserKeys.errorKey), findsOneWidget);
    expect(find.text('这个文件夹找不到了'), findsOneWidget);
    expect(find.textContaining('返回上一级'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('空目录：明确说这里是空的，并可在深层返回上一级', (WidgetTester tester) async {
    await _pumpBrowser(
      tester,
      FakeStorageProvider(
        directories: <String, List<StorageEntry>>{
          '': const <StorageEntry>[
            StorageEntry(name: '空文件夹', path: '空文件夹', isDirectory: true),
          ],
          '空文件夹': const <StorageEntry>[],
        },
      ),
    );

    await tester.tap(find.byKey(LibraryBrowserKeys.entryKey('空文件夹')));
    await tester.pumpAndSettle();

    expect(find.byKey(LibraryBrowserKeys.emptyKey), findsOneWidget);
    expect(find.text('这个文件夹是空的'), findsOneWidget);
    expect(find.text('返回上一级'), findsOneWidget);

    await tester.tap(find.text('返回上一级'));
    await tester.pumpAndSettle();
    expect(find.byKey(LibraryBrowserKeys.entryKey('空文件夹')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('退出浏览页时释放 provider', (WidgetTester tester) async {
    final FakeStorageProvider provider = FakeStorageProvider.fromPaths(
      <String, int>{'Alpha.mp3': 40},
    );
    await _pumpBrowser(
      tester,
      provider,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const LibraryBrowserPage(root: _testRoot),
                  ),
                );
              },
              child: const Text('打开书库'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('打开书库'));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryBrowserPage), findsOneWidget);
    expect(provider.isDisposed, isFalse);

    // 根层返回：PopScope 放行，页面退出并释放 provider。
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LibraryBrowserPage), findsNothing);
    expect(provider.isDisposed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
