import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// Markdown 正文渲染组件。
///
/// 深度适配项目主题色盘与排版规范，内部基于 [MarkdownBody] 渲染，
/// 支持超链接唤起外部浏览器或自定义点击回调。
class MarkdownBodyView extends StatelessWidget {
  /// 创建 Markdown 正文组件。
  const MarkdownBodyView({
    required this.data,
    this.selectable = false,
    this.onTapLink,
    super.key,
  });

  /// Markdown 源码文本。
  final String data;

  /// 是否允许文本选取。
  final bool selectable;

  /// 自定义链接点击回调；若未提供则默认尝试调用 [launchUrl] 外部唤起。
  final void Function(String text, String? href, String title)? onTapLink;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    final MarkdownStyleSheet baseStyle = MarkdownStyleSheet.fromTheme(theme);
    final MarkdownStyleSheet customStyle = baseStyle.copyWith(
      p: textTheme.bodyMedium?.copyWith(
        color: scheme.onSurface,
        height: 1.6,
      ),
      h1: textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h2: textTheme.titleMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h3: textTheme.titleSmall?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      a: TextStyle(
        color: scheme.primary,
        decoration: TextDecoration.underline,
      ),
      code: TextStyle(
        color: scheme.onSurfaceVariant,
        backgroundColor: scheme.surfaceContainerHighest,
        fontSize: textTheme.bodySmall?.fontSize,
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadii.sm,
      ),
      blockquoteDecoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadii.xs,
        border: Border(
          left: BorderSide(
            color: scheme.primary,
            width: 3,
          ),
        ),
      ),
      listBullet: textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );

    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: customStyle,
      onTapLink: (String text, String? href, String title) {
        if (onTapLink != null) {
          onTapLink!(text, href, title);
          return;
        }
        if (href != null && href.isNotEmpty) {
          final uri = Uri.tryParse(href);
          if (uri != null) {
            unawaited(
              launchUrl(uri, mode: LaunchMode.externalApplication).catchError(
                (_) => false,
              ),
            );
          }
        }
      },
    );
  }
}
