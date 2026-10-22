import 'package:flutter/material.dart';
import 'package:tometone/app/app_info.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'cache_settings_section.dart';

/// 设置页（《架构需求文档》§2.1 / §2.8 / §3.3）。
///
/// 信息层级（自上而下）：
/// 1. **外观** —— 本轮只读说明（色盘 / OLED 需要偏好持久化，不放假开关）；
/// 2. **关于** —— 版本、开源许可、检查更新（更新源未配置时如实说明）。
///
/// 方案 A：书库根已拆到独立的「书库」tab，设置页不再读写书库数据，
/// 只保留偏好与说明；页面也因此不再需要 provider 依赖。
class SettingsPage extends StatelessWidget {
  /// 创建设置页。
  const SettingsPage({super.key});

  /// 开源许可入口。
  static const Key licensesKey = Key('settings-licenses');

  /// 检查更新入口。
  static const Key checkUpdateKey = Key('settings-check-update');

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

/// 外观：本轮只读，不提供按下去却记不住的开关。
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SectionHeader(
          eyebrow: '外观 · APPEARANCE',
          title: '外观',
          description: '色盘与暗夜 OLED 需要记住你的选择，本轮暂未开放。',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.contrast_rounded,
                      size: 20,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text('跟随系统明暗', style: text.titleSmall)),
                    const _Tag(label: '只读'),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '当前按系统的浅色 / 深色自动切换。五套国风色盘与暗夜 OLED '
                  '需要偏好持久化，接通后会出现在这里。',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '琥珀旧卷 · 竹海幽青 · 星夜深蓝 · 暮紫沉香 · 山丹丹红',
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 关于：版本、开源许可、检查更新。
class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.onLicenses});

  final VoidCallback onLicenses;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool hasUpdateSource = AppInfo.hasUpdateSource;

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
              const Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),
              _SettingsRow(
                key: SettingsPage.checkUpdateKey,
                icon: Icons.system_update_alt_rounded,
                title: '检查更新',
                subtitle: hasUpdateSource
                    ? '更新源已配置，检查逻辑将在后续版本接入'
                    : '更新源未配置，暂时无法检查更新',
                trailing: _Tag(label: hasUpdateSource ? '待接入' : '未配置'),
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
