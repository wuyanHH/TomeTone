// ignore_for_file: prefer_initializing_formals
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../common/id_generator.dart';
import '../../sources/book_source.dart';
import '../../sources/discovery/source_models.dart';
import '../database/tometone_database.dart';
import '../metadata/book_metadata.dart';
import 'library_queries.dart';
import 'library_views.dart';

/// 在线书在书库中的加入状态。
class OnlineBookStatus {
  const OnlineBookStatus({required this.bookId, required this.onShelf});

  final String bookId;
  final bool onShelf;
}

/// 目录刷新结果。
class TocRefreshResult {
  const TocRefreshResult({
    required this.isComplete,
    required this.newChaptersCount,
    required this.updatedChaptersCount,
    this.error,
  });

  final bool isComplete;
  final int newChaptersCount;
  final int updatedChaptersCount;
  final String? error;
}

/// 在线书籍基本记录。
class OnlineBookRecord {
  const OnlineBookRecord({
    required this.id,
    required this.sourceId,
    required this.bookUrl,
    required this.title,
    required this.libraryRootId,
    this.author,
    this.coverUrl,
    this.intro,
    this.kind,
    this.wordCount,
    this.status,
    this.lastChapter,
    this.totalChapters = 0,
    this.onShelf = true,
    this.lastRefreshAt,
    this.lastRefreshOk,
    this.lastRefreshError,
  });

  final String id;
  final String sourceId;
  final String bookUrl;
  final String title;
  final String libraryRootId;
  final String? author;
  final String? coverUrl;
  final String? intro;
  final String? kind;
  final String? wordCount;
  final String? status;
  final String? lastChapter;
  final int totalChapters;
  final bool onShelf;
  final DateTime? lastRefreshAt;
  final bool? lastRefreshOk;
  final String? lastRefreshError;
}

/// 换源结果。
class SwitchSourceResult {
  const SwitchSourceResult({
    required this.isProgressMapped,
    required this.currentChapterId,
    required this.totalChapters,
  });

  final bool isProgressMapped;
  final String currentChapterId;
  final int totalChapters;
}

/// 一次在线书入库所需的预览数据。
class OnlineBookUpsert {
  const OnlineBookUpsert({
    required this.source,
    required this.summary,
    this.info,
    this.toc,
    this.onShelf = false,
    this.tags = const <String>[],
    this.now,
  });

  final BookSource source;
  final SourceBookSummary summary;
  final SourceBookInfo? info;
  final SourceToc? toc;
  final bool onShelf;
  final List<String> tags;
  final DateTime? now;
}

/// 在线书入库、上架与状态查询端口。
abstract interface class OnlineLibraryQueries {
  Future<String> upsertOnlineBook(OnlineBookUpsert upsert);

  Future<void> setBookShelf(
    String bookId, {
    required bool onShelf,
    List<String> tags = const <String>[],
  });

  Future<void> saveOnlineMetadata(String bookId, BookMetadataDraft metadata);

  Future<Map<String, OnlineBookStatus>> bookStatuses({
    required String sourceId,
    required List<String> bookUrls,
  });

  Future<OnlineBookRecord?> getOnlineBook(String bookId);

  Future<void> updateBookInfo(String bookId, SourceBookInfo info);

  Future<TocRefreshResult> refreshToc({
    required String bookId,
    required BookSource source,
    required SourceToc toc,
    String? error,
  });

  Future<void> recordRefreshFailure(String bookId, String error);

  Future<ChapterView?> getChapterById(String chapterId);

  Future<ProgressSnapshot?> getPlaybackProgress(String bookId);

  Future<List<OnlineBookRecord>> getOnShelfOnlineBooks();

  Future<SwitchSourceResult> applySwitchSource({
    required String bookId,
    required BookSource targetSource,
    required String targetBookUrl,
    required SourceToc targetToc,
    required SourceChapter? mappedChapter,
  });
}

class DriftOnlineLibraryQueries implements OnlineLibraryQueries {
  DriftOnlineLibraryQueries(
    this._database, {
    required IdGenerator idGenerator,
    DateTime Function()? clock,
  }) : _idGenerator = idGenerator,
       _clock = clock ?? DateTime.now;

  final TomeToneDatabase _database;
  final IdGenerator _idGenerator;
  final DateTime Function() _clock;

  @override
  Future<String> upsertOnlineBook(OnlineBookUpsert upsert) async {
    final DateTime now = (upsert.now ?? _clock()).toUtc();
    final SourceBookSummary display = upsert.info ?? upsert.summary;
    final String bookUrl = upsert.summary.bookUrl;

    return _database.transaction(() async {
      final existing =
          await (_database.select(_database.books)..where(
                (tbl) =>
                    tbl.sourceId.equals(upsert.source.id) &
                    tbl.rootPath.equals(bookUrl),
              ))
              .getSingleOrNull();

      final String bookId;
      if (existing == null) {
        bookId = _idGenerator.next();
        await _database
            .into(_database.books)
            .insert(
              BooksCompanion.insert(
                id: bookId,
                libraryRootId: upsert.source.libraryRootId,
                title: display.title,
                author: Value<String?>(display.author),
                narrator: Value<String?>(display.narrator),
                rootPath: bookUrl,
                coverUrl: Value<String?>(display.coverUrl),
                description: Value<String?>(display.intro),
                kind: Value<String?>(display.kind),
                wordCount: Value<String?>(display.wordCount),
                sourceStatus: Value<String?>(display.status),
                lastChapter: Value<String?>(display.lastChapter),
                sourceType: 'online',
                sourceUri: Value<String?>(bookUrl),
                sourceId: Value<String?>(upsert.source.id),
                onShelf: Value<bool>(upsert.onShelf),
                totalChapters: Value<int>(upsert.toc?.chapters.length ?? 0),
                lastRefreshAt: Value<DateTime?>(now),
                lastRefreshOk: Value<bool?>(upsert.toc != null),
                lastRefreshError: Value<String?>(
                  upsert.toc == null ? '目录待刷新' : null,
                ),
                createdAt: now,
                updatedAt: now,
              ),
            );
      } else {
        bookId = existing.id;
        await (_database.update(
          _database.books,
        )..where((tbl) => tbl.id.equals(bookId))).write(
          BooksCompanion(
            onShelf: Value<bool>(existing.onShelf || upsert.onShelf),
            updatedAt: Value<DateTime>(now),
          ),
        );
      }

      final volume =
          await (_database.select(_database.volumes)
                ..where((tbl) => tbl.bookId.equals(bookId))
                ..limit(1))
              .getSingleOrNull();
      final String volumeId;
      if (volume == null) {
        volumeId = _idGenerator.next();
        await _database
            .into(_database.volumes)
            .insert(
              VolumesCompanion.insert(
                id: volumeId,
                bookId: bookId,
                title: '正文',
                volumeIndex: 0,
                path: '',
                updatedAt: now,
              ),
            );
      } else {
        volumeId = volume.id;
      }

      final int existingChapters =
          await (_database.selectOnly(_database.chapters)
                ..addColumns(<Expression<Object>>[countAll()])
                ..where(_database.chapters.bookId.equals(bookId)))
              .map((row) => row.read(countAll()) ?? 0)
              .getSingle();
      final toc = upsert.toc;
      if (existingChapters == 0 && toc != null) {
        for (final SourceChapter chapter in toc.chapters) {
          await _database
              .into(_database.chapters)
              .insert(
                ChaptersCompanion.insert(
                  id: _idGenerator.next(),
                  bookId: bookId,
                  volumeId: volumeId,
                  libraryRootId: upsert.source.libraryRootId,
                  title: chapter.title,
                  chapterIndex: chapter.index,
                  filePath: 'online/${_hash(chapter.url)}',
                  sourceUri: Value<String?>(chapter.rawUrl),
                  retired: const Value<bool>(false),
                  isVip: Value<bool>(chapter.isVip),
                  updatedAt: now,
                ),
              );
        }
      }

      if (upsert.onShelf && upsert.tags.isNotEmpty) {
        await _replaceTags(bookId, upsert.tags);
      }
      return bookId;
    });
  }

  @override
  Future<void> setBookShelf(
    String bookId, {
    required bool onShelf,
    List<String> tags = const <String>[],
  }) async {
    final now = _clock().toUtc();
    await _database.transaction(() async {
      await (_database.update(
        _database.books,
      )..where((tbl) => tbl.id.equals(bookId))).write(
        BooksCompanion(
          onShelf: Value<bool>(onShelf),
          updatedAt: Value<DateTime>(now),
        ),
      );
      if (tags.isNotEmpty) {
        await _replaceTags(bookId, tags);
      }
    });
  }

  @override
  Future<void> saveOnlineMetadata(String bookId, BookMetadataDraft metadata) {
    return DriftLibraryQueries(_database)
        .saveBookMetadata(bookId: bookId, metadata: metadata, manual: true);
  }

  @override
  Future<Map<String, OnlineBookStatus>> bookStatuses({
    required String sourceId,
    required List<String> bookUrls,
  }) async {
    if (bookUrls.isEmpty) {
      return const <String, OnlineBookStatus>{};
    }
    final rows =
        await (_database.select(_database.books)..where(
              (tbl) =>
                  tbl.sourceId.equals(sourceId) & tbl.rootPath.isIn(bookUrls),
            ))
            .get();
    return <String, OnlineBookStatus>{
      for (final row in rows)
        row.rootPath: OnlineBookStatus(bookId: row.id, onShelf: row.onShelf),
    };
  }

  @override
  Future<OnlineBookRecord?> getOnlineBook(String bookId) async {
    final row = await (_database.select(_database.books)
          ..where((tbl) => tbl.id.equals(bookId)))
        .getSingleOrNull();
    if (row == null || row.sourceId == null) return null;
    return OnlineBookRecord(
      id: row.id,
      sourceId: row.sourceId!,
      bookUrl: row.rootPath,
      title: row.title,
      libraryRootId: row.libraryRootId,
      author: row.author,
      coverUrl: row.coverUrl,
      intro: row.description,
      kind: row.kind,
      wordCount: row.wordCount,
      status: row.sourceStatus,
      lastChapter: row.lastChapter,
      totalChapters: row.totalChapters,
      onShelf: row.onShelf,
      lastRefreshAt: row.lastRefreshAt,
      lastRefreshOk: row.lastRefreshOk,
      lastRefreshError: row.lastRefreshError,
    );
  }

  @override
  Future<void> updateBookInfo(String bookId, SourceBookInfo info) async {
    final now = _clock().toUtc();
    await (_database.update(_database.books)..where((tbl) => tbl.id.equals(bookId)))
        .write(
      BooksCompanion(
        title: Value<String>(info.title),
        author: Value<String?>(info.author),
        narrator: Value<String?>(info.narrator),
        coverUrl: Value<String?>(info.coverUrl),
        description: Value<String?>(info.intro),
        kind: Value<String?>(info.kind),
        wordCount: Value<String?>(info.wordCount),
        sourceStatus: Value<String?>(info.status),
        lastChapter: Value<String?>(info.lastChapter),
        updatedAt: Value<DateTime>(now),
      ),
    );
  }

  @override
  Future<void> recordRefreshFailure(String bookId, String error) async {
    final now = _clock().toUtc();
    await (_database.update(_database.books)..where((tbl) => tbl.id.equals(bookId)))
        .write(
      BooksCompanion(
        lastRefreshAt: Value<DateTime?>(now),
        lastRefreshOk: const Value<bool?>(false),
        lastRefreshError: Value<String?>(error),
        updatedAt: Value<DateTime>(now),
      ),
    );
  }

  @override
  Future<List<OnlineBookRecord>> getOnShelfOnlineBooks() async {
    final rows = await (_database.select(_database.books)
          ..where((tbl) =>
              tbl.sourceType.equals('online') & tbl.onShelf.equals(true)))
        .get();
    return rows
        .where((r) => r.sourceId != null)
        .map((row) => OnlineBookRecord(
              id: row.id,
              sourceId: row.sourceId!,
              bookUrl: row.rootPath,
              title: row.title,
              libraryRootId: row.libraryRootId,
              author: row.author,
              coverUrl: row.coverUrl,
              intro: row.description,
              kind: row.kind,
              wordCount: row.wordCount,
              status: row.sourceStatus,
              lastChapter: row.lastChapter,
              totalChapters: row.totalChapters,
              onShelf: row.onShelf,
              lastRefreshAt: row.lastRefreshAt,
              lastRefreshOk: row.lastRefreshOk,
              lastRefreshError: row.lastRefreshError,
            ))
        .toList();
  }

  @override
  Future<TocRefreshResult> refreshToc({
    required String bookId,
    required BookSource source,
    required SourceToc toc,
    String? error,
  }) async {
    final now = _clock().toUtc();
    return _database.transaction(() async {
      final volume = await (_database.select(_database.volumes)
            ..where((tbl) => tbl.bookId.equals(bookId))
            ..limit(1))
          .getSingleOrNull();
      final String volumeId;
      if (volume == null) {
        volumeId = _idGenerator.next();
        await _database.into(_database.volumes).insert(
          VolumesCompanion.insert(
            id: volumeId,
            bookId: bookId,
            title: '正文',
            volumeIndex: 0,
            path: '',
            updatedAt: now,
          ),
        );
      } else {
        volumeId = volume.id;
      }

      final existingChapters = await (_database.select(_database.chapters)
            ..where((tbl) => tbl.bookId.equals(bookId)))
          .get();

      final existingByPath = <String, Chapter>{
        for (final ch in existingChapters) ch.filePath: ch,
      };

      int newCount = 0;
      int updatedCount = 0;
      final seenFilePaths = <String>{};

      for (final SourceChapter sc in toc.chapters) {
        final filePath = 'online/${_hash(sc.url)}';
        seenFilePaths.add(filePath);
        final existing = existingByPath[filePath];

        if (existing == null) {
          newCount++;
          await _database.into(_database.chapters).insert(
            ChaptersCompanion.insert(
              id: _idGenerator.next(),
              bookId: bookId,
              volumeId: volumeId,
              libraryRootId: source.libraryRootId,
              title: sc.title,
              chapterIndex: sc.index,
              filePath: filePath,
              sourceUri: Value<String?>(sc.rawUrl),
              retired: const Value<bool>(false),
              missing: const Value<bool>(false),
              isVip: Value<bool>(sc.isVip),
              updatedAt: now,
            ),
          );
        } else {
          updatedCount++;
          await (_database.update(_database.chapters)
                ..where((tbl) => tbl.id.equals(existing.id)))
              .write(
            ChaptersCompanion(
              title: Value<String>(sc.title),
              chapterIndex: Value<int>(sc.index),
              sourceUri: Value<String?>(sc.rawUrl),
              retired: const Value<bool>(false),
              missing: const Value<bool>(false),
              isVip: Value<bool>(sc.isVip),
              updatedAt: Value<DateTime>(now),
            ),
          );
        }
      }

      // 如果全部抓取成功（complete == true），把在远端已消失的旧章节标记为 retired 和 missing
      // 如果完整抓取失败（complete == false），绝对不修改消失章节，完好保留原目录！
      if (toc.complete) {
        for (final ch in existingChapters) {
          if (!seenFilePaths.contains(ch.filePath) && !ch.retired) {
            await (_database.update(_database.chapters)
                  ..where((tbl) => tbl.id.equals(ch.id)))
                .write(
              ChaptersCompanion(
                retired: const Value<bool>(true),
                missing: const Value<bool>(true),
                updatedAt: Value<DateTime>(now),
              ),
            );
          }
        }
      }

      final activeCount = await (_database.selectOnly(_database.chapters)
            ..addColumns(<Expression<Object>>[countAll()])
            ..where(_database.chapters.bookId.equals(bookId) &
                _database.chapters.retired.equals(false)))
          .map((row) => row.read(countAll()) ?? 0)
          .getSingle();

      final effectiveError = toc.complete
          ? null
          : (error ?? (toc.warnings.isNotEmpty ? toc.warnings.join('; ') : '目录部分更新'));

      await (_database.update(_database.books)..where((tbl) => tbl.id.equals(bookId)))
          .write(
        BooksCompanion(
          totalChapters: Value<int>(activeCount),
          lastRefreshAt: Value<DateTime?>(now),
          lastRefreshOk: Value<bool?>(toc.complete),
          lastRefreshError: Value<String?>(effectiveError),
          updatedAt: Value<DateTime>(now),
        ),
      );

      return TocRefreshResult(
        isComplete: toc.complete,
        newChaptersCount: newCount,
        updatedChaptersCount: updatedCount,
        error: effectiveError,
      );
    });
  }

  @override
  Future<ProgressSnapshot?> getPlaybackProgress(String bookId) async {
    final row = await (_database.select(_database.playbackProgress)
          ..where((tbl) => tbl.bookId.equals(bookId)))
        .getSingleOrNull();
    if (row == null) return null;
    return ProgressSnapshot(
      bookId: row.bookId,
      chapterId: row.chapterId,
      position: Duration(milliseconds: row.positionMs),
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<ChapterView?> getChapterById(String chapterId) async {
    final row = await (_database.select(_database.chapters)
          ..where((tbl) => tbl.id.equals(chapterId)))
        .getSingleOrNull();
    if (row == null) return null;
    return ChapterView(
      id: row.id,
      volumeId: row.volumeId,
      title: row.title,
      chapterIndex: row.chapterIndex,
      filePath: row.filePath,
      missing: row.missing,
      durationMs: row.durationMs,
      sourceUri: row.sourceUri,
      retired: row.retired,
      isVip: row.isVip,
    );
  }

  @override
  Future<SwitchSourceResult> applySwitchSource({
    required String bookId,
    required BookSource targetSource,
    required String targetBookUrl,
    required SourceToc targetToc,
    required SourceChapter? mappedChapter,
  }) async {
    final now = _clock().toUtc();
    return _database.transaction(() async {
      // 1. 将原书下所有现有章节打上 retired 标记
      await (_database.update(_database.chapters)
            ..where((tbl) => tbl.bookId.equals(bookId)))
          .write(
        ChaptersCompanion(
          retired: const Value<bool>(true),
          updatedAt: Value<DateTime>(now),
        ),
      );

      // 2. 确保存在卷
      final volume = await (_database.select(_database.volumes)
            ..where((tbl) => tbl.bookId.equals(bookId))
            ..limit(1))
          .getSingleOrNull();
      final String volumeId;
      if (volume == null) {
        volumeId = _idGenerator.next();
        await _database.into(_database.volumes).insert(
          VolumesCompanion.insert(
            id: volumeId,
            bookId: bookId,
            title: '正文',
            volumeIndex: 0,
            path: '',
            updatedAt: now,
          ),
        );
      } else {
        volumeId = volume.id;
      }

      // 3. 写入/重新激活新源的章节（upsert 语义，避免 A -> B -> A 唯一约束冲突）
      final urlToChapterId = <String, String>{};
      for (final sc in targetToc.chapters) {
        final filePath = 'online/${_hash(sc.url)}';
        final existing = await (_database.select(_database.chapters)
              ..where((tbl) =>
                  tbl.libraryRootId.equals(targetSource.libraryRootId) &
                  tbl.filePath.equals(filePath)))
            .getSingleOrNull();

        final String chapterId;
        if (existing != null) {
          chapterId = existing.id;
          await (_database.update(_database.chapters)
                ..where((tbl) => tbl.id.equals(existing.id)))
              .write(
            ChaptersCompanion(
              bookId: Value<String>(bookId),
              volumeId: Value<String>(volumeId),
              title: Value<String>(sc.title),
              chapterIndex: Value<int>(sc.index),
              sourceUri: Value<String?>(sc.rawUrl),
              retired: const Value<bool>(false),
              missing: const Value<bool>(false),
              isVip: Value<bool>(sc.isVip),
              updatedAt: Value<DateTime>(now),
            ),
          );
        } else {
          chapterId = _idGenerator.next();
          await _database.into(_database.chapters).insert(
            ChaptersCompanion.insert(
              id: chapterId,
              bookId: bookId,
              volumeId: volumeId,
              libraryRootId: targetSource.libraryRootId,
              title: sc.title,
              chapterIndex: sc.index,
              filePath: filePath,
              sourceUri: Value<String?>(sc.rawUrl),
              retired: const Value<bool>(false),
              missing: const Value<bool>(false),
              isVip: Value<bool>(sc.isVip),
              updatedAt: now,
            ),
          );
        }
        urlToChapterId[sc.url] = chapterId;
      }

      // 4. 更新 books 表的关联源与状态
      await (_database.update(_database.books)..where((tbl) => tbl.id.equals(bookId)))
          .write(
        BooksCompanion(
          libraryRootId: Value<String>(targetSource.libraryRootId),
          sourceId: Value<String?>(targetSource.id),
          rootPath: Value<String>(targetBookUrl),
          sourceUri: Value<String?>(targetBookUrl),
          totalChapters: Value<int>(targetToc.chapters.length),
          lastRefreshAt: Value<DateTime?>(now),
          lastRefreshOk: const Value<bool?>(true),
          lastRefreshError: const Value<String?>(null),
          updatedAt: Value<DateTime>(now),
        ),
      );

      // 5. 进度映射
      final bool isMapped =
          mappedChapter != null && urlToChapterId.containsKey(mappedChapter.url);
      final String currentChapterId;
      if (isMapped) {
        currentChapterId = urlToChapterId[mappedChapter.url]!;
        await (_database.update(_database.playbackProgress)
              ..where((tbl) => tbl.bookId.equals(bookId)))
            .write(
          PlaybackProgressCompanion(
            chapterId: Value<String>(currentChapterId),
            updatedAt: Value<DateTime>(now),
          ),
        );
      } else {
        // 未对齐：绝不修改 playback_progress，锁定原进度防覆盖
        currentChapterId = targetToc.chapters.isNotEmpty
            ? (urlToChapterId[targetToc.chapters.first.url] ?? '')
            : '';
      }

      return SwitchSourceResult(
        isProgressMapped: isMapped,
        currentChapterId: currentChapterId,
        totalChapters: targetToc.chapters.length,
      );
    });
  }

  Future<void> _replaceTags(String bookId, List<String> tags) async {
    final normalized = normalizeTags(tags);
    await (_database.delete(
      _database.bookTags,
    )..where((tbl) => tbl.bookId.equals(bookId))).go();
    for (final tag in normalized) {
      await _database
          .into(_database.bookTags)
          .insert(BookTagsCompanion.insert(bookId: bookId, tag: tag));
    }
  }

  static String _hash(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }
}
