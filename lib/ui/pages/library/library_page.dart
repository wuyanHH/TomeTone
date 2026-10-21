import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/ui/app_tabs.dart';
import 'package:tometone/ui/pages/library/library_book_row.dart';
import 'package:tometone/ui/pages/library/library_filter.dart';
import 'package:tometone/ui/pages/library/library_roots.dart';
import 'package:tometone/ui/pages/shelf/book_detail_page.dart';
import 'package:tometone/ui/pages/shelf/shelf_filter.dart';
import 'package:tometone/ui/pages/sources/source_import_sheet.dart';
import 'package:tometone/ui/pages/sources/source_management_page.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 书库页稳定测试定位键。
abstract final class LibraryKeys {
  static const Key searchFieldKey = Key('library-search-field');
  static const Key sourcesButtonKey = LibraryRootsKeys.sourcesButtonKey;
  static const Key emptyKey = Key('library-empty');
  static const Key importSourceKey = Key('library-import-source');
  static const Key addLocalRootKey = Key('library-add-local-root');
  static const Key goToDiscoveryKey = Key('library-go-to-discovery');
  static const Key sourceFilterAll = Key('library-filter-all');
  static const Key sourceFilterLocal = Key('library-filter-local');
  static const Key sourceFilterOnline = Key('library-filter-online');
  static const Key statusDropdownKey = Key('library-status-dropdown');
  static const Key tagDropdownKey = Key('library-tag-dropdown');
  static Key bookRowKey(String id) => ValueKey<String>('library-book-$id');
}

/// 书库统一书目列表页：展示本机目录与在线书源的全部藏书。
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key, this.suggestedRootPath});

  final String? suggestedRootPath;

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  LibraryFilterState _filter = const LibraryFilterState();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<BookSummary>> booksAsync = ref.watch(booksProvider);
    final List<BookSummary> books = booksAsync.value ?? const <BookSummary>[];

    final AsyncValue<List<LibraryRootView>> rootsAsync = ref.watch(
      libraryRootsProvider,
    );
    final AsyncValue<List<BookSource>> sourcesAsync = ref.watch(
      bookSourcesProvider,
    );

    final List<LibraryRootView> roots =
        rootsAsync.value ?? const <LibraryRootView>[];
    final List<BookSource> sources =
        sourcesAsync.value ?? const <BookSource>[];
    final bool hasSources =
        roots.isNotEmpty || sources.any((BookSource s) => s.enabled);

    final List<BookSummary> filtered = _filter.apply(books);
    final int localCount = books.where((BookSummary b) => !b.isOnline).length;
    final int onlineCount = books.where((BookSummary b) => b.isOnline).length;

    final Set<String> availableTags = <String>{
      for (final BookSummary b in books) ...b.tags,
    };

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('我的书库'),
            Text(
              '共 ${books.length} 册 · 本地 $localCount · 在线 $onlineCount',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            key: LibraryKeys.sourcesButtonKey,
            tooltip: '来源管理',
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const SourceManagementPage(),
                ),
              );
            },
            icon: const Icon(Icons.source_outlined),
          ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('加载书库失败'),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () => ref.invalidate(booksProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (_) {
          if (books.isEmpty) {
            return _buildEmptyState(context, hasSources);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              _buildFilterBar(context, availableTags),
              const SizedBox(height: AppSpacing.md),
              if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '没有找到匹配的书目',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filter = const LibraryFilterState();
                              _searchController.clear();
                            });
                          },
                          child: const Text('清除筛选'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final BookSummary book in filtered) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: LibraryBookRow(
                      key: LibraryKeys.bookRowKey(book.id),
                      book: book,
                      onTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => BookDetailPage(bookId: book.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, Set<String> availableTags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          key: LibraryKeys.searchFieldKey,
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索书名、作者、简介或标签…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _filter = _filter.copyWith(query: '');
                      });
                    },
                  )
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadii.md,
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          onChanged: (String value) {
            setState(() {
              _filter = _filter.copyWith(query: value);
            });
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              FilterChip(
                key: LibraryKeys.sourceFilterAll,
                label: const Text('全部'),
                selected: _filter.source == LibrarySourceFilter.all,
                onSelected: (_) {
                  setState(() {
                    _filter = _filter.copyWith(source: LibrarySourceFilter.all);
                  });
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              FilterChip(
                key: LibraryKeys.sourceFilterLocal,
                label: const Text('本地'),
                selected: _filter.source == LibrarySourceFilter.local,
                onSelected: (_) {
                  setState(() {
                    _filter = _filter.copyWith(
                      source: LibrarySourceFilter.local,
                    );
                  });
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              FilterChip(
                key: LibraryKeys.sourceFilterOnline,
                label: const Text('在线'),
                selected: _filter.source == LibrarySourceFilter.online,
                onSelected: (_) {
                  setState(() {
                    _filter = _filter.copyWith(
                      source: LibrarySourceFilter.online,
                    );
                  });
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              DropdownButton<ShelfStatusFilter>(
                key: LibraryKeys.statusDropdownKey,
                value: _filter.status,
                underline: const SizedBox.shrink(),
                items: const <DropdownMenuItem<ShelfStatusFilter>>[
                  DropdownMenuItem(
                    value: ShelfStatusFilter.all,
                    child: Text('全部状态'),
                  ),
                  DropdownMenuItem(
                    value: ShelfStatusFilter.listening,
                    child: Text('在听'),
                  ),
                  DropdownMenuItem(
                    value: ShelfStatusFilter.unlistened,
                    child: Text('未听'),
                  ),
                  DropdownMenuItem(
                    value: ShelfStatusFilter.finished,
                    child: Text('已完'),
                  ),
                ],
                onChanged: (ShelfStatusFilter? value) {
                  if (value != null) {
                    setState(() {
                      _filter = _filter.copyWith(status: value);
                    });
                  }
                },
              ),
              if (availableTags.isNotEmpty) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<String?>(
                  key: LibraryKeys.tagDropdownKey,
                  value: _filter.tag,
                  underline: const SizedBox.shrink(),
                  hint: const Text('全部分类'),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('全部分类'),
                    ),
                    for (final String tag in availableTags)
                      DropdownMenuItem<String?>(
                        value: tag,
                        child: Text(tag),
                      ),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      _filter = _filter.copyWith(tag: value);
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasSources) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Center(
      key: LibraryKeys.emptyKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.menu_book_outlined, size: 56, color: scheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text('还没有书', style: text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasSources
                  ? '已连接书源。去「发现」找书并收听或加入书库。'
                  : '书库包含本机扫描与在线缓存的全部书目。导入网络书源或添加本机听书目录后开始建立书库。',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (hasSources)
              FilledButton.icon(
                key: LibraryKeys.goToDiscoveryKey,
                onPressed: () {
                  ref.read(appTabProvider.notifier).select(AppTab.discovery);
                },
                icon: const Icon(Icons.explore_outlined),
                label: const Text('去发现找书'),
              )
            else
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  FilledButton.icon(
                    key: LibraryKeys.importSourceKey,
                    onPressed: () {
                      unawaited(
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => const SourceImportSheet(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('导入书源'),
                  ),
                  OutlinedButton.icon(
                    key: LibraryKeys.addLocalRootKey,
                    onPressed: () {
                      final String suggested = widget.suggestedRootPath ??
                          defaultRootPathSuggestion();
                      unawaited(
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) =>
                              LibraryAddRootSheet(suggestedPath: suggested),
                        ),
                      );
                    },
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('添加本机目录'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
