import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/cover_art.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/ui/pages/shelf/shelf_progress.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'package:tometone/ui/widgets/book_cover.dart';
import 'package:tometone/ui/widgets/network_cover.dart';

/// 书库统一书目列表行。
class LibraryBookRow extends ConsumerWidget {
  const LibraryBookRow({
    required this.book,
    required this.onTap,
    super.key,
  });

  final BookSummary book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    final CoverArt? coverArt = !book.isOnline
        ? ref
              .watch(
                coverArtProvider(
                  CoverArtKey(
                    rootId: book.libraryRootId,
                    coverPath: book.coverPath,
                  ),
                ),
              )
              .value
        : null;

    final BookSource? source = book.isOnline && book.sourceId != null
        ? ref.watch(bookSourceByIdProvider(book.sourceId!)).value
        : null;

    final String meta = _byline(book);
    final String description = (book.description ?? '').trim();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadii.md,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: AppRadii.cover,
                child: book.isOnline
                    ? NetworkCover(
                        coverUrl: book.coverUrl,
                        size: 64,
                        headers: source?.header,
                        borderRadius: AppRadii.cover,
                      )
                    : BookCover(
                        title: book.title,
                        size: 64,
                        coverPath: coverArt is CoverArtFile
                            ? coverArt.absolutePath
                            : null,
                        coverImage: coverArt is CoverArtBytes
                            ? MemoryImage(coverArt.bytes)
                            : null,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(height: 1.3),
                    ),
                    if (meta.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (description.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _buildBadges(context, scheme, text),
                    const SizedBox(height: AppSpacing.sm),
                    ShelfProgress(book: book),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadges(
    BuildContext context,
    ColorScheme scheme,
    TextTheme text,
  ) {
    final List<Widget> badges = <Widget>[];

    // 来源名称 badge
    if (book.isOnline) {
      final String? name = book.sourceName?.trim();
      if (name != null && name.isNotEmpty) {
        badges.add(
          _BadgeChip(
            label: name,
            color: scheme.secondaryContainer,
            textColor: scheme.onSecondaryContainer,
          ),
        );
      }
    } else {
      badges.add(
        _BadgeChip(
          label: '本机',
          color: scheme.surfaceContainerHighest,
          textColor: scheme.onSurfaceVariant,
        ),
      );
    }

    // 来源异常与缺失状态
    if (book.sourceDeleted == true) {
      badges.add(
        _BadgeChip(
          label: '来源已删除',
          color: scheme.errorContainer,
          textColor: scheme.onErrorContainer,
        ),
      );
    } else if (book.sourceEnabled == false) {
      badges.add(
        _BadgeChip(
          label: '来源已停用',
          color: scheme.errorContainer,
          textColor: scheme.onErrorContainer,
        ),
      );
    } else if (book.isOnline && book.totalChapters == 0) {
      badges.add(
        _BadgeChip(
          label: '目录待刷新',
          color: scheme.tertiaryContainer,
          textColor: scheme.onTertiaryContainer,
        ),
      );
    }

    if (book.missingChapters > 0) {
      badges.add(
        _BadgeChip(
          label: '缺失 ${book.missingChapters} 章',
          color: scheme.errorContainer,
          textColor: scheme.onErrorContainer,
        ),
      );
    }

    // 书籍标签
    for (final String tag in book.tags) {
      badges.add(
        _BadgeChip(
          label: tag,
          color: scheme.surfaceContainerHigh,
          textColor: scheme.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: badges,
    );
  }

  static String _byline(BookSummary book) {
    final String? author = book.author?.trim();
    final String? narrator = book.narrator?.trim();
    final List<String> parts = <String>[];
    if (author != null && author.isNotEmpty) {
      parts.add('$author 著');
    }
    if (narrator != null && narrator.isNotEmpty) {
      parts.add('$narrator 演播');
    }
    return parts.join(' · ');
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
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
        ),
      ),
    );
  }
}
