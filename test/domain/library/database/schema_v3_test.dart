import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';

/// 让裸 [NativeDatabase] 以 v2 打开，便于手工写 v2 最小 schema。
class _V2SchemaUser implements QueryExecutorUser {
  const _V2SchemaUser();

  @override
  int get schemaVersion => 2;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

Future<void> _createV2Database(File file) async {
  final raw = NativeDatabase(file);
  await raw.ensureOpen(const _V2SchemaUser());
  try {
    await raw.runCustom('''
      CREATE TABLE library_roots (
        id TEXT NOT NULL PRIMARY KEY,
        type TEXT NOT NULL,
        uri TEXT NOT NULL,
        display_name TEXT NOT NULL,
        last_scan_at INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
    await raw.runCustom('''
      CREATE TABLE books (
        id TEXT NOT NULL PRIMARY KEY,
        library_root_id TEXT NOT NULL,
        title TEXT NOT NULL,
        author TEXT,
        narrator TEXT,
        series_name TEXT,
        series_index INTEGER,
        root_path TEXT NOT NULL,
        cover_path TEXT,
        cover_source_type INTEGER NOT NULL DEFAULT 4,
        source_type TEXT NOT NULL,
        source_uri TEXT,
        total_chapters INTEGER NOT NULL DEFAULT 0,
        total_duration_ms INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await raw.runCustom('''
      CREATE TABLE chapters (
        id TEXT NOT NULL PRIMARY KEY,
        book_id TEXT NOT NULL,
        volume_id TEXT NOT NULL,
        library_root_id TEXT NOT NULL,
        title TEXT NOT NULL,
        chapter_index INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        source_uri TEXT,
        duration_ms INTEGER,
        size_bytes INTEGER,
        missing INTEGER NOT NULL DEFAULT 0,
        metadata_attempts INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    await raw.runCustom('''
      INSERT INTO library_roots (id, type, uri, display_name, created_at)
      VALUES ('root-1', 'local', '/books', '内部存储', 0)
    ''');
    await raw.runCustom('''
      INSERT INTO books (id, library_root_id, title, root_path, source_type,
        created_at, updated_at)
      VALUES ('book-1', 'root-1', '三体', '三体', 'local', 0, 0)
    ''');
    await raw.runCustom('''
      INSERT INTO chapters (id, book_id, volume_id, library_root_id, title,
        chapter_index, file_path, updated_at)
      VALUES ('ch-1', 'book-1', 'vol-1', 'root-1', '第一章', 0,
        '三体/001.mp3', 0)
    ''');
    await raw.runCustom('PRAGMA user_version = 2');
  } finally {
    await raw.close();
  }
}

Future<Set<String>> _tableNames(TomeToneDatabase db) async {
  final rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%'",
      )
      .get();
  return rows.map((QueryRow row) => row.read<String>('name')).toSet();
}

Future<Set<String>> _columnNames(TomeToneDatabase db, String table) async {
  final rows = await db.customSelect("PRAGMA table_info('$table')").get();
  return rows.map((QueryRow row) => row.read<String>('name')).toSet();
}

void main() {
  group('新库 schema v3', () {
    late TomeToneDatabase db;

    setUp(() {
      db = TomeToneDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('版本、业务表与新增列齐备', () async {
      expect(db.schemaVersion, 3);

      expect(
        await _tableNames(db),
        containsAll(<String>[
          'book_sources',
          'audio_cache_entries',
          'app_settings',
        ]),
      );

      expect(
        await _columnNames(db, 'books'),
        containsAll(<String>[
          'on_shelf',
          'source_id',
          'cover_url',
          'description',
          'kind',
          'word_count',
          'source_status',
          'last_chapter',
          'source_updated_at',
          'last_refresh_at',
          'last_refresh_ok',
          'last_refresh_error',
        ]),
      );

      expect(
        await _columnNames(db, 'chapters'),
        containsAll(<String>['retired', 'is_vip']),
      );
    });

    test('旧书默认上架、旧章未退休且非 VIP', () async {
      await db.customStatement('''
        INSERT INTO library_roots (id, type, uri, display_name, created_at)
        VALUES ('root-1', 'local', '/books', '内部存储', 0)
      ''');
      await db.customStatement('''
        INSERT INTO books (id, library_root_id, title, root_path, source_type,
          created_at, updated_at)
        VALUES ('book-1', 'root-1', '三体', '三体', 'local', 0, 0)
      ''');
      await db.customStatement('''
        INSERT INTO volumes (id, book_id, title, volume_index, path, updated_at)
        VALUES ('vol-1', 'book-1', '第一卷', 0, '', 0)
      ''');
      await db.customStatement('''
        INSERT INTO chapters (id, book_id, volume_id, library_root_id, title,
          chapter_index, file_path, updated_at)
        VALUES ('ch-1', 'book-1', 'vol-1', 'root-1', '第一章', 0,
          '三体/001.mp3', 0)
      ''');

      final book = await db
          .customSelect('SELECT on_shelf, source_id FROM books')
          .getSingle();
      expect(book.read<bool>('on_shelf'), isTrue);
      expect(book.read<String?>('source_id'), isNull);

      final chapter = await db
          .customSelect('SELECT retired, is_vip FROM chapters')
          .getSingle();
      expect(chapter.read<bool>('retired'), isFalse);
      expect(chapter.read<bool>('is_vip'), isFalse);
    });
  });

  group('v2 → v3', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('tometone_v3_');
      dbFile = File('${tempDir.path}/migration_v3.db');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('保留旧数据，补默认值并建新表', () async {
      await _createV2Database(dbFile);

      final db = TomeToneDatabase(NativeDatabase(dbFile));
      addTearDown(db.close);

      expect(db.schemaVersion, 3);
      expect(
        await _tableNames(db),
        containsAll(<String>[
          'book_sources',
          'audio_cache_entries',
          'app_settings',
        ]),
      );

      final book = await db
          .customSelect(
            "SELECT title, on_shelf, source_id FROM books WHERE id = 'book-1'",
          )
          .getSingle();
      expect(book.read<String>('title'), '三体');
      expect(book.read<bool>('on_shelf'), isTrue);
      expect(book.read<String?>('source_id'), isNull);

      final chapter = await db
          .customSelect(
            "SELECT title, retired, is_vip FROM chapters WHERE id = 'ch-1'",
          )
          .getSingle();
      expect(chapter.read<String>('title'), '第一章');
      expect(chapter.read<bool>('retired'), isFalse);
      expect(chapter.read<bool>('is_vip'), isFalse);
    });
  });
}
