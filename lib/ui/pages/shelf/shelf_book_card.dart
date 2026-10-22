import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/cover_art.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'package:tometone/ui/widgets/book_cover.dart';
import 'package:tometone/ui/widgets/network_cover.dart';

/// 书架网格卡片（标准 2:3 书籍护封）。
///
/// 自上而下：2:3 护封（右下角播放按钮）→ 书名（可选）→ 作者·演播（可选）。
/// 默认隐藏进度条，保持封面纯粹；播放按钮独立于卡片主体，点卡片触发 [onOpen]，
/// 点播放按钮触发 [onPlay]，长按触发 [onLongPress]。
class ShelfBookCard extends ConsumerWidget {
  /// 创建网格卡片。
  const ShelfBookCard({
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

  /// 点卡片主体（进详情）。
  final VoidCallback onOpen;

  /// 点播放按钮（直接起播）。
  final VoidCallback onPlay;

  /// 长按卡片（呼出操作菜单）。
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final AppPreferences prefs = ref.watch(preferencesProvider);
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
    final String meta = _byline(
      book,
      showAuthor: prefs.shelfShowAuthor,
      showNarrator: prefs.shelfShowNarrator,
    );
    final String description = (book.description ?? '').trim();
    final String missing = book.missingChapters > 0
        ? '${book.missingChapters} 章缺失'
        : '';
    final String sourceState = book.sourceDeleted == true
        ? '来源已删除'
        : book.sourceEnabled == false
        ? '来源已停用'
        : '';
    final String warning = <String>[
      if (sourceState.isNotEmpty) sourceState,
      if (missing.isNotEmpty) missing,
    ].join(' · ');
    final String semanticsLabel = <String>[
      '《${book.title}》',
      if (meta.isNotEmpty) meta,
      if (description.isNotEmpty) description,
    ].join('，');

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onOpen,
          onLongPress: onLongPress,
          borderRadius: AppRadii.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 2 / 3,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        if (book.isOnline)
                          NetworkCover(
                            coverUrl: book.coverUrl,
                            size: constraints.maxWidth,
                            headers: source?.header,
                            borderRadius: AppRadii.cover,
                          )
                        else
                          BookCover(
                            title: book.title,
                            size: constraints.maxWidth,
                            coverPath: coverArt is CoverArtFile
                                ? coverArt.absolutePath
                                : null,
                            coverImage: coverArt is CoverArtBytes
                                ? MemoryImage(coverArt.bytes)
                                : null,
                          ),
                        Positioned(
                          right: AppSpacing.xs,
                          bottom: AppSpacing.xs,
                          child: _PlayButton(
                            key: playKeyOf(book.id),
                            onPlay: onPlay,
                            diameter: 36,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (prefs.shelfShowTitle) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(height: 1.35),
                ),
              ],
              if ((prefs.shelfShowAuthor || prefs.shelfShowNarrator) &&
                  meta.isNotEmpty) ...<Widget>[
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
              if (warning.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: scheme.tertiary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          warning,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            color: scheme.tertiary,
                          ),
                        ),
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

  static String _byline(
    BookSummary book, {
    bool showAuthor = true,
    bool showNarrator = true,
  }) {
    final String? author = book.author?.trim();
    final String? narrator = book.narrator?.trim();
    final List<String> parts = <String>[];
    if (showAuthor && author != null && author.isNotEmpty) {
      parts.add('$author 著');
    }
    if (showNarrator && narrator != null && narrator.isNotEmpty) {
      parts.add('$narrator 演播');
    }
    return parts.join(' · ');
  }
}

/// 圆形播放按钮（网格封面右下角 / 列表行右侧共用）。
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
