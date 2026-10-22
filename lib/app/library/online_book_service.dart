// ignore_for_file: prefer_initializing_formals
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/contracts/audio/audio_cache_repository.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/book_source_queries.dart';
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
    BookSourceQueries? sourceQueries,
    AudioCacheRepository? cacheRepository,
  }) : _queries = queries,
       _discovery = discovery,
       _sourceQueries = sourceQueries,
       _cacheRepository = cacheRepository;

  final OnlineLibraryQueries _queries;
  final SourceDiscovery _discovery;
  final BookSourceQueries? _sourceQueries;
  final AudioCacheRepository? _cacheRepository;

  Future<void> refreshBookInfo(String bookId, {BookSource? source}) async {
    final book = await _queries.getOnlineBook(bookId);
    if (book == null) {
      throw StateError('在线书目不存在: $bookId');
    }
    final resolvedSource = source ?? await _sourceQueries?.sourceById(book.sourceId);
    if (resolvedSource == null) {
      throw StateError('书源不存在: ${book.sourceId}');
    }

    final info = await _discovery.bookInfo(resolvedSource, book.bookUrl);
    await _queries.updateBookInfo(bookId, info);
  }

  Future<TocRefreshResult> refreshBookToc(String bookId, {BookSource? source}) async {
    final book = await _queries.getOnlineBook(bookId);
    if (book == null) {
      throw StateError('在线书目不存在: $bookId');
    }
    final resolvedSource = source ?? await _sourceQueries?.sourceById(book.sourceId);
    if (resolvedSource == null) {
      throw StateError('书源不存在: ${book.sourceId}');
    }

    SourceBookInfo? info;
    try {
      info = await _discovery.bookInfo(resolvedSource, book.bookUrl);
    } catch (_) {}
    info ??= SourceBookInfo(
      bookUrl: book.bookUrl,
      tocUrl: book.bookUrl,
      title: book.title,
    );

    try {
      final toc = await _discovery.toc(resolvedSource, info);
      return await _queries.refreshToc(
        bookId: bookId,
        source: resolvedSource,
        toc: toc,
      );
    } catch (e) {
      final errStr = e.toString();
      await _queries.recordRefreshFailure(bookId, errStr);
      return TocRefreshResult(
        isComplete: false,
        newChaptersCount: 0,
        updatedChaptersCount: 0,
        error: errStr,
      );
    }
  }

  Future<SwitchSourceResult> switchSource({
    required String bookId,
    required String targetSourceId,
    required String targetBookUrl,
    String? targetChapterId,
    BookSource? targetSource,
    SourceToc? targetToc,
  }) async {
    final book = await _queries.getOnlineBook(bookId);
    if (book == null) {
      throw StateError('在线书目不存在: $bookId');
    }

    final resolvedTargetSource =
        targetSource ?? await _sourceQueries?.sourceById(targetSourceId);
    if (resolvedTargetSource == null) {
      throw StateError('目标书源不存在: $targetSourceId');
    }

    SourceToc? resolvedToc = targetToc;
    if (resolvedToc == null) {
      SourceBookInfo? info;
      try {
        info = await _discovery.bookInfo(resolvedTargetSource, targetBookUrl);
      } catch (_) {}
      info ??= SourceBookInfo(
        bookUrl: targetBookUrl,
        tocUrl: targetBookUrl,
        title: book.title,
      );
      resolvedToc = await _discovery.toc(resolvedTargetSource, info);
    }

    // 章节对齐算法
    SourceChapter? mappedChapter;
    if (targetChapterId != null) {
      mappedChapter = resolvedToc.chapters.cast<SourceChapter?>().firstWhere(
            (c) => c!.rawUrl == targetChapterId || c.url == targetChapterId,
            orElse: () => null,
          );
    } else {
      final progress = await _queries.getPlaybackProgress(bookId);
      if (progress != null) {
        final oldChapter = await _queries.getChapterById(progress.chapterId);
        if (oldChapter != null) {
          final oldClean = _cleanChapterTitle(oldChapter.title);
          if (oldClean.isNotEmpty) {
            mappedChapter = resolvedToc.chapters.cast<SourceChapter?>().firstWhere(
                  (c) => _cleanChapterTitle(c!.title) == oldClean,
                  orElse: () => null,
                );
          }
          mappedChapter ??= resolvedToc.chapters.cast<SourceChapter?>().firstWhere(
                (c) => c!.index == oldChapter.chapterIndex,
                orElse: () => null,
              );
        }
      }
    }

    final result = await _queries.applySwitchSource(
      bookId: bookId,
      targetSource: resolvedTargetSource,
      targetBookUrl: targetBookUrl,
      targetToc: resolvedToc,
      mappedChapter: mappedChapter,
    );

    // 清理旧音频缓存
    try {
      await _cacheRepository?.clearBookCache(bookId);
    } catch (_) {}

    return result;
  }

  static String _cleanChapterTitle(String title) {
    return title
        .replaceAll(RegExp(r'第\s*\d+\s*章|[^\w\u4e00-\u9fa5]'), '')
        .trim()
        .toLowerCase();
  }

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
