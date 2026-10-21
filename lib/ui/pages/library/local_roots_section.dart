import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/library_root_providers.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/pages/library/library_browser_page.dart';
import 'package:tometone/ui/pages/library/library_roots.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 来源管理页里的本机目录管理段。
class LocalRootsSection extends ConsumerStatefulWidget {
  const LocalRootsSection({super.key, this.suggestedRootPath});

  final String? suggestedRootPath;

  @override
  ConsumerState<LocalRootsSection> createState() => _LocalRootsSectionState();
}

class _LocalRootsSectionState extends ConsumerState<LocalRootsSection> {
  static const int _impactQueryLimit = 2000;

  ({String message, LibraryNoticeTone tone})? _notice;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<LibraryRootView>> rootsAsync = ref.watch(
      libraryRootsProvider,
    );
    final Map<String, RootScanState> scans = ref.watch(libraryScanProvider);
    final List<LibraryRootView> roots =
        rootsAsync.value ?? const <LibraryRootView>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '本机目录',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: LibraryRootsKeys.addButtonKey,
                tooltip: '添加本机目录',
                onPressed: () => unawaited(_openAddRootSheet()),
                icon: const Icon(Icons.create_new_folder_outlined),
              ),
            ],
          ),
        ),
        Padding(
          padding: AppSpacing.pagePadding,
          child: _buildRoots(rootsAsync, roots, scans),
        ),
        if (_notice != null)
          Padding(
            padding: AppSpacing.pagePadding,
            child: LibraryRootNotice(
              key: LibraryRootsKeys.noticeKey,
              message: _notice!.message,
              tone: _notice!.tone,
            ),
          ),
      ],
    );
  }

  Widget _buildRoots(
    AsyncValue<List<LibraryRootView>> rootsAsync,
    List<LibraryRootView> roots,
    Map<String, RootScanState> scans,
  ) {
    if (rootsAsync.hasError) {
      return LibraryRootsError(
        onRetry: () => ref.invalidate(libraryRootsProvider),
      );
    }
    if (!rootsAsync.hasValue) {
      return const LibraryRootsLoading();
    }
    if (roots.isEmpty) {
      return LibraryRootsEmpty(onAdd: () => unawaited(_openAddRootSheet()));
    }
    return Column(
      key: LibraryRootsKeys.rootsListKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final LibraryRootView root in roots)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: LibraryRootCard(
              root: root,
              scan: scans[root.id] ?? const RootScanState(),
              onScan: () => _scan(root),
              onOpen: () => _openRoot(root),
              onRename: () => unawaited(_renameRoot(root)),
              onRemove: () => unawaited(_removeRoot(root)),
              onDismissResult: () =>
                  ref.read(libraryScanProvider.notifier).collapse(root.id),
            ),
          ),
      ],
    );
  }

  Future<void> _openAddRootSheet() async {
    _clearNotice();
    final String suggested =
        widget.suggestedRootPath ?? defaultRootPathSuggestion();
    final String? addedName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AnimationStyle(
        duration: AppMotion.resolve(context, AppDurations.standard),
        reverseDuration: AppMotion.resolve(context, AppDurations.fast),
      ),
      builder: (_) => LibraryAddRootSheet(suggestedPath: suggested),
    );
    if (!mounted || addedName == null) {
      return;
    }
    _showNotice('已添加「$addedName」。点这一行的「扫描」开始建立书目。');
    ref.invalidate(libraryRootsProvider);
  }

  void _openRoot(LibraryRootView root) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => LibraryBrowserPage(root: root)),
      ),
    );
  }

  Future<void> _renameRoot(LibraryRootView root) async {
    _clearNotice();
    final String? name = await showRenameRootDialog(context, root: root);
    if (!mounted || name == null || name == root.displayName) {
      return;
    }
    try {
      await ref.read(libraryRootServiceProvider).renameRoot(root.id, name);
    } on Object {
      _showNotice('重命名没有成功，请稍后再试。', tone: LibraryNoticeTone.error);
      return;
    }
    if (!mounted) {
      return;
    }
    ref.invalidate(libraryRootsProvider);
  }

  Future<void> _removeRoot(LibraryRootView root) async {
    _clearNotice();
    final LibraryRemovalImpact? impact = await _loadRemovalImpact(root.id);
    if (!mounted) {
      return;
    }
    final bool confirmed = await showRemoveRootDialog(
      context,
      root: root,
      impact: impact,
    );
    if (!mounted || !confirmed) {
      return;
    }
    try {
      await ref.read(libraryRootServiceProvider).removeRoot(root.id);
    } on Object {
      _showNotice(
        '「${root.displayName}」没有移除成功，请稍后再试。',
        tone: LibraryNoticeTone.error,
      );
      return;
    }
    if (!mounted) {
      return;
    }
    ref.read(libraryScanProvider.notifier).forget(root.id);
    ref.invalidate(libraryRootsProvider);
    ref.invalidate(booksProvider);
    _showNotice('已移除「${root.displayName}」。目录里的文件没有任何改动。');
  }

  Future<LibraryRemovalImpact?> _loadRemovalImpact(String rootId) async {
    try {
      final List<BookSummary> books = await ref
          .read(libraryQueriesProvider)
          .listBooks(libraryRootId: rootId, limit: _impactQueryLimit);
      return _summarizeImpact(books, capped: books.length >= _impactQueryLimit);
    } on Object {
      try {
        final List<BookSummary> cached = await ref.read(booksProvider.future);
        return _summarizeImpact(<BookSummary>[
          for (final BookSummary book in cached)
            if (book.libraryRootId == rootId) book,
        ], capped: false);
      } on Object {
        return null;
      }
    }
  }

  LibraryRemovalImpact _summarizeImpact(
    List<BookSummary> books, {
    required bool capped,
  }) {
    int chapters = 0;
    for (final BookSummary book in books) {
      chapters += book.totalChapters;
    }
    return LibraryRemovalImpact(
      books: books.length,
      chapters: chapters,
      capped: capped,
    );
  }

  void _scan(LibraryRootView root) {
    if (ref.read(libraryScanProvider)[root.id]?.scanning ?? false) {
      return;
    }
    _clearNotice();
    unawaited(ref.read(libraryScanProvider.notifier).scan(root.id));
  }

  void _showNotice(
    String message, {
    LibraryNoticeTone tone = LibraryNoticeTone.success,
  }) {
    if (!mounted) {
      return;
    }
    setState(() => _notice = (message: message, tone: tone));
  }

  void _clearNotice() {
    if (_notice == null) {
      return;
    }
    setState(() => _notice = null);
  }
}
