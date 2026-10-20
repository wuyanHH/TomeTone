import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';

/// 固定时间基准（drift 默认把 `DateTime` 存为 UTC 秒级时间戳，故不带毫秒）。
final DateTime _t0 = DateTime.utc(2026, 10, 18, 3);

Future<void> _seedLibraryRoot(TomeToneDatabase db) async {
  await db
      .into(db.libraryRoots)
      .insert(
        LibraryRootsCompanion.insert(
          id: 'root-1',
          type: 'local',
          uri: '/storage/emulated/0/Books',
          displayName: '内部存储',
          createdAt: _t0,
        ),
      );
}

Future<void> _seedBook(
  TomeToneDatabase db, {
  String id = 'book-1',
  String rootPath = '三体',
}) async {
  await db
      .into(db.books)
      .insert(
        BooksCompanion.insert(
          id: id,
          libraryRootId: 'root-1',
          title: '三体',
          rootPath: rootPath,
          sourceType: 'local',
          createdAt: _t0,
          updatedAt: _t0,
        ),
      );
}

Future<void> _seedVolume(TomeToneDatabase db, {String id = 'vol-1'}) async {
  await db
      .into(db.volumes)
      .insert(
        VolumesCompanion.insert(
          id: id,
          bookId: 'book-1',
          title: '第一卷',
          volumeIndex: 0,
          path: '',
          updatedAt: _t0,
        ),
      );
}

ChaptersCompanion _chapter({
  String id = 'ch-1',
  String bookId = 'book-1',
  String volumeId = 'vol-1',
  String libraryRootId = 'root-1',
  String filePath = '三体/001.mp3',
  int chapterIndex = 0,
  String? sourceUri,
  int? durationMs,
  int? sizeBytes,
}) {
  return ChaptersCompanion.insert(
    id: id,
    bookId: bookId,
    volumeId: volumeId,
    libraryRootId: libraryRootId,
    title: '第一章',
    chapterIndex: chapterIndex,
    filePath: filePath,
    sourceUri: Value<String?>(sourceUri),
    durationMs: Value<int?>(durationMs),
    sizeBytes: Value<int?>(sizeBytes),
    updatedAt: _t0,
  );
}

void main() {
  late TomeToneDatabase db;

  setUp(() {
    db = TomeToneDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('schema', () {
    test('schemaVersion 为 2', () {
      expect(db.schemaVersion, 2);
    });

    test('建库后 10 张业务表齐备', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      final names = rows
          .map((QueryRow row) => row.data['name'] as String)
          .toSet();

      expect(
        names,
        containsAll(<String>[
          'library_roots',
          'books',
          'volumes',
          'chapters',
          'book_metadata_overrides',
          'book_tags',
          'playback_progress',
          'per_book_prefs',
          'listening_records',
          'storage_accounts',
        ]),
      );
    });

    test('外键约束在每个连接上开启', () async {
      final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(row.data.values.first, 1);
    });

    test('时间列保留瞬时、截断毫秒（读回为本地 DateTime）', () async {
      final withMillis = DateTime.utc(2026, 10, 18, 3, 0, 0, 789);
      await db
          .into(db.libraryRoots)
          .insert(
            LibraryRootsCompanion.insert(
              id: 'root-t',
              type: 'local',
              uri: '/x',
              displayName: 'x',
              createdAt: withMillis,
            ),
          );

      final row = await db.select(db.libraryRoots).getSingle();
      expect(
        row.createdAt.millisecondsSinceEpoch ~/ 1000,
        withMillis.millisecondsSinceEpoch ~/ 1000,
        reason: '同一瞬时（秒级）',
      );
      expect(row.createdAt.millisecond, 0, reason: '毫秒被截断');
    });

    test('封面档位按枚举读写，默认字标兜底', () async {
      await _seedLibraryRoot(db);
      await _seedBook(db);

      var book = await db.select(db.books).getSingle();
      expect(book.coverSourceType, CoverSource.typography);

      await (db.update(
        db.books,
      )..where((tbl) => tbl.id.equals('book-1'))).write(
        const BooksCompanion(
          coverSourceType: Value<CoverSource>(CoverSource.firstVolumeFeedback),
        ),
      );

      book = await db.select(db.books).getSingle();
      expect(book.coverSourceType, CoverSource.firstVolumeFeedback);
    });

    test('sourceUri / durationMs / sizeBytes 可为空并可读回', () async {
      await _seedLibraryRoot(db);
      await _seedBook(db);
      await _seedVolume(db);
      await db
          .into(db.chapters)
          .insert(
            _chapter(
              sourceUri: 'https://nas.local/a.mp3',
              durationMs: 180000,
              sizeBytes: 4096,
            ),
          );

      final chapter = await db.select(db.chapters).getSingle();
      expect(chapter.sourceUri, 'https://nas.local/a.mp3');
      expect(chapter.durationMs, 180000);
      expect(chapter.sizeBytes, 4096);
      expect(chapter.missing, isFalse, reason: 'missing 默认 false');
      // drift 按 UTC epoch 秒存储、按本地时区读回；比较必须归一化到 UTC。
      expect(chapter.updatedAt.toUtc(), _t0);
      expect(
        chapter.updatedAt.millisecondsSinceEpoch,
        _t0.millisecondsSinceEpoch,
      );
    });
  });

  group('完整性约束', () {
    test('外键指向不存在的书时插入失败', () async {
      await _seedLibraryRoot(db);
      await _seedBook(db);
      await _seedVolume(db);

      await expectLater(
        db.into(db.chapters).insert(_chapter(bookId: 'missing-book')),
        throwsA(
          predicate(
            (Object error) => error.toString().contains('FOREIGN KEY'),
            '外键约束错误',
          ),
        ),
      );
    });

    test('同一书库根下的同一相对路径只能绑定一个章（绑定键唯一）', () async {
      await _seedLibraryRoot(db);
      await _seedBook(db);
      await _seedVolume(db);
      await db.into(db.chapters).insert(_chapter());

      await expectLater(
        db.into(db.chapters).insert(_chapter(id: 'ch-2', chapterIndex: 1)),
        throwsA(
          predicate(
            (Object error) => error.toString().contains('UNIQUE'),
            '唯一索引冲突',
          ),
        ),
      );
    });

    test('同一书库根下的同一书根路径只能有一本书', () async {
      await _seedLibraryRoot(db);
      await _seedBook(db);

      await expectLater(
        db
            .into(db.books)
            .insert(
              BooksCompanion.insert(
                id: 'book-2',
                libraryRootId: 'root-1',
                title: '三体（重复）',
                rootPath: '三体',
                sourceType: 'local',
                createdAt: _t0,
                updatedAt: _t0,
              ),
            ),
        throwsA(
          predicate(
            (Object error) => error.toString().contains('UNIQUE'),
            '唯一索引冲突',
          ),
        ),
      );
    });

    test('不同书库根下同名路径互不冲突', () async {
      await _seedLibraryRoot(db);
      await db
          .into(db.libraryRoots)
          .insert(
            LibraryRootsCompanion.insert(
              id: 'root-2',
              type: 'saf',
              uri: 'content://tree/books',
              displayName: 'SD 卡',
              createdAt: _t0,
            ),
          );
      await _seedBook(db);
      await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              id: 'book-2',
              libraryRootId: 'root-2',
              title: '三体',
              rootPath: '三体',
              sourceType: 'saf',
              createdAt: _t0,
              updatedAt: _t0,
            ),
          );

      expect(await db.select(db.books).get(), hasLength(2));
    });
  });

  group('级联与保留语义', () {
    test('删书级联清理卷 / 章 / 偏好 / 进度 / 纪录', () async {
      await _seedLibraryRoot(db);
      await _seedBook(db);
      await _seedVolume(db);
      await db.into(db.chapters).insert(_chapter());
      await db
          .into(db.perBookPrefs)
          .insert(
            PerBookPrefsCompanion.insert(bookId: 'book-1', updatedAt: _t0),
          );
      await db
          .into(db.playbackProgress)
          .insert(
            PlaybackProgressCompanion.insert(
              bookId: 'book-1',
              chapterId: 'ch-1',
              positionMs: 12345,
              updatedAt: _t0,
            ),
          );
      await db
          .into(db.listeningRecords)
          .insert(
            ListeningRecordsCompanion.insert(
              id: 'rec-1',
              bookId: 'book-1',
              startedAt: _t0,
              durationMs: 30000,
            ),
          );

      await (db.delete(db.books)..where((tbl) => tbl.id.equals('book-1'))).go();

      expect(await db.select(db.books).get(), isEmpty);
      expect(await db.select(db.volumes).get(), isEmpty);
      expect(await db.select(db.chapters).get(), isEmpty);
      expect(await db.select(db.perBookPrefs).get(), isEmpty);
      expect(await db.select(db.playbackProgress).get(), isEmpty);
      expect(await db.select(db.listeningRecords).get(), isEmpty);
    });

    test('缺失章节只标记 missing，不删记录与进度', () async {
      await _seedLibraryRoot(db);
      await _seedBook(db);
      await _seedVolume(db);
      await db.into(db.chapters).insert(_chapter());
      await db
          .into(db.playbackProgress)
          .insert(
            PlaybackProgressCompanion.insert(
              bookId: 'book-1',
              chapterId: 'ch-1',
              positionMs: 99000,
              updatedAt: _t0,
            ),
          );

      await (db.update(db.chapters)..where((tbl) => tbl.id.equals('ch-1')))
          .write(const ChaptersCompanion(missing: Value<bool>(true)));

      final chapter = await db.select(db.chapters).getSingle();
      expect(chapter.missing, isTrue);
      expect(await db.select(db.playbackProgress).get(), hasLength(1));
    });
  });

  group('进度与偏好', () {
    test('进度按书 upsert，重复写入只保留一条', () async {
      await _seedLibraryRoot(db);
      await _seedBook(db);
      await _seedVolume(db);
      await db.into(db.chapters).insert(_chapter());

      await db
          .into(db.playbackProgress)
          .insertOnConflictUpdate(
            PlaybackProgressCompanion.insert(
              bookId: 'book-1',
              chapterId: 'ch-1',
              positionMs: 1000,
              updatedAt: _t0,
            ),
          );
      await db
          .into(db.playbackProgress)
          .insertOnConflictUpdate(
            PlaybackProgressCompanion.insert(
              bookId: 'book-1',
              chapterId: 'ch-1',
              positionMs: 2000,
              updatedAt: _t0,
            ),
          );

      final progress = await db.select(db.playbackProgress).getSingle();
      expect(progress.positionMs, 2000);
    });

    test('偏好默认值符合文档', () async {
      await _seedLibraryRoot(db);
      await _seedBook(db);
      await db
          .into(db.perBookPrefs)
          .insert(
            PerBookPrefsCompanion.insert(bookId: 'book-1', updatedAt: _t0),
          );

      final prefs = await db.select(db.perBookPrefs).getSingle();
      expect(prefs.speed, 1.0);
      expect(prefs.skipIntroSec, 0);
      expect(prefs.skipOutroSec, 0);
      expect(prefs.rewindOverride, isNull);
    });
  });

  group('迁移纪律', () {
    test('创建与升级回调均已注册（schemaVersion 提升必须走显式迁移）', () {
      expect(db.migration.onCreate, isNotNull);
      expect(
        db.migration.onUpgrade,
        isNotNull,
        reason: '缺少 onUpgrade 时 drift 会默认丢库重建，违反 §8.3 禁止破坏性迁移',
      );
    });
  });
}
