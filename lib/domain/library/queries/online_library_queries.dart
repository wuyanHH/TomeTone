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

/// 在线书在书库中的加入状态。
class OnlineBookStatus {
  const OnlineBookStatus({required this.bookId, required this.onShelf});

  final String bookId;
  final bool onShelf;
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
