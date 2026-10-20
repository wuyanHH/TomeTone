import 'package:drift/drift.dart';

import '../cover/cover_source.dart';
import 'tables.dart';

part 'tometone_database.g.dart';

/// TomeTone 本地数据库（《架构需求文档》§8 数据模型与持久化）。
///
/// 连接通过 [QueryExecutor] 注入，因此本类**不依赖 Flutter**：
/// - 生产：`NativeDatabase` 指向应用私有目录，开启 WAL；
/// - 单元测试：`NativeDatabase.memory()`，纯 Dart 环境即可运行；
/// - 未来桌面端：换成对应平台的 executor 即可，schema 与迁移不变。
@DriftDatabase(
  tables: <Type>[
    LibraryRoots,
    Books,
    Volumes,
    Chapters,
    BookMetadataOverrides,
    BookTags,
    PlaybackProgress,
    PerBookPrefs,
    ListeningRecords,
    StorageAccounts,
  ],
)
class TomeToneDatabase extends _$TomeToneDatabase {
  /// 创建数据库实例。
  TomeToneDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      // §8.3 三条线之一：Drift Migration **必须手写**，禁止破坏性迁移（保用户数据）。
      //
      // v1 → v2 只增列、增表，不改列、不删表、不重建库：
      // - `book_metadata_overrides` 增 `manual_edited_at`；
      // - `playback_progress` 增 `finished_at`；
      // - 新建 `book_tags`。
      if (from < 2) {
        await migrator.addColumn(
          bookMetadataOverrides,
          bookMetadataOverrides.manualEditedAt,
        );
        await migrator.addColumn(playbackProgress, playbackProgress.finishedAt);
        await migrator.createTable(bookTags);
      }
    },
    beforeOpen: (OpeningDetails details) async {
      // SQLite 默认不启用外键约束，必须每个连接显式开启。
      //
      // WAL 不在这里设置：`PRAGMA journal_mode` 必须在任何事务之外执行，
      // 由连接工厂在 `DriftNativeOptions.setup` 中对原始句柄设置
      // （见 `lib/platform/database_connection.dart`）。
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
