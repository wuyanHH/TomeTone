import 'package:flutter/material.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'package:tometone/ui/widgets/network_cover.dart';

/// 发现/搜索的一条结果；只读，不提供加入书架或播放入口。
class DiscoveryResultTile extends StatelessWidget {
  /// 创建发现结果行。
  const DiscoveryResultTile({
    super.key,
    required this.item,
    required this.sourceName,
    this.membership,
    required this.onTap,
  });

  /// 书目摘要。
  final SourceBookSummary item;

  /// 来源名，显示在结果行底部。
  final String sourceName;

  /// 在书架/书库中的状态（未命中为 null）。
  final OnlineBookStatus? membership;

  /// 打开只读预览。
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? people = _people(item);
    final String? details = _details(item);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              NetworkCover(coverUrl: item.coverUrl, size: 64),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (membership != null) ...<Widget>[
                          const SizedBox(width: AppSpacing.xs),
                          _MembershipChip(membership: membership!),
                        ],
                      ],
                    ),
                    if (people != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        people,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ],
                    if (details != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '来源 · $sourceName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(color: scheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _people(SourceBookSummary item) {
    final List<String> parts = <String>[];
    final String? author = item.author?.trim();
    final String? narrator = item.narrator?.trim();
    if (author != null && author.isNotEmpty) {
      parts.add('作者：$author');
    }
    if (narrator != null && narrator.isNotEmpty) {
      parts.add('演播：$narrator');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String? _details(SourceBookSummary item) {
    final List<String> parts = <String>[];
    final String? kind = item.kind?.trim();
    final String? wordCount = item.wordCount?.trim();
    if (kind != null && kind.isNotEmpty) {
      parts.add(kind);
    }
    if (wordCount != null && wordCount.isNotEmpty) {
      parts.add(wordCount);
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class _MembershipChip extends StatelessWidget {
  const _MembershipChip({required this.membership});

  final OnlineBookStatus membership;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool onShelf = membership.onShelf;
    final Color color = onShelf
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final Color textColor = onShelf
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    final String label = onShelf ? '已在书架' : '已在书库';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadii.sm,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          height: 1.2,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
