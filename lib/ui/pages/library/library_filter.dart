import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/pages/shelf/shelf_filter.dart';

/// 书库来源类型筛选。
enum LibrarySourceFilter {
  /// 全部来源（本地与在线）。
  all,

  /// 仅本机目录。
  local,

  /// 仅在线网络书源。
  online,
}

const Object _unset = Object();

/// 书库筛选状态：来源类型 + 搜索词 + 标签 + 收听状态。
class LibraryFilterState {
  const LibraryFilterState({
    this.source = LibrarySourceFilter.all,
    this.query = '',
    this.tag,
    this.status = ShelfStatusFilter.all,
  });

  /// 来源类型（全部 / 本地 / 在线）。
  final LibrarySourceFilter source;

  /// 搜索词（书名 / 作者 / 演播 / 系列 / 简介 / 标签）。
  final String query;

  /// 选中的标签分类。
  final String? tag;

  /// 收听状态。
  final ShelfStatusFilter status;

  /// 是否激活任何非默认筛选。
  bool get isActive =>
      source != LibrarySourceFilter.all ||
      query.trim().isNotEmpty ||
      (tag != null && tag!.isNotEmpty) ||
      status != ShelfStatusFilter.all;

  /// 复制并替换部分字段。
  LibraryFilterState copyWith({
    LibrarySourceFilter? source,
    String? query,
    Object? tag = _unset,
    ShelfStatusFilter? status,
  }) {
    return LibraryFilterState(
      source: source ?? this.source,
      query: query ?? this.query,
      tag: identical(tag, _unset) ? this.tag : tag as String?,
      status: status ?? this.status,
    );
  }

  /// 将筛选条件应用到书目列表，返回命中的书（保持原有顺序）。
  List<BookSummary> apply(List<BookSummary> books) {
    final String needle = query.trim().toLowerCase();
    return <BookSummary>[
      for (final BookSummary book in books)
        if (_matches(book, needle)) book,
    ];
  }

  bool _matches(BookSummary book, String needle) {
    // 1. 来源类型
    switch (source) {
      case LibrarySourceFilter.all:
        break;
      case LibrarySourceFilter.local:
        if (book.isOnline) {
          return false;
        }
      case LibrarySourceFilter.online:
        if (!book.isOnline) {
          return false;
        }
    }

    // 2. 收听状态
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

    // 3. 标签/分类
    if (tag != null && tag!.isNotEmpty) {
      final String targetTag = tag!.toLowerCase();
      final bool tagHit =
          book.tags.any((String t) => t.toLowerCase() == targetTag) ||
          (book.kind?.toLowerCase().contains(targetTag) ?? false);
      if (!tagHit) {
        return false;
      }
    }

    // 4. 搜索关键字
    if (needle.isNotEmpty) {
      final bool textHit =
          book.title.toLowerCase().contains(needle) ||
          (book.author?.toLowerCase().contains(needle) ?? false) ||
          (book.narrator?.toLowerCase().contains(needle) ?? false) ||
          (book.seriesName?.toLowerCase().contains(needle) ?? false) ||
          (book.description?.toLowerCase().contains(needle) ?? false) ||
          book.tags.any((String t) => t.toLowerCase().contains(needle));
      if (!textHit) {
        return false;
      }
    }

    return true;
  }
}
