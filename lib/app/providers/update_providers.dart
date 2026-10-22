/// 应用更新状态与控制器 Provider（《架构需求文档》2.7 与更新基础设施）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/app/update/semver.dart';
import 'package:tometone/app/update/update_service.dart';
import 'package:tometone/contracts/update/device_architecture.dart';
import 'package:tometone/contracts/update/update_source.dart';
import 'package:tometone/contracts/update/update_state.dart';

/// 设备架构 Provider，装配层必须覆盖。
final Provider<DeviceArchitecture> deviceArchitectureProvider =
    Provider<DeviceArchitecture>((Ref ref) {
  throw UnimplementedError('deviceArchitectureProvider must be overridden');
});

/// 更新数据源 Provider，装配层必须覆盖。
final Provider<UpdateSource> updateSourceProvider =
    Provider<UpdateSource>((Ref ref) {
  throw UnimplementedError('updateSourceProvider must be overridden');
});

/// 更新服务 Provider。
final Provider<UpdateService> updateServiceProvider =
    Provider<UpdateService>((Ref ref) {
  return UpdateService(source: ref.watch(updateSourceProvider));
});

/// 更新状态控制器。
class UpdateController extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateState(status: UpdateStatus.idle);

  /// 执行更新检查。
  ///
  /// [manual] 表示是否由用户手动触发。
  /// 内置防重复触发检查；检查完毕后自动写回偏好并更新状态。
  Future<void> check({required bool manual}) async {
    if (state.status == UpdateStatus.checking) {
      return;
    }
    state = state.copyWith(status: UpdateStatus.checking);

    final outcome = await ref.read(updateServiceProvider).check(
          preferences: ref.read(preferencesProvider),
          manual: manual,
        );

    ref.read(preferencesProvider.notifier).replace(outcome.preferences);
    state = UpdateState(
      status: outcome.status,
      release: outcome.release,
      failure: outcome.failure,
      fromCache: outcome.fromCache,
    );
  }

  /// 跳过指定版本。
  ///
  /// 自动规范化版本号并写入偏好，将当前状态置为 [UpdateStatus.skipped]。
  Future<void> skipVersion(String version) async {
    final normalized = versionFromTag(version)?.toString() ?? version;
    ref.read(preferencesProvider.notifier).update(
          (p) => p.copyWith(
            skippedVersion: normalized,
            acknowledgedVersion: normalized,
          ),
        );
    state = state.copyWith(status: UpdateStatus.skipped);
  }

  /// 清除已跳过的版本，并立即触发一次手动更新检查。
  Future<void> clearSkip() async {
    ref.read(preferencesProvider.notifier).update(
          (p) => p.copyWith(skippedVersion: null),
        );
    await check(manual: true);
  }

  /// 标记用户已确认/获知指定版本（清除更新红点）。
  Future<void> acknowledge(String version) async {
    final normalized = versionFromTag(version)?.toString() ?? version;
    ref.read(preferencesProvider.notifier).update(
          (p) => p.copyWith(acknowledgedVersion: normalized),
        );
  }

  /// 标记已对指定版本弹窗提示过（防止重复弹窗打扰）。
  Future<void> markPrompted(String version) async {
    final normalized = versionFromTag(version)?.toString() ?? version;
    ref.read(preferencesProvider.notifier).update(
          (p) => p.copyWith(promptedVersion: normalized),
        );
  }

  /// 设置是否开启自动检查更新。
  Future<void> setAutoCheck(bool enabled) async {
    ref.read(preferencesProvider.notifier).update(
          (p) => p.copyWith(autoCheckUpdates: enabled),
        );
  }

  /// 若开启自动检查偏好，则触发一次自动更新检查。
  Future<void> maybeAutoCheck() async {
    if (ref.read(preferencesProvider).autoCheckUpdates) {
      await check(manual: false);
    }
  }
}

/// 全局更新状态控制器 Provider。
final NotifierProvider<UpdateController, UpdateState> updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

/// 更新红点提示 Provider。
///
/// 当且仅当满足以下全部条件时为 true：
/// 1. 开启了自动检查更新；
/// 2. 当前更新状态为有新版可用（available）且 release 非空；
/// 3. 最新版本号未被用户确认（acknowledgedVersion 不等于最新版本）。
final Provider<bool> updateBadgeProvider = Provider<bool>((Ref ref) {
  final prefs = ref.watch(preferencesProvider);
  final updateState = ref.watch(updateControllerProvider);
  final release = updateState.release;

  if (!prefs.autoCheckUpdates) {
    return false;
  }
  if (updateState.status != UpdateStatus.available || release == null) {
    return false;
  }

  final latestVersion = versionFromTag(release.tag)?.toString() ?? release.tag;
  final acknowledged = prefs.acknowledgedVersion;
  final normalizedAcknowledged = acknowledged != null
      ? (versionFromTag(acknowledged)?.toString() ?? acknowledged)
      : null;

  return latestVersion != normalizedAcknowledged &&
      release.tag != acknowledged;
});
