import 'package:flutter/foundation.dart';
import 'package:tometone/contracts/update/update_state.dart';

/// 明暗外观偏好（《架构需求文档》§8.2）。
enum BrightnessPreference {
  /// 跟随系统设置。
  system,

  /// 始终浅色。
  light,

  /// 始终深色。
  dark,
}

/// 全局应用偏好（《架构需求文档》§8.2）。
///
/// 不可变实体类。存储色盘、明暗、更新检查等应用级配置。
/// 架构铁律：本文件位于 `lib/app/`，严禁直接或间接导入 `lib/ui/`，
/// 色盘以 String（[paletteId]）存储，由 UI 层按需查找对应配色。
@immutable
class AppPreferences {
  /// 创建应用偏好。
  const AppPreferences({
    this.paletteId = 'amberScroll',
    this.brightness = BrightnessPreference.system,
    this.oledDark = false,
    this.autoCheckUpdates = true,
    this.skippedVersion,
    this.promptedVersion,
    this.acknowledgedVersion,
    this.lastCheckAt,
    this.lastAttemptAt,
    this.cachedRelease,
  });

  /// 默认应用偏好（琥珀旧卷、跟随系统、关闭 OLED 纯黑、开启自动检查）。
  static const AppPreferences defaults = AppPreferences();

  /// 色盘标识（对应 UI 层色盘的 name，默认 'amberScroll'）。
  final String paletteId;

  /// 明暗偏好（默认跟随系统）。
  final BrightnessPreference brightness;

  /// 深色模式下是否使用 OLED 纯黑底色（默认关闭）。
  final bool oledDark;

  /// 是否自动检查更新（默认开启）。
  final bool autoCheckUpdates;

  /// 用户选择跳过的版本号（默认 null）。
  final String? skippedVersion;

  /// 已弹窗提示过的版本号（默认 null，避免重复打扰）。
  final String? promptedVersion;

  /// 用户已打开更新页确认过的版本号（默认 null，用于清除更新红点）。
  final String? acknowledgedVersion;

  /// 上次成功检查更新的时间（UTC，默认 null）。
  final DateTime? lastCheckAt;

  /// 上次尝试检查更新的时间（UTC，含失败，默认 null）。
  final DateTime? lastAttemptAt;

  /// 本地缓存的最新 Release 详情（用于离线展示与 304 快速比对，默认 null）。
  final CachedRelease? cachedRelease;

  static const Object _sentinel = Object();

  /// 复制并覆盖部分字段。
  ///
  /// 对于可空字段，显式传入 `null` 会清空该字段为 `null`；省略则保留当前值。
  AppPreferences copyWith({
    String? paletteId,
    BrightnessPreference? brightness,
    bool? oledDark,
    bool? autoCheckUpdates,
    Object? skippedVersion = _sentinel,
    Object? promptedVersion = _sentinel,
    Object? acknowledgedVersion = _sentinel,
    Object? lastCheckAt = _sentinel,
    Object? lastAttemptAt = _sentinel,
    Object? cachedRelease = _sentinel,
  }) {
    return AppPreferences(
      paletteId: paletteId ?? this.paletteId,
      brightness: brightness ?? this.brightness,
      oledDark: oledDark ?? this.oledDark,
      autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
      skippedVersion: identical(skippedVersion, _sentinel)
          ? this.skippedVersion
          : skippedVersion as String?,
      promptedVersion: identical(promptedVersion, _sentinel)
          ? this.promptedVersion
          : promptedVersion as String?,
      acknowledgedVersion: identical(acknowledgedVersion, _sentinel)
          ? this.acknowledgedVersion
          : acknowledgedVersion as String?,
      lastCheckAt: identical(lastCheckAt, _sentinel)
          ? this.lastCheckAt
          : lastCheckAt as DateTime?,
      lastAttemptAt: identical(lastAttemptAt, _sentinel)
          ? this.lastAttemptAt
          : lastAttemptAt as DateTime?,
      cachedRelease: identical(cachedRelease, _sentinel)
          ? this.cachedRelease
          : cachedRelease as CachedRelease?,
    );
  }

  /// 序列化为 JSON Map。
  ///
  /// 采用稳定的 key，DateTime 统一转换为 UTC ISO-8601 字符串。
  Map<String, Object?> toJson() => <String, Object?>{
        'paletteId': paletteId,
        'brightness': brightness.name,
        'oledDark': oledDark,
        'autoCheckUpdates': autoCheckUpdates,
        'skippedVersion': skippedVersion,
        'promptedVersion': promptedVersion,
        'acknowledgedVersion': acknowledgedVersion,
        'lastCheckAt': lastCheckAt?.toUtc().toIso8601String(),
        'lastAttemptAt': lastAttemptAt?.toUtc().toIso8601String(),
        'cachedRelease': cachedRelease?.toJson(),
      };

  /// 从 JSON Map 反序列化偏好。
  ///
  /// 独立字段容错：任何字段缺失、类型不匹配或非法枚举值回落到默认值，
  /// 日期解析失败为 null，绝不抛出异常。
  factory AppPreferences.fromJson(Map<String, Object?> json) {
    final rawPaletteId = json['paletteId'];
    final paletteId = (rawPaletteId is String && rawPaletteId.isNotEmpty)
        ? rawPaletteId
        : defaults.paletteId;

    final rawBrightness = json['brightness'];
    final brightness = rawBrightness is String
        ? _parseBrightness(rawBrightness)
        : defaults.brightness;

    final rawOledDark = json['oledDark'];
    final oledDark = rawOledDark is bool ? rawOledDark : defaults.oledDark;

    final rawAutoCheck = json['autoCheckUpdates'];
    final autoCheckUpdates =
        rawAutoCheck is bool ? rawAutoCheck : defaults.autoCheckUpdates;

    final rawSkippedVersion = json['skippedVersion'];
    final skippedVersion =
        rawSkippedVersion is String ? rawSkippedVersion : null;

    final rawPromptedVersion = json['promptedVersion'];
    final promptedVersion =
        rawPromptedVersion is String ? rawPromptedVersion : null;

    final rawAcknowledgedVersion = json['acknowledgedVersion'];
    final acknowledgedVersion =
        rawAcknowledgedVersion is String ? rawAcknowledgedVersion : null;

    final lastCheckAt = _parseDateTime(json['lastCheckAt']);
    final lastAttemptAt = _parseDateTime(json['lastAttemptAt']);

    final rawCached = json['cachedRelease'];
    final CachedRelease? cachedRelease;
    if (rawCached is Map<String, Object?>) {
      cachedRelease = _parseCachedRelease(rawCached);
    } else if (rawCached is Map) {
      cachedRelease = _parseCachedRelease(rawCached.cast<String, Object?>());
    } else {
      cachedRelease = null;
    }

    return AppPreferences(
      paletteId: paletteId,
      brightness: brightness,
      oledDark: oledDark,
      autoCheckUpdates: autoCheckUpdates,
      skippedVersion: skippedVersion,
      promptedVersion: promptedVersion,
      acknowledgedVersion: acknowledgedVersion,
      lastCheckAt: lastCheckAt,
      lastAttemptAt: lastAttemptAt,
      cachedRelease: cachedRelease,
    );
  }

  static CachedRelease? _parseCachedRelease(Map<String, Object?> json) {
    try {
      return CachedRelease.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static BrightnessPreference _parseBrightness(String name) {
    for (final value in BrightnessPreference.values) {
      if (value.name == name) {
        return value;
      }
    }
    return defaults.brightness;
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPreferences &&
          runtimeType == other.runtimeType &&
          paletteId == other.paletteId &&
          brightness == other.brightness &&
          oledDark == other.oledDark &&
          autoCheckUpdates == other.autoCheckUpdates &&
          skippedVersion == other.skippedVersion &&
          promptedVersion == other.promptedVersion &&
          acknowledgedVersion == other.acknowledgedVersion &&
          lastCheckAt == other.lastCheckAt &&
          lastAttemptAt == other.lastAttemptAt &&
          cachedRelease == other.cachedRelease;

  @override
  int get hashCode => Object.hash(
        paletteId,
        brightness,
        oledDark,
        autoCheckUpdates,
        skippedVersion,
        promptedVersion,
        acknowledgedVersion,
        lastCheckAt,
        lastAttemptAt,
        cachedRelease,
      );

  @override
  String toString() =>
      'AppPreferences(paletteId: $paletteId, brightness: ${brightness.name}, '
      'oledDark: $oledDark, autoCheckUpdates: $autoCheckUpdates, '
      'skippedVersion: $skippedVersion, promptedVersion: $promptedVersion, '
      'acknowledgedVersion: $acknowledgedVersion, '
      'lastCheckAt: $lastCheckAt, lastAttemptAt: $lastAttemptAt, '
      'cachedRelease: $cachedRelease)';
}
