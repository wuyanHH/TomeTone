import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/app_info.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/app/providers/update_providers.dart';
import 'package:tometone/contracts/update/update_state.dart';
import 'package:tometone/ui/pages/settings/settings_page.dart';
import 'package:tometone/ui/pages/settings/update_history_page.dart';
import 'package:tometone/ui/pages/settings/update_page.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 关于与版本更新二级页面。
class AboutSettingsPage extends ConsumerWidget {
  const AboutSettingsPage({super.key});

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('关于与更新'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
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
                        onTap: () => _openLicenses(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  '${AppInfo.appName}（${AppInfo.appNameLatin}）只在本机整理与播放你的有声书。\n本地优先，离线可用',
                  textAlign: TextAlign.center,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _openLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: AppInfo.appName,
      applicationVersion: AppInfo.version,
      applicationLegalese: '© 2026 ${AppInfo.appNameLatin}',
    );
  }
}

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

    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(title, style: text.bodyLarge),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadii.xs,
      ),
      child: Text(
        label,
        style: text.labelSmall?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
