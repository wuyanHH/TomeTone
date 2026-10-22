/// 应用更新检查服务（《架构需求文档》2.7 与更新基础设施）。
library;

import 'package:tometone/app/app_info.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/update/release_selection.dart';
import 'package:tometone/app/update/semver.dart';
import 'package:tometone/contracts/update/update_models.dart';
import 'package:tometone/contracts/update/update_source.dart';
import 'package:tometone/contracts/update/update_state.dart';

/// 更新检查执行结果（包含计算后的状态、目标版本以及待持久化的偏好）。
class UpdateCheckOutcome {
  /// 创建更新检查结果。
  const UpdateCheckOutcome({
    required this.status,
    this.release,
    this.failure,
    this.fromCache = false,
    required this.preferences,
  });

  /// 本次检查判定的更新状态。
  final UpdateStatus status;

  /// 关联的发布详情（若有）。
  final ReleaseInfo? release;

  /// 异常失败原因（若发生错误）。
  final UpdateFailureKind? failure;

  /// 是否基于本地离线/降级缓存得出的结果。
  final bool fromCache;

  /// 需写回存储的应用偏好。
  final AppPreferences preferences;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateCheckOutcome &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          release == other.release &&
          failure == other.failure &&
          fromCache == other.fromCache &&
          preferences == other.preferences;

  @override
  int get hashCode =>
      Object.hash(status, release, failure, fromCache, preferences);

  @override
  String toString() =>
      'UpdateCheckOutcome(status: $status, release: ${release?.tag}, '
      'failure: $failure, fromCache: $fromCache, preferences: $preferences)';
}

/// 更新服务。
///
/// 封装更新检查、网络请求、缓存降级、304 增量刷新以及 24 小时节流逻辑。
class UpdateService {
  /// 创建更新服务。
  UpdateService({
    required this.source,
    this.now = DateTime.now,
  });

  /// 更新数据源。
  final UpdateSource source;

  /// 当前时间获取函数。
  final DateTime Function() now;

  /// 自动检查节流间隔（24 小时）。
  static const Duration checkInterval = Duration(hours: 24);

  /// 执行更新检查。
  ///
  /// [manual] 为 true 时代表用户主动点击触发（绕过 24h 节流与 autoCheckUpdates 开关）；
  /// [manual] 为 false 时代表应用启动/后台自动检测。
  Future<UpdateCheckOutcome> check({
    required AppPreferences preferences,
    required bool manual,
  }) async {
    // 1. 若非手动触发且未开启自动检查：不发起网络请求
    if (!manual && !preferences.autoCheckUpdates) {
      if (preferences.cachedRelease != null) {
        final status = _evaluateRelease(
          release: preferences.cachedRelease!.release,
          preferences: preferences,
        );
        return UpdateCheckOutcome(
          status: status,
          release: preferences.cachedRelease!.release,
          fromCache: true,
          preferences: preferences,
        );
      }
      return UpdateCheckOutcome(
        status: UpdateStatus.upToDate,
        preferences: preferences,
      );
    }

    // 2. 节流判定（仅针对自动检查 !manual）
    if (!manual && preferences.lastAttemptAt != null) {
      final diff = now().toUtc().difference(preferences.lastAttemptAt!.toUtc());
      if (!diff.isNegative && diff < checkInterval) {
        if (preferences.cachedRelease != null) {
          final status = _evaluateRelease(
            release: preferences.cachedRelease!.release,
            preferences: preferences,
          );
          return UpdateCheckOutcome(
            status: status,
            release: preferences.cachedRelease!.release,
            fromCache: true,
            preferences: preferences,
          );
        }
        return UpdateCheckOutcome(
          status: UpdateStatus.idle,
          preferences: preferences,
        );
      }
    }

    // 3. 发起网络请求
    final attemptAt = now().toUtc();
    final etag = preferences.cachedRelease?.etag;

    final UpdateFetchResult fetchResult;
    try {
      fetchResult = await source.fetchReleases(etag: etag);
    } on UpdateException catch (e) {
      return _handleFailure(
        preferences: preferences,
        failureKind: e.kind,
        attemptAt: attemptAt,
      );
    } catch (_) {
      return _handleFailure(
        preferences: preferences,
        failureKind: UpdateFailureKind.network,
        attemptAt: attemptAt,
      );
    }

    // 4. 处理 304 未修改
    if (fetchResult.notModified) {
      if (preferences.cachedRelease != null) {
        final updatedCached = CachedRelease(
          release: preferences.cachedRelease!.release,
          etag: fetchResult.etag ?? preferences.cachedRelease!.etag,
          fetchedAt: attemptAt,
        );
        final status = _evaluateRelease(
          release: updatedCached.release,
          preferences: preferences,
        );
        return UpdateCheckOutcome(
          status: status,
          release: updatedCached.release,
          fromCache: true,
          preferences: preferences.copyWith(
            lastCheckAt: attemptAt,
            lastAttemptAt: attemptAt,
            cachedRelease: updatedCached,
          ),
        );
      }
      return UpdateCheckOutcome(
        status: UpdateStatus.upToDate,
        fromCache: false,
        preferences: preferences.copyWith(
          lastCheckAt: attemptAt,
          lastAttemptAt: attemptAt,
        ),
      );
    }

    // 5. 处理 200 返回 Releases
    final candidate = selectLatestRelease(
      releases: fetchResult.releases,
      channel: AppInfo.channel,
    );

    if (candidate == null) {
      return UpdateCheckOutcome(
        status: UpdateStatus.noRelease,
        preferences: preferences.copyWith(
          lastCheckAt: attemptAt,
          lastAttemptAt: attemptAt,
        ),
      );
    }

    final newCached = CachedRelease(
      release: candidate.release,
      etag: fetchResult.etag,
      fetchedAt: attemptAt,
    );

    final currentVer = SemVer.tryParse(AppInfo.version) ??
        const SemVer(major: 0, minor: 0, patch: 0);
    final verdict =
        compareToCurrent(current: currentVer, latest: candidate.version);

    final UpdateStatus status;
    if (verdict == UpdateVerdict.upToDate) {
      status = UpdateStatus.upToDate;
    } else if (_isVersionSkipped(
      release: candidate.release,
      version: candidate.version,
      skippedVersion: preferences.skippedVersion,
    )) {
      status = UpdateStatus.skipped;
    } else {
      status = UpdateStatus.available;
    }

    return UpdateCheckOutcome(
      status: status,
      release: candidate.release,
      fromCache: false,
      preferences: preferences.copyWith(
        lastCheckAt: attemptAt,
        lastAttemptAt: attemptAt,
        cachedRelease: newCached,
      ),
    );
  }

  /// 异常降级处理
  UpdateCheckOutcome _handleFailure({
    required AppPreferences preferences,
    required UpdateFailureKind failureKind,
    required DateTime attemptAt,
  }) {
    if (preferences.cachedRelease != null) {
      final status = _evaluateRelease(
        release: preferences.cachedRelease!.release,
        preferences: preferences,
      );
      return UpdateCheckOutcome(
        status: status,
        release: preferences.cachedRelease!.release,
        failure: failureKind,
        fromCache: true,
        preferences: preferences.copyWith(lastAttemptAt: attemptAt),
      );
    }
    return UpdateCheckOutcome(
      status: UpdateStatus.failure,
      failure: failureKind,
      fromCache: false,
      preferences: preferences.copyWith(lastAttemptAt: attemptAt),
    );
  }

  /// 根据当前版本与偏好评估 ReleaseInfo 的更新状态
  UpdateStatus _evaluateRelease({
    required ReleaseInfo release,
    required AppPreferences preferences,
  }) {
    final currentVer = SemVer.tryParse(AppInfo.version) ??
        const SemVer(major: 0, minor: 0, patch: 0);
    final latestVer = versionFromTag(release.tag);
    if (latestVer == null) {
      return UpdateStatus.upToDate;
    }

    final verdict = compareToCurrent(current: currentVer, latest: latestVer);
    if (verdict == UpdateVerdict.upToDate) {
      return UpdateStatus.upToDate;
    }

    if (_isVersionSkipped(
      release: release,
      version: latestVer,
      skippedVersion: preferences.skippedVersion,
    )) {
      return UpdateStatus.skipped;
    }

    return UpdateStatus.available;
  }

  /// 判断版本是否已被跳过
  bool _isVersionSkipped({
    required ReleaseInfo release,
    required SemVer version,
    required String? skippedVersion,
  }) {
    if (skippedVersion == null || skippedVersion.trim().isEmpty) {
      return false;
    }
    final trimmed = skippedVersion.trim();
    final normalizedSkipped = versionFromTag(trimmed)?.toString() ?? trimmed;
    final normalizedRelease =
        versionFromTag(release.tag)?.toString() ?? release.tag.trim();
    final versionStr = version.toString();

    return trimmed == release.tag ||
        trimmed == versionStr ||
        normalizedSkipped == normalizedRelease ||
        normalizedSkipped == versionStr;
  }
}
