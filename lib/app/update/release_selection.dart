/// 发布候选版本筛选与判定（《架构需求文档》2.7）。
library;

import 'package:tometone/app/app_info.dart';
import 'package:tometone/contracts/update/update_models.dart';

import 'semver.dart';

/// 经初步筛选符合条件的发布候选。
class ReleaseCandidate {
  /// 创建候选发布。
  const ReleaseCandidate({
    required this.release,
    required this.version,
  });

  /// 原始发布信息。
  final ReleaseInfo release;

  /// 解析出的语义化版本号。
  final SemVer version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReleaseCandidate &&
          runtimeType == other.runtimeType &&
          release == other.release &&
          version == other.version;

  @override
  int get hashCode => Object.hash(release, version);

  @override
  String toString() =>
      'ReleaseCandidate(version: $version, tag: ${release.tag})';
}

/// 更新判定结论。
enum UpdateVerdict {
  /// 当前版本已是最新或高于远程，无需更新。
  upToDate,

  /// 有新版本可用。
  available,
}

/// 从远程版本列表中按通道策略挑选最新的发布候选。
///
/// 过滤规则：
/// 1. 排除草稿（`draft == true`）；
/// 2. 排除 Tag 无法解析为合法 SemVer 的版本；
/// 3. 排除不包含任何 `.apk` 产物的版本；
/// 4. 若通道为 [AppChannel.stable]，排除预发布版本（`prerelease == true` 或版本本身含有预发布标识）。
///
/// 在最终候选池中选择版本最大者；若版本相同，保留列表中靠前的一项。
ReleaseCandidate? selectLatestRelease({
  required List<ReleaseInfo> releases,
  required AppChannel channel,
}) {
  ReleaseCandidate? best;

  for (final release in releases) {
    if (release.draft) {
      continue;
    }

    final version = versionFromTag(release.tag);
    if (version == null) {
      continue;
    }

    final hasApk = release.assets.any(
      (a) => a.name.toLowerCase().endsWith('.apk'),
    );
    if (!hasApk) {
      continue;
    }

    if (channel == AppChannel.stable &&
        (release.prerelease || version.isPrerelease)) {
      continue;
    }

    final candidate = ReleaseCandidate(release: release, version: version);
    if (best == null || candidate.version.compareTo(best.version) > 0) {
      best = candidate;
    }
  }

  return best;
}

/// 比较最新版本与当前版本，给出更新裁决。
///
/// 严格遵循不降级原则：仅在 [latest] 严格大于 [current] 时判定为 [UpdateVerdict.available]，
/// 否则返回 [UpdateVerdict.upToDate]。
UpdateVerdict compareToCurrent({
  required SemVer current,
  required SemVer latest,
}) {
  if (latest.compareTo(current) > 0) {
    return UpdateVerdict.available;
  }
  return UpdateVerdict.upToDate;
}

/// 根据设备支持的 ABI 列表按优先级推荐最适合的 APK 产物文件名。
///
/// 遍历 [deviceAbis]（通常高优在前，例如 `arm64-v8a` > `armeabi-v7a` > `x86_64`），
/// 在 `.apk` 资产中查找文件名包含该 ABI 标识的条目，返回首个命中的 `asset.name`。
/// 若无可匹配项则返回 `null`。
String? recommendedAbiAsset(
  List<String> deviceAbis,
  List<ReleaseAsset> assets,
) {
  final apkAssets = assets
      .where((a) => a.name.toLowerCase().endsWith('.apk'))
      .toList(growable: false);

  for (final abi in deviceAbis) {
    final normalized = abi.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    for (final asset in apkAssets) {
      if (_matchesAbi(asset.name, normalized)) {
        return asset.name;
      }
    }
  }

  return null;
}

bool _matchesAbi(String assetName, String targetAbi) {
  final lowerName = assetName.toLowerCase();
  final lowerAbi = targetAbi.toLowerCase();
  if (!lowerName.contains(lowerAbi)) {
    return false;
  }
  // 防止 x86 误匹配 x86_64
  if (lowerAbi == 'x86' &&
      lowerName.contains('x86_64') &&
      !lowerName.contains(RegExp(r'x86(?![_0-9a-zA-Z])'))) {
    return false;
  }
  // 防止 armeabi 误匹配 armeabi-v7a
  if (lowerAbi == 'armeabi' &&
      lowerName.contains('armeabi-v7a') &&
      !lowerName.contains(RegExp(r'armeabi(?!-v7a)'))) {
    return false;
  }
  return true;
}
