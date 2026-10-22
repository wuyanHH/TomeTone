import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/app_info.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/app/providers/update_providers.dart';
import 'package:tometone/contracts/update/update_state.dart';
import 'package:tometone/ui/theme/app_color_palette.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'cache_settings_section.dart';
import 'update_history_page.dart';
import 'update_page.dart';

/// 设置页（《架构需求文档》§2.1 / §2.8 / §3.3）。
///
/// 信息层级（自上而下）：
/// 1. **外观** —— 色盘、明暗与暗夜 OLED 偏好设置；
/// 2. **音频缓存** —— 在线缓存容量与预下载策略；
/// 3. **关于** —— 版本、开源许可、检查更新（更新源未配置时如实说明）。
///
/// 方案 A：书库根已拆到独立的「书库」tab，设置页不再读写书库数据，
/// 只保留偏好与说明；页面也因此不再需要 provider 依赖。
class SettingsPage extends StatelessWidget {
  /// 创建设置页。
  const SettingsPage({super.key});

  /// 开源许可入口。
  static const Key licensesKey = Key('settings-licenses');

  /// 更新历史入口。
  static const Key updateHistoryKey = Key('settings-update-history');

  /// 检查更新入口。
  static const Key checkUpdateKey = Key('settings-check-update');

  /// 自动检查更新开关。
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
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _SettingsHeader(),
              const Padding(
                padding: AppSpacing.pagePadding,
                child: _AppearanceSection(),
              ),
              const _SectionRule(),
              const Padding(
                padding: AppSpacing.pagePadding,
                child: CacheSettingsSection(),
              ),
              const _SectionRule(),
              Padding(
                padding: AppSpacing.pagePadding,
                child: _AboutSection(onLicenses: () => _openLicenses(context)),
              ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: AppSpacing.pagePadding,
                child: Text(
                  '${AppInfo.appName} · ${AppInfo.appNameLatin}　本地优先，离线可用',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: AppInfo.appName,
      applicationVersion: AppInfo.version,
      applicationLegalese: '© 2026 ${AppInfo.appNameLatin}',
    );
  }
}

/// 页首题头。
class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '偏好 · PREFERENCES',
            style: text.labelSmall?.copyWith(
              color: scheme.primary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            header: true,
            child: Text('系统偏好', style: text.headlineMedium),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '外观与关于，都收在这一页；书库根在「书库」里管理。',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 分组标题：眉题 + 标题 + 说明。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    this.description,
  });

  final String eyebrow;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          eyebrow,
          style: text.labelSmall?.copyWith(
            color: scheme.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(header: true, child: Text(title, style: text.titleLarge)),
        if (description != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            description!,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// 分组之间的发丝分隔线。
class _SectionRule extends StatelessWidget {
  const _SectionRule();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Divider(height: 1),
    );
  }
}

/// 外观：色盘、明暗与暗夜 OLED。
class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPreferences prefs = ref.watch(preferencesProvider);
    final AppPaletteId currentPaletteId = paletteIdFromName(prefs.paletteId);
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SectionHeader(
          eyebrow: '外观 · APPEARANCE',
          title: '外观',
          description: '色盘、明暗与暗夜 OLED，改完立刻生效并记住。',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('明暗模式', style: text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<BrightnessPreference>(
                    segments: <ButtonSegment<BrightnessPreference>>[
                      ButtonSegment<BrightnessPreference>(
                        value: BrightnessPreference.system,
                        label: Text(
                          '跟随系统',
                          key: SettingsPage.brightnessKey(
                            BrightnessPreference.system,
                          ),
                        ),
                        icon: const Icon(Icons.brightness_auto_rounded),
                      ),
                      ButtonSegment<BrightnessPreference>(
                        value: BrightnessPreference.light,
                        label: Text(
                          '浅色',
                          key: SettingsPage.brightnessKey(
                            BrightnessPreference.light,
                          ),
                        ),
                        icon: const Icon(Icons.light_mode_rounded),
                      ),
                      ButtonSegment<BrightnessPreference>(
                        value: BrightnessPreference.dark,
                        label: Text(
                          '深色',
                          key: SettingsPage.brightnessKey(
                            BrightnessPreference.dark,
                          ),
                        ),
                        icon: const Icon(Icons.dark_mode_rounded),
                      ),
                    ],
                    selected: <BrightnessPreference>{prefs.brightness},
                    onSelectionChanged: (Set<BrightnessPreference> selection) {
                      ref
                          .read(preferencesProvider.notifier)
                          .update((s) => s.copyWith(brightness: selection.first));
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.lg),
                Text('国风色盘', style: text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.spaceAround,
                  children: AppColorPalettes.all.map((AppPalette palette) {
                    final bool isSelected = palette.id == currentPaletteId;
                    return _PaletteOption(
                      palette: palette,
                      isSelected: isSelected,
                      onTap: () {
                        ref
                            .read(preferencesProvider.notifier)
                            .update((s) => s.copyWith(paletteId: palette.id.name));
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.xs),
                SwitchListTile(
                  key: SettingsPage.oledSwitchKey,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('暗夜 OLED 纯黑'),
                  subtitle: const Text('仅深色模式生效，背景降为纯黑节省功耗'),
                  value: prefs.oledDark,
                  onChanged: prefs.brightness == BrightnessPreference.light
                      ? null
                      : (bool val) {
                          ref
                              .read(preferencesProvider.notifier)
                              .update((s) => s.copyWith(oledDark: val));
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 单个国风色盘选项卡。
class _PaletteOption extends StatelessWidget {
  const _PaletteOption({
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final AppPaletteColors lightColors = palette.light;

    return Semantics(
      selected: isSelected,
      label: palette.label,
      button: true,
      child: InkWell(
        key: SettingsPage.appearancePaletteKey(palette.id),
        borderRadius: AppRadii.sm,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSizes.minTouchTarget,
            minHeight: AppSizes.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lightColors.primaryContainer,
                    border: Border.all(
                      color: isSelected ? scheme.primary : lightColors.primary,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: lightColors.onPrimaryContainer,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  palette.label,
                  style: text.labelMedium?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? scheme.primary : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 关于：版本、开源许可、检查更新。
class _AboutSection extends ConsumerWidget {
  const _AboutSection({required this.onLicenses});

  final VoidCallback onLicenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final AppPreferences prefs = ref.watch(preferencesProvider);
    final UpdateState updateState = ref.watch(updateControllerProvider);
    final release = updateState.release;

    final (String updateSubtitle, Widget updateTrailing) = switch (updateState.status) {
      UpdateStatus.checking => (
          '正在检查新版本…',
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      UpdateStatus.available => (
          '发现新版本 ${release?.tag ?? ''}',
          const _Tag(label: '可更新'),
        ),
      UpdateStatus.upToDate => (
          '当前已是最新版本',
          const _Tag(label: '最新'),
        ),
      UpdateStatus.skipped => (
          '已跳过版本 ${release?.tag ?? prefs.skippedVersion ?? ''}',
          const _Tag(label: '已跳过'),
        ),
      UpdateStatus.noRelease => (
          '暂无可用版本',
          const _Tag(label: '暂无'),
        ),
      UpdateStatus.failure => (
          '检查失败，点击重试或查看',
          const _Tag(label: '失败'),
        ),
      _ => (
          '点击检查新版本',
          const _Tag(label: '检查'),
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SectionHeader(
          eyebrow: '关于 · ABOUT',
          title: '关于',
          description:
              '${AppInfo.appName}（${AppInfo.appNameLatin}）只在本机整理与播放你的有声书。',
        ),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                key: SettingsPage.autoCheckSwitchKey,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xxs,
                ),
                title: const Text('自动检查更新'),
                subtitle: const Text('每天最多一次，只读取版本信息'),
                value: prefs.autoCheckUpdates,
                onChanged: (bool val) {
                  ref
                      .read(updateControllerProvider.notifier)
                      .setAutoCheck(val);
                },
              ),
              const Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),
              _SettingsRow(
                key: SettingsPage.checkUpdateKey,
                icon: Icons.system_update_alt_rounded,
                title: '检查更新',
                subtitle: updateSubtitle,
                trailing: updateTrailing,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const UpdatePage(),
                    ),
                  );
                  unawaited(
                    ref
                        .read(updateControllerProvider.notifier)
                        .check(manual: true),
                  );
                },
              ),
              const Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),
              _SettingsRow(
                key: SettingsPage.updateHistoryKey,
                icon: Icons.history_rounded,
                title: '更新历史',
                subtitle: '逐版本查看更新内容',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const UpdateHistoryPage(),
                  ),
                ),
              ),
              const Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),
              _SettingsRow(
                icon: Icons.tag_rounded,
                title: '版本',
                subtitle: '发布通道 · ${AppInfo.channel.label}',
                trailing: Text(
                  AppInfo.version,
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),
              _SettingsRow(
                key: SettingsPage.licensesKey,
                icon: Icons.article_outlined,
                title: '开源许可',
                subtitle: '查看第三方依赖与许可原文',
                onTap: onLicenses,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 关于区的一行：图标 + 标题 + 说明 + 尾部内容。
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSizes.minTouchTarget + AppSpacing.sm,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: enabled ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(title, style: text.titleSmall),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
              if (enabled) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 小标签：只读 / 未配置。
class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadii.pill,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
