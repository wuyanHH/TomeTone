import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tometone/app/providers/apk_download_providers.dart';
import 'package:tometone/app/update/apk_downloader.dart';
import 'package:tometone/contracts/update/apk_download_state.dart';
import 'package:tometone/contracts/update/package_installer.dart';
import 'package:tometone/contracts/update/update_models.dart';

class FakePackageInstaller implements PackageInstaller {
  String? lastInstalledPath;
  bool returnResult = true;
  int installCallCount = 0;

  @override
  Future<bool> installApk(String filePath) async {
    installCallCount++;
    lastInstalledPath = filePath;
    return returnResult;
  }
}

class FakeApkDownloader extends ApkDownloader {
  FakeApkDownloader() : super(client: http.Client());

  int downloadCallCount = 0;
  ReleaseAsset? lastAsset;
  Stream<ApkDownloadState> Function(ReleaseAsset asset)? onDownload;

  @override
  Stream<ApkDownloadState> download({
    required ReleaseAsset asset,
    void Function()? onCancel,
  }) {
    downloadCallCount++;
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
  group('packageInstallerProvider', () {
    test('未 override 依赖时抛出 UnimplementedError', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(packageInstallerProvider),
        throwsA(
          isA<ProviderException>().having(
            (ProviderException e) => e.exception,
            'exception',
            isA<UnimplementedError>(),
          ),
        ),
      );
    });
  });

  group('ApkDownloadNotifier 状态与行为测试', () {
    late FakePackageInstaller fakeInstaller;
    late FakeApkDownloader fakeDownloader;
    late ProviderContainer container;

    setUp(() {
      fakeInstaller = FakePackageInstaller();
      fakeDownloader = FakeApkDownloader();
      container = ProviderContainer(
        overrides: [
          packageInstallerProvider.overrideWithValue(fakeInstaller),
          apkDownloaderProvider.overrideWithValue(fakeDownloader),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    const testAsset = ReleaseAsset(
      name: 'tometone-arm64-v8a.apk',
      sizeBytes: 2048,
      downloadUrl: 'https://example.com/tometone-arm64-v8a.apk',
    );

    test('初始状态为 idle', () {
      final state = container.read(apkDownloadProvider);
      expect(state.status, ApkDownloadStatus.idle);
      expect(state.receivedBytes, 0);
      expect(state.totalBytes, 0);
      expect(state.filePath, isNull);
    });

    test('startDownload 订阅流并将状态同步至 state', () async {
      final controller = StreamController<ApkDownloadState>();
      fakeDownloader.onDownload = (_) => controller.stream;

      final notifier = container.read(apkDownloadProvider.notifier);
      await notifier.startDownload(testAsset);

      expect(fakeDownloader.downloadCallCount, 1);

      controller.add(
        const ApkDownloadState(
          status: ApkDownloadStatus.downloading,
          assetName: 'tometone-arm64-v8a.apk',
          receivedBytes: 1024,
          totalBytes: 2048,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      var state = container.read(apkDownloadProvider);
      expect(state.status, ApkDownloadStatus.downloading);
      expect(state.receivedBytes, 1024);
      expect(state.progress, 0.5);

      controller.add(
        const ApkDownloadState(
          status: ApkDownloadStatus.completed,
          assetName: 'tometone-arm64-v8a.apk',
          receivedBytes: 2048,
          totalBytes: 2048,
          filePath: '/data/local/tmp/tometone-arm64-v8a.apk',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      state = container.read(apkDownloadProvider);
      expect(state.status, ApkDownloadStatus.completed);
      expect(state.filePath, '/data/local/tmp/tometone-arm64-v8a.apk');
      expect(state.progress, 1.0);

      await controller.close();
    });

    test('对正在下载的同一 asset 重复调用 startDownload 会直接忽略', () async {
      final controller = StreamController<ApkDownloadState>();
      fakeDownloader.onDownload = (_) => controller.stream;

      final notifier = container.read(apkDownloadProvider.notifier);
      await notifier.startDownload(testAsset);

      controller.add(
        const ApkDownloadState(
          status: ApkDownloadStatus.downloading,
          assetName: 'tometone-arm64-v8a.apk',
          receivedBytes: 500,
          totalBytes: 2048,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(fakeDownloader.downloadCallCount, 1);

      // 重复调用
      await notifier.startDownload(testAsset);
      expect(fakeDownloader.downloadCallCount, 1);

      await controller.close();
    });

    test('开始下载不同 asset 时会取消旧的 subscription', () async {
      final controller1 = StreamController<ApkDownloadState>();
      var cancelled1 = false;
      controller1.onCancel = () {
        cancelled1 = true;
      };

      final controller2 = StreamController<ApkDownloadState>();

      var call = 0;
      fakeDownloader.onDownload = (asset) {
        call++;
        return call == 1 ? controller1.stream : controller2.stream;
      };

      final notifier = container.read(apkDownloadProvider.notifier);
      await notifier.startDownload(testAsset);

      const otherAsset = ReleaseAsset(
        name: 'tometone-universal.apk',
        sizeBytes: 4096,
        downloadUrl: 'https://example.com/other.apk',
      );

      await notifier.startDownload(otherAsset);

      expect(cancelled1, isTrue);
      expect(fakeDownloader.downloadCallCount, 2);

      await controller1.close();
      await controller2.close();
    });

    test('cancel 在 downloading 状态时取消流并将状态置为 cancelled', () async {
      final controller = StreamController<ApkDownloadState>();
      var isCancelled = false;
      controller.onCancel = () {
        isCancelled = true;
      };

      fakeDownloader.onDownload = (_) => controller.stream;

      final notifier = container.read(apkDownloadProvider.notifier);
      await notifier.startDownload(testAsset);

      controller.add(
        const ApkDownloadState(
          status: ApkDownloadStatus.downloading,
          assetName: 'tometone-arm64-v8a.apk',
          receivedBytes: 100,
          totalBytes: 2048,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(apkDownloadProvider).status, ApkDownloadStatus.downloading);

      notifier.cancel();

      expect(isCancelled, isTrue);
      final cancelledState = container.read(apkDownloadProvider);
      expect(cancelledState.status, ApkDownloadStatus.cancelled);
      expect(cancelledState.assetName, 'tometone-arm64-v8a.apk');

      await controller.close();
    });

    test('cancel 在非 downloading 状态时不修改状态', () {
      final notifier = container.read(apkDownloadProvider.notifier);
      notifier.cancel();

      expect(container.read(apkDownloadProvider).status, ApkDownloadStatus.idle);
    });

    test('installCurrent：completed 且 filePath 不为空时调用 installer 并返回成功', () async {
      final controller = StreamController<ApkDownloadState>();
      fakeDownloader.onDownload = (_) => controller.stream;

      final notifier = container.read(apkDownloadProvider.notifier);
      await notifier.startDownload(testAsset);

      controller.add(
        const ApkDownloadState(
          status: ApkDownloadStatus.completed,
          assetName: 'tometone-arm64-v8a.apk',
          filePath: '/data/local/tmp/app.apk',
          receivedBytes: 2048,
          totalBytes: 2048,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      fakeInstaller.returnResult = true;
      final ok = await notifier.installCurrent();

      expect(ok, isTrue);
      expect(fakeInstaller.installCallCount, 1);
      expect(fakeInstaller.lastInstalledPath, '/data/local/tmp/app.apk');

      await controller.close();
    });

    test('installCurrent：非 completed 状态返回 false 且不调用 installer', () async {
      final notifier = container.read(apkDownloadProvider.notifier);
      final ok = await notifier.installCurrent();

      expect(ok, isFalse);
      expect(fakeInstaller.installCallCount, 0);
    });

    test('reset 取消下载并重置为初始 idle 状态', () async {
      final controller = StreamController<ApkDownloadState>();
      var isCancelled = false;
      controller.onCancel = () {
        isCancelled = true;
      };

      fakeDownloader.onDownload = (_) => controller.stream;

      final notifier = container.read(apkDownloadProvider.notifier);
      await notifier.startDownload(testAsset);

      controller.add(
        const ApkDownloadState(
          status: ApkDownloadStatus.downloading,
          assetName: 'tometone-arm64-v8a.apk',
          receivedBytes: 100,
          totalBytes: 2048,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      notifier.reset();

      expect(isCancelled, isTrue);
      final resetState = container.read(apkDownloadProvider);
      expect(resetState.status, ApkDownloadStatus.idle);
      expect(resetState.assetName, isNull);
      expect(resetState.receivedBytes, 0);

      await controller.close();
    });
  });
}
