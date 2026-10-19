import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/cover_art.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/playback_providers.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/app_tabs.dart';
import 'package:tometone/ui/pages/player/player_page.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'package:tometone/ui/widgets/book_cover.dart';

/// 书架（《架构需求文档》§2.1）。
///
/// 职责边界（方案 A）：书架只负责「看与听」，内容来源在「书库」tab 里管理。
///
/// 布局：
/// - 页首是藏馆题头与藏书数量（进入页面先知道"有多少"）；
/// - 手机纵屏 2 列，`>=600dp` 3 列、`>=960dp` 4 列；
/// - 每一项从上到下是封面 → 书名（最多两行）→ 进度 / 未听 → 缺失提示。
///
/// 三态都直接来自 [booksProvider]：加载中不假装有内容，空态一句话指向
/// 「书库」并给出直达按钮，错误态提供重试（`ref.invalidate`）。
class ShelfPage extends ConsumerWidget {
  /// 创建书架。
  const ShelfPage({super.key});

  /// 加载态。
  static const Key loadingKey = Key('shelf-loading');

  /// 空态。
  static const Key emptyKey = Key('shelf-empty');

  /// 错误态。
  static const Key errorKey = Key('shelf-error');

  /// 错误态重试按钮。
  static const Key retryKey = Key('shelf-retry');

  /// 书籍网格。
  static const Key gridKey = Key('shelf-grid');

  /// 空态里「去书库添加目录」的引导按钮。
  static const Key goToLibraryKey = Key('shelf-open-library');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BookSummary>> booksAsync = ref.watch(booksProvider);
    final AsyncValue<List<LibraryRootView>> rootsAsync = ref.watch(
      libraryRootsProvider,
    );
    final bool failed = booksAsync.hasError || rootsAsync.hasError;
    final bool loading =
        !failed &&
        (booksAsync.isLoading ||
            rootsAsync.isLoading ||
            booksAsync.value == null ||
            rootsAsync.value == null);

    final List<BookSummary> books = booksAsync.value ?? const <BookSummary>[];
    final List<LibraryRootView> roots =
        rootsAsync.value ?? const <LibraryRootView>[];
    final Map<String, String> rootUriById = <String, String>{
      for (final LibraryRootView root in roots) root.id: root.uri,
    };

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final int columns = width >= 960
            ? 4
            : width >= AppSizes.wideBreakpoint
            ? 3
            : 2;
        final double tileWidth =
            (width - AppSpacing.lg * 2 - AppSpacing.md * (columns - 1)) /
            columns;
        final double textScale = MediaQuery.textScalerOf(context).scale(1);
        final double textBlock = 92 * (textScale < 1 ? 1 : textScale);
        final SliverGridDelegate delegate =
            SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: AppSpacing.xl,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: tileWidth / (tileWidth + textBlock),
            );

        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: _ShelfHeader(
                countLabel: failed
                    ? '读取失败'
                    : loading
                    ? '正在读取…'
                    : '${books.length} 册',
              ),
            ),
            if (failed)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ShelfError(
                  onRetry: () {
                    ref.invalidate(booksProvider);
                    ref.invalidate(libraryRootsProvider);
                  },
                ),
              )
            else if (loading) ...<Widget>[
              const SliverToBoxAdapter(child: _ShelfLoadingLine()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverGrid.builder(
                  key: ShelfPage.loadingKey,
                  gridDelegate: delegate,
                  itemCount: columns * 3,
                  itemBuilder: (BuildContext context, int index) {
                    return const _ShelfSkeletonTile();
                  },
                ),
              ),
            ] else if (books.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ShelfEmpty(
                  onOpenLibrary: () {
                    ref.read(appTabProvider.notifier).select(AppTab.library);
                  },
                  onRefresh: () {
                    ref.invalidate(booksProvider);
                    ref.invalidate(libraryRootsProvider);
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverGrid.builder(
                  key: ShelfPage.gridKey,
                  gridDelegate: delegate,
                  itemCount: books.length,
                  itemBuilder: (BuildContext context, int index) {
                    final BookSummary book = books[index];
                    return _ShelfTile(
                      book: book,
                      onTap: () => unawaited(
                        _openBook(
                          context,
                          ref,
                          book,
                          rootUriById[book.libraryRootId],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openBook(
    BuildContext context,
    WidgetRef ref,
    BookSummary book,
    String? rootUri,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    // 根缺失（或根还没加载出来）：走可区分的「根已移除」文案。
    final resolver = ref.read(
      mediaSourceResolverForRootProvider(book.libraryRootId),
    );
    if (rootUri == null || rootUri.isEmpty || resolver == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('找不到这本书的书库根目录，可能已被移除')),
      );
      return;
    }

    final BookDetail? detail = await ref.read(
      bookDetailProvider(book.id).future,
    );
    if (detail == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('《${book.title}》的书目信息不完整，无法打开')),
      );
      return;
    }

    final OpenBookResult result = await openBook(
      controller: ref.read(playbackControllerProvider),
      currentBook: ref.read(currentBookProvider.notifier),
      resolver: resolver,
      detail: detail,
    );

    switch (result.status) {
      case OpenBookStatus.failed:
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? '打不开《${book.title}》，请稍后再试')),
        );
      case OpenBookStatus.alreadyOpen:
      case OpenBookStatus.opened:
        if (!context.mounted) {
          return;
        }
        await showPlayerPage(context);
    }
  }
}

/// 藏馆题头：眉题 + 标题 + 册数 + 一句说明。
class _ShelfHeader extends StatelessWidget {
  const _ShelfHeader({required this.countLabel});

  final String countLabel;

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
            '藏馆 · THE VAULT',
            style: text.labelSmall?.copyWith(
              color: scheme.primary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('书卷藏馆', style: text.headlineMedium),
                ),
              ),
              Text(
                countLabel,
                style: text.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '点开一本，从上次停下的地方继续听。',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 加载态的一行说明 + 环形进度。
class _ShelfLoadingLine extends StatelessWidget {
  const _ShelfLoadingLine();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: <Widget>[
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '正在整理书架…',
            style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 加载骨架：封面方块 + 两条文字占位。
class _ShelfSkeletonTile extends StatelessWidget {
  const _ShelfSkeletonTile();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    Widget bar(double widthFactor, double height) {
      return FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: AppRadii.xs,
          ),
          child: SizedBox(height: height),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: AppRadii.cover,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        bar(0.82, 12),
        const SizedBox(height: AppSpacing.xs),
        bar(0.48, 10),
      ],
    );
  }
}

/// 空态：不假装能扫描，一句话指向「书库」，并给一个直达按钮。
class _ShelfEmpty extends StatelessWidget {
  const _ShelfEmpty({required this.onOpenLibrary, required this.onRefresh});

  /// 跳到「书库」tab（通过外壳级 provider，不依赖 AppShell 实例）。
  final VoidCallback onOpenLibrary;

  /// 重新读取书架。
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
          child: Column(
            key: ShelfPage.emptyKey,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: AppRadii.xl,
                ),
                child: SizedBox.square(
                  dimension: 64,
                  child: Icon(
                    Icons.auto_stories_outlined,
                    size: 30,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('还没有书库', style: text.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '书架还空着：去「书库」添加一个目录，扫描完成后书目就会出现在这里。',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                key: ShelfPage.goToLibraryKey,
                onPressed: onOpenLibrary,
                icon: const Icon(Icons.folder_special_outlined, size: 18),
                label: const Text('去「书库」添加目录'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('重新读取书架'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 错误态：说明 + 重试。
class _ShelfError extends StatelessWidget {
  const _ShelfError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        child: Column(
          key: ShelfPage.errorKey,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: AppRadii.xl,
              ),
              child: SizedBox.square(
                dimension: 64,
                child: Icon(
                  Icons.folder_off_outlined,
                  size: 30,
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('书架读取失败', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '书库数据暂时读不出来，可能是数据库还没准备好。稍后再试一次。',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              key: ShelfPage.retryKey,
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 一本书的网格项。
class _ShelfTile extends ConsumerWidget {
  const _ShelfTile({required this.book, required this.onTap});

  final BookSummary book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String meta = _progressLabel(book);
    final CoverArt? coverArt = ref
        .watch(
          coverArtProvider(
            CoverArtKey(rootId: book.libraryRootId, coverPath: book.coverPath),
          ),
        )
        .value;
    final String missing = book.missingChapters > 0
        ? '${book.missingChapters} 章缺失'
        : '';
    final String semanticsLabel = <String>[
      '《${book.title}》',
      if (book.author != null && book.author!.trim().isNotEmpty)
        book.author!.trim(),
      meta,
      if (missing.isNotEmpty) missing,
    ].join('，');

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return BookCover(
                      title: book.title,
                      size: constraints.maxWidth,
                      coverPath: coverArt is CoverArtFile
                          ? coverArt.absolutePath
                          : null,
                      coverImage: coverArt is CoverArtBytes
                          ? MemoryImage(coverArt.bytes)
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(height: 1.35),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (missing.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.link_off_rounded,
                        size: 12,
                        color: scheme.tertiary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          missing,
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

  static String _progressLabel(BookSummary book) {
    if (book.hasProgress) {
      final String? chapter = book.progressChapterTitle?.trim();
      if (chapter == null || chapter.isEmpty) {
        return '在听 · 继续收听';
      }
      return '在听 · $chapter';
    }
    final Duration total = book.totalDuration;
    if (total > Duration.zero) {
      return '未听 · ${_formatSpan(total)}';
    }
    return '未听';
  }

  static String _formatSpan(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return minutes > 0 ? '$hours 小时 $minutes 分' : '$hours 小时';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} 分钟';
    }
    return '不足 1 分钟';
  }
}
