import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/cover_art.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/metadata_providers.dart';
import 'package:tometone/app/providers/online_providers.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/ui/pages/shelf/add_to_shelf_sheet.dart';
import 'package:tometone/ui/pages/shelf/book_metadata_sheet.dart';
import 'package:tometone/ui/pages/shelf/chapter_list_sheet.dart';
import 'package:tometone/ui/pages/shelf/open_book_action.dart';
import 'package:tometone/ui/pages/shelf/shelf_progress.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'package:tometone/ui/widgets/book_cover.dart';
import 'package:tometone/ui/widgets/network_cover.dart';

/// 详情页的稳定测试键。
abstract final class BookDetailKeys {
  static const Key addShelfKey = Key('book-detail-add-shelf');
  static const Key removeShelfKey = Key('book-detail-remove-shelf');
  static const Key listenKey = Key('book-detail-listen');
}

/// 详情页的起播动作；测试可注入假实现。
typedef BookOpenAction = Future<void> Function(
  BookDetail detail,
  String? startChapterId,
);

/// 书籍详情页（§2.1）：完整元数据、标签、简介、章节目录 / 卷册入口。
class BookDetailPage extends ConsumerWidget {
  /// 创建详情页。
  const BookDetailPage({required this.bookId, this.onOpen, super.key});

  /// 书 ID。
  final String bookId;

  /// 起播动作；为空时走真实的 `openBookAndShowPlayer`。
  final BookOpenAction? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<BookDetail?> detailAsync = ref.watch(
      bookDetailProvider(bookId),
    );
    final AsyncValue<List<LibraryRootView>> rootsAsync = ref.watch(
      libraryRootsProvider,
    );
    final BookDetail? detail = detailAsync.value;
    final String? rootUri = detail == null
        ? null
        : _rootUriFor(rootsAsync.value, detail.summary.libraryRootId);
    final bool online = detail?.summary.isOnline ?? false;
    final BookSource? source = online && detail?.summary.sourceId != null
        ? ref.watch(bookSourceByIdProvider(detail!.summary.sourceId!)).value
        : null;

    final BookOpenAction open =
        onOpen ??
        (BookDetail value, String? chapterId) => openBookAndShowPlayer(
          context: context,
          ref: ref,
          detail: value,
          startChapterId: chapterId,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('书籍详情'),
        actions: detail == null
            ? null
            : <Widget>[
                PopupMenuButton<String>(
                  tooltip: '更多',
                  onSelected: (String value) {
                    switch (value) {
                      case 'edit':
                        unawaited(_edit(context, ref, detail, rootUri, online));
                      case 'reimport':
                        if (!online) {
                          unawaited(_reimport(context, ref, detail, rootUri));
                        }
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('编辑元数据'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (!online)
                          const PopupMenuItem<String>(
                            value: 'reimport',
                            child: ListTile(
                              leading: Icon(Icons.file_download_outlined),
                              title: Text('从书根重新导入'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                ),
              ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => _DetailError(
          onRetry: () => ref.invalidate(bookDetailProvider(bookId)),
        ),
        data: (BookDetail? value) {
          if (value == null) {
            return const _DetailMissing();
          }
          return _BookDetailBody(
            detail: value,
            source: source,
            onOpen: open,
            onEdit: () => unawaited(
              _edit(context, ref, value, rootUri, value.summary.isOnline),
            ),
            onAddShelf: value.summary.isOnline
                ? () => unawaited(_addToShelf(context, ref, value))
                : null,
            onRemoveShelf: value.summary.isOnline
                ? () => unawaited(_removeFromShelf(context, ref, value))
                : null,
          );
        },
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    BookDetail detail,
    String? rootUri,
    bool online,
  ) async {
    if (!online && (rootUri == null || rootUri.isEmpty)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('书库根已移除，暂时不能编辑元数据')));
      return;
    }
    final BookSummary summary = detail.summary;
    final bool? saved = await showBookMetadataSheet(
      context,
      book: summary,
      rootUri: rootUri,
      online: online,
      initial: BookMetadataDraft(
        title: summary.title,
        author: summary.author,
        narrator: summary.narrator,
        seriesName: summary.seriesName,
        seriesIndex: summary.seriesIndex,
        description: summary.description,
        tags: summary.tags,
      ),
    );
    if (saved == true) {
      ref.invalidate(bookDetailProvider(bookId));
      ref.invalidate(booksProvider);
    }
  }

  Future<void> _addToShelf(
    BuildContext context,
    WidgetRef ref,
    BookDetail detail,
  ) async {
    final Set<String>? tags = await showAddToShelfSheet(
      context,
      bookTitle: detail.summary.title,
      initialTags: detail.summary.tags.toSet(),
    );
    if (!context.mounted || tags == null) {
      return;
    }
    try {
      await ref
          .read(onlineLibraryQueriesProvider)
          .setBookShelf(detail.summary.id, onShelf: true, tags: tags.toList());
      ref.invalidate(bookDetailProvider(detail.summary.id));
      ref.invalidate(booksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已加入书架')));
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('加入书架失败，请稍后再试')));
      }
    }
  }

  Future<void> _removeFromShelf(
    BuildContext context,
    WidgetRef ref,
    BookDetail detail,
  ) async {
    try {
      await ref
          .read(onlineLibraryQueriesProvider)
          .setBookShelf(detail.summary.id, onShelf: false);
      ref.invalidate(bookDetailProvider(detail.summary.id));
      ref.invalidate(booksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已移出书架，书目仍保留在书库')));
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('移出书架失败，请稍后再试')));
      }
    }
  }

  Future<void> _reimport(
    BuildContext context,
    WidgetRef ref,
    BookDetail detail,
    String? rootUri,
  ) async {
    if (rootUri == null || rootUri.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('书库根已移除，暂时不能从书根导入')));
      return;
    }
    final BookSummary summary = detail.summary;
    if (summary.metadataEdited) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('从书根重新导入？'),
          content: const Text(
            '会用书根 tometone.meta.json 中实际出现的字段覆盖当前元数据；'
            '文件里没有的字段会保留手填值。',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('导入'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }

    try {
      final BookMetadataDraft? imported = await ref
          .read(bookMetadataServiceProvider)
          .importFromBookRoot(
            book: summary,
            rootUri: rootUri,
            overwriteManual: summary.metadataEdited,
          );
      if (!context.mounted) {
        return;
      }
      if (imported == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('书根没有可导入的 tometone.meta.json')),
        );
        return;
      }
      ref.invalidate(bookDetailProvider(bookId));
      ref.invalidate(booksProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已从书根导入元数据')));
    } on Object {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('导入失败，请稍后再试')));
    }
  }

  static String? _rootUriFor(List<LibraryRootView>? roots, String rootId) {
    if (roots == null) {
      return null;
    }
    for (final LibraryRootView root in roots) {
      if (root.id == rootId) {
        return root.uri;
      }
    }
    return null;
  }
}

class _BookDetailBody extends ConsumerWidget {
  const _BookDetailBody({
    required this.detail,
    required this.source,
    required this.onOpen,
    required this.onEdit,
    this.onAddShelf,
    this.onRemoveShelf,
  });

  final BookDetail detail;
  final BookSource? source;
  final BookOpenAction onOpen;
  final VoidCallback onEdit;
  final VoidCallback? onAddShelf;
  final VoidCallback? onRemoveShelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BookSummary book = detail.summary;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final CoverArt? coverArt = ref
        .watch(
          coverArtProvider(
            CoverArtKey(rootId: book.libraryRootId, coverPath: book.coverPath),
          ),
        )
        .value;
    final String description = (book.description ?? '').trim();
    final String? progressTitle = book.progressChapterTitle;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: AppRadii.cover,
                    child: book.isOnline
                        ? NetworkCover(
                            coverUrl: book.coverUrl,
                            size: 124,
                            headers: source?.header,
                            borderRadius: AppRadii.cover,
                          )
                        : BookCover(
                            title: book.title,
                            size: 124,
                            coverPath: coverArt is CoverArtFile
                                ? coverArt.absolutePath
                                : null,
                            coverImage: coverArt is CoverArtBytes
                                ? MemoryImage(coverArt.bytes)
                                : null,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (book.seriesName != null &&
                            book.seriesName!.trim().isNotEmpty) ...<Widget>[
                          Text(
                            book.seriesIndex == null
                                ? book.seriesName!.trim()
                                : '${book.seriesName!.trim()} · 第 ${book.seriesIndex} 卷',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelMedium?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        Text(
                          book.title,
                          style: text.headlineSmall?.copyWith(height: 1.25),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _byline(book),
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  _StatusPill(book: book),
                  if (book.isOnline)
                    _MetaPill(
                      icon: Icons.cloud_outlined,
                      label: _sourceState(book),
                    ),
                  _MetaPill(
                    icon: Icons.menu_book_outlined,
                    label:
                        '第 ${(book.progressChapterIndex ?? 0) + 1} / ${book.totalChapters} 章',
                  ),
                  if (book.missingChapters > 0)
                    _MetaPill(
                      icon: Icons.link_off_rounded,
                      label: '${book.missingChapters} 章缺失',
                    ),
                ],
              ),
              if (book.tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    for (final String tag in book.tags)
                      Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: '简介',
                trailing: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('编辑'),
                ),
                child: Text(
                  description.isEmpty ? '暂无简介' : description,
                  style: text.bodyMedium?.copyWith(
                    height: 1.6,
                    color: description.isEmpty ? scheme.onSurfaceVariant : null,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _EntryCard(
                      icon: Icons.list_alt_rounded,
                      title: '章节目录',
                      value:
                          '第 ${(book.progressChapterIndex ?? 0) + 1} / ${book.totalChapters} 章',
                      onTap: () => _openChapters(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _EntryCard(
                      icon: Icons.library_books_outlined,
                      title: '卷册',
                      value: '${detail.volumes.length} 卷',
                      onTap: () => _openChapters(context),
                    ),
                  ),
                ],
              ),
              if (book.hasProgress) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: '收听进度',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ShelfProgress(book: book),
                      if (progressTitle != null &&
                          progressTitle.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '上次听到：$progressTitle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                '共 ${book.totalChapters} 章 · ${_formatDuration(book.totalDurationMs)}',
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: book.isOnline
                ? Row(
                    children: <Widget>[
                      if (!book.onShelf) ...<Widget>[
                        Expanded(
                          child: OutlinedButton(
                            key: BookDetailKeys.addShelfKey,
                            onPressed: onAddShelf,
                            child: const Text('加入书架'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: FilledButton(
                          key: BookDetailKeys.listenKey,
                          onPressed: () => _start(context),
                          child: Text(
                            book.onShelf
                                ? (book.hasProgress ? '继续收听' : '开始收听')
                                : '立即收听',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (book.onShelf) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton(
                            key: BookDetailKeys.removeShelfKey,
                            onPressed: onRemoveShelf,
                            child: const Text('移出书架'),
                          ),
                        ),
                      ],
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _start(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            book.isFinished
                                ? Icons.replay_rounded
                                : book.hasProgress
                                ? Icons.play_arrow_rounded
                                : Icons.headphones_rounded,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              _primaryLabel(book),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  static String _sourceState(BookSummary book) {
    if (book.sourceDeleted == true) {
      return '来源已删除';
    }
    if (book.sourceEnabled == false) {
      return '来源已停用';
    }
    return '来源正常';
  }

  void _openChapters(BuildContext context) {
    showChapterListSheet(
      context,
      detail: detail,
      currentChapterId: detail.summary.progressChapterId,
      onChapterSelected: (ChapterView chapter) {
        unawaited(onOpen(detail, chapter.id));
      },
    );
  }

  void _start(BuildContext context) {
    if (detail.summary.isFinished && detail.chapters.isNotEmpty) {
      unawaited(onOpen(detail, detail.chapters.first.id));
      return;
    }
    unawaited(onOpen(detail, null));
  }

  static String _primaryLabel(BookSummary book) {
    if (book.isFinished) {
      return '重新收听';
    }
    if (book.hasProgress) {
      final int chapter = (book.progressChapterIndex ?? 0) + 1;
      return '从第 $chapter 章继续收听';
    }
    return '开始收听';
  }

  static String _byline(BookSummary book) {
    final List<String> parts = <String>[];
    final String? author = book.author?.trim();
    final String? narrator = book.narrator?.trim();
    if (author != null && author.isNotEmpty) {
      parts.add('$author 著');
    }
    if (narrator != null && narrator.isNotEmpty) {
      parts.add('$narrator 演播');
    }
    return parts.isEmpty ? '作者 / 演播待补充' : parts.join(' · ');
  }

  static String _formatDuration(int milliseconds) {
    final Duration duration = Duration(milliseconds: milliseconds);
    final int minutes = duration.inMinutes;
    if (minutes < 60) {
      return '$minutes 分钟';
    }
    final int hours = minutes ~/ 60;
    final int rest = minutes % 60;
    return rest == 0 ? '$hours 小时' : '$hours 小时 $rest 分';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.book});

  final BookSummary book;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String label = book.isFinished
        ? '已完'
        : book.hasProgress
        ? '在听'
        : '未听';
    return _MetaPill(
      icon: book.isFinished
          ? Icons.check_circle_rounded
          : book.hasProgress
          ? Icons.graphic_eq_rounded
          : Icons.circle_outlined,
      label: label,
      color: book.isFinished ? scheme.primary : null,
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color foreground = color ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: AppRadii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadii.md,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(title, style: text.titleSmall)),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: scheme.surface,
      borderRadius: AppRadii.md,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.md,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: text.labelLarge),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('书籍详情读取失败'),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _DetailMissing extends StatelessWidget {
  const _DetailMissing();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('这本书已经不在书架里了'));
  }
}
