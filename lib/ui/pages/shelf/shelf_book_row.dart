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

/// 书架列表行（单列信息卡）。
///
/// 一行一本书：封面只做识别，正文让给书名、作者·演播、两行简介与标签；
/// 右侧是播放按钮，点击直接起播。点行主体触发 [onOpen]（进详情）。
class ShelfBookRow extends ConsumerWidget {
  /// 创建列表行。
  const ShelfBookRow({
    required this.book,
    required this.onOpen,
    required this.onPlay,
    this.onLongPress,
    super.key,
  });

  /// 播放按钮的稳定定位键（`shelf-play-<书ID>`）。
  static Key playKeyOf(String bookId) => Key('shelf-play-$bookId');

  /// 所属书。
  final BookSummary book;

  /// 点行主体（进详情）。
  final VoidCallback onOpen;

  /// 点播放按钮（直接起播）。
  final VoidCallback onPlay;

  /// 长按行主体。
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final CoverArt? coverArt = ref
        .watch(
          coverArtProvider(
            CoverArtKey(rootId: book.libraryRootId, coverPath: book.coverPath),
          ),
        )
        .value;

    final BookSource? source = book.isOnline && book.sourceId != null
        ? ref.watch(bookSourceByIdProvider(book.sourceId!)).value
        : null;
    final String meta = _byline(book);
    final String description = (book.description ?? '').trim();
    final String sourceState = book.sourceDeleted == true
        ? '来源已删除'
        : book.sourceEnabled == false
        ? '来源已停用'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadii.md,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onOpen,
        onLongPress: onLongPress,
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description.isEmpty ? '暂无简介' : description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    if (book.tags.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      _TagChips(tags: book.tags),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    ShelfProgress(book: book),
                    if (sourceState.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        sourceState,
                        style: text.labelSmall?.copyWith(
                          color: scheme.tertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _PlayButton(
                key: playKeyOf(book.id),
                onPlay: onPlay,
                diameter: 44,
              ),
            ],
          ),
        ),
      ),
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

/// 标签 chips（列表行内）。
class _TagChips extends StatelessWidget {
  const _TagChips({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        for (final String tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: AppRadii.xs,
            ),
            child: Text(
              tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
      ],
    );
  }
}

/// 圆形播放按钮。
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onPlay, required this.diameter, super.key});

  final VoidCallback onPlay;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: scheme.shadow,
      child: InkWell(
        onTap: onPlay,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: diameter,
          child: Icon(
            Icons.play_arrow_rounded,
            size: diameter * 0.62,
            color: scheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
