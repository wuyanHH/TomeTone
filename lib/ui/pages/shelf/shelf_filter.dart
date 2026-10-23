import 'package:tometone/domain/library/queries/library_views.dart';

/// 书架收听状态筛选。
enum ShelfStatusFilter {
  /// 全部藏书。
  all,

  /// 在听：有进度且未听完。
  listening,

  /// 未听：还没有任何进度。
  unlistened,

  /// 已完：已听完。
  finished,
}

/// 书架藏书来源类型筛选。
enum ShelfSourceFilter {
  /// 全部藏书（本地与在线）。
  all,

  /// 仅本地音频。
  local,

  /// 仅在线网络书源。
  online,
}

/// 书架布局密度（本轮只存内存）。
enum ShelfLayout {
  /// 双列藏书格。
  grid,

  /// 单列信息卡。
  list,
}

/// 书架筛选状态：搜索词 + 状态 + 来源 + 标签 + 系列，组合为 AND。
///
/// 各维度的比较口径：
/// - 搜索：小写化后对书名 / 作者 / 演播 / 系列 / 简介做 contains；
/// - 状态：`listening => hasProgress && !isFinished`、`unlistened =>
///   !hasProgress`、`finished => isFinished`；
/// - 来源：`local => !isOnline`、`online => isOnline`；
/// - 标签：大小写折叠后相等；
/// - 系列：按原文（trim 后）相等。
class ShelfFilterState {
  /// 创建筛选状态；默认全部维度关闭。
  const ShelfFilterState({
    this.query = '',
    this.status = ShelfStatusFilter.all,
    this.source = ShelfSourceFilter.all,
    this.tag,
    this.series,
  });

  /// 搜索词（书名 / 作者 / 演播 / 系列 / 简介，大小写不敏感）。
  final String query;

  /// 收听状态。
  final ShelfStatusFilter status;

  /// 藏书来源类型。
  final ShelfSourceFilter source;

  /// 标签（大小写折叠比较）。
  final String? tag;

  /// 系列（原文比较）。
  final String? series;

  /// 任一维度偏离默认值即激活（数量徽标与零结果空态的判定依据）。
  ///
  /// 空白字符串视为未设置，避免「看不见的筛选」。
  bool get isActive =>
      query.trim().isNotEmpty ||
      status != ShelfStatusFilter.all ||
      source != ShelfSourceFilter.all ||
      _present(tag) ||
      _present(series);

  /// 把筛选应用到书单，返回命中的书（保持原有顺序）。
  List<BookSummary> apply(List<BookSummary> books) {
    final String needle = query.trim().toLowerCase();
    return <BookSummary>[
      for (final BookSummary book in books)
        if (_matches(book, needle)) book,
    ];
  }

  /// 复制并替换部分字段；tag / series 传 `null` 表示清除该维度。
  ShelfFilterState copyWith({
    String? query,
    ShelfStatusFilter? status,
    ShelfSourceFilter? source,
    Object? tag = _unset,
    Object? series = _unset,
  }) {
    return ShelfFilterState(
      query: query ?? this.query,
      status: status ?? this.status,
      source: source ?? this.source,
      tag: identical(tag, _unset) ? this.tag : tag as String?,
      series: identical(series, _unset) ? this.series : series as String?,
    );
  }

  bool _matches(BookSummary book, String needle) {
    // 来源：本地 vs 在线。
    switch (source) {
      case ShelfSourceFilter.all:
        break;
      case ShelfSourceFilter.local:
        if (book.isOnline) {
          return false;
        }
      case ShelfSourceFilter.online:
        if (!book.isOnline) {
          return false;
        }
    }

    // 搜索：五个可检索字段，大小写不敏感 contains。
    if (needle.isNotEmpty) {
      final bool hit =
          _contains(book.title, needle) ||
          _contains(book.author, needle) ||
          _contains(book.narrator, needle) ||
          _contains(book.seriesName, needle) ||
          _contains(book.description, needle);
      if (!hit) {
        return false;
      }
    }

    // 状态：按进度与完听标记判定。
    switch (status) {
      case ShelfStatusFilter.all:
        break;
      case ShelfStatusFilter.listening:
        if (!book.hasProgress || book.isFinished) {
          return false;
        }
      case ShelfStatusFilter.unlistened:
        if (book.hasProgress) {
          return false;
        }
      case ShelfStatusFilter.finished:
        if (!book.isFinished) {
          return false;
        }
    }

    // 标签：大小写折叠后相等（一本书任一标签命中即可）。
    if (_present(tag)) {
      final String wanted = tag!.trim().toLowerCase();
      final bool tagged = book.tags.any(
        (String value) => value.trim().toLowerCase() == wanted,
      );
      if (!tagged) {
        return false;
      }
    }

    // 系列：按原文比较。
    if (_present(series) && book.seriesName?.trim() != series!.trim()) {
      return false;
    }

    return true;
  }

  static bool _contains(String? field, String needle) {
    return field != null && field.toLowerCase().contains(needle);
  }

  static bool _present(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShelfFilterState &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          status == other.status &&
          source == other.source &&
          tag == other.tag &&
          series == other.series;

  @override
  int get hashCode => Object.hash(query, status, source, tag, series);

  @override
  String toString() =>
      'ShelfFilterState(query: "$query", status: ${status.name}, '
      'source: ${source.name}, tag: $tag, series: $series)';

  /// `copyWith` 的「未传参」哨兵，用于区分「不改动」与「清除为 null」。
  static const Object _unset = Object();
}
