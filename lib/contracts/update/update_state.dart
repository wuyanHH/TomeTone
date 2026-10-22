/// 更新状态与缓存契约（《架构需求文档》2.7 与更新基础设施）。
///
/// 纯 Dart 类，严禁依赖 Flutter。
library;

import 'update_models.dart';
import 'update_source.dart';

/// 更新检查与运行状态枚举。
enum UpdateStatus {
  /// 空闲初始态（尚未执行更新检查）。
  idle,

  /// 正在检查更新中。
  checking,

  /// 已是最新版本，无需更新。
  upToDate,

  /// 远端无匹配当前发布通道或设备的可用 Release 产物。
  noRelease,

  /// 发现新版本可用。
  available,

  /// 发现的新版本已被用户选择跳过。
  skipped,

  /// 更新检查过程发生异常。
  failure,
}

/// 更新状态实体。
class UpdateState {
  /// 创建更新状态。
  const UpdateState({
    required this.status,
    this.release,
    this.failure,
    this.fromCache = false,
  });

  /// 当前更新状态。
  final UpdateStatus status;

  /// 最新目标版本信息（若有）。
  final ReleaseInfo? release;

  /// 失败类别（仅在 [status] 为 [UpdateStatus.failure] 时存在）。
  final UpdateFailureKind? failure;

  /// 当前展示结果是否来自本地离线/降级缓存。
  final bool fromCache;

  static const Object _sentinel = Object();

  /// 复制并更新部分字段。
  UpdateState copyWith({
    UpdateStatus? status,
    Object? release = _sentinel,
    Object? failure = _sentinel,
    bool? fromCache,
  }) {
    return UpdateState(
      status: status ?? this.status,
      release: identical(release, _sentinel)
          ? this.release
          : release as ReleaseInfo?,
      failure: identical(failure, _sentinel)
          ? this.failure
          : failure as UpdateFailureKind?,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          release == other.release &&
          failure == other.failure &&
          fromCache == other.fromCache;

  @override
  int get hashCode => Object.hash(status, release, failure, fromCache);

  @override
  String toString() =>
      'UpdateState(status: $status, release: ${release?.tag}, failure: $failure, fromCache: $fromCache)';
}

/// 本地持久化缓存的发布信息。
class CachedRelease {
  /// 创建本地持久化缓存发布信息。
  const CachedRelease({
    required this.release,
    this.etag,
    required this.fetchedAt,
  });

  /// 从 Map 容错解析缓存版本信息。
  ///
  /// 日期解析失败回退至当前 UTC 时间。
  factory CachedRelease.fromJson(Map<String, Object?> json) {
    final rawRelease = json['release'];
    final ReleaseInfo release;
    if (rawRelease is Map<String, Object?>) {
      release = ReleaseInfo.fromJson(rawRelease);
    } else if (rawRelease is Map) {
      release = ReleaseInfo.fromJson(rawRelease.cast<String, Object?>());
    } else {
      release = ReleaseInfo.fromJson(const <String, Object?>{});
    }

    final rawEtag = json['etag'];
    final String? etag = rawEtag is String ? rawEtag : null;

    final rawFetchedAt = json['fetchedAt'];
    DateTime fetchedAt;
    if (rawFetchedAt is String) {
      fetchedAt =
          DateTime.tryParse(rawFetchedAt)?.toUtc() ?? DateTime.now().toUtc();
    } else if (rawFetchedAt is int) {
      fetchedAt =
          DateTime.fromMillisecondsSinceEpoch(rawFetchedAt, isUtc: true);
    } else {
      fetchedAt = DateTime.now().toUtc();
    }

    return CachedRelease(
      release: release,
      etag: etag,
      fetchedAt: fetchedAt,
    );
  }

  /// 缓存的发布详情。
  final ReleaseInfo release;

  /// 上次拉取所记录的 HTTP ETag 标识。
  final String? etag;

  /// 本次缓存拉取或验证通过的时间（UTC）。
  final DateTime fetchedAt;

  /// 序列化为 JSON Map。
  Map<String, Object?> toJson() => <String, Object?>{
        'release': release.toJson(),
        if (etag != null) 'etag': etag,
        'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedRelease &&
          runtimeType == other.runtimeType &&
          release == other.release &&
          etag == other.etag &&
          fetchedAt.isAtSameMomentAs(other.fetchedAt);

  @override
  int get hashCode => Object.hash(
        release,
        etag,
        fetchedAt.toUtc().millisecondsSinceEpoch,
      );

  @override
  String toString() =>
      'CachedRelease(tag: ${release.tag}, etag: $etag, fetchedAt: $fetchedAt)';
}
