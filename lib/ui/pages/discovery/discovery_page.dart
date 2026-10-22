import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/online_providers.dart';
import 'package:tometone/app/providers/source_engine_providers.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/app/sources/book_source_service.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';
import 'package:tometone/domain/sources/discovery/source_failure.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/pages/discovery/discovery_result_tile.dart';
import 'package:tometone/ui/pages/discovery/online_book_preview_page.dart';
import 'package:tometone/ui/pages/discovery/source_switcher_sheet.dart';
import 'package:tometone/ui/pages/sources/source_management_page.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 发现页的稳定测试键。
abstract final class DiscoveryPageKeys {
  static const Key headerTitleKey = Key('discovery-header-title');
  static const Key headerSourcePillKey = Key('discovery-header-source-pill');
  static const Key emptyKey = Key('discovery-empty');
  static const Key importKey = Key('discovery-import');
  static const Key sourceCardKey = Key('discovery-source-card');
  static const Key switchKey = Key('discovery-switch-source');
  static const Key manageKey = Key('discovery-manage-sources');
  static const Key retryKey = Key('discovery-retry');
  static const Key loadingKey = Key('discovery-loading');
  static const Key errorKey = Key('discovery-error');
  static const Key searchFieldKey = Key('discovery-search-field');
  static const Key searchClearKey = Key('discovery-search-clear');
  static const Key resultListKey = Key('discovery-result-list');
  static const Key loadMoreKey = Key('discovery-load-more');
  static const Key errorBannerKey = Key('discovery-error-banner');
  static const Key emptyResultKey = Key('discovery-empty-result');
  static const Key resultErrorKey = Key('discovery-result-error');

  static Key categoryKey(String name) =>
      ValueKey<String>('discovery-category-$name');

  static Key resultTileKey(String bookUrl) =>
      ValueKey<String>('discovery-result-$bookUrl');
}

/// 发现页：加载启用的听书源，显示当前源、分类、搜索结果与分页。
///
/// 发现页只读：结果与预览都不写 `books` / `chapters`，加入书架和播放属于
/// M1-C。每次首屏/切源/切分类/搜索/刷新都会推进 `_generation`，过期响应
/// 直接丢弃，避免旧源或旧关键词覆盖当前列表。
class DiscoveryPage extends ConsumerStatefulWidget {
  /// 创建发现页。
  const DiscoveryPage({super.key});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<BookSourceListItem> _sources = const <BookSourceListItem>[];
  BookSource? _source;
  List<ExploreCategory> _categories = const <ExploreCategory>[];
  ExploreCategory? _category;

  List<SourceBookSummary> _items = const <SourceBookSummary>[];
  Map<String, OnlineBookStatus> _statuses =
      const <String, OnlineBookStatus>{};
  bool _searchMode = false;
  String _keyword = '';
  int _page = 1;
  bool _hasMore = true;
  bool _loadingSources = true;
  bool _loadingPage = false;
  bool _loadingMore = false;
  String? _failure;
  String? _pageFailure;
  String? _bannerMessage;
  String? _loadMoreFailure;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadSources());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter > 200) {
      return;
    }
    if (_items.isEmpty) {
      return;
    }
    unawaited(_loadMore());
  }

  Future<void> _loadSources() async {
    final int generation = ++_generation;
    if (mounted) {
      setState(() {
        _loadingSources = true;
        _failure = null;
      });
    }

    try {
      final List<BookSourceListItem> all = await ref
          .read(bookSourceServiceProvider)
          .listSources();
      final List<BookSourceListItem> enabled = all
          .where(
            (BookSourceListItem item) =>
                !item.source.isDeleted && item.source.enabled,
          )
          .toList(growable: false);
      if (!mounted || generation != _generation) {
        return;
      }

      final String? selectedId = ref.read(selectedSourceIdProvider);
      BookSourceListItem? selected;
      for (final BookSourceListItem item in enabled) {
        if (item.source.id == selectedId) {
          selected = item;
          break;
        }
      }
      selected ??= enabled.isEmpty ? null : enabled.first;

      final List<ExploreCategory> categories = selected == null
          ? const <ExploreCategory>[]
          : parseExploreCategories(
              exploreUrl: selected.source.exploreUrl,
              enabledExplore: selected.source.enabledExplore,
            );

      if (!mounted || generation != _generation) {
        return;
      }
      _searchController.clear();
      setState(() {
        _sources = enabled;
        _source = selected?.source;
        _categories = categories;
        _category = categories.isEmpty ? null : categories.first;
        _searchMode = false;
        _keyword = '';
        _items = const <SourceBookSummary>[];
        _page = 1;
        _hasMore = true;
        _loadingSources = false;
        _loadingPage = false;
        _loadingMore = false;
        _pageFailure = null;
        _bannerMessage = null;
        _loadMoreFailure = null;
      });
      if (selected != null && selected.source.id != selectedId) {
        ref.read(selectedSourceIdProvider.notifier).state = selected.source.id;
      }
      if (selected != null && categories.isNotEmpty) {
        unawaited(_loadFirstPage());
      }
    } on Object {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _loadingSources = false;
        _loadingPage = false;
        _failure = '书源读取失败，请稍后重试。';
      });
    }
  }

  Future<void> _loadFirstPage({bool keepItems = false}) async {
    final BookSource? source = _source;
    if (source == null) {
      return;
    }
    final ExploreCategory? category = _category;
    if (!_searchMode && category == null) {
      return;
    }

    final int generation = ++_generation;
    if (!keepItems) {
      setState(() {
        _items = const <SourceBookSummary>[];
        _statuses = const <String, OnlineBookStatus>{};
        _page = 1;
        _hasMore = true;
        _loadMoreFailure = null;
      });
    }
    setState(() {
      _loadingPage = true;
      _loadingMore = false;
      _pageFailure = null;
      _bannerMessage = null;
      _loadMoreFailure = null;
    });

    try {
      final SourcePage<SourceBookSummary> result = _searchMode
          ? await ref.read(sourceDiscoveryProvider).search(source, _keyword, 1)
          : await ref
                .read(sourceDiscoveryProvider)
                .explore(source, category!, 1);
      if (!mounted || generation != _generation) {
        return;
      }
      final List<SourceBookSummary> items = _dedupe(result.items);
      final Map<String, OnlineBookStatus> statuses =
          await _fetchStatuses(source.id, items);
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _items = items;
        _statuses = statuses;
        _page = 1;
        _hasMore = result.hasMore;
        _loadingPage = false;
        _pageFailure = null;
        _bannerMessage = null;
        _loadMoreFailure = null;
      });
    } on SourceFailure catch (failure) {
      _handleFirstPageFailure(generation, failure.message);
    } on Object {
      _handleFirstPageFailure(generation, '书源请求失败，请稍后重试。');
    }
  }

  void _handleFirstPageFailure(int generation, String message) {
    if (!mounted || generation != _generation) {
      return;
    }
    setState(() {
      _loadingPage = false;
      _loadingMore = false;
      if (_items.isEmpty) {
        _pageFailure = message;
        _bannerMessage = null;
      } else {
        _pageFailure = null;
        _bannerMessage = message;
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loadingPage || _loadingMore || !_hasMore || _loadMoreFailure != null) {
      return;
    }
    final BookSource? source = _source;
    if (source == null) {
      return;
    }
    final ExploreCategory? category = _category;
    if (!_searchMode && category == null) {
      return;
    }

    final int generation = _generation;
    final int page = _page;
    setState(() => _loadingMore = true);

    try {
      final SourcePage<SourceBookSummary> result = _searchMode
          ? await ref
                .read(sourceDiscoveryProvider)
                .search(source, _keyword, page + 1)
          : await ref
                .read(sourceDiscoveryProvider)
                .explore(source, category!, page + 1);
      if (!mounted || generation != _generation) {
        return;
      }
      final Set<String> seen = _items
          .map((SourceBookSummary item) => item.bookUrl)
          .toSet();
      final List<SourceBookSummary> fresh = <SourceBookSummary>[];
      for (final SourceBookSummary item in result.items) {
        if (seen.add(item.bookUrl)) {
          fresh.add(item);
        }
      }
      final Map<String, OnlineBookStatus> newStatuses =
          await _fetchStatuses(source.id, fresh);
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _items = <SourceBookSummary>[..._items, ...fresh];
        _statuses = <String, OnlineBookStatus>{..._statuses, ...newStatuses};
        _page = page + 1;
        _hasMore = result.hasMore && fresh.isNotEmpty;
        _loadingMore = false;
        _loadMoreFailure = null;
      });
    } on SourceFailure catch (failure) {
      _handleLoadMoreFailure(generation, failure.message);
    } on Object {
      _handleLoadMoreFailure(generation, '书源请求失败，请稍后重试。');
    }
  }

  void _handleLoadMoreFailure(int generation, String message) {
    if (!mounted || generation != _generation) {
      return;
    }
    setState(() {
      _loadingMore = false;
      _loadMoreFailure = message;
    });
  }

  void _submitSearch(String value) {
    final String keyword = value.trim();
    if (keyword.isEmpty || _source == null) {
      return;
    }
    FocusScope.of(context).unfocus();
    _searchController.text = keyword;
    setState(() {
      _searchMode = true;
      _keyword = keyword;
      _items = const <SourceBookSummary>[];
      _statuses = const <String, OnlineBookStatus>{};
      _page = 1;
      _hasMore = true;
      _pageFailure = null;
      _bannerMessage = null;
      _loadMoreFailure = null;
    });
    unawaited(_loadFirstPage());
  }

  void _clearSearch() {
    if (!_searchMode) {
      return;
    }
    _searchController.clear();
    setState(() {
      _searchMode = false;
      _keyword = '';
      _items = const <SourceBookSummary>[];
      _statuses = const <String, OnlineBookStatus>{};
      _page = 1;
      _hasMore = true;
      _pageFailure = null;
      _bannerMessage = null;
      _loadMoreFailure = null;
    });
    unawaited(_loadFirstPage());
  }

  Future<void> _refresh() {
    return _loadFirstPage(keepItems: true);
  }

  Future<void> _openManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SourceManagementPage(),
      ),
    );
    if (mounted) {
      await _loadSources();
    }
  }

  Future<void> _openSwitcher() async {
    final SourceSwitcherResult? result = await showSourceSwitcherSheet(
      context: context,
      sources: _sources,
      selectedId: _source?.id,
    );
    if (!mounted || result == null) {
      return;
    }
    if (result.manage) {
      await _openManagement();
      return;
    }
    final String? id = result.sourceId;
    if (id != null) {
      _selectSource(id);
    }
  }

  void _selectSource(String id) {
    BookSourceListItem? selected;
    for (final BookSourceListItem item in _sources) {
      if (item.source.id == id) {
        selected = item;
        break;
      }
    }
    if (selected == null || selected.source.id == _source?.id) {
      return;
    }

    _generation++;
    _searchController.clear();
    final List<ExploreCategory> categories = parseExploreCategories(
      exploreUrl: selected.source.exploreUrl,
      enabledExplore: selected.source.enabledExplore,
    );
    ref.read(selectedSourceIdProvider.notifier).state = id;
    setState(() {
      _source = selected!.source;
      _categories = categories;
      _category = categories.isEmpty ? null : categories.first;
      _searchMode = false;
      _keyword = '';
      _items = const <SourceBookSummary>[];
      _statuses = const <String, OnlineBookStatus>{};
      _page = 1;
      _hasMore = true;
      _loadingPage = false;
      _loadingMore = false;
      _failure = null;
      _pageFailure = null;
      _bannerMessage = null;
      _loadMoreFailure = null;
    });
    if (categories.isNotEmpty) {
      unawaited(_loadFirstPage());
    }
  }

  void _selectCategory(ExploreCategory category) {
    if (_category?.name == category.name &&
        _category?.urlTemplate == category.urlTemplate) {
      return;
    }
    _generation++;
    _searchController.clear();
    setState(() {
      _category = category;
      _searchMode = false;
      _keyword = '';
      _items = const <SourceBookSummary>[];
      _statuses = const <String, OnlineBookStatus>{};
      _page = 1;
      _hasMore = true;
      _loadingPage = false;
      _loadingMore = false;
      _pageFailure = null;
      _bannerMessage = null;
      _loadMoreFailure = null;
    });
    unawaited(_loadFirstPage());
  }

  Future<void> _openPreview(SourceBookSummary item) async {
    final BookSource? source = _source;
    if (source == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            OnlineBookPreviewPage(source: source, item: item),
      ),
    );
    if (!mounted) {
      return;
    }
    await _refreshStatus(source.id, item.bookUrl);
  }

  Future<Map<String, OnlineBookStatus>> _fetchStatuses(
    String sourceId,
    List<SourceBookSummary> items,
  ) async {
    if (items.isEmpty) {
      return const <String, OnlineBookStatus>{};
    }
    try {
      return await ref
          .read(onlineLibraryQueriesProvider)
          .bookStatuses(
            sourceId: sourceId,
            bookUrls: items
                .map((SourceBookSummary item) => item.bookUrl)
                .toList(),
          );
    } on Object {
      return const <String, OnlineBookStatus>{};
    }
  }

  Future<void> _refreshStatus(String sourceId, String bookUrl) async {
    try {
      final Map<String, OnlineBookStatus> result = await ref
          .read(onlineLibraryQueriesProvider)
          .bookStatuses(
            sourceId: sourceId,
            bookUrls: <String>[bookUrl],
          );
      if (!mounted) {
        return;
      }
      setState(() {
        final OnlineBookStatus? status = result[bookUrl];
        if (status != null) {
          _statuses = <String, OnlineBookStatus>{
            ..._statuses,
            bookUrl: status,
          };
        } else if (_statuses.containsKey(bookUrl)) {
          final Map<String, OnlineBookStatus> next =
              Map<String, OnlineBookStatus>.of(_statuses);
          next.remove(bookUrl);
          _statuses = next;
        }
      });
    } on Object {
      // 状态刷新失败静默处理，避免干扰发现页浏览
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(
                          '发现',
                          key: DiscoveryPageKeys.headerTitleKey,
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_source != null) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: _SourceQuickPill(
                            source: _source!,
                            onSwitch: () => unawaited(_openSwitcher()),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_source != null)
                  IconButton(
                    key: DiscoveryPageKeys.manageKey,
                    tooltip: '书源管理',
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () => unawaited(_openManagement()),
                  ),
              ],
            ),
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loadingSources) {
      return const Center(
        key: DiscoveryPageKeys.loadingKey,
        child: CircularProgressIndicator(),
      );
    }
    if (_failure != null) {
      return _ErrorState(message: _failure!, onRetry: _loadSources);
    }
    if (_source == null) {
      return _EmptyState(onImport: _openManagement);
    }
    return _buildSourceBody();
  }

  Widget _buildSourceBody() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(child: _buildSearchAndCategories()),
          if (_searchMode) SliverToBoxAdapter(child: _buildSearchHeader()),
          if (_bannerMessage != null)
            SliverToBoxAdapter(child: _buildErrorBanner()),
          ..._buildResultSlivers(),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
        ],
      ),
    );
  }

  Widget _buildSearchAndCategories() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            key: DiscoveryPageKeys.searchFieldKey,
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: _submitSearch,
            decoration: const InputDecoration(
              hintText: '搜索书名 / 作者',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_categories.isEmpty && !_searchMode)
            Text(
              '该源没有发现分类，试试搜索',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          else if (_categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (final ExploreCategory category in _categories)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        key: DiscoveryPageKeys.categoryKey(category.name),
                        label: Text(category.name),
                        selected: _category?.name == category.name,
                        onSelected: (_) => _selectCategory(category),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '搜索结果 · 来自 ${_source?.name ?? ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            key: DiscoveryPageKeys.searchClearKey,
            tooltip: '清除搜索',
            onPressed: _clearSearch,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        key: DiscoveryPageKeys.errorBannerKey,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadii.xsValue),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '本次加载失败 · ${_bannerMessage ?? ''}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onErrorContainer),
              ),
            ),
            TextButton(
              key: DiscoveryPageKeys.retryKey,
              onPressed: () => unawaited(_refresh()),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResultSlivers() {
    if (_loadingPage && _items.isEmpty) {
      return <Widget>[
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }
    if (_pageFailure != null && _items.isEmpty) {
      return <Widget>[
        SliverToBoxAdapter(
          child: _ResultError(
            key: DiscoveryPageKeys.resultErrorKey,
            message: _pageFailure!,
            onRetry: () => unawaited(_loadFirstPage()),
          ),
        ),
      ];
    }
    if (_items.isEmpty) {
      return <Widget>[
        SliverToBoxAdapter(child: _EmptyResult(searchMode: _searchMode)),
      ];
    }

    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverList(
          key: DiscoveryPageKeys.resultListKey,
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int index,
          ) {
            final SourceBookSummary item = _items[index];
            return DiscoveryResultTile(
              key: DiscoveryPageKeys.resultTileKey(item.bookUrl),
              item: item,
              sourceName: _source?.name ?? '',
              membership: _statuses[item.bookUrl],
              onTap: () => unawaited(_openPreview(item)),
            );
          }, childCount: _items.length),
        ),
      ),
      SliverToBoxAdapter(child: _buildLoadMoreFooter()),
    ];
  }

  Widget _buildLoadMoreFooter() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Container(
        key: DiscoveryPageKeys.loadMoreKey,
        alignment: Alignment.center,
        child: _loadMoreFailure != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '加载下一页失败 · $_loadMoreFailure',
                    style: text.bodySmall?.copyWith(color: scheme.error),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _loadMoreFailure = null);
                      unawaited(_loadMore());
                    },
                    child: const Text('重试'),
                  ),
                ],
              )
            : _loadingMore
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : _hasMore
            ? TextButton(
                onPressed: () => unawaited(_loadMore()),
                child: const Text('加载更多'),
              )
            : Text(
                '已经到底了',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
      ),
    );
  }

  static List<SourceBookSummary> _dedupe(Iterable<SourceBookSummary> items) {
    final Set<String> seen = <String>{};
    final List<SourceBookSummary> unique = <SourceBookSummary>[];
    for (final SourceBookSummary item in items) {
      if (seen.add(item.bookUrl)) {
        unique.add(item);
      }
    }
    return unique;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onImport});

  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Column(
        key: DiscoveryPageKeys.emptyKey,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.travel_explore_rounded, size: 56, color: scheme.primary),
          const SizedBox(height: AppSpacing.lg),
          Text('还没有书源', style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '支持 Legado 听书源 JSON',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            key: DiscoveryPageKeys.importKey,
            onPressed: () => unawaited(onImport()),
            icon: const Icon(Icons.add_rounded),
            label: const Text('导入书源'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      key: DiscoveryPageKeys.errorKey,
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off_rounded, size: 48, color: scheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              key: DiscoveryPageKeys.retryKey,
              onPressed: () => unawaited(onRetry()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.searchMode});

  final bool searchMode;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        key: DiscoveryPageKeys.emptyResultKey,
        children: <Widget>[
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            searchMode ? '换个关键词' : '该分类暂无书目',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ResultError extends StatelessWidget {
  const _ResultError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.cloud_off_rounded, size: 48, color: scheme.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            '加载失败 · $message',
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            key: DiscoveryPageKeys.retryKey,
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

/// 顶栏书源快捷切换胶囊。
class _SourceQuickPill extends StatelessWidget {
  const _SourceQuickPill({
    required this.source,
    required this.onSwitch,
  });

  final BookSource source;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    final bool hasFailure = source.lastTestOk == false && source.consecutiveFailures > 0;
    final Color statusColor = hasFailure ? scheme.error : const Color(0xFF4CAF50);

    return Semantics(
      button: true,
      label: '当前书源：${source.name}，点击切换',
      child: Container(
        key: DiscoveryPageKeys.headerSourcePillKey,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: DiscoveryPageKeys.switchKey,
            onTap: onSwitch,
            borderRadius: AppRadii.pill,
            child: Ink(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: AppRadii.pill,
                border: Border.all(
                  color: hasFailure
                      ? scheme.error.withValues(alpha: 0.5)
                      : scheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      source.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (hasFailure) ...<Widget>[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '连续失败 ${source.consecutiveFailures} 次',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          color: scheme.error,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
