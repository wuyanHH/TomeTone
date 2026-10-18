import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/library_root_providers.dart';
import 'package:tometone/contracts/storage/storage_provider.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/modules/playback_just_audio/just_audio_playback_engine.dart';
import 'package:tometone/modules/storage_local/local_storage_provider.dart';
import 'package:tometone/modules/storage_saf/saf_storage_provider.dart';
import 'package:tometone/platform/database_connection.dart';
import 'package:tometone/platform/saf/saf_bridge.dart';
import 'package:tometone/ui/app.dart';

/// TomeTone（听卷）装配入口 —— 全仓库唯一的 composition root。
///
/// 依赖方向铁律（《架构需求文档》§5.2）：UI / 应用 / 领域层只依赖契约层
/// （`lib/contracts/`），具体模块实现（`lib/modules/`）只能在这里注入。
/// 本文件由 `tool/ci/check_import_boundaries.dart` 显式豁免。
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 数据库与引擎是进程级单例：随进程生命周期存在，退出即由系统回收。
  final database = TomeToneDatabase(openTomeToneDatabaseConnection());
  final engine = JustAudioPlaybackEngine();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        playbackEngineProvider.overrideWithValue(engine),
        storageProviderFactoryProvider.overrideWithValue(_createProvider),
        directoryPickerProvider.overrideWithValue(const SafBridge()),
      ],
      child: const TomeToneApp(),
    ),
  );
}

/// 按根 URI 选实现：`content://` 走 SAF，其余按本地绝对路径处理。
///
/// 用 scheme 而不是 `library_roots.type` 判断，是因为工厂只拿到 URI；
/// 若将来出现第三种 provider（WebDAV），这里改为传 type 即可。
StorageProvider _createProvider(String rootUri) {
  if (rootUri.startsWith('content://')) {
    return SafStorageProvider(rootUri);
  }
  return LocalStorageProvider(rootUri);
}
