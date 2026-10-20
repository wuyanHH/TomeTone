import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../cover/cover_source.dart';
import '../database/tometone_database.dart';
import '../metadata/book_metadata.dart';
import 'library_views.dart';

/// 书库只读查询 + 进度 / 偏好写入的端口（供 UI 与播放编排使用）。
///
/// 用聚合视图而非裸露表行：UI 不应该自己去 join 五张表，也不应该知道
/// `cover_source_type` 是 int。
abstract interface class LibraryQueries {
  /// 书架列表（按最近收听 / 最近加入倒序）。
  Future<List<BookSummary>> listBooks({
    String? libraryRootId,
    int limit = 50,
    int offset = 0,
  });

  /// 全部书（不受分页限制），供标签筛选 / 统计等场景。
  Future<List<BookSummary>> listAllBooks();

  /// 全部标签（去重后，不区分大小写排序）。
  Future<List<String>> listBookTags();

  /// 书详情（卷 / 章 / 进度 / 偏好）。不存在返回 `null`。
  Future<BookDetail?> bookDetail(String bookId);

  /// 全部书库根（设置页与筛选用）。
  Future<List<LibraryRootView>> libraryRoots();

  /// 写入 / 更新播放进度（按书 upsert）。
  Future<void> saveProgress({
    required String bookId,
    required String chapterId,
    required Duration position,
    bool finished = false,
    DateTime? updatedAt,
  });

  /// 写入 / 更新元数据（覆盖层 + 标签）。
  ///
  /// 语义见实现注释：`manual` 决定是否整体覆盖；`onlyFillEmpty` 只对手动写入有意义。
  Future<void> saveBookMetadata({
    required String bookId,
    required BookMetadataDraft metadata,
    bool manual = true,
    bool onlyFillEmpty = false,
    DateTime? updatedAt,
  });

  /// 写入 / 更新每书偏好。
  Future<void> savePreferences(
    String bookId,
    PerBookPrefsSnapshot preferences, {
    DateTime? updatedAt,
  });
}

/// Drift 实现。
///
/// 刻意用裸 SQL 做聚合：`books ⨝ playback_progress ⨝ chapters` 三表左连接在
/// drift 的类型化 join 里可读性极差，而这里的投影是稳定的、有测试覆盖的。
class DriftLibraryQueries implements LibraryQueries {
  /// 创建查询实现。
  DriftLibraryQueries(this._database);

  /// `IN (...)` 分片大小（SQLite 变量上限）。
  static const int _inChunkSize = 500;

  final TomeToneDatabase _database;

  @override
  Future<List<BookSummary>> listBooks({
    String? libraryRootId,
    int limit = 50,
    int offset = 0,
  }) async {
    final summaries = await _selectSummaries(
      whereClause: libraryRootId == null ? '' : 'WHERE b.library_root_id = ?',
      leadingVariables: <Variable<Object>>[
        if (libraryRootId != null) Variable<String>(libraryRootId),
      ],
      limit: limit,
      offset: offset,
    );
    return summaries;
  }

  @override
  Future<List<BookSummary>> listAllBooks() {
    return _selectSummaries(
      whereClause: '',
      leadingVariables: const <Variable<Object>>[],
    );
  }

  @override
  Future<List<String>> listBookTags() async {
    final rows = await _database
        .customSelect('SELECT DISTINCT tag FROM book_tags ORDER BY tag COLLATE NOCASE')
        .get();
    return <String>[
      for (final row in rows) row.read<String>('tag'),
    ];
  }

  @override
  Future<BookDetail?> bookDetail(String bookId) async {
    final summaries = await _selectSummaries(
      whereClause: 'WHERE b.id = ?',
      leadingVariables: <Variable<Object>>[Variable<String>(bookId)],
      limit: 1,
      offset: 0,
    );
    if (summaries.isEmpty) {
      return null;
    }

    final volumeRows =
        await (_database.select(_database.volumes)
              ..where((tbl) => tbl.bookId.equals(bookId))
              ..orderBy(<OrderClauseGenerator<$VolumesTable>>[
                (tbl) => OrderingTerm(expression: tbl.volumeIndex),
              ]))
            .get();

    final chapterRows =
        await (_database.select(_database.chapters)
              ..where((tbl) => tbl.bookId.equals(bookId))
              ..orderBy(<OrderClauseGenerator<$ChaptersTable>>[
                (tbl) => OrderingTerm(expression: tbl.chapterIndex),
              ]))
            .get();

    final chaptersByVolume = <String, List<ChapterView>>{};
    for (final chapter in chapterRows) {
      chaptersByVolume
          .putIfAbsent(chapter.volumeId, () => <ChapterView>[])
          .add(
            ChapterView(
              id: chapter.id,
              volumeId: chapter.volumeId,
              title: chapter.title,
              chapterIndex: chapter.chapterIndex,
              filePath: chapter.filePath,
              missing: chapter.missing,
              durationMs: chapter.durationMs,
            ),
          );
    }

    final volumes = <VolumeView>[
      for (final volume in volumeRows)
        VolumeView(
          id: volume.id,
          title: volume.title,
          volumeIndex: volume.volumeIndex,
          coverPath: volume.coverPath,
          chapters: chaptersByVolume[volume.id] ?? const <ChapterView>[],
        ),
    ];

    final prefsRow = await (_database.select(
      _database.perBookPrefs,
    )..where((tbl) => tbl.bookId.equals(bookId))).getSingleOrNull();

    final progressRow = await (_database.select(
      _database.playbackProgress,
    )..where((tbl) => tbl.bookId.equals(bookId))).getSingleOrNull();

    return BookDetail(
      summary: summaries.first,
      volumes: volumes,
      preferences: prefsRow == null
          ? const PerBookPrefsSnapshot()
          : PerBookPrefsSnapshot(
              speed: prefsRow.speed,
              skipIntro: Duration(seconds: prefsRow.skipIntroSec),
              skipOutro: Duration(seconds: prefsRow.skipOutroSec),
              rewindOverrideJson: prefsRow.rewindOverride,
            ),
      progress: progressRow == null
          ? null
          : ProgressSnapshot(
              bookId: progressRow.bookId,
              chapterId: progressRow.chapterId,
              position: Duration(milliseconds: progressRow.positionMs),
              updatedAt: progressRow.updatedAt,
            ),
    );
  }

  @override
  Future<List<LibraryRootView>> libraryRoots() async {
    final rows =
        await (_database.select(_database.libraryRoots)
              ..orderBy(<OrderClauseGenerator<$LibraryRootsTable>>[
                (tbl) => OrderingTerm(expression: tbl.createdAt),
              ]))
            .get();

    return <LibraryRootView>[
      for (final row in rows)
        LibraryRootView(
          id: row.id,
          type: row.type,
          uri: row.uri,
          displayName: row.displayName,
          lastScanAt: row.lastScanAt,
        ),
    ];
  }

  @override
  Future<void> saveProgress({
    required String bookId,
    required String chapterId,
    required Duration position,
    bool finished = false,
    DateTime? updatedAt,
  }) async {
    final DateTime now = (updatedAt ?? DateTime.now()).toUtc();
    await _database
        .into(_database.playbackProgress)
        .insertOnConflictUpdate(
          PlaybackProgressCompanion.insert(
            bookId: bookId,
            chapterId: chapterId,
            positionMs: position.isNegative ? 0 : position.inMilliseconds,
            finishedAt: Value<DateTime?>(finished ? now : null),
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> saveBookMetadata({
    required String bookId,
    required BookMetadataDraft metadata,
    bool manual = true,
    bool onlyFillEmpty = false,
    DateTime? updatedAt,
  }) async {
    final BookMetadataDraft draft = metadata.normalized();
    final DateTime now = (updatedAt ?? DateTime.now()).toUtc();

    await _database.transaction(() async {
      final existing = await (_database.select(_database.bookMetadataOverrides)
            ..where((tbl) => tbl.bookId.equals(bookId)))
          .getSingleOrNull();
      final List<String> existingTags = await _existingTags(bookId);

      if (manual) {
        // 手动编辑：整体覆盖（空即清空），并写 manualEditedAt。
        await _upsertOverrides(
          bookId: bookId,
          draft: draft,
          manualEditedAt: now,
          now: now,
        );
        await _replaceTags(bookId, draft.tags);
      } else if (onlyFillEmpty) {
        // 自动导入只填空：若用户已手动编辑过，绝不覆盖，直接 no-op。
        if (existing?.manualEditedAt != null) {
          return;
        }
        await _upsertOverrides(
          bookId: bookId,
          draft: BookMetadataDraft(
            title: draft.title ?? existing?.title,
            author: draft.author ?? existing?.author,
            narrator: draft.narrator ?? existing?.narrator,
            seriesName: draft.seriesName ?? existing?.seriesName,
            seriesIndex: draft.seriesIndex ?? existing?.seriesIndex,
            description: draft.description ?? existing?.description,
            tags: draft.tags,
          ),
          manualEditedAt: null,
          now: now,
        );
        // 标签：仅在现有标签为空时写入。
        if (existingTags.isEmpty) {
          await _replaceTags(bookId, draft.tags);
        }
      } else {
        // 用户确认后的重新导入：只覆盖非空字段，保守地不清 manualEditedAt
        // （以后自动导入仍不会碰这本书）。
        await _upsertOverrides(
          bookId: bookId,
          draft: BookMetadataDraft(
            title: draft.title ?? existing?.title,
            author: draft.author ?? existing?.author,
            narrator: draft.narrator ?? existing?.narrator,
            seriesName: draft.seriesName ?? existing?.seriesName,
            seriesIndex: draft.seriesIndex ?? existing?.seriesIndex,
            description: draft.description ?? existing?.description,
            tags: draft.tags,
          ),
          manualEditedAt: existing?.manualEditedAt,
          now: now,
        );
        // 标签：空列表视为「未提供」，不清空现有标签；否则整体替换。
        if (draft.tags.isNotEmpty) {
          await _replaceTags(bookId, draft.tags);
        }
      }
    });
  }

  @override
  Future<void> savePreferences(
    String bookId,
    PerBookPrefsSnapshot preferences, {
    DateTime? updatedAt,
  }) async {
    await _database
        .into(_database.perBookPrefs)
        .insertOnConflictUpdate(
          PerBookPrefsCompanion.insert(
            bookId: bookId,
            speed: Value<double>(preferences.speed),
            skipIntroSec: Value<int>(preferences.skipIntro.inSeconds),
            skipOutroSec: Value<int>(preferences.skipOutro.inSeconds),
            rewindOverride: Value<String?>(preferences.rewindOverrideJson),
            updatedAt: updatedAt ?? DateTime.now().toUtc(),
          ),
        );
  }

  // ---------------------------------------------------------------------------

  Future<List<BookSummary>> _selectSummaries({
    required String whereClause,
    required List<Variable<Object>> leadingVariables,
    int? limit,
    int offset = 0,
  }) async {
    final String limitClause = limit == null ? '' : 'LIMIT ? OFFSET ?';
    final rows = await _database
        .customSelect(
          '''
SELECT b.id,
       COALESCE(m.title, b.title) AS title,
       COALESCE(m.author, b.author) AS author,
       COALESCE(m.narrator, b.narrator) AS narrator,
       COALESCE(m.series_name, b.series_name) AS series_name,
       COALESCE(m.series_index, b.series_index) AS series_index,
       b.cover_path, b.cover_source_type, b.total_chapters, b.total_duration_ms,
       b.library_root_id, b.root_path,
       m.description AS description,
       m.manual_edited_at IS NOT NULL AS metadata_edited,
       p.chapter_id AS progress_chapter_id,
       p.position_ms AS progress_position_ms,
       p.updated_at AS progress_updated_at,
       p.finished_at AS finished_at,
       c.title AS progress_chapter_title,
       c.chapter_index AS progress_chapter_index
FROM books b
LEFT JOIN book_metadata_overrides m ON m.book_id = b.id
LEFT JOIN playback_progress p ON p.book_id = b.id
LEFT JOIN chapters c ON c.id = p.chapter_id
$whereClause
ORDER BY COALESCE(p.updated_at, b.updated_at) DESC
$limitClause
''',
          variables: <Variable<Object>>[
            ...leadingVariables,
            if (limit != null) ...[
              Variable<int>(limit),
              Variable<int>(offset),
            ],
          ],
        )
        .get();

    if (rows.isEmpty) {
      return const <BookSummary>[];
    }

    final missing = await _missingCounts(<String>[
      for (final row in rows) row.read<String>('id'),
    ]);
    final tagsByBook = await _tagsByBook();

    return <BookSummary>[
      for (final row in rows)
        BookSummary(
          id: row.read<String>('id'),
          title: row.read<String>('title'),
          author: row.read<String?>('author'),
          narrator: row.read<String?>('narrator'),
          seriesName: row.read<String?>('series_name'),
          seriesIndex: row.read<int?>('series_index'),
          coverPath: row.read<String?>('cover_path'),
          coverSource: CoverSource.fromRank(row.read<int>('cover_source_type')),
          totalChapters: row.read<int>('total_chapters'),
          totalDurationMs: row.read<int>('total_duration_ms'),
          libraryRootId: row.read<String>('library_root_id'),
          rootPath: row.read<String>('root_path'),
          description: row.read<String?>('description'),
          tags: tagsByBook[row.read<String>('id')] ?? const <String>[],
          isFinished: row.read<DateTime?>('finished_at') != null,
          metadataEdited: row.read<bool>('metadata_edited'),
          progressChapterId: row.read<String?>('progress_chapter_id'),
          progressChapterTitle: row.read<String?>('progress_chapter_title'),
          progressChapterIndex: row.read<int?>('progress_chapter_index'),
          progressPositionMs: row.read<int?>('progress_position_ms'),
          lastListenedAt: row.read<DateTime?>('progress_updated_at'),
          missingChapters: missing[row.read<String>('id')] ?? 0,
        ),
    ];
  }

  /// 全部标签按 book_id 分组（`ORDER BY tag COLLATE NOCASE` 保证组内有序）。
  Future<Map<String, List<String>>> _tagsByBook() async {
    final rows = await _database
        .customSelect(
          'SELECT book_id, tag FROM book_tags ORDER BY tag COLLATE NOCASE',
        )
        .get();
    final result = <String, List<String>>{};
    for (final row in rows) {
      result
          .putIfAbsent(row.read<String>('book_id'), () => <String>[])
          .add(row.read<String>('tag'));
    }
    return result;
  }

  Future<List<String>> _existingTags(String bookId) async {
    final rows = await (_database.select(_database.bookTags)
          ..where((tbl) => tbl.bookId.equals(bookId)))
        .get();
    return <String>[for (final row in rows) row.tag];
  }

  Future<void> _replaceTags(String bookId, List<String> tags) async {
    await (_database.delete(_database.bookTags)
          ..where((tbl) => tbl.bookId.equals(bookId)))
        .go();
    for (final tag in tags) {
      await _database
          .into(_database.bookTags)
          .insert(BookTagsCompanion.insert(bookId: bookId, tag: tag));
    }
  }

  Future<void> _upsertOverrides({
    required String bookId,
    required BookMetadataDraft draft,
    required DateTime? manualEditedAt,
    required DateTime now,
  }) async {
    await _database
        .into(_database.bookMetadataOverrides)
        .insertOnConflictUpdate(
          BookMetadataOverridesCompanion.insert(
            bookId: bookId,
            title: Value<String?>(draft.title),
            author: Value<String?>(draft.author),
            narrator: Value<String?>(draft.narrator),
            seriesName: Value<String?>(draft.seriesName),
            seriesIndex: Value<int?>(draft.seriesIndex),
            description: Value<String?>(draft.description),
            manualEditedAt: Value<DateTime?>(manualEditedAt),
            updatedAt: now,
          ),
        );
  }

  Future<Map<String, int>> _missingCounts(List<String> bookIds) async {
    final result = <String, int>{};
    for (var start = 0; start < bookIds.length; start += _inChunkSize) {
      final chunk = bookIds.sublist(
        start,
        math.min(start + _inChunkSize, bookIds.length),
      );
      final placeholders = List<String>.filled(chunk.length, '?').join(', ');
      final rows = await _database
          .customSelect(
            'SELECT book_id, COUNT(*) AS missing_count FROM chapters '
            'WHERE missing = 1 AND book_id IN ($placeholders) GROUP BY book_id',
            variables: <Variable<Object>>[
              for (final id in chunk) Variable<String>(id),
            ],
          )
          .get();
      for (final row in rows) {
        result[row.read<String>('book_id')] = row.read<int>('missing_count');
      }
    }
    return result;
  }
}
