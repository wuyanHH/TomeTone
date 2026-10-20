import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/contracts/storage/book_metadata_file_store.dart';
import 'package:tometone/contracts/storage/storage_entry.dart';
import 'package:tometone/contracts/storage/storage_provider.dart';
import 'package:tometone/domain/common/id_generator.dart';
import 'package:tometone/domain/library/cover/cover_resolver.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/media/media_metadata_reader.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';
import 'package:tometone/domain/library/metadata/book_metadata_codec.dart';

import 'media_format.dart';
import 'path_normalizer.dart';
import 'scan_report.dart';
import 'topology.dart';

/// 书库扫描编排（《架构需求文档》§2.1）。
///
/// ## 两阶段
///
/// - [scanStructure]（Phase 1）：只建立「书 / 卷 / 章」结构与排序，**不读取**时长与封面，
///   保证首屏尽快可用；所有写入在**一个事务**内完成（崩溃不会留下半本书）。
/// - [backfillMetadata]（Phase 2）：异步回填时长 / 内嵌封面；单章失败只计数，不中断。
///
/// ## 增量与数据安全
///
/// - 以绑定键 `libraryRootId + NFC 相对路径` 匹配已有章：**会话内 ID 不变**，
///   因此播放进度与收听统计不会因重扫描而断链。
/// - 消失的文件只置 `missing = true`，**永不删除记录**（§9.2 数据安全铁律）。
/// - 只有真正发生变化的行才会写库；二次扫描同一棵树不会产生任何写入。
///
/// ## 并发
///
/// 同一实例内的扫描串行执行（[StateError] 保护）。书库写入是单进程内唯一的
/// 生产者，因此不需要跨实例锁；若未来出现多 isolate 写入，需要改为数据库级锁。
class LibraryScanner {
  /// 创建扫描器。
  ///
  /// [idGenerator] 必须返回**不可变** ID（生产用 ULID）；测试可注入确定性生成器。
  LibraryScanner({
    required this._database,
    required this._idGenerator,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// `IN (...)` 的分片大小：SQLite 对单条语句的变量数量有上限，
  /// 万本书不能一次性塞进 `IN`。
  static const int _inChunkSize = 500;

  /// 单章元信息回填的最大尝试次数。
  ///
  /// 永久读不出时长的章（坏文件 / 编码异常）会在连续失败后退出队列，
  /// 否则它永远排在队首，饿死后面所有章节。
  static const int maxMetadataAttempts = 3;

  final TomeToneDatabase _database;
  final IdGenerator _idGenerator;
  final DateTime Function() _clock;

  bool _scanning = false;

  /// Phase 1：扫描并建立结构。
  ///
  /// [provider] 必须**以单个书库根为作用域**：`list('')` 返回根下直接子项，
  /// 路径均为根相对路径。
  Future<ScanReport> scanStructure({
    required String libraryRootId,
    required StorageProvider provider,
    int bookDepth = 1,
    String sourceType = 'local',
    BookMetadataFileStore? metadataStore,
  }) async {
    if (_scanning) {
      throw StateError('同一扫描器上已有扫描在进行；同一书库根必须串行扫描');
    }
    _scanning = true;
    final stopwatch = Stopwatch()..start();

    try {
      final collection = await _collect(provider);
      final topology = TopologyBuilder.build(
        collection.nodes,
        bookDepth: bookDepth,
      );
      final ignoredFiles = collection.nodes
          .where((ScanNode node) => !MediaFormat.isSupported(node.path))
          .length;
      final images = _indexImages(collection.nodes);

      final snapshot = await _loadSnapshot(libraryRootId);
      final now = _clock().toUtc();
      final plan = await _buildPlan(
        libraryRootId: libraryRootId,
        topology: topology,
        snapshot: snapshot,
        images: images,
        now: now,
        sourceType: sourceType,
        metadataStore: metadataStore,
      );

      await _applyPlan(plan, libraryRootId: libraryRootId, now: now);

      stopwatch.stop();
      return ScanReport(
        libraryRootId: libraryRootId,
        booksSeen: topology.length,
        booksAdded: plan.booksAdded,
        booksUpdated: plan.booksUpdated,
        volumesAdded: plan.volumesAdded,
        chaptersSeen: plan.chaptersSeen,
        chaptersAdded: plan.chaptersAdded,
        chaptersUpdated: plan.chaptersUpdated,
        chaptersMarkedMissing: plan.chaptersMarkedMissing,
        chaptersRestored: plan.chaptersRestored,
        ignoredFiles: ignoredFiles,
        failedPaths: List<String>.unmodifiable(collection.failedPaths),
        elapsed: stopwatch.elapsed,
      );
    } finally {
      _scanning = false;
    }
  }

  /// Phase 2：回填时长（并重算书的累计时长）。
  ///
  /// 每轮最多处理 [maxChapters] 条；`remaining > 0` 时由调用方调度下一轮，
  /// 避免长时间占用 IO 影响播放。
  Future<BackfillReport> backfillMetadata({
    required String libraryRootId,
    required MediaMetadataReader reader,
    required AudioSourceRef Function(String filePath) sourceOf,
    int maxChapters = 200,
  }) async {
    final pending =
        await (_database.select(_database.chapters)
              ..where(
                (tbl) =>
                    tbl.libraryRootId.equals(libraryRootId) &
                    tbl.missing.equals(false) &
                    tbl.durationMs.isNull() &
                    tbl.metadataAttempts.isSmallerThanValue(
                      maxMetadataAttempts,
                    ),
              )
              ..orderBy(<OrderClauseGenerator<$ChaptersTable>>[
                (tbl) => OrderingTerm(expression: tbl.bookId),
                (tbl) => OrderingTerm(expression: tbl.chapterIndex),
              ])
              ..limit(maxChapters))
            .get();

    var updated = 0;
    var failed = 0;
    final affectedBooks = <String>{};

    for (final chapter in pending) {
      final duration = await _readDuration(reader, sourceOf, chapter);
      if (duration == null) {
        await _recordMetadataFailure(chapter);
        failed++;
        continue;
      }
      await (_database.update(
        _database.chapters,
      )..where((tbl) => tbl.id.equals(chapter.id))).write(
        ChaptersCompanion(
          durationMs: Value<int>(duration.inMilliseconds),
          updatedAt: Value<DateTime>(_clock().toUtc()),
        ),
      );
      affectedBooks.add(chapter.bookId);
      updated++;
    }

    for (final bookId in affectedBooks) {
      await _refreshBookDuration(bookId);
    }

    return BackfillReport(
      updated: updated,
      failed: failed,
      remaining: await _countPending(libraryRootId),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 1 实现
  // ---------------------------------------------------------------------------

  Future<_Collection> _collect(StorageProvider provider) async {
    final nodes = <ScanNode>[];
    final failedPaths = <String>[];
    final seenPaths = <String>{};
    final queue = <String>[''];

    while (queue.isNotEmpty) {
      final path = queue.removeLast();
      final List<StorageEntry> entries;
      try {
        entries = await provider.list(path);
      } catch (_) {
        // 单目录不可读（权限 / 断链）不应中断整次扫描；由上层按 §2.5 提示。
        failedPaths.add(path);
        continue;
      }

      for (final entry in entries) {
        final relative = PathNormalizer.normalize(
          path.isEmpty ? entry.name : '$path/${entry.name}',
        );
        if (relative.isEmpty) {
          continue;
        }
        if (entry.isDirectory) {
          if (PathNormalizer.depthOf(relative) < TopologyBuilder.maxDepth) {
            queue.add(relative);
          }
          continue;
        }
        // provider 若返回重复条目，会让同一绑定键插入两次而触发唯一索引冲突；
        // 这里按归一化路径去重，把"实现不规范"挡在扫描器之外。
        if (!seenPaths.add(relative)) {
          continue;
        }
        nodes.add(
          ScanNode(
            path: relative,
            sizeBytes: entry.sizeBytes,
            modifiedAt: entry.lastModified,
          ),
        );
      }
    }

    return _Collection(nodes: nodes, failedPaths: failedPaths);
  }

  /// 目录（相对书库根）→ 该目录下**直接**包含的封面候选图片路径。
  ///
  /// 只索引直接子项：封面继承是"就近优先"，跨目录的图片不参与本级判定。
  Map<String, List<String>> _indexImages(List<ScanNode> nodes) {
    final index = <String, List<String>>{};
    for (final node in nodes) {
      if (!CoverResolver.isCoverImage(node.path)) {
        continue;
      }
      final slash = node.path.lastIndexOf('/');
      final directory = slash < 0 ? '' : node.path.substring(0, slash);
      index.putIfAbsent(directory, () => <String>[]).add(node.path);
    }
    return index;
  }

  static String _joinPath(String parent, String child) =>
      child.isEmpty ? parent : '$parent/$child';

  Future<_Snapshot> _loadSnapshot(String libraryRootId) async {
    final books = await (_database.select(
      _database.books,
    )..where((tbl) => tbl.libraryRootId.equals(libraryRootId))).get();

    final bookIds = <String>[for (final book in books) book.id];
    final volumes = <Volume>[];
    for (var start = 0; start < bookIds.length; start += _inChunkSize) {
      final chunk = bookIds.sublist(
        start,
        math.min(start + _inChunkSize, bookIds.length),
      );
      volumes.addAll(
        await (_database.select(
          _database.volumes,
        )..where((tbl) => tbl.bookId.isIn(chunk))).get(),
      );
    }

    final chapters = await (_database.select(
      _database.chapters,
    )..where((tbl) => tbl.libraryRootId.equals(libraryRootId))).get();

    return _Snapshot(books: books, volumes: volumes, chapters: chapters);
  }

  Future<_Plan> _buildPlan({
    required String libraryRootId,
    required List<BookTopology> topology,
    required _Snapshot snapshot,
    required Map<String, List<String>> images,
    required DateTime now,
    required String sourceType,
    BookMetadataFileStore? metadataStore,
  }) async {
    final plan = _Plan();
    final booksByPath = <String, Book>{
      for (final book in snapshot.books) book.rootPath: book,
    };
    final volumesByKey = <String, Volume>{
      for (final volume in snapshot.volumes)
        '${volume.bookId}|${volume.path}': volume,
    };
    final chaptersByPath = <String, Chapter>{
      for (final chapter in snapshot.chapters) chapter.filePath: chapter,
    };
    final seenChapterPaths = <String>{};

    // 每本书已存在的章数（用于计算"含缺失占位"的章节总数，避免 O(书×章) 扫描）。
    final existingChapterCountByBook = <String, int>{};
    for (final chapter in snapshot.chapters) {
      existingChapterCountByBook[chapter.bookId] =
          (existingChapterCountByBook[chapter.bookId] ?? 0) + 1;
    }

    for (final bookTopology in topology) {
      final existingBook = booksByPath[bookTopology.rootPath];
      final bookId = existingBook?.id ?? _idGenerator.next();

      final rootImages = images[bookTopology.rootPath] ?? const <String>[];
      final firstVolume = bookTopology.volumes.isEmpty
          ? null
          : bookTopology.volumes.first;
      final firstVolumeImages = firstVolume == null
          ? const <String>[]
          : images[_joinPath(bookTopology.rootPath, firstVolume.path)] ??
                const <String>[];
      final bookCover = CoverResolver.resolveBook(
        rootImages: rootImages,
        firstVolumeImages: firstVolumeImages,
      );

      var chapterCount = 0;
      var existingMatched = 0;
      var totalDurationMs = 0;

      for (final volumeTopology in bookTopology.volumes) {
        final existingVolume = volumesByKey['$bookId|${volumeTopology.path}'];
        final volumeId = existingVolume?.id ?? _idGenerator.next();
        final volumeCover = CoverResolver.resolveVolume(
          volumeImages:
              images[_joinPath(bookTopology.rootPath, volumeTopology.path)] ??
              const <String>[],
          rootImages: rootImages,
        );

        if (existingVolume == null) {
          plan.volumesAdded++;
          plan.volumeInserts.add(
            VolumesCompanion.insert(
              id: volumeId,
              bookId: bookId,
              title: volumeTopology.title,
              volumeIndex: volumeTopology.volumeIndex,
              path: volumeTopology.path,
              coverPath: Value<String?>(volumeCover.relativePath),
              updatedAt: now,
            ),
          );
        } else if (existingVolume.title != volumeTopology.title ||
            existingVolume.volumeIndex != volumeTopology.volumeIndex ||
            existingVolume.coverPath != volumeCover.relativePath) {
          plan.volumeUpdates.add((
            id: volumeId,
            data: VolumesCompanion(
              title: Value<String>(volumeTopology.title),
              volumeIndex: Value<int>(volumeTopology.volumeIndex),
              coverPath: Value<String?>(volumeCover.relativePath),
              updatedAt: Value<DateTime>(now),
            ),
          ));
        }

        for (final chapterTopology in volumeTopology.chapters) {
          chapterCount++;
          plan.chaptersSeen++;
          seenChapterPaths.add(chapterTopology.filePath);

          final existingChapter = chaptersByPath[chapterTopology.filePath];
          if (existingChapter == null) {
            plan.chaptersAdded++;
            plan.chapterInserts.add(
              ChaptersCompanion.insert(
                id: _idGenerator.next(),
                bookId: bookId,
                volumeId: volumeId,
                libraryRootId: libraryRootId,
                title: chapterTopology.title,
                chapterIndex: chapterTopology.chapterIndex,
                filePath: chapterTopology.filePath,
                sizeBytes: Value<int?>(chapterTopology.sizeBytes),
                updatedAt: now,
              ),
            );
            continue;
          }

          // 已存在的章：ID 复用（不可变），仅更新真正变化的字段。
          existingMatched++;
          totalDurationMs += existingChapter.durationMs ?? 0;
          final changed =
              existingChapter.title != chapterTopology.title ||
              existingChapter.chapterIndex != chapterTopology.chapterIndex ||
              existingChapter.volumeId != volumeId ||
              existingChapter.bookId != bookId ||
              existingChapter.sizeBytes != chapterTopology.sizeBytes ||
              existingChapter.missing;

          if (existingChapter.missing) {
            plan.chaptersRestored++;
          }
          if (!changed) {
            continue;
          }
          plan.chaptersUpdated++;
          plan.chapterUpdates.add((
            id: existingChapter.id,
            data: ChaptersCompanion(
              bookId: Value<String>(bookId),
              volumeId: Value<String>(volumeId),
              title: Value<String>(chapterTopology.title),
              chapterIndex: Value<int>(chapterTopology.chapterIndex),
              sizeBytes: Value<int?>(chapterTopology.sizeBytes),
              missing: const Value<bool>(false),
              updatedAt: Value<DateTime>(now),
            ),
          ));
        }
      }

      // 章节总数 = 本次拓扑中的章 + 已存在但本次未出现的章（缺失章仍占位，§2.1）。
      final totalChapters =
          chapterCount +
          (existingChapterCountByBook[bookId] ?? 0) -
          existingMatched;

      if (existingBook == null) {
        plan.booksAdded++;
        plan.bookInserts.add(
          BooksCompanion.insert(
            id: bookId,
            libraryRootId: libraryRootId,
            title: bookTopology.title,
            rootPath: bookTopology.rootPath,
            sourceType: sourceType,
            coverPath: Value<String?>(bookCover.relativePath),
            coverSourceType: Value<CoverSource>(bookCover.source),
            totalChapters: Value<int>(totalChapters),
            totalDurationMs: Value<int>(totalDurationMs),
            createdAt: now,
            updatedAt: now,
          ),
        );

        // 只对本次新增的书读 sidecar：老书走详情页「从书根重新导入」，
        // 避免每次扫描对上千本书做文件 IO。
        final Uint8List? bytes = await metadataStore?.read(bookTopology.rootPath);
        final BookMetadataDraft? draft =
            bytes == null ? null : BookMetadataCodec.decode(bytes);
        if (draft != null && !draft.isEmpty) {
          plan.metadataOverrides.add((bookId: bookId, metadata: draft));
        }
        continue;
      }

      final bookChanged =
          existingBook.title != bookTopology.title ||
          existingBook.totalChapters != totalChapters ||
          existingBook.totalDurationMs != totalDurationMs ||
          existingBook.coverPath != bookCover.relativePath ||
          existingBook.coverSourceType != bookCover.source;
      if (bookChanged) {
        plan.booksUpdated++;
        plan.bookUpdates.add((
          id: bookId,
          data: BooksCompanion(
            title: Value<String>(bookTopology.title),
            coverPath: Value<String?>(bookCover.relativePath),
            coverSourceType: Value<CoverSource>(bookCover.source),
            totalChapters: Value<int>(totalChapters),
            totalDurationMs: Value<int>(totalDurationMs),
            updatedAt: Value<DateTime>(now),
          ),
        ));
      }
    }

    // 消失的文件：只标记缺失，不删除（§9.2）。
    for (final chapter in snapshot.chapters) {
      if (chapter.missing || seenChapterPaths.contains(chapter.filePath)) {
        continue;
      }
      plan.chaptersMarkedMissing++;
      plan.chapterUpdates.add((
        id: chapter.id,
        data: ChaptersCompanion(
          missing: const Value<bool>(true),
          updatedAt: Value<DateTime>(now),
        ),
      ));
    }

    return plan;
  }

  Future<void> _applyPlan(
    _Plan plan, {
    required String libraryRootId,
    required DateTime now,
  }) async {
    await _database.transaction(() async {
      await _database.batch((Batch batch) {
        // 顺序即外键依赖顺序：书 → 卷 → 章；更新放在插入之后。
        for (final companion in plan.bookInserts) {
          batch.insert(_database.books, companion);
        }
        // sidecar 覆盖层 + 标签：仅本次新增的书，紧随书插入同一事务（外键依赖）。
        for (final override in plan.metadataOverrides) {
          batch.insert(
            _database.bookMetadataOverrides,
            BookMetadataOverridesCompanion.insert(
              bookId: override.bookId,
              title: Value<String?>(override.metadata.title),
              author: Value<String?>(override.metadata.author),
              narrator: Value<String?>(override.metadata.narrator),
              seriesName: Value<String?>(override.metadata.seriesName),
              seriesIndex: Value<int?>(override.metadata.seriesIndex),
              description: Value<String?>(override.metadata.description),
              // manualEditedAt 不写（null）：扫描自动导入，不视为用户手改。
              updatedAt: now,
            ),
          );
          for (final tag in override.metadata.tags) {
            batch.insert(
              _database.bookTags,
              BookTagsCompanion.insert(bookId: override.bookId, tag: tag),
            );
          }
        }
        for (final companion in plan.volumeInserts) {
          batch.insert(_database.volumes, companion);
        }
        for (final entry in plan.bookUpdates) {
          batch.update(
            _database.books,
            entry.data,
            where: (tbl) => tbl.id.equals(entry.id),
          );
        }
        for (final entry in plan.volumeUpdates) {
          batch.update(
            _database.volumes,
            entry.data,
            where: (tbl) => tbl.id.equals(entry.id),
          );
        }
        for (final companion in plan.chapterInserts) {
          batch.insert(_database.chapters, companion);
        }
        for (final entry in plan.chapterUpdates) {
          batch.update(
            _database.chapters,
            entry.data,
            where: (tbl) => tbl.id.equals(entry.id),
          );
        }
        batch.update(
          _database.libraryRoots,
          LibraryRootsCompanion(lastScanAt: Value<DateTime>(now)),
          where: (tbl) => tbl.id.equals(libraryRootId),
        );
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Phase 2 实现
  // ---------------------------------------------------------------------------

  Future<void> _refreshBookDuration(String bookId) async {
    final row = await _database
        .customSelect(
          'SELECT COALESCE(SUM(duration_ms), 0) AS total FROM chapters '
          'WHERE book_id = ? AND missing = 0',
          variables: <Variable<Object>>[Variable<String>(bookId)],
        )
        .getSingle();
    final total = row.data['total'] as int? ?? 0;
    await (_database.update(_database.books)
          ..where((tbl) => tbl.id.equals(bookId)))
        .write(BooksCompanion(totalDurationMs: Value<int>(total)));
  }

  /// 读取单章时长。任何异常都折算为 `null` —— 单章坏文件不得中断回填。
  Future<Duration?> _readDuration(
    MediaMetadataReader reader,
    AudioSourceRef Function(String filePath) sourceOf,
    Chapter chapter,
  ) async {
    try {
      final metadata = await reader.read(sourceOf(chapter.filePath));
      return metadata?.duration;
    } catch (_) {
      return null;
    }
  }

  /// 记一次回填失败：累加尝试次数，达到上限后该章退出队列（防饿死）。
  Future<void> _recordMetadataFailure(Chapter chapter) async {
    await (_database.update(
      _database.chapters,
    )..where((tbl) => tbl.id.equals(chapter.id))).write(
      ChaptersCompanion(
        metadataAttempts: Value<int>(chapter.metadataAttempts + 1),
      ),
    );
  }

  Future<int> _countPending(String libraryRootId) async {
    final row = await _database
        .customSelect(
          'SELECT COUNT(*) AS c FROM chapters '
          'WHERE library_root_id = ? AND duration_ms IS NULL AND missing = 0 '
          'AND metadata_attempts < ?',
          variables: <Variable<Object>>[
            Variable<String>(libraryRootId),
            const Variable<int>(maxMetadataAttempts),
          ],
        )
        .getSingle();
    return row.data['c'] as int? ?? 0;
  }
}

class _Collection {
  _Collection({required this.nodes, required this.failedPaths});

  final List<ScanNode> nodes;
  final List<String> failedPaths;
}

class _Snapshot {
  _Snapshot({
    required this.books,
    required this.volumes,
    required this.chapters,
  });

  final List<Book> books;
  final List<Volume> volumes;
  final List<Chapter> chapters;
}

class _Plan {
  final List<BooksCompanion> bookInserts = <BooksCompanion>[];
  final List<({String id, BooksCompanion data})> bookUpdates =
      <({String id, BooksCompanion data})>[];
  final List<({String bookId, BookMetadataDraft metadata})> metadataOverrides =
      <({String bookId, BookMetadataDraft metadata})>[];
  final List<VolumesCompanion> volumeInserts = <VolumesCompanion>[];
  final List<({String id, VolumesCompanion data})> volumeUpdates =
      <({String id, VolumesCompanion data})>[];
  final List<ChaptersCompanion> chapterInserts = <ChaptersCompanion>[];
  final List<({String id, ChaptersCompanion data})> chapterUpdates =
      <({String id, ChaptersCompanion data})>[];

  int booksAdded = 0;
  int booksUpdated = 0;
  int volumesAdded = 0;
  int chaptersSeen = 0;
  int chaptersAdded = 0;
  int chaptersUpdated = 0;
  int chaptersMarkedMissing = 0;
  int chaptersRestored = 0;
}
