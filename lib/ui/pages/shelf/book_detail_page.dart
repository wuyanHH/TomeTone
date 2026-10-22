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
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_failure.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/pages/library/safe_delete_book_dialog.dart';
import 'package:tometone/ui/pages/library/switch_source_sheet.dart';
import 'package:tometone/ui/pages/shelf/add_to_shelf_sheet.dart';
import 'package:tometone/ui/pages/shelf/book_metadata_sheet.dart';
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

/// 统一书籍详情与目录页。
///
/// 无论是本地书、在线已存书，还是从发现页搜索/分类进来的未入架书，
/// 均统一呈现相同的页面结构与交互模式。
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
  int _generation = 0;
  bool _busy = false;

  SourceBookSummary get _display => _info ?? widget.item!;

  @override
  void initState() {
    super.initState();
    _persistedBookId = widget.bookId;
    if (_persistedBookId == null && widget.source != null && widget.item != null) {
      unawaited(_initOnlineBook());
    }
  }

  Future<void> _initOnlineBook() async {
    try {
      final Map<String, OnlineBookStatus> statuses = await ref
          .read(onlineLibraryQueriesProvider)
          .bookStatuses(
            sourceId: widget.source!.id,
            bookUrls: <String>[widget.item!.bookUrl],
          );
      final OnlineBookStatus? status = statuses[widget.item!.bookUrl];
      if (status != null && mounted) {
        setState(() {
          _persistedBookId = status.bookId;
          _loading = false;
        });
        return;
      }
    } on Object {
      // 容错回退至在线获取
    }
    await _loadOnlinePreview();
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

  Future<void> _listenFromPreview(BookOpenAction open, {int? startChapterIndex}) async {
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
      String? startChapterId;
      if (startChapterIndex != null) {
        final List<ChapterView> allChapters = detail.chapters;
        if (startChapterIndex >= 0 && startChapterIndex < allChapters.length) {
          startChapterId = allChapters[startChapterIndex].id;
        }
      }
      await open(detail, startChapterId);
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
      // 在线只读预览模式：统一复用同一套 BookDetail 页面视觉与操作架构
      return Scaffold(
        appBar: AppBar(
          title: const Text('书籍详情'),
          actions: <Widget>[
            PopupMenuButton<String>(
              tooltip: '更多',
              onSelected: (String value) {
                if (value == 'refresh') {
                  unawaited(_loadOnlinePreview());
                }
              },
              itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: ListTile(
                    leading: Icon(Icons.refresh_rounded),
                    title: Text('刷新目录'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: _loading
            ? null
            : _buildCtaBar(
                isOnline: true,
                onShelf: false,
                onAddShelf: _busy ? null : _addToShelfFromPreview,
                onRemoveShelf: null,
                onListen: _busy ? null : () => _listenFromPreview(open),
                ctaLabel: '立即收听',
                busy: _busy,
              ),
        body: _loading
            ? const Center(
                key: OnlineBookPreviewKeys.loadingKey,
                child: CircularProgressIndicator(),
              )
            : _BookDetailBody(
                previewSummary: _display,
                previewToc: _toc,
                previewInfoFailure: _infoFailure,
                previewTocFailure: _tocFailure,
                loadingToc: _loadingToc,
                onRetryInfo: _loadOnlinePreview,
                onRetryToc: _retryToc,
                source: widget.source,
                onOpen: open,
                onListenPreview: (int? index) =>
                    _listenFromPreview(open, startChapterIndex: index),
              ),
      );
    }

    // 已入库书籍（本地书或已入库在线书）
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
                      case 'switch_source':
                        if (online) {
                          unawaited(_openSwitchSource(detail));
                        }
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
                    if (online)
                      const PopupMenuItem<String>(
                        value: 'switch_source',
                        child: ListTile(
                          leading: Icon(Icons.swap_horiz_rounded),
                          title: Text('换源'),
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
      bottomNavigationBar: detail == null
          ? null
          : _buildCtaBar(
              isOnline: online,
              onShelf: detail.summary.onShelf,
              onAddShelf: online ? () => unawaited(_addToShelf(context, ref, detail)) : null,
              onRemoveShelf: online ? () => unawaited(_removeFromShelf(context, ref, detail)) : null,
              onListen: () => _startListening(open, detail),
              ctaLabel: _primaryLabel(detail.summary),
              busy: _busy,
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

  Widget _buildCtaBar({
    required bool isOnline,
    required bool onShelf,
    required VoidCallback? onAddShelf,
    required VoidCallback? onRemoveShelf,
    required VoidCallback? onListen,
    required String ctaLabel,
    bool busy = false,
  }) {
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
            if (isOnline) ...<Widget>[
              Expanded(
                child: OutlinedButton(
                  key: onShelf
                      ? BookDetailKeys.removeShelfKey
                      : BookDetailKeys.addShelfKey,
                  onPressed: onShelf ? onRemoveShelf : onAddShelf,
                  child: Text(onShelf ? '移出书架' : '加入书架'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: FilledButton(
                key: BookDetailKeys.listenKey,
                onPressed: onListen,
                child: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(ctaLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startListening(BookOpenAction open, BookDetail detail) {
    if (detail.summary.isFinished && detail.chapters.isNotEmpty) {
      unawaited(open(detail, detail.chapters.first.id));
      return;
    }
    unawaited(open(detail, null));
  }

  Future<void> _openSwitchSource(BookDetail detail) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return SwitchSourceSheet(
          bookId: detail.summary.id,
          currentBookTitle: detail.summary.title,
          currentSourceId: detail.summary.sourceId ?? '',
        );
      },
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
            final bookDir = Directory.fromUri(uri.resolve(book.rootPath));
            if (bookDir.existsSync()) {
              bookDir.deleteSync(recursive: true);
            }
          }
        } catch (_) {}
      }
    }
    ref.invalidate(booksProvider);
    if (context.mounted) {
      Navigator.of(context).maybePop();
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

  static String _primaryLabel(BookSummary book) {
    if (book.isOnline && !book.onShelf) {
      return '立即收听';
    }
    if (book.isFinished) {
      return '重新收听';
    }
    if (book.hasProgress) {
      final int chapter = (book.progressChapterIndex ?? 0) + 1;
      return '从第 $chapter 章继续收听';
    }
    return '开始收听';
  }

  static String? _rootUriFor(List<LibraryRootView>? roots, String rootId) {
    if (roots == null) return null;
    for (final LibraryRootView root in roots) {
      if (root.id == rootId) return root.uri;
    }
    return null;
  }
}

/// 统一的书籍详情主体渲染组件。
class _BookDetailBody extends ConsumerStatefulWidget {
  const _BookDetailBody({
    this.detail,
    this.previewSummary,
    this.previewToc,
    this.previewInfoFailure,
    this.previewTocFailure,
    this.loadingToc = false,
    this.onRetryInfo,
    this.onRetryToc,
    required this.source,
    required this.onOpen,
    this.onEdit,
    this.onAddShelf,
    this.onRemoveShelf,
    this.onListenPreview,
  });

  final BookDetail? detail;
  final SourceBookSummary? previewSummary;
  final SourceToc? previewToc;
  final SourceFailure? previewInfoFailure;
  final SourceFailure? previewTocFailure;
  final bool loadingToc;
  final VoidCallback? onRetryInfo;
  final VoidCallback? onRetryToc;
  final BookSource? source;
  final BookOpenAction onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onAddShelf;
  final VoidCallback? onRemoveShelf;
  final void Function(int? startChapterIndex)? onListenPreview;

  @override
  ConsumerState<_BookDetailBody> createState() => _BookDetailBodyState();
}

class _BookDetailBodyState extends ConsumerState<_BookDetailBody> {
  bool _reversed = false;
  bool _introExpanded = false;
  final Set<String> _collapsedVolumeIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    final BookDetail? detail = widget.detail;
    final SourceBookSummary? preview = widget.previewSummary;
    final BookSummary? book = detail?.summary;

    final String title = book?.title ?? preview?.title ?? '未知书目';
    final String author = (book?.author ?? preview?.author ?? '').trim();
    final String narrator = (book?.narrator ?? preview?.narrator ?? '').trim();
    final String description = (book?.description ?? preview?.intro ?? '').trim();
    final String? seriesName = book?.seriesName;
    final int? seriesIndex = book?.seriesIndex;
    final List<String> tags = book?.tags ?? const <String>[];
    final bool isOnline = book?.isOnline ?? true;
    final String? sourceName = widget.source?.name;

    final int totalChapters = book?.totalChapters ??
        widget.previewToc?.chapters.length ??
        detail?.chapters.length ??
        0;

    final CoverArt? coverArt = book == null
        ? null
        : ref
            .watch(
              coverArtProvider(
                CoverArtKey(
                  rootId: book.libraryRootId,
                  coverPath: book.coverPath,
                ),
              ),
            )
            .value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: <Widget>[
        if (widget.previewInfoFailure != null) ...<Widget>[
          _FailureBanner(
            message: widget.previewInfoFailure!.message,
            onRetry: widget.onRetryInfo,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (widget.previewTocFailure != null) ...<Widget>[
          _TocFailure(
            message: widget.previewTocFailure!.message,
            loading: widget.loadingToc,
            onRetry: widget.onRetryToc,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 头部：左侧 2:3 封面，右侧大字标题与双行作者/演播
        Row(
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
                      child: isOnline
                          ? NetworkCover(
                              coverUrl: book?.coverUrl ?? preview?.coverUrl,
                              size: constraints.maxWidth,
                              headers: widget.source?.header,
                              borderRadius: AppRadii.cover,
                            )
                          : BookCover(
                              title: title,
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
                  if (seriesName != null && seriesName.trim().isNotEmpty) ...<Widget>[
                    Text(
                      seriesIndex == null
                          ? seriesName.trim()
                          : '${seriesName.trim()} · 第 $seriesIndex 卷',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(
                    title,
                    key: OnlineBookPreviewKeys.titleKey,
                    style: text.headlineSmall?.copyWith(
                      height: 1.25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // 作者独立展示（Line 1）
                  if (author.isNotEmpty) ...<Widget>[
                    Text(
                      author.startsWith('作者') || author.endsWith('著')
                          ? author
                          : '$author 著',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  // 演播独立展示（Line 2）
                  if (narrator.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      narrator.startsWith('演播') || narrator.endsWith('演播')
                          ? narrator
                          : '$narrator 演播',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (isOnline && sourceName != null && sourceName.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '书源：$sourceName',
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

        // 指标小胶囊行
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            if (isOnline && book != null)
              _MetaPill(
                icon: Icons.cloud_outlined,
                label: _sourceStatus(book),
              ),
            _MetaPill(
              icon: Icons.library_music_outlined,
              label: '$totalChapters 章',
            ),
            if ((book?.totalDurationMs ?? 0) > 0)
              _MetaPill(
                icon: Icons.timer_outlined,
                label: _formatDuration(book!.totalDurationMs),
              ),
            if (book?.hasProgress == true)
              _MetaPill(
                icon: Icons.headphones_rounded,
                label:
                    '第 ${(book!.progressChapterIndex ?? 0) + 1} / ${book.totalChapters} 章',
              ),
            if ((book?.missingChapters ?? 0) > 0)
              _MetaPill(
                icon: Icons.link_off_rounded,
                label: '${book!.missingChapters} 章缺失',
              ),
          ],
        ),

        // 标签
        if (tags.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (final String tag in tags)
                Chip(
                  label: Text(tag),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.lg),

        // 简介卡片（去除卡片内编辑按钮）
        _SectionCard(
          title: '简介',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                description.isEmpty ? '暂无简介' : description,
                maxLines: _introExpanded ? null : 3,
                overflow: _introExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(
                  height: 1.6,
                  color: description.isEmpty ? scheme.onSurfaceVariant : null,
                ),
              ),
              if (description.length > 80)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _introExpanded = !_introExpanded),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(_introExpanded ? '收起' : '展开全文'),
                  ),
                ),
            ],
          ),
        ),

        // 收听进度（有进度时显示在章节目录上方）
        if (book != null && book.hasProgress) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: '收听进度',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ShelfProgress(book: book),
                if (book.progressChapterTitle != null &&
                    book.progressChapterTitle!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '上次听到：${book.progressChapterTitle}',
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

        const SizedBox(height: AppSpacing.lg),

        // 章节目录表头与排序切换
        Row(
          children: <Widget>[
            Text(
              '章节目录',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '目录 · $totalChapters 章',
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const Spacer(),
            IconButton(
              tooltip: _reversed ? '切换为正序' : '切换为倒序',
              icon: Icon(
                _reversed
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 20,
              ),
              onPressed: () => setState(() => _reversed = !_reversed),
            ),
          ],
        ),

        if (widget.previewToc != null && !widget.previewToc!.complete) ...<Widget>[
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
              '目录未完整抓取，共 ${widget.previewToc!.chapters.length} 章',
              style: text.bodySmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xs),

        // 直接内嵌渲染的章节与卷册列表
        _buildCatalogContent(context, detail),
      ],
    );
  }

  Widget _buildCatalogContent(BuildContext context, BookDetail? detail) {
    if (detail != null) {
      final List<VolumeView> volumes = detail.volumes;
      if (volumes.length > 1) {
        // 多卷模式：带折叠/展开的卷卡片
        final List<VolumeView> orderedVolumes =
            _reversed ? volumes.reversed.toList() : volumes;
        return Column(
          children: <Widget>[
            for (final VolumeView volume in orderedVolumes)
              _buildVolumeSection(context, detail, volume),
            if (detail.retiredChapters.isNotEmpty)
              _buildRetiredSection(context, detail.retiredChapters),
          ],
        );
      } else {
        // 单卷模式：平铺章节列表
        final List<ChapterView> chapters = _reversed
            ? detail.chapters.reversed.toList()
            : detail.chapters;
        return Column(
          children: <Widget>[
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chapters.length,
                separatorBuilder: (BuildContext _, int _) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final ChapterView chapter = chapters[index];
                  return _buildChapterTile(context, detail, chapter);
                },
              ),
            ),
            if (detail.retiredChapters.isNotEmpty)
              _buildRetiredSection(context, detail.retiredChapters),
          ],
        );
      }
    }

    // 在线预览模式平铺目录
    final SourceToc? toc = widget.previewToc;
    if (toc == null) {
      return const SizedBox.shrink();
    }
    final List<SourceChapter> chapters =
        _reversed ? toc.chapters.reversed.toList() : toc.chapters;
    final int total = toc.chapters.length;

    return Card(
      key: OnlineBookPreviewKeys.tocListKey,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: chapters.length,
        separatorBuilder: (BuildContext _, int _) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final SourceChapter chapter = chapters[index];
          final int displayNum = _reversed ? total - index : index + 1;
          return ListTile(
            key: OnlineBookPreviewKeys.chapterKey(chapter.index),
            dense: true,
            leading: SizedBox(
              width: 32,
              child: Text(
                '$displayNum',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            title: Text(
              chapter.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: chapter.isVip
                ? Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : null,
            onTap: () => widget.onListenPreview?.call(chapter.index),
          );
        },
      ),
    );
  }

  Widget _buildVolumeSection(
    BuildContext context,
    BookDetail detail,
    VolumeView volume,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool collapsed = _collapsedVolumeIds.contains(volume.id);
    final List<ChapterView> chapters =
        _reversed ? volume.chapters.reversed.toList() : volume.chapters;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        children: <Widget>[
          InkWell(
            onTap: () {
              setState(() {
                if (collapsed) {
                  _collapsedVolumeIds.remove(volume.id);
                } else {
                  _collapsedVolumeIds.add(volume.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(AppRadii.smValue),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  Container(width: 3, height: 14, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      volume.title,
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${volume.chapters.length} 章',
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    collapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (!collapsed) ...<Widget>[
            const Divider(height: 1),
            for (final ChapterView chapter in chapters)
              _buildChapterTile(context, detail, chapter),
          ],
        ],
      ),
    );
  }

  Widget _buildRetiredSection(
    BuildContext context,
    List<ChapterView> retiredChapters,
  ) {
    final List<ChapterView> chapters =
        _reversed ? retiredChapters.reversed.toList() : retiredChapters;
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              '已下架 ${retiredChapters.length} 章',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const Divider(height: 1),
          for (final ChapterView chapter in chapters)
            ListTile(
              dense: true,
              enabled: false,
              title: Text(
                chapter.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: const Text('已下架'),
              trailing: const Icon(Icons.lock_outline_rounded, size: 18),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已下架')),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChapterTile(
    BuildContext context,
    BookDetail detail,
    ChapterView chapter,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isCurrent = chapter.id == detail.summary.progressChapterId;
    final bool isPlayable = !chapter.missing && !chapter.isVip;

    Widget? trailing;
    if (chapter.missing) {
      trailing = Text(
        '缺失',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.error.withValues(alpha: 0.8),
            ),
      );
    } else if (chapter.isVip) {
      trailing = Icon(
        Icons.lock_outline_rounded,
        size: 18,
        color: scheme.onSurfaceVariant,
      );
    } else if (isCurrent) {
      trailing = Text(
        '正在播放',
        style: TextStyle(
          color: scheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return ListTile(
      dense: true,
      enabled: isPlayable,
      selected: isCurrent,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.2),
      leading: SizedBox(
        width: 32,
        child: Text(
          '${chapter.chapterIndex + 1}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isCurrent ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ),
      title: Text(
        chapter.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isCurrent ? scheme.primary : null,
          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: chapter.missing
          ? Text(
              '文件缺失，暂不可播放',
              style: TextStyle(color: scheme.error, fontSize: 12),
            )
          : null,
      trailing: trailing,
      onTap: isPlayable
          ? () => unawaited(widget.onOpen(detail, chapter.id))
          : null,
    );
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
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
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

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

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
              onPressed: onRetry,
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
  final VoidCallback? onRetry;

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
              onPressed: loading ? null : onRetry,
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
