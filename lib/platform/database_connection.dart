import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// 打开生产数据库连接（Android 应用私有目录）。
///
/// 放在平台层而不是领域层：领域层的 `TomeToneDatabase` 只接收 [QueryExecutor]，
/// 因此可以在纯 Dart 测试里用 `NativeDatabase.memory()` 跑，不依赖 Flutter。
///
/// 两个 PRAGMA 在这里设置而不是 `beforeOpen`：
/// `journal_mode` 必须在任何事务之外执行，`setup` 拿到的正是原始 sqlite3 句柄。
QueryExecutor openTomeToneDatabaseConnection({
  String name = 'tometone',
  bool shareAcrossIsolates = false,
}) {
  return driftDatabase(
    name: name,
    native: DriftNativeOptions(
      shareAcrossIsolates: shareAcrossIsolates,
      setup: (db) {
        // §2.2：进度写入可靠性依赖 WAL（模式持久化在数据库文件里）。
        db.execute('PRAGMA journal_mode = WAL');
        // 每个连接都要开，SQLite 默认关闭。
        db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}
