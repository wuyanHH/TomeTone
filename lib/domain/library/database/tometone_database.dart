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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      // §8.3 三条线之一：Drift Migration **必须手写**，禁止破坏性迁移（保用户数据）。
      //
      // v1 是首个 schema，尚不存在历史版本；一旦 schemaVersion 提升，
      // 必须在此按 `from → to` 增量实现迁移，而不是让用户丢库重建。
      throw UnsupportedError('缺少 $from → $to 的数据库迁移步骤：禁止破坏性迁移（《架构需求文档》§8.3）');
    },
    beforeOpen: (OpeningDetails details) async {
      // SQLite 默认不启用外键约束，必须每个连接显式开启。
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.wasCreated) {
        // §2.2 进度写入可靠性依赖 WAL；模式持久化在数据库文件中，建库时设置一次即可。
        await customStatement('PRAGMA journal_mode = WAL');
      }
    },
  );
}
