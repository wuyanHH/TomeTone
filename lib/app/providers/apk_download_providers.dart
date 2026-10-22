/// APK 下载与安装状态 Provider（《架构需求文档》2.7 与更新基础设施）。
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:tometone/app/update/apk_downloader.dart';
import 'package:tometone/contracts/update/apk_download_state.dart';
import 'package:tometone/contracts/update/package_installer.dart';
import 'package:tometone/contracts/update/update_models.dart';

/// 安装包安装器 Provider，装配层必须覆盖。
final Provider<PackageInstaller> packageInstallerProvider =
    Provider<PackageInstaller>((Ref ref) {
  throw UnimplementedError('packageInstallerProvider must be overridden');
});

/// APK 下载器 Provider。
final Provider<ApkDownloader> apkDownloaderProvider =
    Provider<ApkDownloader>((Ref ref) {
  return ApkDownloader(client: http.Client());
});

/// APK 下载与安装状态控制器。
class ApkDownloadNotifier extends Notifier<ApkDownloadState> {
  StreamSubscription<ApkDownloadState>? _subscription;

  @override
  ApkDownloadState build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return const ApkDownloadState();
  }

  /// 开始下载指定产物。
  Future<void> startDownload(ReleaseAsset asset) async {
    if (state.status == ApkDownloadStatus.downloading &&
        state.assetName == asset.name) {
      return;
    }

    await _subscription?.cancel();
    _subscription = null;

    final downloader = ref.read(apkDownloaderProvider);
    _subscription = downloader.download(asset: asset).listen(
      (newState) {
        state = newState;
      },
      onError: (Object error) {
        state = state.copyWith(
          status: ApkDownloadStatus.failed,
          error: error.toString(),
        );
      },
    );
  }

  /// 取消当前下载。
  void cancel() {
    _subscription?.cancel();
    _subscription = null;
    if (state.status == ApkDownloadStatus.downloading) {
      state = state.copyWith(status: ApkDownloadStatus.cancelled);
    }
  }

  /// 安装已下载完成的安装包。
  Future<bool> installCurrent() async {
    if (state.status == ApkDownloadStatus.completed && state.filePath != null) {
      return ref.read(packageInstallerProvider).installApk(state.filePath!);
    }
    return false;
  }

  /// 重置下载状态。
  void reset() {
    _subscription?.cancel();
    _subscription = null;
    state = const ApkDownloadState();
  }
}

/// APK 下载与安装状态 Provider。
final NotifierProvider<ApkDownloadNotifier, ApkDownloadState>
    apkDownloadProvider =
    NotifierProvider<ApkDownloadNotifier, ApkDownloadState>(
  ApkDownloadNotifier.new,
);
