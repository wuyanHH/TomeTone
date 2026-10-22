/// APK 下载状态契约（《架构需求文档》2.7 与更新基础设施）。
///
/// 纯 Dart 类，严禁依赖 Flutter。
library;

/// APK 下载状态枚举。
enum ApkDownloadStatus {
  /// 空闲状态。
  idle,

  /// 正在下载。
  downloading,

  /// 下载完成。
  completed,

  /// 下载失败。
  failed,

  /// 已取消。
  cancelled,
}

/// APK 下载状态快照。
class ApkDownloadState {
  /// 创建 APK 下载状态。
  const ApkDownloadState({
    this.status = ApkDownloadStatus.idle,
    this.assetName,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.filePath,
    this.error,
  });

  /// 当前下载状态。
  final ApkDownloadStatus status;

  /// 正在下载的产物文件名。
  final String? assetName;

  /// 已接收字节数。
  final int receivedBytes;

  /// 文件总字节数。
  final int totalBytes;

  /// 下载完成后保存的本地文件路径。
  final String? filePath;

  /// 失败时的错误信息。
  final String? error;

  /// 下载进度（0.0 至 1.0 之间）。
  double get progress =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  static const Object _sentinel = Object();

  /// 复制并更新部分字段。
  ApkDownloadState copyWith({
    ApkDownloadStatus? status,
    Object? assetName = _sentinel,
    int? receivedBytes,
    int? totalBytes,
    Object? filePath = _sentinel,
    Object? error = _sentinel,
  }) {
    return ApkDownloadState(
      status: status ?? this.status,
      assetName: identical(assetName, _sentinel)
          ? this.assetName
          : assetName as String?,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      filePath: identical(filePath, _sentinel)
          ? this.filePath
          : filePath as String?,
      error: identical(error, _sentinel)
          ? this.error
          : error as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApkDownloadState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          assetName == other.assetName &&
          receivedBytes == other.receivedBytes &&
          totalBytes == other.totalBytes &&
          filePath == other.filePath &&
          error == other.error;

  @override
  int get hashCode => Object.hash(
        status,
        assetName,
        receivedBytes,
        totalBytes,
        filePath,
        error,
      );

  @override
  String toString() =>
      'ApkDownloadState(status: $status, assetName: $assetName, receivedBytes: $receivedBytes, totalBytes: $totalBytes, filePath: $filePath, error: $error)';
}
