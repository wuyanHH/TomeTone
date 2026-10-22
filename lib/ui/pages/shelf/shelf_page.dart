import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/app_tabs.dart';
import 'package:tometone/ui/pages/shelf/book_detail_page.dart';
import 'package:tometone/ui/pages/shelf/open_book_action.dart';
import 'package:tometone/ui/pages/shelf/shelf_book_card.dart';
import 'package:tometone/ui/pages/shelf/shelf_book_row.dart';
import 'package:tometone/ui/pages/shelf/shelf_filter.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 书架（《架构需求文档》§2.1）。
///
/// 职责边界（方案 A）：书架只负责「看与听」，内容来源在「书库」tab 里管理。
///
/// 布局：
/// - 页首是藏馆题头与藏书数量（进入页面先知道"有多少"）；
/// - 题头下方是筛选工具行：可展开的搜索输入、状态 chips（全部 / 在听 /
///   未听 / 已完）、分类与系列弹层（选项从当前书单派生）、布局切换；
/// - 手机纵屏 2 列，`>=600dp` 3 列、`>=960dp` 4 列；
/// - 每一项从上到下是封面 → 书名（最多两行）→ 进度 / 未听 → 缺失提示。
///
/// 三态都直接来自 [booksProvider]：加载中不假装有内容，空态一句话指向
/// 「书库」并给出直达按钮，错误态提供重试（`ref.invalidate`）。筛选只作用于
/// 加载完成后的书单；筛选后的零结果有独立空态与「清除筛选」出口。
class ShelfPage extends ConsumerStatefulWidget {
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

  /// 书籍列表。
  static const Key listKey = Key('shelf-list');

  /// 空态里「去书库添加目录」的引导按钮。
  static const Key goToLibraryKey = Key('shelf-open-library');

  /// 空态里「去发现找书」的引导按钮。
  static const Key goToDiscoveryKey = Key('shelf-open-discovery');

  /// 筛选后零结果的专用空态。
  static const Key filteredEmptyKey = Key('shelf-filtered-empty');

  /// 零结果空态里的「清除筛选」按钮。
  static const Key clearFiltersKey = Key('shelf-clear-filters');

  /// 搜索图标（展开 / 收起搜索输入）。
  static const Key searchToggleKey = Key('shelf-search-toggle');

  /// 展开后的单行搜索输入框。
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
      ValueKey('shelf-status-${status.name}');

  @override
  ConsumerState<ShelfPage> createState() => _ShelfPageState();
}

class _ShelfPageState extends ConsumerState<ShelfPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// 当前筛选（搜索词 / 状态 / 分类 / 系列），只存在内存里。
  ShelfFilterState _filter = const ShelfFilterState();

  /// 布局密度；本轮仅存内存，重新进入页面回落网格。
  ShelfLayout _layout = ShelfLayout.grid;

  /// 搜索输入框是否展开。
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilter(ShelfFilterState next) {
    setState(() => _filter = next);
  }

  /// 清除全部筛选（零结果空态的出口）。
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

  /// 展开 / 收起搜索输入；收起时顺手清空搜索词，避免看不见的隐性筛选。
  void _toggleSearch() {
    final bool opening = !_searchOpen;
    if (!opening && _searchController.text.isNotEmpty) {
      _searchController.clear();
      _filter = _filter.copyWith(query: '');
    }
    setState(() => _searchOpen = opening);
    if (opening) {
      _searchFocus.requestFocus();
    }
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
    final List<BookSummary> visibleBooks = _filter.apply(books);

    // 工具行只在「加载完成且有书」时出现：加载 / 错误 / 全局空态保持原样。
    final bool toolbarVisible = !failed && !loading && books.isNotEmpty;

    // 数量徽标：读取态保持原文案；筛选激活时给出「可见 / 总数」。
    final String countLabel = failed
        ? '读取失败'
        : loading
        ? '正在读取…'
        : _filter.isActive
        ? '${visibleBooks.length} / ${books.length} 册'
        : '${books.length} 册';

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
        // 卡片正文块高度（书名 + 作者·演播 + 一句简介 + 进度 + 缺失提示）：
        // 按最坏情况（含元信息行与缺失提示）预留，避免大字号下溢出。
        final double textBlock = 116 * (textScale < 1 ? 1 : textScale);
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
                countLabel: countLabel,
                searchOpen: _searchOpen,
                layout: _layout,
                onSearchToggle: _toggleSearch,
                onLayoutToggle: () {
                  setState(() {
                    _layout = _layout == ShelfLayout.grid
                        ? ShelfLayout.list
                        : ShelfLayout.grid;
                  });
                },
              ),
            ),
            if (toolbarVisible)
              SliverToBoxAdapter(
                child: _ShelfToolbar(
                  filter: _filter,
                  searchOpen: _searchOpen,
                  searchController: _searchController,
                  searchFocus: _searchFocus,
                  tagOptions: _deriveTagOptions(books),
                  seriesOptions: _deriveSeriesOptions(books),
                  onQueryChanged: (String value) =>
                      _updateFilter(_filter.copyWith(query: value)),
                  onStatusChanged: (ShelfStatusFilter status) =>
                      _updateFilter(_filter.copyWith(status: status)),
                  onTagChanged: (String? tag) =>
                      _updateFilter(_filter.copyWith(tag: tag)),
                  onSeriesChanged: (String? series) =>
                      _updateFilter(_filter.copyWith(series: series)),
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
                  onOpenDiscovery: () {
                    ref.read(appTabProvider.notifier).select(AppTab.discovery);
                  },
                  onOpenLibrary: () {
                    ref.read(appTabProvider.notifier).select(AppTab.library);
                  },
                  onRefresh: () {
                    ref.invalidate(booksProvider);
                    ref.invalidate(libraryRootsProvider);
                  },
                ),
              )
            else if (visibleBooks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ShelfFilteredEmpty(onClear: _clearFilters),
              )
            else if (_layout == ShelfLayout.grid)
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
                  itemCount: visibleBooks.length,
                  itemBuilder: (BuildContext context, int index) {
                    final BookSummary book = visibleBooks[index];
                    return ShelfBookCard(
                      book: book,
                      onOpen: () => _openDetail(context, book),
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
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverList.builder(
                  key: ShelfPage.listKey,
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
      },
    );
  }
}

/// 藏馆题头：单行紧凑题头（标题 + 册数徽标 + 搜索 / 布局操作）。
class _ShelfHeader extends StatelessWidget {
  const _ShelfHeader({
    required this.countLabel,
    required this.searchOpen,
    required this.layout,
    required this.onSearchToggle,
    required this.onLayoutToggle,
    this.trailing,
  });

  /// 册数徽标文案（读取态 / 失败态 / `N 册` / `M / N 册`）。
  final String countLabel;

  /// 搜索输入是否展开（决定搜索按钮的提示文案）。
  final bool searchOpen;

  /// 当前布局密度。
  final ShelfLayout layout;

  /// 展开 / 收起搜索。
  final VoidCallback onSearchToggle;

  /// 切换网格 / 列表。
  final VoidCallback onLayoutToggle;

  /// 右侧附加操作（如更多菜单）。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
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
            Expanded(
              child: Row(
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
              ),
            ),
            IconButton(
              key: ShelfPage.searchToggleKey,
              onPressed: onSearchToggle,
              tooltip: searchOpen ? '收起搜索' : '搜索',
              icon: const Icon(Icons.search_rounded),
            ),
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
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// 筛选工具行：可展开的单行搜索输入 + 状态 chips + 分类 / 系列弹层。
///
/// chips 用 [Wrap] 排布，窄屏与系统大字号下自动折行而不是溢出；
/// 分类与系列的选项由页面从当前书单派生后传入。
class _ShelfToolbar extends StatelessWidget {
  const _ShelfToolbar({
    required this.filter,
    required this.searchOpen,
    required this.searchController,
    required this.searchFocus,
    required this.tagOptions,
    required this.seriesOptions,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.onTagChanged,
    required this.onSeriesChanged,
  });

  /// 当前筛选状态。
  final ShelfFilterState filter;

  /// 搜索输入是否展开。
  final bool searchOpen;

  /// 搜索输入控制器（清除按钮共用）。
  final TextEditingController searchController;

  /// 搜索输入焦点（展开时自动聚焦）。
  final FocusNode searchFocus;

  /// 分类选项（书单标签派生）。
  final List<String> tagOptions;

  /// 系列选项（书单系列派生）。
  final List<String> seriesOptions;

  /// 搜索词变化。
  final ValueChanged<String> onQueryChanged;

  /// 状态切换。
  final ValueChanged<ShelfStatusFilter> onStatusChanged;

  /// 分类切换；`null` 表示不限。
  final ValueChanged<String?> onTagChanged;

  /// 系列切换；`null` 表示不限。
  final ValueChanged<String?> onSeriesChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 搜索输入：收起时高度归零，展开时撑满一行。
          AnimatedSize(
            duration: AppMotion.resolve(context, AppDurations.standard),
            curve: AppDurations.standardCurve,
            alignment: Alignment.topCenter,
            child: searchOpen
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: TextField(
                      key: ShelfPage.searchFieldKey,
                      controller: searchController,
                      focusNode: searchFocus,
                      onChanged: onQueryChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: '搜书名、作者、演播或简介',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: filter.query.trim().isNotEmpty
                            ? IconButton(
                                key: ShelfPage.searchClearKey,
                                onPressed: () {
                                  searchController.clear();
                                  onQueryChanged('');
                                },
                                tooltip: '清除搜索',
                                icon: const Icon(Icons.close_rounded, size: 18),
                              )
                            : null,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              _statusChip(context, '全部', ShelfStatusFilter.all),
              _statusChip(context, '在听', ShelfStatusFilter.listening),
              _statusChip(context, '未听', ShelfStatusFilter.unlistened),
              _statusChip(context, '已完', ShelfStatusFilter.finished),
              _filterMenu(
                context,
                menuKey: ShelfPage.tagFilterKey,
                tooltip: '按分类筛选',
                icon: Icons.sell_outlined,
                label: '分类',
                clearLabel: '不限分类',
                options: tagOptions,
                selectedValue: filter.tag,
                onSelected: onTagChanged,
              ),
              _filterMenu(
                context,
                menuKey: ShelfPage.seriesFilterKey,
                tooltip: '按系列筛选',
                icon: Icons.auto_stories_outlined,
                label: '系列',
                clearLabel: '不限系列',
                options: seriesOptions,
                selectedValue: filter.series,
                onSelected: onSeriesChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 单个状态 chip（选中即过滤，无需确认）。
  Widget _statusChip(
    BuildContext context,
    String label,
    ShelfStatusFilter value,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool selected = filter.status == value;
    return ChoiceChip(
      key: ShelfPage.statusChipKey(value),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onStatusChanged(value),
      labelStyle: text.labelMedium?.copyWith(
        color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
      ),
    );
  }

  /// 分类 / 系列的弹层筛选入口（胶囊按钮 + 下拉菜单）。
  Widget _filterMenu(
    BuildContext context, {
    required Key menuKey,
    required String tooltip,
    required IconData icon,
    required String label,
    required String clearLabel,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String?> onSelected,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool selected =
        selectedValue != null && selectedValue.trim().isNotEmpty;
    final Color foreground = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return PopupMenuButton<String>(
      key: menuKey,
      tooltip: tooltip,
      // 长菜单限高，窄屏不顶出屏幕。
      constraints: const BoxConstraints(maxHeight: 360),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
      // 空字符串是「不限」哨兵：清除该维度。
      onSelected: (String value) => onSelected(value.isEmpty ? null : value),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: '', child: Text(clearLabel)),
        for (final String option in options)
          CheckedPopupMenuItem<String>(
            value: option,
            checked: option == selectedValue,
            child: Text(option),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: ShapeDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHigh,
          shape: StadiumBorder(
            side: selected
                ? BorderSide(color: scheme.primary)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                selected ? '$label · $selectedValue' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelMedium?.copyWith(color: foreground),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.expand_more_rounded, size: 16, color: foreground),
          ],
        ),
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
          constraints: const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
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
                '试试换个关键词，或清除状态、分类与系列筛选。',
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
