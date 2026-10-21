// ignore_for_file: prefer_initializing_formals
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';

/// 在线书目录不可用，不能开始播放。
class OnlineBookNotPlayable implements Exception {
  const OnlineBookNotPlayable(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 在线书入库编排：补齐预览缺的详情/目录，再交给查询端口写入。
class OnlineBookService {
  OnlineBookService({
    required OnlineLibraryQueries queries,
    required SourceDiscovery discovery,
  }) : _queries = queries,
       _discovery = discovery;

  final OnlineLibraryQueries _queries;
  final SourceDiscovery _discovery;

  Future<String> addToShelf({
    required BookSource source,
    required SourceBookSummary item,
    SourceBookInfo? info,
    SourceToc? toc,
    required List<String> tags,
  }) async {
    final SourceBookInfo? resolvedInfo =
        info ?? await _tryBookInfo(source, item);
    final SourceToc? resolvedToc = toc ?? await _tryToc(source, resolvedInfo);
    return _queries.upsertOnlineBook(
      OnlineBookUpsert(
        source: source,
        summary: item,
        info: resolvedInfo,
        toc: resolvedToc,
        onShelf: true,
        tags: tags,
      ),
    );
  }

  Future<String> startListening({
    required BookSource source,
    required SourceBookSummary item,
    SourceBookInfo? info,
    SourceToc? toc,
  }) async {
    final SourceBookInfo? resolvedInfo =
        info ?? await _tryBookInfo(source, item);
    final SourceToc? resolvedToc = toc ?? await _tryToc(source, resolvedInfo);
    if (resolvedToc == null || resolvedToc.chapters.isEmpty) {
      throw const OnlineBookNotPlayable('目录暂不可用，无法开始播放');
    }
    return _queries.upsertOnlineBook(
      OnlineBookUpsert(
        source: source,
        summary: item,
        info: resolvedInfo,
        toc: resolvedToc,
      ),
    );
  }

  Future<SourceBookInfo?> _tryBookInfo(
    BookSource source,
    SourceBookSummary item,
  ) async {
    try {
      return await _discovery.bookInfo(source, item.bookUrl);
    } on Object {
      return null;
    }
  }

  Future<SourceToc?> _tryToc(BookSource source, SourceBookInfo? info) async {
    if (info == null) {
      return null;
    }
    try {
      return await _discovery.toc(source, info);
    } on Object {
      return null;
    }
  }
}
