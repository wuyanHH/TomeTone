import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/sources/book_source_service.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';

/// 发现页内存状态快照，用于在切换 tab 或页面重建时保留已加载的内容，
/// 避免在没有切换听书源或手动刷新时重复触发全量网络请求与加载菊花。
class DiscoveryCacheState {
  const DiscoveryCacheState({
    this.sources = const <BookSourceListItem>[],
    this.source,
    this.categories = const <ExploreCategory>[],
    this.category,
    this.items = const <SourceBookSummary>[],
    this.statuses = const <String, OnlineBookStatus>{},
    this.searchMode = false,
    this.keyword = '',
    this.page = 1,
    this.hasMore = true,
    this.scrollOffset = 0.0,
    this.isInitialized = false,
  });

  final List<BookSourceListItem> sources;
  final BookSource? source;
  final List<ExploreCategory> categories;
  final ExploreCategory? category;
  final List<SourceBookSummary> items;
  final Map<String, OnlineBookStatus> statuses;
  final bool searchMode;
  final String keyword;
  final int page;
  final bool hasMore;
  final double scrollOffset;
  final bool isInitialized;
}

/// 发现页缓存 Provider。
final discoveryCacheProvider =
    NotifierProvider<DiscoveryCacheNotifier, DiscoveryCacheState>(
  DiscoveryCacheNotifier.new,
);

class DiscoveryCacheNotifier extends Notifier<DiscoveryCacheState> {
  @override
  DiscoveryCacheState build() => const DiscoveryCacheState();

  void update(DiscoveryCacheState state) {
    this.state = state;
  }

  void updateOffset(double offset) {
    if (state.scrollOffset != offset) {
      state = DiscoveryCacheState(
        sources: state.sources,
        source: state.source,
        categories: state.categories,
        category: state.category,
        items: state.items,
        statuses: state.statuses,
        searchMode: state.searchMode,
        keyword: state.keyword,
        page: state.page,
        hasMore: state.hasMore,
        scrollOffset: offset,
        isInitialized: state.isInitialized,
      );
    }
  }

  void reset() {
    state = const DiscoveryCacheState();
  }
}
