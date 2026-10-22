import 'package:flutter/material.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 设置页统一卡片容器 (SettingsSectionCard)。
///
/// 使用 Material 承载背景色与圆角边框，使内部 ListTile 的水波纹 (ink splash)
/// 能够正确绘制在卡片表面，且视觉层级与质感更统一。
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    required this.children,
    super.key,
    this.padding,
    this.margin,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    Widget content = Material(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.lg,
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }
    return content;
  }
}

/// 设置分节题头 (SettingsSectionHeader)。
///
/// 包含可选图标徽章、标题与说明文字，让设置项分组逻辑一目了然。
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Color accent = iconColor ?? scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: AppRadii.xs,
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 统一的图标容器徽章 (SettingsIconBadge)。
///
/// 给设置项前导图标提供优雅的淡色柔和背景衬底与轻微圆角。
class SettingsIconBadge extends StatelessWidget {
  const SettingsIconBadge({
    required this.icon,
    required this.color,
    super.key,
    this.size = 38,
    this.iconSize = 20,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.md,
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: color,
        ),
      ),
    );
  }
}

/// 统一的设置项微边分割线 (SettingsDivider)。
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({
    super.key,
    this.indent = AppSpacing.lg,
    this.endIndent = AppSpacing.lg,
  });

  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: endIndent,
      color: scheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}
