import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/online_providers.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/app_tabs.dart';
import 'package:tometone/ui/pages/shelf/book_detail_page.dart';
import 'package:tometone/ui/pages/shelf/open_book_action.dart';
import 'package:tometone/ui/pages/shelf/shelf_book_card.dart';
import 'package:tometone/ui/pages/shelf/shelf_book_row.dart';
import 'package:tometone/ui/pages/shelf/shelf_filter.dart';
import 'package:tometone/ui/pages/shelf/shelf_series_management_sheet.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'package:tometone/ui/widgets/search_filter_bar.dart';

/// 书架（《架构需求文档》§2.1）。
///
/// 职责边界（方案 A）：书架只负责「看与听」，内容来源在「书库」tab 里管理。
///
/// 布局与导航：
/// - 顶部系列导航（TabBar 横向滑动切页 / Dropdown 下拉选择框）；
/// - 一体化 [SearchFilterBar] 搜索与筛选卡片，收纳收听状态、来源渠道与分类标签；
/// - 手机纵屏 2 列，`>=600dp` 3 列、`>=960dp` 4 列；
/// - 每一项从上到下是封面 → 书名（最多两行）→ 进度 / 未听 → 缺失提示。
class ShelfPage extends ConsumerStatefulWidget {
  /// 创建书架。
  const ShelfPage({super.key});

  /// 全部系列固定标识符。
  static const String kSeriesAll = '__all__';

  /// 未分类（单本）系列固定标识符。
  static const String kSeriesUncategorized = '__uncategorized__';

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

  /// 书籍列表。
  static const Key listKey = Key('shelf-list');

  /// 更多设置菜单（列数、字段显隐与管理系列入口）。
  static const Key moreMenuKey = Key('shelf-more-menu');

  /// 空态里「去书库添加目录」的引导按钮。
  static const Key goToLibraryKey = Key('shelf-open-library');

  /// 空态里「去发现找书」的引导按钮。
  static const Key goToDiscoveryKey = Key('shelf-open-discovery');

  /// 筛选后零结果的专用空态。
  static const Key filteredEmptyKey = Key('shelf-filtered-empty');

  /// 零结果空态里的「清除筛选」按钮。
  static const Key clearFiltersKey = Key('shelf-clear-filters');

  /// 搜索图标（展开 / 聚焦搜索输入）。
  static const Key searchToggleKey = Key('shelf-search-toggle');

  /// 单行搜索输入框。
  static const Key searchFieldKey = Key('shelf-search-field');

  /// 有搜索词时输入框尾部的清除按钮。
  static const Key searchClearKey = Key('shelf-search-clear');

  /// 分类（标签）筛选入口。
  static const Key tagFilterKey = Key('shelf-tag-filter');

  /// 系列筛选入口。
  static const Key seriesFilterKey = Key('shelf-series-filter');

  /// 布局切换（网格 / 列表）按钮。
  static const Key layoutToggleKey = Key('shelf-layout-toggle');

  /// 状态筛选 chip 的稳定 key（`shelf-status-<枚举名>`）。
  static Key statusChipKey(ShelfStatusFilter status) =>
      ValueKey<String>('shelf-status-${status.name}');

  /// 系列导航 TabBar 的 key。
  static const Key seriesTabBarKey = Key('shelf-series-tab-bar');

  /// 单个系列 Tab 的 key。
  static Key seriesTabKey(String series) =>
      ValueKey<String>('shelf-series-tab-$series');

  /// 系列下拉选择框标题按钮的 key。
  static const Key seriesDropdownKey = Key('shelf-series-dropdown');

  /// 系列下拉选择项的 key。
  static Key seriesDropdownItemKey(String series) =>
      ValueKey<String>('shelf-series-dropdown-item-$series');

  /// 一体化搜索筛选条的 key。
  static const Key filterBarKey = Key('shelf-search-filter-bar');

  /// 筛选折叠卡片触发按钮的 key。
  static const Key filterToggleKey = Key('shelf-filter-toggle');

  /// 筛选重置按钮的 key。
  static const Key resetFilterKey = Key('shelf-reset-filter');

  /// 筛选面板收起按钮的 key。
  static const Key collapseFilterKey = Key('shelf-collapse-filter');

  /// 来源渠道 chip 的 key。
  static Key sourceChipKey(ShelfSourceFilter source) =>
      ValueKey<String>('shelf-source-${source.name}');

  /// 分类标签 chip 的 key。
  static Key tagChipKey(String? tag) =>
      ValueKey<String>('shelf-tag-${tag ?? "all"}');

  /// 计算可见系列列表（结合偏好过滤、排序与防空保底）。
  static List<String> calculateVisibleSeries({
    required List<String> allAvailableSeries,
    required AppPreferences prefs,
  }) {
    final List<String> ordered = _computeOrderedSeries(
      allAvailableSeries,
      prefs.shelfSeriesOrder,
    );
    final List<String> result = <String>[];
    if (prefs.shelfShowAllSeriesTab) {
      result.add(kSeriesAll);
    }
    if (prefs.shelfShowUncategorizedSeriesTab) {
      result.add(kSeriesUncategorized);
    }
    final Set<String> hidden = prefs.shelfHiddenSeries.toSet();
    for (final String s in ordered) {
      if (!hidden.contains(s)) {
        result.add(s);
      }
    }
    if (result.isEmpty) {
      result.add(kSeriesAll);
    }
    return result;
  }

  static List<String> _computeOrderedSeries(
    List<String> allAvailable,
    List<String> savedOrder,
  ) {
    final List<String> result = <String>[];
    final Set<String> availableSet = allAvailable.toSet();

    for (final String s in savedOrder) {
      if (availableSet.contains(s) && !result.contains(s)) {
        result.add(s);
      }
    }
    for (final String s in allAvailable) {
      if (!result.contains(s)) {
        result.add(s);
      }
    }
    return result;
  }

  /// 系列展示文案。
  static String seriesDisplayName(String series) {
    if (series == kSeriesAll) return '全部';
    if (series == kSeriesUncategorized) return '未分类';
    return series;
  }

  /// 过滤特定系列的书籍。
  static List<BookSummary> booksForSeries(
    List<BookSummary> books,
    String series,
  ) {
    if (series == kSeriesAll) {
      return books;
    }
    if (series == kSeriesUncategorized) {
      return books.where((BookSummary b) {
        final String? name = b.seriesName?.trim();
        return name == null || name.isEmpty;
      }).toList();
    }
    return books
        .where((BookSummary b) => b.seriesName?.trim() == series)
        .toList();
  }

  /// 计算特定系列在书架中的总册数（用于 Tab 稳定徽标）。
  static int countForSeries(List<BookSummary> books, String series) {
    return booksForSeries(books, series).length;
  }

  @override
  ConsumerState<ShelfPage> createState() => _ShelfPageState();
}

class _ShelfPageState extends ConsumerState<ShelfPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// 当前筛选（搜索词 / 状态 / 来源 / 标签），只存在内存里。
  ShelfFilterState _filter = const ShelfFilterState();

  /// 布局密度；本轮仅存内存，重新进入页面回落网格。
  ShelfLayout _layout = ShelfLayout.grid;

  TabController? _tabController;
  int _currentSeriesIndex = 0;
  List<String> _currentVisibleSeries = const <String>[];

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController != null &&
        _tabController!.index != _currentSeriesIndex) {
      setState(() {
        _currentSeriesIndex = _tabController!.index;
      });
    }
  }

  void _syncTabController(List<String> visibleSeries) {
    if (_tabController == null ||
        _tabController!.length != visibleSeries.length ||
        !_listEquals(_currentVisibleSeries, visibleSeries)) {
      _currentVisibleSeries = List<String>.from(visibleSeries);
      final int initialIndex =
          _currentSeriesIndex.clamp(0, visibleSeries.length - 1);
      _tabController?.removeListener(_onTabChanged);
      _tabController?.dispose();
      _tabController = TabController(
        length: visibleSeries.length,
        vsync: this,
        initialIndex: initialIndex,
      );
      _currentSeriesIndex = initialIndex;
      _tabController!.addListener(_onTabChanged);
    }
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _updateFilter(ShelfFilterState next) {
    setState(() => _filter = next);
  }

  /// 清除全部筛选（零结果空态与重置按钮的出口）。
  void _clearFilters() {
    _searchController.clear();
    setState(() => _filter = const ShelfFilterState());
  }

  /// 点卡片进详情；播放按钮走 [playBookFromSummary] 直接起播。
  void _openDetail(BuildContext context, BookSummary book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BookDetailPage(bookId: book.id),
      ),
    );
  }

  int _calculateActiveFilterCount(ShelfFilterState filter) {
    int count = 0;
    if (filter.query.trim().isNotEmpty) {
      count++;
    }
    if (filter.status != ShelfStatusFilter.all) {
      count++;
    }
    if (filter.source != ShelfSourceFilter.all) {
      count++;
    }
    if (filter.tag != null && filter.tag!.trim().isNotEmpty) {
      count++;
    }
    return count;
  }

  /// 从书单派生分类选项：标签跨书去重（大小写折叠），保留首次出现的原文。
  static List<String> _deriveTagOptions(List<BookSummary> books) {
    final Map<String, String> seen = <String, String>{};
    for (final BookSummary book in books) {
      for (final String tag in book.tags) {
        final String key = tag.trim().toLowerCase();
        if (key.isNotEmpty) {
          seen.putIfAbsent(key, tag.trim);
        }
      }
    }
    return seen.values.toList()..sort();
  }

  /// 从书单派生系列选项（原文去重排序）。
  static List<String> _deriveSeriesOptions(List<BookSummary> books) {
    final Set<String> names = <String>{};
    for (final BookSummary book in books) {
      final String? name = book.seriesName?.trim();
      if (name != null && name.isNotEmpty) {
        names.add(name);
      }
    }
    return names.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<BookSummary>> booksAsync = ref.watch(
      shelfBooksProvider,
    );
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
    final AppPreferences prefs = ref.watch(preferencesProvider);

    final List<String> allAvailableSeries = _deriveSeriesOptions(books);
    final List<String> visibleSeries = ShelfPage.calculateVisibleSeries(
      allAvailableSeries: allAvailableSeries,
      prefs: prefs,
    );

    _syncTabController(visibleSeries);

    final bool hasBooks = !failed && !loading && books.isNotEmpty;

    final String countLabel = failed
        ? '读取失败'
        : loading
            ? '正在读取…'
            : '${books.length} 册';

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final int columns;
        if (width >= 960) {
          columns = prefs.shelfColumns == 2 ? 2 : 4;
        } else if (width >= AppSizes.wideBreakpoint) {
          columns = prefs.shelfColumns == 2
              ? 2
              : (prefs.shelfColumns == 4 ? 4 : 3);
        } else {
          columns = prefs.shelfColumns.clamp(2, 4);
        }
        final double tileWidth =
            (width - AppSpacing.lg * 2 - AppSpacing.md * (columns - 1)) /
            columns;
        final double textScale = MediaQuery.textScalerOf(context).scale(1);
        final double scale = textScale < 1 ? 1 : textScale;
        double textBlock = 0;
        if (prefs.shelfShowTitle) {
          textBlock += 30 * scale + AppSpacing.xs;
        }
        if (prefs.shelfShowAuthor || prefs.shelfShowNarrator) {
          textBlock += 24 * scale + AppSpacing.xxs;
        }
        // 预留告警行空间（如章节缺失、来源停用）
        textBlock += 26 * scale + AppSpacing.xs;
        final double coverHeight = tileWidth * 1.5;
        final SliverGridDelegate delegate =
            SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: tileWidth / (coverHeight + textBlock),
        );

        final Widget headerWidget = _ShelfHeader(
          countLabel: countLabel,
          hasBooks: hasBooks,
          navMode: prefs.shelfSeriesNavMode,
          visibleSeries: visibleSeries,
          currentSeriesIndex: _currentSeriesIndex,
          tabController: _tabController,
          books: books,
          allAvailableSeries: allAvailableSeries,
          layout: _layout,
          prefs: prefs,
          onSeriesSelected: (int index) {
            setState(() {
              _currentSeriesIndex = index;
              _tabController?.animateTo(index);
            });
          },
          onLayoutToggle: () {
            setState(() {
              _layout = _layout == ShelfLayout.grid
                  ? ShelfLayout.list
                  : ShelfLayout.grid;
            });
          },
          onPrefsChanged: (AppPreferences newPrefs) {
            ref.read(preferencesProvider.notifier).replace(newPrefs);
          },
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            headerWidget,
            if (!failed && !loading)
              SearchFilterBar(
                key: ShelfPage.filterBarKey,
                searchFieldKey: ShelfPage.searchFieldKey,
                searchClearKey: ShelfPage.searchClearKey,
                searchToggleKey: ShelfPage.searchToggleKey,
                filterButtonKey: ShelfPage.filterToggleKey,
                controller: _searchController,
                focusNode: _searchFocus,
                hintText: '搜书名、作者、演播或简介',
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                onQueryChanged: (String value) =>
                    _updateFilter(_filter.copyWith(query: value)),
                activeFilterCount: _calculateActiveFilterCount(_filter),
                filterPanelBuilder: (BuildContext context) =>
                    _buildFilterPanel(context, _deriveTagOptions(books)),
              ),
            Expanded(
              child: failed
                  ? SingleChildScrollView(
                      child: _ShelfError(
                        onRetry: () {
                          ref.invalidate(booksProvider);
                          ref.invalidate(libraryRootsProvider);
                        },
                      ),
                    )
                  : loading
                      ? CustomScrollView(
                          slivers: <Widget>[
                            const SliverToBoxAdapter(
                              child: _ShelfLoadingLine(),
                            ),
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
                                itemBuilder:
                                    (BuildContext context, int index) {
                                  return const _ShelfSkeletonTile();
                                },
                              ),
                            ),
                          ],
                        )
                      : books.isEmpty
                          ? SingleChildScrollView(
                              child: _ShelfEmpty(
                                onOpenDiscovery: () {
                                  ref
                                      .read(appTabProvider.notifier)
                                      .select(AppTab.discovery);
                                },
                                onOpenLibrary: () {
                                  ref
                                      .read(appTabProvider.notifier)
                                      .select(AppTab.library);
                                },
                                onRefresh: () {
                                  ref.invalidate(booksProvider);
                                  ref.invalidate(libraryRootsProvider);
                                },
                              ),
                            )
                          : prefs.shelfSeriesNavMode ==
                                  ShelfSeriesNavMode.tabs
                              ? TabBarView(
                                  controller: _tabController,
                                  children: <Widget>[
                                    for (int i = 0;
                                        i < visibleSeries.length;
                                        i++)
                                      _buildSeriesPage(
                                        context: context,
                                        series: visibleSeries[i],
                                        books: books,
                                        delegate: delegate,
                                        isCurrentPage:
                                            i == _currentSeriesIndex,
                                      ),
                                  ],
                                )
                              : _buildSeriesPage(
                                  context: context,
                                  series: visibleSeries[_currentSeriesIndex
                                      .clamp(0, visibleSeries.length - 1)],
                                  books: books,
                                  delegate: delegate,
                                  isCurrentPage: true,
                                ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeriesPage({
    required BuildContext context,
    required String series,
    required List<BookSummary> books,
    required SliverGridDelegate delegate,
    required bool isCurrentPage,
  }) {
    final List<BookSummary> seriesBooks =
        ShelfPage.booksForSeries(books, series);
    final List<BookSummary> visibleBooks = _filter.apply(seriesBooks);

    if (visibleBooks.isEmpty) {
      return _ShelfFilteredEmpty(onClear: _clearFilters);
    }

    if (_layout == ShelfLayout.grid) {
      return CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            sliver: SliverGrid.builder(
              key: isCurrentPage
                  ? ShelfPage.gridKey
                  : ValueKey<String>('shelf-grid-$series'),
              gridDelegate: delegate,
              itemCount: visibleBooks.length,
              itemBuilder: (BuildContext context, int index) {
                final BookSummary book = visibleBooks[index];
                return ShelfBookCard(
                  book: book,
                  onOpen: () => _openDetail(context, book),
                  onLongPress: () => _showBookActions(context, book),
                  onPlay: () => unawaited(
                    playBookFromSummary(
                      context: context,
                      ref: ref,
                      book: book,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else {
      return CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            sliver: SliverList.builder(
              key: isCurrentPage
                  ? ShelfPage.listKey
                  : ValueKey<String>('shelf-list-$series'),
              itemCount: visibleBooks.length,
              itemBuilder: (BuildContext context, int index) {
                final BookSummary book = visibleBooks[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == visibleBooks.length - 1
                        ? 0
                        : AppSpacing.md,
                  ),
                  child: ShelfBookRow(
                    book: book,
                    onOpen: () => _openDetail(context, book),
                    onLongPress: () => _showBookActions(context, book),
                    onPlay: () => unawaited(
                      playBookFromSummary(
                        context: context,
                        ref: ref,
                        book: book,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildFilterPanel(BuildContext context, List<String> tagOptions) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SearchFilterGroup.wrap(
          title: '收听状态',
          children: <Widget>[
            SearchFilterChip(
              key: ShelfPage.statusChipKey(ShelfStatusFilter.all),
              label: '全部',
              selected: _filter.status == ShelfStatusFilter.all,
              onTap: () => _updateFilter(
                _filter.copyWith(status: ShelfStatusFilter.all),
              ),
            ),
            SearchFilterChip(
              key: ShelfPage.statusChipKey(ShelfStatusFilter.listening),
              label: '在听',
              selected: _filter.status == ShelfStatusFilter.listening,
              onTap: () => _updateFilter(
                _filter.copyWith(status: ShelfStatusFilter.listening),
              ),
            ),
            SearchFilterChip(
              key: ShelfPage.statusChipKey(ShelfStatusFilter.unlistened),
              label: '未听',
              selected: _filter.status == ShelfStatusFilter.unlistened,
              onTap: () => _updateFilter(
                _filter.copyWith(status: ShelfStatusFilter.unlistened),
              ),
            ),
            SearchFilterChip(
              key: ShelfPage.statusChipKey(ShelfStatusFilter.finished),
              label: '已完',
              selected: _filter.status == ShelfStatusFilter.finished,
              onTap: () => _updateFilter(
                _filter.copyWith(status: ShelfStatusFilter.finished),
              ),
            ),
          ],
        ),
        SearchFilterGroup.wrap(
          title: '来源渠道',
          children: <Widget>[
            SearchFilterChip(
              key: ShelfPage.sourceChipKey(ShelfSourceFilter.all),
              label: '全部来源',
              selected: _filter.source == ShelfSourceFilter.all,
              onTap: () => _updateFilter(
                _filter.copyWith(source: ShelfSourceFilter.all),
              ),
            ),
            SearchFilterChip(
              key: ShelfPage.sourceChipKey(ShelfSourceFilter.local),
              label: '本地音频',
              selected: _filter.source == ShelfSourceFilter.local,
              onTap: () => _updateFilter(
                _filter.copyWith(source: ShelfSourceFilter.local),
              ),
            ),
            SearchFilterChip(
              key: ShelfPage.sourceChipKey(ShelfSourceFilter.online),
              label: '在线网络源',
              selected: _filter.source == ShelfSourceFilter.online,
              onTap: () => _updateFilter(
                _filter.copyWith(source: ShelfSourceFilter.online),
              ),
            ),
          ],
        ),
        if (tagOptions.isNotEmpty)
          SearchFilterGroup.wrap(
            title: '分类标签',
            children: <Widget>[
              SearchFilterChip(
                key: ShelfPage.tagChipKey(null),
                label: '不限',
                selected: _filter.tag == null,
                onTap: () => _updateFilter(_filter.copyWith(tag: null)),
              ),
              for (final String tag in tagOptions)
                SearchFilterChip(
                  key: ShelfPage.tagChipKey(tag),
                  label: tag,
                  selected: _filter.tag == tag,
                  onTap: () => _updateFilter(
                    _filter.copyWith(
                      tag: _filter.tag == tag ? null : tag,
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            TextButton.icon(
              key: ShelfPage.resetFilterKey,
              onPressed: _clearFilters,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('重置筛选'),
            ),
            const Spacer(),
            TextButton.icon(
              key: ShelfPage.collapseFilterKey,
              onPressed: () {
                SearchFilterBarScope.maybeOf(context)?.collapse();
              },
              icon: const Icon(Icons.expand_less_rounded, size: 18),
              label: const Text('收起'),
            ),
          ],
        ),
      ],
    );
  }

  void _showBookActions(BuildContext context, BookSummary book) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(book.title),
                subtitle: Text(
                  (book.author?.trim().isNotEmpty ?? false)
                      ? book.author!
                      : '查看详情与目录',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openDetail(context, book);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.bookmark_remove_outlined),
                title: const Text('移出书架'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final bool? confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('移出书架'),
                        content:
                            Text('确定将《${book.title}》移出书架？\n（不会删除本地音频文件）'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
                            child: const Text('确定移出'),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirmed == true && mounted) {
                    await ref
                        .read(onlineLibraryQueriesProvider)
                        .setBookShelf(book.id, onShelf: false);
                    ref.invalidate(booksProvider);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 藏馆题头：系列导航（TabBar / Dropdown）+ 布局切换 + 更多设置（含管理系列）。
class _ShelfHeader extends StatelessWidget {
  const _ShelfHeader({
    required this.countLabel,
    required this.hasBooks,
    required this.navMode,
    required this.visibleSeries,
    required this.currentSeriesIndex,
    required this.tabController,
    required this.books,
    required this.allAvailableSeries,
    required this.layout,
    required this.prefs,
    required this.onSeriesSelected,
    required this.onLayoutToggle,
    required this.onPrefsChanged,
  });

  final String countLabel;
  final bool hasBooks;
  final ShelfSeriesNavMode navMode;
  final List<String> visibleSeries;
  final int currentSeriesIndex;
  final TabController? tabController;
  final List<BookSummary> books;
  final List<String> allAvailableSeries;
  final ShelfLayout layout;
  final AppPreferences prefs;
  final ValueChanged<int> onSeriesSelected;
  final VoidCallback onLayoutToggle;
  final ValueChanged<AppPreferences> onPrefsChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;

    Widget titleOrSeriesNav;

    if (!hasBooks) {
      titleOrSeriesNav = Row(
        children: <Widget>[
          Flexible(
            child: Semantics(
              header: true,
              child: Text(
                '我的书架',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            countLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    } else if (navMode == ShelfSeriesNavMode.tabs && tabController != null) {
      titleOrSeriesNav = TabBar(
        key: ShelfPage.seriesTabBarKey,
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: <Widget>[
          for (int i = 0; i < visibleSeries.length; i++)
            _buildTab(
              context: context,
              series: visibleSeries[i],
              isSelected: currentSeriesIndex == i,
              count: ShelfPage.countForSeries(books, visibleSeries[i]),
            ),
        ],
      );
    } else {
      final String currentSeries = visibleSeries[
          currentSeriesIndex.clamp(0, visibleSeries.length - 1)];
      final String displayName = ShelfPage.seriesDisplayName(currentSeries);
      final int count = ShelfPage.countForSeries(books, currentSeries);

      titleOrSeriesNav = Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          key: ShelfPage.seriesDropdownKey,
          borderRadius: AppRadii.md,
          onTap: () => _showDropdownPicker(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    displayName,
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: AppRadii.pill,
                  ),
                  child: Text(
                    '$count',
                    style: text.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
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
            Expanded(child: titleOrSeriesNav),
            IconButton(
              key: ShelfPage.layoutToggleKey,
              onPressed: onLayoutToggle,
              tooltip: layout == ShelfLayout.grid ? '切换为列表视图' : '切换为网格视图',
              icon: Icon(
                layout == ShelfLayout.grid
                    ? Icons.grid_view_rounded
                    : Icons.view_list_rounded,
              ),
            ),
            PopupMenuButton<String>(
              key: ShelfPage.moreMenuKey,
              tooltip: '书架设置',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (String value) {
                switch (value) {
                  case 'col-2':
                    onPrefsChanged(prefs.copyWith(shelfColumns: 2));
                    if (layout == ShelfLayout.list) onLayoutToggle();
                    break;
                  case 'col-3':
                    onPrefsChanged(prefs.copyWith(shelfColumns: 3));
                    if (layout == ShelfLayout.list) onLayoutToggle();
                    break;
                  case 'col-4':
                    onPrefsChanged(prefs.copyWith(shelfColumns: 4));
                    if (layout == ShelfLayout.list) onLayoutToggle();
                    break;
                  case 'layout-list':
                    if (layout == ShelfLayout.grid) onLayoutToggle();
                    break;
                  case 'toggle-title':
                    onPrefsChanged(
                      prefs.copyWith(shelfShowTitle: !prefs.shelfShowTitle),
                    );
                    break;
                  case 'toggle-author':
                    onPrefsChanged(
                      prefs.copyWith(
                          shelfShowAuthor: !prefs.shelfShowAuthor),
                    );
                    break;
                  case 'toggle-narrator':
                    onPrefsChanged(
                      prefs.copyWith(
                        shelfShowNarrator: !prefs.shelfShowNarrator,
                      ),
                    );
                    break;
                  case 'manage-series':
                    ShelfSeriesManagementSheet.show(
                      context,
                      allAvailableSeries: allAvailableSeries,
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<String>>[
                CheckedPopupMenuItem<String>(
                  value: 'col-2',
                  checked:
                      layout == ShelfLayout.grid && prefs.shelfColumns == 2,
                  child: const Text('2 列'),
                ),
                CheckedPopupMenuItem<String>(
                  value: 'col-3',
                  checked:
                      layout == ShelfLayout.grid && prefs.shelfColumns == 3,
                  child: const Text('3 列'),
                ),
                CheckedPopupMenuItem<String>(
                  value: 'col-4',
                  checked:
                      layout == ShelfLayout.grid && prefs.shelfColumns == 4,
                  child: const Text('4 列'),
                ),
                CheckedPopupMenuItem<String>(
                  value: 'layout-list',
                  checked: layout == ShelfLayout.list,
                  child: const Text('列表视图'),
                ),
                const PopupMenuDivider(),
                CheckedPopupMenuItem<String>(
                  value: 'toggle-title',
                  checked: prefs.shelfShowTitle,
                  child: const Text('显示书名'),
                ),
                CheckedPopupMenuItem<String>(
                  value: 'toggle-author',
                  checked: prefs.shelfShowAuthor,
                  child: const Text('显示作者'),
                ),
                CheckedPopupMenuItem<String>(
                  value: 'toggle-narrator',
                  checked: prefs.shelfShowNarrator,
                  child: const Text('显示演播'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'manage-series',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.tune_rounded, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text('管理系列'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required String series,
    required bool isSelected,
    required int count,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String displayName = ShelfPage.seriesDisplayName(series);

    return Tab(
      key: ShelfPage.seriesTabKey(series),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            displayName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.primary.withValues(alpha: 0.15)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: AppRadii.pill,
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color:
                    isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDropdownPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        final ColorScheme scheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Text(
                  '选择系列',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: visibleSeries.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String series = visibleSeries[index];
                    final bool isSelected = index == currentSeriesIndex;
                    final int count =
                        ShelfPage.countForSeries(books, series);
                    return ListTile(
                      key: ShelfPage.seriesDropdownItemKey(series),
                      selected: isSelected,
                      leading: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color:
                            isSelected ? scheme.primary : scheme.outline,
                      ),
                      title: Text(
                        ShelfPage.seriesDisplayName(series),
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(
                        '$count 册',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onSeriesSelected(index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: AppRadii.md,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        bar(0.8, 14),
        const SizedBox(height: AppSpacing.xs),
        bar(0.45, 12),
      ],
    );
  }
}

/// 空态：不假装能扫描，给出「发现」与「书库」两个直达入口。
class _ShelfEmpty extends StatelessWidget {
  const _ShelfEmpty({
    required this.onOpenDiscovery,
    required this.onOpenLibrary,
    required this.onRefresh,
  });

  /// 跳到「发现」tab。
  final VoidCallback onOpenDiscovery;

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
          constraints:
              const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
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
                '书架还空着：去「发现」找在线书，或去「书库」添加一个目录，扫描完成后书目就会出现在这里。',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  FilledButton.icon(
                    key: ShelfPage.goToDiscoveryKey,
                    onPressed: onOpenDiscovery,
                    icon: const Icon(Icons.explore_outlined, size: 18),
                    label: const Text('去发现找书'),
                  ),
                  OutlinedButton.icon(
                    key: ShelfPage.goToLibraryKey,
                    onPressed: onOpenLibrary,
                    icon: const Icon(Icons.folder_special_outlined, size: 18),
                    label: const Text('去「书库」添加目录'),
                  ),
                ],
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

/// 筛选后零结果：保留筛选工具行，只替换列表区域，并给一个清除入口。
class _ShelfFilteredEmpty extends StatelessWidget {
  const _ShelfFilteredEmpty({required this.onClear});

  /// 清除全部筛选。
  final VoidCallback onClear;

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
          constraints:
              const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
          child: Column(
            key: ShelfPage.filteredEmptyKey,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: AppRadii.xl,
                ),
                child: SizedBox.square(
                  dimension: 64,
                  child: Icon(
                    Icons.filter_alt_off_outlined,
                    size: 30,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('没有符合条件的书', style: text.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '试试换个关键词，或清除状态、渠道与标签筛选。',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonalIcon(
                key: ShelfPage.clearFiltersKey,
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('清除筛选'),
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
            Text('书架读取失败', style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '可能是音频目录未就绪或存储权限受阻。',
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonalIcon(
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
