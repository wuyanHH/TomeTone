import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';

/// 用于把 `NativeDatabase`（裸 [QueryExecutor]）打开并写入 v1 schema 的占位用户。
///
/// `NativeDatabase` 不是 `GeneratedDatabase`，没有 `customStatement` 等高层 API；
/// 通过实现 [QueryExecutorUser] 并调用 `ensureOpen`，可让连接以 `user_version = 1`
/// 打开，随后用 [QueryExecutor.runCustom] 直接执行 DDL/DML。
class _V1SchemaUser implements QueryExecutorUser {
  const _V1SchemaUser();

  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

/// 手工构造一个 v1 库（旧列集合：无 `manual_edited_at` / `finished_at` / `book_tags`），
/// 并写入一条书库根、一条书、一条覆盖层，`user_version` 置 1。
///
/// 注：迁移会 `addColumn(playback_progress, finished_at)`，故 v1 库必须已存在
/// `playback_progress` 表（否则 `ALTER TABLE` 会因缺表失败）；其余 v2 前就有的表
/// 与本次迁移无关，为保持用例聚焦只建被断言涉及的表。
Future<void> _createV1Database(File file) async {
  final raw = NativeDatabase(file);
  await raw.ensureOpen(const _V1SchemaUser());
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
      CREATE TABLE book_metadata_overrides (
        book_id TEXT NOT NULL PRIMARY KEY,
        title TEXT,
        author TEXT,
        narrator TEXT,
        series_name TEXT,
        series_index INTEGER,
        description TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');
    await raw.runCustom('''
      CREATE TABLE playback_progress (
        book_id TEXT NOT NULL PRIMARY KEY,
        chapter_id TEXT NOT NULL,
        position_ms INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await raw.runCustom(
      "INSERT INTO library_roots (id, type, uri, display_name, created_at) VALUES ('root-1', 'local', '/storage/Books', '内部存储', 0)",
    );
    await raw.runCustom(
      "INSERT INTO books (id, library_root_id, title, root_path, source_type, created_at, updated_at) VALUES ('book-1', 'root-1', '三体', '三体', 'local', 0, 0)",
    );
    await raw.runCustom(
      "INSERT INTO book_metadata_overrides (book_id, title, updated_at) VALUES ('book-1', '覆盖标题', 0)",
    );

    // `ensureOpen` 已通过 `DynamicVersionDelegate` 把 `user_version` 置为 1；
    // 这里显式再设一次，与 brief「PRAGMA user_version = 1」保持一致。
    await raw.runCustom('PRAGMA user_version = 1');
  } finally {
    await raw.close();
  }
}

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('tometone_v2_');
    dbFile = File('${tempDir.path}/migration_v2.db');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('v1 库增量升级到 v2：增列增表且保留既有覆盖层数据', () async {
    await _createV1Database(dbFile);

    final db = TomeToneDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);

    expect(db.schemaVersion, 2);

    final columns = await db
        .customSelect("PRAGMA table_info('book_metadata_overrides')")
        .get();
    expect(
      columns.map((r) => r.read<String>('name')),
      contains('manual_edited_at'),
    );

    final progressColumns = await db
        .customSelect("PRAGMA table_info('playback_progress')")
        .get();
    expect(
      progressColumns.map((r) => r.read<String>('name')),
      contains('finished_at'),
    );

    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
        .get();
    expect(tables.map((r) => r.read<String>('name')), contains('book_tags'));

    expect(await db.select(db.bookMetadataOverrides).get(), hasLength(1));
  });
}
