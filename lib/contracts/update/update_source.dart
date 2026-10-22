/// 更新源契约定义（《架构需求文档》2.7 与更新基础设施）。
///
/// 纯 Dart 类，严禁依赖 Flutter。
library;

import 'update_models.dart';

/// 更新拉取结果。
class UpdateFetchResult {
  /// 创建更新拉取结果。
  const UpdateFetchResult({
    this.releases = const <ReleaseInfo>[],
    this.etag,
    this.notModified = false,
  });

  /// 解析出的发布版本列表。
  final List<ReleaseInfo> releases;

  /// HTTP ETag 缓存标识，用于条件请求（`If-None-Match`）。
  final String? etag;

  /// 远端资源未修改（HTTP 304），复用本地缓存。
  final bool notModified;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UpdateFetchResult || runtimeType != other.runtimeType) {
      return false;
    }
    if (etag != other.etag ||
        notModified != other.notModified ||
        releases.length != other.releases.length) {
      return false;
    }
    for (var i = 0; i < releases.length; i++) {
      if (releases[i] != other.releases[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        etag,
        notModified,
        Object.hashAll(releases),
      );

  @override
  String toString() =>
      'UpdateFetchResult(releases: ${releases.length}, etag: $etag, notModified: $notModified)';
}

/// 更新异常失败分类。
enum UpdateFailureKind {
  /// 网络连接异常或超时。
  network,

  /// API 频次受限（如 GitHub 403 / 429 且 ratelimit 配额耗尽）。
  rateLimited,

  /// 远端响应异常（非预期 HTTP 状态码或非合法数据格式）。
  badResponse,

  /// 更新源未配置（如 owner 或 repo 为空）。
  notConfigured,
}

/// 更新操作异常。
class UpdateException implements Exception {
  /// 创建更新异常。
  const UpdateException({required this.kind, this.message});

  /// 失败类别。
  final UpdateFailureKind kind;

  /// 人类可读的失败描述。
  final String? message;

  @override
  String toString() => message != null
      ? 'UpdateException($kind, message: $message)'
      : 'UpdateException($kind)';
}

/// 更新数据源接口。
abstract interface class UpdateSource {
  /// 拉取最新发布版本列表。
  ///
  /// 可传入前一次响应的 [etag]，若远端未变更则返回 [UpdateFetchResult.notModified] 为 `true`。
  Future<UpdateFetchResult> fetchReleases({String? etag});
}
