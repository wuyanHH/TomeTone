import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tometone/app/preferences/app_preferences_store.dart';
import 'package:tometone/app/providers/apk_download_providers.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/app/providers/update_providers.dart';
import 'package:tometone/app/update/apk_downloader.dart';
import 'package:tometone/contracts/update/apk_download_state.dart';
import 'package:tometone/contracts/update/update_models.dart';
import 'package:tometone/contracts/update/update_source.dart';
import 'package:tometone/contracts/update/update_state.dart';
import 'package:tometone/ui/pages/settings/update_page.dart';
import 'package:tometone/ui/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ui_test_harness.dart';

class FakeApkDownloader extends ApkDownloader {
  FakeApkDownloader() : super(client: http.Client());

  int downloadCalls = 0;
  ReleaseAsset? lastAsset;
  Stream<ApkDownloadState> Function(ReleaseAsset asset)? onDownload;

  @override
  Stream<ApkDownloadState> download({
    required ReleaseAsset asset,
    void Function()? onCancel,
  }) {
    downloadCalls++;
    lastAsset = asset;
    if (onDownload != null) {
      return onDownload!(asset);
    }
    return Stream.value(
      ApkDownloadState(
        status: ApkDownloadStatus.completed,
        assetName: asset.name,
        filePath: '/data/local/tmp/${asset.name}',
        receivedBytes: asset.sizeBytes,
        totalBytes: asset.sizeBytes,
      ),
    );
  }
}

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
        theme: AppTheme.build(),
        home: UpdatePage(initialReleaseTag: initialTag),
      ),
    );
  }

  testWidgets(
      'UpdatePage: 测试 1 available 状态下，跳过按钮与主下载按钮无需滑动，立即在底部常驻栏可见并正常渲染',
      (WidgetTester tester) async {
    usePhoneViewport(tester);
    final store = InMemoryAppPreferencesStore();
    final fakeSource = FakeUpdateSource(
      result: UpdateFetchResult(releases: [sampleRelease]),
    );
    const fakeDevice = FakeDeviceArchitecture(
      abis: ['arm64-v8a', 'armeabi-v7a'],
    );
    final fakeInstaller = FakePackageInstaller();
    final fakeDownloader = FakeApkDownloader();
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        initialPreferencesProvider.overrideWithValue(store.current),
        deviceArchitectureProvider.overrideWithValue(fakeDevice),
        updateSourceProvider.overrideWithValue(fakeSource),
        packageInstallerProvider.overrideWithValue(fakeInstaller),
        apkDownloaderProvider.overrideWithValue(fakeDownloader),
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

    // 检查常驻栏存在
    expect(find.byKey(UpdatePage.stickyBottomBarKey), findsOneWidget);

    // 检查常驻栏上的跳过按钮与主下载按钮，无需滑动即可见
    final skipFinder = find.byKey(UpdatePage.skipKey);
    final primaryFinder = find.byKey(UpdatePage.primaryActionKey);
    expect(skipFinder, findsOneWidget);
    expect(primaryFinder, findsOneWidget);

    final skipRect = tester.getRect(skipFinder);
    final primaryRect = tester.getRect(primaryFinder);
    expect(skipRect.top, greaterThanOrEqualTo(0));
    expect(skipRect.bottom, lessThanOrEqualTo(800));
    expect(primaryRect.top, greaterThanOrEqualTo(0));
    expect(primaryRect.bottom, lessThanOrEqualTo(800));

    // 检查推荐 arm64-v8a 大小 25.0 MB 文案
    expect(find.text('下载更新 (25.0 MB)'), findsOneWidget);

    // 检查常驻栏中的 Release 页面入口图标
    expect(find.byKey(UpdatePage.releasePageKey), findsOneWidget);

    // 检查正文中的更新说明与 APK 列表
    expect(find.text('更新说明'), findsOneWidget);
    expect(find.textContaining('离线增强'), findsOneWidget);
    expect(find.text('安装包列表'), findsOneWidget);
    expect(find.text('tometone-v0.3.0-arm64-v8a.apk'), findsOneWidget);
    expect(find.text('推荐架构'), findsOneWidget);
    expect(
      find.text('请在系统设置中允许安装未知来源应用。当前版本为 Debug/Pre-release 签名。'),
      findsOneWidget,
    );
  });

  testWidgets('UpdatePage: 测试 2 点击主下载按钮或列表下载按钮，进入下载状态并展示下载进度',
      (WidgetTester tester) async {
    usePhoneViewport(tester);
    final store = InMemoryAppPreferencesStore();
    final fakeSource = FakeUpdateSource(
      result: UpdateFetchResult(releases: [sampleRelease]),
    );
    const fakeDevice = FakeDeviceArchitecture(
      abis: ['arm64-v8a', 'armeabi-v7a'],
    );
    final fakeInstaller = FakePackageInstaller();
    final fakeDownloader = FakeApkDownloader();
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        initialPreferencesProvider.overrideWithValue(store.current),
        deviceArchitectureProvider.overrideWithValue(fakeDevice),
        updateSourceProvider.overrideWithValue(fakeSource),
        packageInstallerProvider.overrideWithValue(fakeInstaller),
        apkDownloaderProvider.overrideWithValue(fakeDownloader),
      ],
    );
    addTearDown(container.dispose);

    container.read(updateControllerProvider.notifier).state = UpdateState(
      status: UpdateStatus.available,
      release: sampleRelease,
    );

    final downloadController = StreamController<ApkDownloadState>.broadcast();
    addTearDown(downloadController.close);
    fakeDownloader.onDownload = (_) => downloadController.stream;

    await tester.pumpWidget(createUpdateApp(container: container));
    await tester.pumpAndSettle();

    // 点击常驻栏主下载按钮
    await tester.tap(find.byKey(UpdatePage.primaryActionKey));
    await tester.pump();

    expect(fakeDownloader.downloadCalls, 1);
    expect(fakeDownloader.lastAsset?.name, 'tometone-v0.3.0-arm64-v8a.apk');

    // 推送下载中进度（10MB / 25MB = 40%）
    downloadController.add(
      const ApkDownloadState(
        status: ApkDownloadStatus.downloading,
        assetName: 'tometone-v0.3.0-arm64-v8a.apk',
        receivedBytes: 10 * 1024 * 1024,
        totalBytes: 25 * 1024 * 1024,
      ),
    );
    await tester.pump();

    // 检查进度条及文案
    expect(find.byKey(UpdatePage.downloadProgressKey), findsOneWidget);
    final indicator = tester.widget<LinearProgressIndicator>(
      find.byKey(UpdatePage.downloadProgressKey),
    );
    expect(indicator.value, closeTo(10 / 25, 0.01));
    expect(find.text('10.0 MB / 25.0 MB'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);

    // 检查展示取消下载按钮
    expect(find.byKey(UpdatePage.cancelDownloadKey), findsOneWidget);

    // 点击取消下载
    await tester.tap(find.byKey(UpdatePage.cancelDownloadKey));
    await tester.pump();
    expect(
      container.read(apkDownloadProvider).status,
      ApkDownloadStatus.cancelled,
    );

    // 点击列表中的另一个安装包下载按钮
    final armv7DownloadKey =
        UpdatePage.downloadKey('tometone-v0.3.0-armeabi-v7a.apk');
    await tester.ensureVisible(find.byKey(armv7DownloadKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(armv7DownloadKey));
    await tester.pump();

    expect(fakeDownloader.downloadCalls, 2);
    expect(fakeDownloader.lastAsset?.name, 'tometone-v0.3.0-armeabi-v7a.apk');

    // 模拟推送新产物进度
    downloadController.add(
      const ApkDownloadState(
        status: ApkDownloadStatus.downloading,
        assetName: 'tometone-v0.3.0-armeabi-v7a.apk',
        receivedBytes: 15 * 1024 * 1024,
        totalBytes: 20 * 1024 * 1024,
      ),
    );
    await tester.pump();
    expect(find.text('15.0 MB / 20.0 MB'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets(
      'UpdatePage: 测试 3 下载完成后展示“立即安装”按钮，点击后成功调起 FakePackageInstaller.installApk',
      (WidgetTester tester) async {
    usePhoneViewport(tester);
    final store = InMemoryAppPreferencesStore();
    final fakeSource = FakeUpdateSource(
      result: UpdateFetchResult(releases: [sampleRelease]),
    );
    const fakeDevice = FakeDeviceArchitecture(
      abis: ['arm64-v8a'],
    );
    final fakeInstaller = FakePackageInstaller();
    final fakeDownloader = FakeApkDownloader();
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        initialPreferencesProvider.overrideWithValue(store.current),
        deviceArchitectureProvider.overrideWithValue(fakeDevice),
        updateSourceProvider.overrideWithValue(fakeSource),
        packageInstallerProvider.overrideWithValue(fakeInstaller),
        apkDownloaderProvider.overrideWithValue(fakeDownloader),
      ],
    );
    addTearDown(container.dispose);

    container.read(updateControllerProvider.notifier).state = UpdateState(
      status: UpdateStatus.available,
      release: sampleRelease,
    );

    // 模拟下载成功直接流式完成
    fakeDownloader.onDownload = (asset) => Stream.value(
          ApkDownloadState(
            status: ApkDownloadStatus.completed,
            assetName: asset.name,
            filePath: '/data/local/tmp/${asset.name}',
            receivedBytes: asset.sizeBytes,
            totalBytes: asset.sizeBytes,
          ),
        );

    await tester.pumpWidget(createUpdateApp(container: container));
    await tester.pumpAndSettle();

    // 点击主操作下载按钮
    await tester.tap(find.byKey(UpdatePage.primaryActionKey));
    await tester.pumpAndSettle();

    // 检查完成提示文案
    expect(find.text('下载完成（已校验 SHA-256），准备安装'), findsOneWidget);

    // 检查“立即安装”按钮
    final installBtn = find.byKey(UpdatePage.installKey);
    expect(installBtn, findsOneWidget);

    // 点击立即安装
    await tester.tap(installBtn);
    await tester.pumpAndSettle();

    expect(fakeInstaller.installCalls, 1);
    expect(
      fakeInstaller.installedPath,
      '/data/local/tmp/tometone-v0.3.0-arm64-v8a.apk',
    );
  });

  testWidgets('UpdatePage: 测试 4 在常驻栏点击“跳过此版本”与“取消跳过”，正确更新偏好与状态',
      (WidgetTester tester) async {
    usePhoneViewport(tester);
    final store = InMemoryAppPreferencesStore();
    final fakeSource = FakeUpdateSource(
      result: UpdateFetchResult(releases: [sampleRelease]),
    );
    final fakeInstaller = FakePackageInstaller();
    final fakeDownloader = FakeApkDownloader();
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        initialPreferencesProvider.overrideWithValue(store.current),
        deviceArchitectureProvider.overrideWithValue(
          const FakeDeviceArchitecture(),
        ),
        updateSourceProvider.overrideWithValue(fakeSource),
        packageInstallerProvider.overrideWithValue(fakeInstaller),
        apkDownloaderProvider.overrideWithValue(fakeDownloader),
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

  testWidgets('UpdatePage: 测试 5 点击浏览器下载与 Release 页面按钮，正确唤起外部浏览器',
      (WidgetTester tester) async {
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
        packageInstallerProvider.overrideWithValue(FakePackageInstaller()),
        apkDownloaderProvider.overrideWithValue(FakeApkDownloader()),
      ],
    );
    addTearDown(container.dispose);

    container.read(updateControllerProvider.notifier).state = UpdateState(
      status: UpdateStatus.available,
      release: sampleRelease,
    );

    Uri? launchedUri;
    LaunchMode? launchedMode;
    UpdatePage.urlLauncher =
        (Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
      launchedUri = uri;
      launchedMode = mode;
      return true;
    };

    await tester.pumpWidget(createUpdateApp(container: container));
    await tester.pumpAndSettle();

    // 点击列表中第一个资产的浏览器下载按钮
    final browserBtnFinder = find.byKey(UpdatePage.browserDownloadKey).first;
    await tester.ensureVisible(browserBtnFinder);
    await tester.pumpAndSettle();
    await tester.tap(browserBtnFinder);
    await tester.pumpAndSettle();

    expect(launchedUri?.toString(), 'https://example.com/arm64.apk');
    expect(launchedMode, LaunchMode.externalApplication);

    // 点击常驻栏中的“打开 Release 页面”按钮
    final releasePageBtn = find.byKey(UpdatePage.releasePageKey);
    expect(releasePageBtn, findsOneWidget);
    await tester.tap(releasePageBtn);
    await tester.pumpAndSettle();

    expect(
      launchedUri?.toString(),
      'https://github.com/example/releases/v0.3.0',
    );
    expect(launchedMode, LaunchMode.externalApplication);
  });

  testWidgets('UpdatePage: 测试 6 点击复制 SHA256 校验值到剪贴板',
      (WidgetTester tester) async {
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
        packageInstallerProvider.overrideWithValue(FakePackageInstaller()),
        apkDownloaderProvider.overrideWithValue(FakeApkDownloader()),
      ],
    );
    addTearDown(container.dispose);

    container.read(updateControllerProvider.notifier).state = UpdateState(
      status: UpdateStatus.available,
      release: sampleRelease,
    );

    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          copiedText =
              (methodCall.arguments as Map<dynamic, dynamic>)['text'] as String?;
          return null;
        }
        return null;
      },
    );

    await tester.pumpWidget(createUpdateApp(container: container));
    await tester.pumpAndSettle();

    final digestFinder = find.text('sha256:1111222233334444');
    expect(digestFinder, findsOneWidget);
    await tester.ensureVisible(digestFinder);
    await tester.pumpAndSettle();
    await tester.tap(digestFinder);
    await tester.pumpAndSettle();

    expect(copiedText, 'sha256:1111222233334444');
    expect(find.text('校验值已复制'), findsOneWidget);
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
        packageInstallerProvider.overrideWithValue(FakePackageInstaller()),
        apkDownloaderProvider.overrideWithValue(FakeApkDownloader()),
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
    expect(
      container.read(updateControllerProvider).status,
      UpdateStatus.available,
    );
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
        packageInstallerProvider.overrideWithValue(FakePackageInstaller()),
        apkDownloaderProvider.overrideWithValue(FakeApkDownloader()),
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
