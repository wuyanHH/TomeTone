import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/cover_art.dart';
import 'package:tometone/app/library/online_book_service.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/metadata_providers.dart';
import 'package:tometone/app/providers/online_providers.dart';
import 'package:tometone/app/providers/source_engine_providers.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_failure.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/pages/library/safe_delete_book_dialog.dart';
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

/// 在线预览兼容测试键。
abstract final class OnlineBookPreviewKeys {
  static const Key loadingKey = Key('online-preview-loading');
  static const Key errorKey = Key('online-preview-error');
  static const Key retryKey = Key('online-preview-retry');
  static const Key titleKey = Key('online-preview-title');
  static const Key tocListKey = Key('online-preview-toc-list');
  static const Key partialTocKey = Key('online-preview-partial-toc');
  static const Key previewNoticeKey = Key('online-preview-notice');
  static const Key tocRetryKey = Key('online-preview-toc-retry');
  static const Key addToShelfKey = BookDetailKeys.addShelfKey;
  static const Key listenKey = BookDetailKeys.listenKey;

  static Key chapterKey(int index) =>
      ValueKey<String>('online-preview-chapter-$index');
}

/// 详情页的起播动作；测试可注入假实现。
typedef BookOpenAction = Future<void> Function(
  BookDetail detail,
  String? startChapterId,
);

/// 书籍详情与目录页（§2.1 / §3.3）：
///
/// 统一承接：
/// 1. 已入库书目（本地书或在线书）完整元数据、标签、简介与章节目录；
/// 2. 未持久化在线书预览：只读拉取书目信息与目录，保证零写入；支持一键加入书架或立即试听入库。
class BookDetailPage extends ConsumerStatefulWidget {
  /// 创建已持久化书籍的详情页。
  const BookDetailPage({required this.bookId, this.onOpen, super.key})
      : source = null,
        item = null;

  /// 创建未持久化在线书的预览详情页。
  const BookDetailPage.online({
    required this.source,
    required this.item,
    this.onOpen,
    super.key,
  }) : bookId = null;

  /// 书 ID（若已入库）。
  final String? bookId;

  /// 书源（在线预览模式使用）。
  final BookSource? source;

  /// 搜索或分类返回的书目条目（在线预览模式使用）。
  final SourceBookSummary? item;

  /// 起播动作；为空时走真实的 `openBookAndShowPlayer`。
  final BookOpenAction? onOpen;

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  String? _persistedBookId;

  // 在线未入库预览状态
  SourceBookInfo? _info;
  SourceToc? _toc;
  SourceFailure? _infoFailure;
  SourceFailure? _tocFailure;
  bool _loading = true;
  bool _loadingToc = false;
  bool _introExpanded = false;
  int _generation = 0;
  bool _busy = false;

  SourceBookSummary get _display => _info ?? widget.item!;

  @override
  void initState() {
    super.initState();
    _persistedBookId = widget.bookId;
    if (_persistedBookId == null && widget.source != null && widget.item != null) {
      unawaited(_loadOnlinePreview());
    }
  }

  Future<void> _loadOnlinePreview() async {
    final int generation = ++_generation;
    if (mounted) {
      setState(() {
        _loading = true;
        _loadingToc = false;
        _info = null;
        _toc = null;
        _infoFailure = null;
        _tocFailure = null;
        _introExpanded = false;
      });
    }

    SourceBookInfo info;
    try {
      info = await ref
          .read(sourceDiscoveryProvider)
          .bookInfo(widget.source!, widget.item!.bookUrl);
    } on SourceFailure catch (failure) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _infoFailure = failure;
      });
      return;
    } on Object {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _infoFailure = const SourceFailure(
          kind: SourceFailureKind.rule,
          stage: SourceStage.bookInfo,
          message: '书源规则无法解析',
        );
      });
      return;
    }

    if (!mounted || generation != _generation) return;
    setState(() {
      _info = info;
    });

    try {
      final SourceToc toc = await ref
          .read(sourceDiscoveryProvider)
          .toc(widget.source!, info);
      if (!mounted || generation != _generation) return;
      setState(() {
        _toc = toc;
        _loading = false;
      });
    } on SourceFailure catch (failure) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _tocFailure = failure;
      });
    } on Object {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _tocFailure = const SourceFailure(
          kind: SourceFailureKind.rule,
          stage: SourceStage.toc,
          message: '书源规则无法解析',
        );
      });
    }
  }

  Future<void> _retryToc() async {
    final SourceBookInfo? info = _info;
    if (info == null) {
      await _loadOnlinePreview();
      return;
    }
    final int generation = ++_generation;
    setState(() {
      _loadingToc = true;
      _tocFailure = null;
    });

    try {
      final SourceToc toc = await ref
          .read(sourceDiscoveryProvider)
          .toc(widget.source!, info);
      if (!mounted || generation != _generation) return;
      setState(() {
        _toc = toc;
        _loadingToc = false;
      });
    } on SourceFailure catch (failure) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _tocFailure = failure;
        _loadingToc = false;
      });
    } on Object {
      if (!mounted || generation != _generation) return;
      setState(() {
        _tocFailure = const SourceFailure(
          kind: SourceFailureKind.rule,
          stage: SourceStage.toc,
          message: '书源规则无法解析',
        );
        _loadingToc = false;
      });
    }
  }

  Future<void> _addToShelfFromPreview() async {
    if (_busy) return;
    final Set<String>? tags = await showAddToShelfSheet(
      context,
      bookTitle: _display.title,
    );
    if (!mounted || tags == null) return;

    setState(() => _busy = true);
    try {
      final String newBookId = await ref
          .read(onlineBookServiceProvider)
          .addToShelf(
            source: widget.source!,
            item: widget.item!,
            info: _info,
            toc: _toc,
            tags: tags.toList(),
          );
      ref.invalidate(booksProvider);
      if (!mounted) return;
      setState(() {
        _persistedBookId = newBookId;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已加入书架')),
      );
    } on Object {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加入书架失败，请稍后再试')),
        );
      }
    }
  }

  Future<void> _listenFromPreview(BookOpenAction open) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final String newBookId = await ref
          .read(onlineBookServiceProvider)
          .startListening(
            source: widget.source!,
            item: widget.item!,
            info: _info,
            toc: _toc,
          );
      ref.invalidate(booksProvider);
      final BookDetail? detail = await ref.read(
        bookDetailProvider(newBookId).future,
      );
      if (!mounted) return;
      setState(() {
        _persistedBookId = newBookId;
        _busy = false;
      });
      if (detail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('书目信息不完整，暂时无法播放')),
        );
        return;
      }
      await open(detail, null);
    } on OnlineBookNotPlayable catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } on Object {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('暂时无法开始播放，请稍后再试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final BookOpenAction open =
        widget.onOpen ??
        (BookDetail value, String? chapterId) => openBookAndShowPlayer(
              context: context,
              ref: ref,
              detail: value,
              startChapterId: chapterId,
            );

    final String? activeBookId = _persistedBookId;
    if (activeBookId == null) {
      // 在线只读预览模式（零写入）
      return _buildOnlinePreviewScaffold(context, open);
    }

    // 已入库模式
    final AsyncValue<BookDetail?> detailAsync = ref.watch(
      bookDetailProvider(activeBookId),
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
                      case 'delete':
                        unawaited(
                          _deleteBook(
                            context,
                            ref,
                            detail.summary,
                            online,
                            rootUri,
                          ),
                        );
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
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                        title: Text(
                          '删除书目',
                          style: TextStyle(color: Colors.red),
                        ),
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
          onRetry: () => ref.invalidate(bookDetailProvider(activeBookId)),
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

  Widget _buildOnlinePreviewScaffold(
    BuildContext context,
    BookOpenAction open,
  ) {
    return Scaffold(
      bottomNavigationBar: _loading ? null : _buildPreviewCta(open),
      appBar: AppBar(
        title: Text(
          '在线预览 · ${widget.source?.name ?? '书源'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading
          ? const Center(
              key: OnlineBookPreviewKeys.loadingKey,
              child: CircularProgressIndicator(),
            )
          : _buildPreviewContent(context),
    );
  }

  Widget _buildPreviewCta(BookOpenAction open) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                key: BookDetailKeys.addShelfKey,
                onPressed: _busy ? null : _addToShelfFromPreview,
                child: const Text('加入书架'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                key: BookDetailKeys.listenKey,
                onPressed: _busy ? null : () => _listenFromPreview(open),
                child: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('立即收听'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context) {
    final SourceBookSummary display = _display;
    final SourceToc? toc = _toc;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _PreviewNotice(),
                if (_infoFailure != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _FailureBanner(
                    message: _infoFailure!.message,
                    onRetry: _loadOnlinePreview,
                  ),
                ],
                if (_tocFailure != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _TocFailure(
                    message: _tocFailure!.message,
                    loading: _loadingToc,
                    onRetry: _retryToc,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _BookHeader(
                  display: display,
                  sourceName: widget.source?.name,
                  titleKey: OnlineBookPreviewKeys.titleKey,
                ),
                if (_metaLine(display).isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _metaLine(display),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
                if (display.intro != null && display.intro!.trim().isNotEmpty)
                  _IntroSection(
                    intro: display.intro!.trim(),
                    expanded: _introExpanded,
                    onToggle: () {
                      setState(() => _introExpanded = !_introExpanded);
                    },
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  toc == null ? '目录暂不可用' : '目录 · ${toc.chapters.length} 章',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (toc != null && !toc.complete) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    key: OnlineBookPreviewKeys.partialTocKey,
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadii.xsValue),
                    ),
                    child: Text(
                      '目录未完整抓取，共 ${toc.chapters.length} 章',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (toc != null)
          SliverList(
            key: OnlineBookPreviewKeys.tocListKey,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final SourceChapter chapter = toc.chapters[index];
                return ListTile(
                  key: OnlineBookPreviewKeys.chapterKey(chapter.index),
                  dense: true,
                  leading: Text('${index + 1}'),
                  title: Text(
                    chapter.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: chapter.isVip
                      ? Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        )
                      : null,
                );
              },
              childCount: toc.chapters.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
      ],
    );
  }

  static String _metaLine(SourceBookSummary display) {
    final List<String> parts = <String>[];
    if (display.author != null && display.author!.trim().isNotEmpty) {
      parts.add('作者：${display.author!.trim()}');
    }
    if (display.narrator != null && display.narrator!.trim().isNotEmpty) {
      parts.add('演播：${display.narrator!.trim()}');
    }
    if (display.kind != null && display.kind!.trim().isNotEmpty) {
      parts.add(display.kind!.trim());
    }
    if (display.wordCount != null && display.wordCount!.trim().isNotEmpty) {
      parts.add(display.wordCount!.trim());
    }
    if (display.status != null && display.status!.trim().isNotEmpty) {
      parts.add(display.status!.trim());
    }
    return parts.join(' · ');
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    BookDetail detail,
    String? rootUri,
    bool online,
  ) async {
    if (!online && (rootUri == null || rootUri.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('书库根已移除，暂时不能编辑元数据')),
      );
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
    if (saved == true && _persistedBookId != null) {
      ref.invalidate(bookDetailProvider(_persistedBookId!));
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
    );
    if (tags == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(onlineLibraryQueriesProvider)
          .setBookShelf(detail.summary.id, onShelf: true, tags: tags.toList());
      ref.invalidate(bookDetailProvider(detail.summary.id));
      ref.invalidate(booksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已加入书架')),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加入书架失败，请稍后再试')),
        );
      }
    }
  }

  Future<void> _removeFromShelf(
    BuildContext context,
    WidgetRef ref,
    BookDetail detail,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('移出书架'),
        content: Text('确定要将《${detail.summary.title}》移出书架吗？本地文件和历史进度仍会保留。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('移出'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(onlineLibraryQueriesProvider)
          .setBookShelf(detail.summary.id, onShelf: false);
      ref.invalidate(bookDetailProvider(detail.summary.id));
      ref.invalidate(booksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已移出书架，书目仍保留在书库')),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('移出书架失败，请稍后再试')),
        );
      }
    }
  }

  Future<void> _deleteBook(
    BuildContext context,
    WidgetRef ref,
    BookSummary book,
    bool online,
    String? rootUri,
  ) async {
    final bool isSafRoot = rootUri != null && rootUri.startsWith('content://');
    final result = await showSafeDeleteBookDialog(
      context,
      book: book,
      isLocal: !online,
      isSafRoot: isSafRoot,
    );
    if (result == null || !context.mounted) return;

    if (result.action == SafeDeleteAction.removeFromShelf) {
      await ref
          .read(onlineLibraryQueriesProvider)
          .setBookShelf(book.id, onShelf: false);
    } else {
      await ref.read(libraryQueriesProvider).deleteBookRecord(book.id);
      if (online) {
        try {
          await ref.read(audioCacheRepositoryProvider).clearBookCache(book.id);
        } catch (_) {}
      } else if (result.deleteLocalFiles && rootUri != null) {
        try {
          final uri = Uri.parse(rootUri);
          if (uri.scheme == 'file' || uri.scheme.isEmpty) {
            final dir = Directory(rootUri);
            final entities = dir.listSync();
            for (final entity in entities) {
              if (entity is Directory &&
                  entity.path.endsWith(book.rootPath)) {
                entity.deleteSync(recursive: true);
                break;
              }
            }
          }
        } catch (_) {}
      }
    }

    ref.invalidate(booksProvider);
    if (_persistedBookId != null) {
      ref.invalidate(bookDetailProvider(_persistedBookId!));
    }
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.action == SafeDeleteAction.removeFromShelf
                ? '已将《${book.title}》移出书架'
                : '已删除《${book.title}》${result.deleteLocalFiles ? '及其本地文件' : ''}',
          ),
        ),
      );
    }
  }

  Future<void> _reimport(
    BuildContext context,
    WidgetRef ref,
    BookDetail detail,
    String? rootUri,
  ) async {
    if (rootUri == null || rootUri.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('书库根已移除，暂时不能重新导入')),
      );
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
      if (_persistedBookId != null) {
        ref.invalidate(bookDetailProvider(_persistedBookId!));
      }
      ref.invalidate(booksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已从书根导入元数据')),
      );
    } on Object {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入失败，请稍后再试')),
      );
    }
  }

  static String? _rootUriFor(List<LibraryRootView>? roots, String rootId) {
    if (roots == null) return null;
    for (final LibraryRootView root in roots) {
      if (root.id == rootId) return root.uri;
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
                  SizedBox(
                    width: 96,
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          return ClipRRect(
                            borderRadius: AppRadii.cover,
                            child: book.isOnline
                                ? NetworkCover(
                                    coverUrl: book.coverUrl,
                                    size: constraints.maxWidth,
                                    headers: source?.header,
                                    borderRadius: AppRadii.cover,
                                  )
                                : BookCover(
                                    title: book.title,
                                    size: constraints.maxWidth,
                                    coverPath: coverArt is CoverArtFile
                                        ? coverArt.absolutePath
                                        : null,
                                    coverImage: coverArt is CoverArtBytes
                                        ? MemoryImage(coverArt.bytes)
                                        : null,
                                  ),
                          );
                        },
                      ),
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
                          _authorNarrator(book),
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (book.isOnline && source != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '书源：${source!.name}',
                            style: text.labelSmall?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  if (book.isOnline)
                    _MetaPill(
                      icon: Icons.cloud_outlined,
                      label: _sourceStatus(book),
                    ),
                  _MetaPill(
                    icon: Icons.library_music_outlined,
                    label: '${book.totalChapters} 章',
                  ),
                  if (book.totalDurationMs > 0)
                    _MetaPill(
                      icon: Icons.timer_outlined,
                      label: _formatDuration(book.totalDurationMs),
                    ),
                  if (book.hasProgress)
                    _MetaPill(
                      icon: Icons.headphones_rounded,
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
            child: Row(
              children: <Widget>[
                if (book.isOnline) ...<Widget>[
                  Expanded(
                    child: OutlinedButton(
                      key: book.onShelf
                          ? BookDetailKeys.removeShelfKey
                          : BookDetailKeys.addShelfKey,
                      onPressed: book.onShelf ? onRemoveShelf : onAddShelf,
                      child: Text(book.onShelf ? '移出书架' : '加入书架'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: FilledButton(
                    key: BookDetailKeys.listenKey,
                    onPressed: () => _start(context),
                    child: Text(
                      book.isOnline && !book.onShelf
                          ? '立即收听'
                          : _primaryLabel(book),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _authorNarrator(BookSummary book) {
    final List<String> parts = <String>[];
    if (book.author != null && book.author!.trim().isNotEmpty) {
      parts.add('${book.author!.trim()} 著');
    }
    if (book.narrator != null && book.narrator!.trim().isNotEmpty) {
      parts.add('${book.narrator!.trim()} 演播');
    }
    return parts.isEmpty ? '佚名' : parts.join(' · ');
  }

  static String _formatDuration(int ms) {
    final Duration d = Duration(milliseconds: ms);
    final int hours = d.inHours;
    final int minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours 小时 ${minutes.toString().padLeft(2, '0')} 分';
    }
    return '$minutes 分钟';
  }

  static String _sourceStatus(BookSummary book) {
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
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      key: OnlineBookPreviewKeys.previewNoticeKey,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.xsValue),
      ),
      child: Text(
        '预览模式 · 不会写入书库',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
      ),
    );
  }
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      key: OnlineBookPreviewKeys.errorKey,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.xsValue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onErrorContainer,
                ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: OnlineBookPreviewKeys.retryKey,
              onPressed: () => unawaited(onRetry()),
              child: const Text('重试'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TocFailure extends StatelessWidget {
  const _TocFailure({
    required this.message,
    required this.loading,
    required this.onRetry,
  });

  final String message;
  final bool loading;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.xsValue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '目录暂不可用 · $message',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: OnlineBookPreviewKeys.tocRetryKey,
              onPressed: loading ? null : () => unawaited(onRetry()),
              child: loading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('重试目录'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookHeader extends StatelessWidget {
  const _BookHeader({
    required this.display,
    required this.titleKey,
    this.sourceName,
  });

  final SourceBookSummary display;
  final Key titleKey;
  final String? sourceName;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 96,
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return ClipRRect(
                  borderRadius: AppRadii.cover,
                  child: NetworkCover(
                    coverUrl: display.coverUrl,
                    size: constraints.maxWidth,
                    borderRadius: AppRadii.cover,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                display.title,
                key: titleKey,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (sourceName != null && sourceName!.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '书源：$sourceName',
                  style: text.labelSmall?.copyWith(color: scheme.primary),
                ),
              ],
              if (display.lastChapter != null &&
                  display.lastChapter!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '最新：${display.lastChapter!.trim()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _IntroSection extends StatelessWidget {
  const _IntroSection({
    required this.intro,
    required this.expanded,
    required this.onToggle,
  });

  final String intro;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final bool canExpand = intro.length > 80;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '简介',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            intro,
            maxLines: expanded ? null : 4,
            overflow: expanded ? null : TextOverflow.ellipsis,
          ),
          if (canExpand)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onToggle,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(expanded ? '收起' : '展开全文'),
              ),
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
    final TextTheme text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  title,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (trailing != null) ...<Widget>[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
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

    return Card(
      child: InkWell(
        borderRadius: AppRadii.lg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Icon(icon, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: text.bodyMedium),
                    Text(
                      value,
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: text.labelSmall),
        ],
      ),
    );
  }
}

class _DetailMissing extends StatelessWidget {
  const _DetailMissing();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('这本书已经不在书架里了', style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '书目可能已被删除或来自未接入的书库根。',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
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
    final TextTheme text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: AppSpacing.md),
            Text('加载详情失败', style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
