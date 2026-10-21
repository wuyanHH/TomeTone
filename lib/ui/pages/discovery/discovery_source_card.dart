import 'package:flutter/material.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 发现页顶部的当前书源卡：名称、分组、健康与最近同步。
class DiscoverySourceCard extends StatelessWidget {
  /// 创建当前书源卡。
  const DiscoverySourceCard({
    super.key,
    required this.source,
    required this.onSwitch,
    required this.onManage,
    this.switchKey,
    this.manageKey,
  });

  /// 当前选中的书源。
  final BookSource source;

  /// 打开切换书源弹层。
  final VoidCallback onSwitch;

  /// 打开书源管理页。
  final VoidCallback onManage;

  /// 「切换」按钮的测试键。
  final Key? switchKey;

  /// 「管理」按钮的测试键。
  final Key? manageKey;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool failed = source.lastTestOk == false;
    final String? lastSync = _formatLastSync(source.lastTestAt);
    final String health = _healthLabel(source);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              source.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (source.groupName != null && source.groupName!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(
                  source.groupName!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                _MetaTag(
                  text: health,
                  color: failed ? scheme.error : scheme.secondary,
                ),
                if (lastSync != null) _MetaTag(text: lastSync),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: AppSpacing.xs,
                children: <Widget>[
                  TextButton(
                    key: switchKey,
                    onPressed: onSwitch,
                    child: const Text('切换'),
                  ),
                  TextButton(
                    key: manageKey,
                    onPressed: onManage,
                    child: const Text('管理'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _healthLabel(BookSource source) {
    final bool? ok = source.lastTestOk;
    if (ok == null) {
      return '未测试';
    }
    if (ok) {
      return '正常';
    }
    return '连续失败 ${source.consecutiveFailures} 次';
  }

  static String? _formatLastSync(DateTime? value) {
    if (value == null) {
      return null;
    }
    final DateTime local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '最近同步 · ${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color foreground = color ?? scheme.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.xsValue),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: foreground),
        ),
      ),
    );
  }
}
