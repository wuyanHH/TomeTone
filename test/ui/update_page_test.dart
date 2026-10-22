import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/preferences/app_preferences_store.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/app/providers/update_providers.dart';
import 'package:tometone/contracts/update/update_models.dart';
import 'package:tometone/contracts/update/update_source.dart';
import 'package:tometone/contracts/update/update_state.dart';
import 'package:tometone/ui/pages/settings/update_page.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ui_test_harness.dart';

void main() {
  final sampleRelease = ReleaseInfo(
    tag: 'v0.3.0',
    name: 'TomeTone 0.3.0',
    body: '### 更新内容\n- 离线增强\n- 体验修复',
    publishedAt: DateTime.utc(2026, 10, 20),
    htmlUrl: 'https://github.com/example/releases/v0.3.0',
    prerelease: false,
    draft: false,
    assets: const <ReleaseAsset>[
      ReleaseAsset(
        name: 'tometone-v0.3.0-arm64-v8a.apk',
        sizeBytes: 25 * 1024 * 1024,
        downloadUrl: 'https://example.com/arm64.apk',
        digest: 'sha256:1111222233334444',
      ),
      ReleaseAsset(
        name: 'tometone-v0.3.0-armeabi-v7a.apk',
        sizeBytes: 20 * 1024 * 1024,
        downloadUrl: 'https://example.com/armv7.apk',
        digest: 'sha256:5555666677778888',
      ),
      ReleaseAsset(
        name: 'tometone-v0.3.0-x86_64.apk',
        sizeBytes: 28 * 1024 * 1024,
        downloadUrl: 'https://example.com/x86_64.apk',
      ),
    ],
  );

  Widget createUpdateApp({
    required ProviderContainer container,
    String? initialTag,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: UpdatePage(initialReleaseTag: initialTag),
      ),
    );
  }

  testWidgets('UpdatePage: available 状态下显示新版本号、Markdown 正文、APK 列表及推荐 ABI 徽章',
      (WidgetTester tester) async {
    usePhoneViewport(tester);
    final store = InMemoryAppPreferencesStore();
    final fakeSource = FakeUpdateSource(
      result: UpdateFetchResult(releases: [sampleRelease]),
    );
    const fakeDevice = FakeDeviceArchitecture(
      abis: ['arm64-v8a', 'armeabi-v7a'],
    );
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        initialPreferencesProvider.overrideWithValue(store.current),
        deviceArchitectureProvider.overrideWithValue(fakeDevice),
        updateSourceProvider.overrideWithValue(fakeSource),
      ],
    );
    addTearDown(container.dispose);

    container.read(updateControllerProvider.notifier).state = UpdateState(
      status: UpdateStatus.available,
      release: sampleRelease,
    );

    await tester.pumpWidget(createUpdateApp(container: container));
    await tester.pumpAndSettle();

    // 检查 AppBar 标题与更新历史入口
    expect(find.text('版本更新'), findsOneWidget);
    expect(find.byKey(UpdatePage.historyKey), findsOneWidget);

    // 检查顶部版本卡片与可更新徽章
    expect(find.textContaining('最新版本：v0.3.0'), findsOneWidget);
    expect(find.textContaining('发布时间：2026-10-20'), findsOneWidget);
    expect(find.text('可更新'), findsOneWidget);

    // 检查已触发 acknowledge 确认已看
    expect(store.current.acknowledgedVersion, '0.3.0');

    // 检查 Markdown 正文
    expect(find.text('更新说明'), findsOneWidget);
    expect(find.textContaining('更新内容'), findsOneWidget);
    expect(find.textContaining('离线增强'), findsOneWidget);

    // 检查 APK 列表
    expect(find.text('安装包列表'), findsOneWidget);
    expect(find.text('tometone-v0.3.0-arm64-v8a.apk'), findsOneWidget);
    expect(find.text('tometone-v0.3.0-armeabi-v7a.apk'), findsOneWidget);
    expect(find.text('tometone-v0.3.0-x86_64.apk'), findsOneWidget);

    // 检查大小格式化
    expect(find.text('25.0 MB'), findsOneWidget);
    expect(find.text('20.0 MB'), findsOneWidget);
    expect(find.text('28.0 MB'), findsOneWidget);

    // 检查推荐 ABI 徽标（命中了 arm64-v8a）
    expect(find.text('推荐架构'), findsOneWidget);

    // 检查底部提示与 Release 页面按钮
    expect(find.byKey(UpdatePage.releasePageKey), findsOneWidget);
    expect(
      find.text('请在系统设置中允许安装未知来源应用。当前版本为 Debug/Pre-release 签名。'),
      findsOneWidget,
    );
  });

  testWidgets('UpdatePage: 点击下载与复制校验值', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final store = InMemoryAppPreferencesStore();
    const fakeDevice = FakeDeviceArchitecture(
      abis: ['arm64-v8a'],
    );
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        initialPreferencesProvider.overrideWithValue(store.current),
        deviceArchitectureProvider.overrideWithValue(fakeDevice),
        updateSourceProvider.overrideWithValue(FakeUpdateSource()),
      ],
    );
    addTearDown(container.dispose);

    container.read(updateControllerProvider.notifier).state = UpdateState(
      status: UpdateStatus.available,
      release: sampleRelease,
    );

    Uri? launchedUri;
    LaunchMode? launchedMode;
    UpdatePage.urlLauncher = (Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
      launchedUri = uri;
      launchedMode = mode;
      return true;
    };

    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          copiedText = (methodCall.arguments as Map<dynamic, dynamic>)['text'] as String?;
          return null;
        }
        return null;
      },
    );

    await tester.pumpWidget(createUpdateApp(container: container));
    await tester.pumpAndSettle();

    // 点击下载推荐的 arm64 安装包
    final downloadArm64Finder = find.byKey(
      UpdatePage.downloadKey('tometone-v0.3.0-arm64-v8a.apk'),
    );
    await tester.ensureVisible(downloadArm64Finder);
    await tester.pumpAndSettle();
    await tester.tap(downloadArm64Finder);
    await tester.pumpAndSettle();

    expect(launchedUri?.toString(), 'https://example.com/arm64.apk');
    expect(launchedMode, LaunchMode.externalApplication);

    // 点击复制校验值
    final digestFinder = find.text('sha256:1111222233334444');
    expect(digestFinder, findsOneWidget);
    await tester.ensureVisible(digestFinder);
    await tester.pumpAndSettle();
    await tester.tap(digestFinder);
    await tester.pumpAndSettle();

    expect(copiedText, 'sha256:1111222233334444');
    expect(find.text('校验值已复制'), findsOneWidget);

    // 点击“打开 Release 页面”
    final releasePageBtn = find.byKey(UpdatePage.releasePageKey);
    await tester.ensureVisible(releasePageBtn);
    await tester.pumpAndSettle();
    await tester.tap(releasePageBtn);
    await tester.pumpAndSettle();

    expect(
      launchedUri?.toString(),
      'https://github.com/example/releases/v0.3.0',
    );
  });

  testWidgets('UpdatePage: 跳过此版本与取消跳过', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final store = InMemoryAppPreferencesStore();
    final fakeSource = FakeUpdateSource(
      result: UpdateFetchResult(releases: [sampleRelease]),
    );
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        initialPreferencesProvider.overrideWithValue(store.current),
        deviceArchitectureProvider.overrideWithValue(
          const FakeDeviceArchitecture(),
        ),
        updateSourceProvider.overrideWithValue(fakeSource),
      ],
    );
    addTearDown(container.dispose);

    container.read(updateControllerProvider.notifier).state = UpdateState(
      status: UpdateStatus.available,
      release: sampleRelease,
    );

    await tester.pumpWidget(createUpdateApp(container: container));
    await tester.pumpAndSettle();

    final skipFinder = find.byKey(UpdatePage.skipKey);
    await tester.ensureVisible(skipFinder);
    await tester.pumpAndSettle();
    expect(skipFinder, findsOneWidget);
    expect(find.text('跳过此版本'), findsOneWidget);
    expect(find.byKey(UpdatePage.unskipKey), findsNothing);

    // 点击跳过此版本
    await tester.tap(skipFinder);
    await tester.pumpAndSettle();

    expect(store.current.skippedVersion, '0.3.0');
    expect(find.text('已跳过'), findsOneWidget);
    expect(find.byKey(UpdatePage.unskipKey), findsOneWidget);
    expect(find.text('取消跳过'), findsOneWidget);

    // 点击取消跳过
    final unskipFinder = find.byKey(UpdatePage.unskipKey);
    await tester.tap(unskipFinder);
    await tester.pumpAndSettle();

    expect(store.current.skippedVersion, isNull);
    expect(fakeSource.calls, greaterThanOrEqualTo(1));
  });

  testWidgets('UpdatePage: 检查失败与重试', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final store = InMemoryAppPreferencesStore();
    final fakeSource = FakeUpdateSource(
      result: UpdateFetchResult(releases: [sampleRelease]),
    );
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        initialPreferencesProvider.overrideWithValue(store.current),
        deviceArchitectureProvider.overrideWithValue(
          const FakeDeviceArchitecture(),
        ),
        updateSourceProvider.overrideWithValue(fakeSource),
      ],
    );
    addTearDown(container.dispose);

    // 初始状态为 failure 且无缓存 release
    container.read(updateControllerProvider.notifier).state = const UpdateState(
      status: UpdateStatus.failure,
      failure: UpdateFailureKind.network,
    );

    await tester.pumpWidget(createUpdateApp(container: container));
    await tester.pumpAndSettle();

    expect(find.text('检查更新失败'), findsOneWidget);
    expect(find.textContaining('网络连接异常或超时'), findsOneWidget);
    final retryFinder = find.byKey(UpdatePage.retryKey);
    expect(retryFinder, findsOneWidget);

    // 点击重试
    await tester.tap(retryFinder);
    await tester.pumpAndSettle();

    expect(fakeSource.calls, 1);
    expect(container.read(updateControllerProvider).status, UpdateStatus.available);
    expect(find.textContaining('最新版本：v0.3.0'), findsOneWidget);
  });

  testWidgets('UpdatePage: 有缓存内容时检查失败展示提示条', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final store = InMemoryAppPreferencesStore();
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        initialPreferencesProvider.overrideWithValue(store.current),
        deviceArchitectureProvider.overrideWithValue(
          const FakeDeviceArchitecture(),
        ),
        updateSourceProvider.overrideWithValue(FakeUpdateSource()),
      ],
    );
    addTearDown(container.dispose);

    // 从缓存加载但本次检查失败
    container.read(updateControllerProvider.notifier).state = UpdateState(
      status: UpdateStatus.failure,
      release: sampleRelease,
      failure: UpdateFailureKind.rateLimited,
      fromCache: true,
    );

    await tester.pumpWidget(createUpdateApp(container: container));
    await tester.pumpAndSettle();

    expect(find.text('检查失败，显示上次结果'), findsOneWidget);
    expect(find.byKey(UpdatePage.retryKey), findsOneWidget);
    expect(find.text('tometone-v0.3.0-arm64-v8a.apk'), findsOneWidget);
  });
}
