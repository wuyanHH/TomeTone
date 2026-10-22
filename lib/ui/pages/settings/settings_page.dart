import 'package:flutter/material.dart';
import 'package:tometone/app/app_info.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/ui/pages/settings/subpages/about_settings_page.dart';
import 'package:tometone/ui/pages/settings/subpages/appearance_settings_page.dart';
import 'package:tometone/ui/pages/settings/subpages/audio_preference_settings_page.dart';
import 'package:tometone/ui/pages/settings/subpages/cache_settings_page.dart';
import 'package:tometone/ui/theme/app_color_palette.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 设置页（《架构需求文档》§2.1 / §2.8 / §3.3）。
///
/// 采用二级清晰分类架构：
/// 1. **外观** —— 色盘、明暗与暗夜 OLED 偏好设置；
/// 2. **听书偏好** —— 默认播放倍速、片头片尾跳过；
/// 3. **存储与缓存** —— 在线音频缓存容量与预下载策略；
/// 4. **关于与更新** —— 版本、开源许可、检查更新与更新历史。
class SettingsPage extends StatelessWidget {
  /// 创建设置页。
  const SettingsPage({super.key});

  /// 一级入口：外观。
  static const Key tileAppearanceKey = Key('settings-tile-appearance');

  /// 一级入口：听书偏好。
  static const Key tileAudioPreferenceKey = Key('settings-tile-audio-preference');

  /// 一级入口：存储与缓存。
  static const Key tileCacheKey = Key('settings-tile-cache');

  /// 一级入口：关于与更新。
  static const Key tileAboutKey = Key('settings-tile-about');

  /// 开源许可入口测试键。
  static const Key licensesKey = Key('settings-licenses');

  /// 更新历史入口测试键。
  static const Key updateHistoryKey = Key('settings-update-history');

  /// 检查更新入口测试键。
  static const Key checkUpdateKey = Key('settings-check-update');

  /// 自动检查更新开关测试键。
  static const Key autoCheckSwitchKey = Key('settings-auto-check-switch');

  /// 外观：色盘选项辅助 key。
  static Key appearancePaletteKey(AppPaletteId id) =>
      Key('appearance-palette-${id.name}');

  /// 外观：暗夜 OLED 开关辅助 key。
  static const Key oledSwitchKey = Key('appearance-oled-switch');

  /// 外观：明暗模式选项辅助 key。
  static Key brightnessKey(BrightnessPreference pref) =>
      Key('appearance-brightness-${pref.name}');

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _SettingsHeader(),
              Padding(
                padding: AppSpacing.pagePadding,
                child: Card(
                  child: Column(
                    children: <Widget>[
                      _SettingsNavTile(
                        key: tileAppearanceKey,
                        icon: Icons.palette_outlined,
                        title: '外观',
                        subtitle: '国风色盘、明暗外观与 OLED 纯黑',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const AppearanceSettingsPage(),
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.lg,
                        endIndent: AppSpacing.lg,
                      ),
                      _SettingsNavTile(
                        key: tileAudioPreferenceKey,
                        icon: Icons.tune_rounded,
                        title: '听书偏好',
                        subtitle: '默认播放倍速、片头片尾智能跳过',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const AudioPreferenceSettingsPage(),
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.lg,
                        endIndent: AppSpacing.lg,
                      ),
                      _SettingsNavTile(
                        key: tileCacheKey,
                        icon: Icons.storage_rounded,
                        title: '存储与缓存',
                        subtitle: '在线音频缓存用量与清理',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const CacheSettingsPage(),
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.lg,
                        endIndent: AppSpacing.lg,
                      ),
                      _SettingsNavTile(
                        key: tileAboutKey,
                        icon: Icons.info_outline_rounded,
                        title: '关于与更新',
                        subtitle: '版本信息、更新检测与开源许可',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const AboutSettingsPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: AppSpacing.pagePadding,
                child: Text(
                  '${AppInfo.appName} · ${AppInfo.appNameLatin}　本地优先，离线可用',
                  textAlign: TextAlign.center,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 设置页导航列表项。
class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(title, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: scheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

/// 页首题头。
class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: SizedBox(
        height: 48,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            header: true,
            child: Text(
              '系统偏好',
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
