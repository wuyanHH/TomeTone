import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:tometone/app/app_info.dart';
import 'package:tometone/app/library/library_root_service.dart';
import 'package:tometone/app/preferences/app_preferences_store.dart';
import 'package:tometone/app/providers/apk_download_providers.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/library_root_providers.dart';
import 'package:tometone/app/providers/online_providers.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/app/providers/source_engine_providers.dart';
import 'package:tometone/app/providers/update_providers.dart';
import 'package:tometone/contracts/media/media_source_resolver.dart';
import 'package:tometone/contracts/storage/book_metadata_file_store.dart';
import 'package:tometone/contracts/storage/storage_provider.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/modules/audio/audio_cache_repository_impl.dart';
import 'package:tometone/modules/network/network_monitor_impl.dart';
import 'package:tometone/modules/playback_just_audio/just_audio_playback_engine.dart';
import 'package:tometone/modules/source_http/io_source_http_client.dart';
import 'package:tometone/modules/storage_local/local_book_metadata_file_store.dart';
import 'package:tometone/modules/storage_local/local_media_source_resolver.dart';
import 'package:tometone/modules/storage_local/local_storage_provider.dart';
import 'package:tometone/modules/storage_saf/saf_book_metadata_file_store.dart';
import 'package:tometone/modules/storage_saf/saf_media_source_resolver.dart';
import 'package:tometone/modules/storage_saf/saf_storage_provider.dart';
import 'package:tometone/modules/update_github/github_releases_source.dart';
import 'package:tometone/platform/database_connection.dart';
import 'package:tometone/platform/device/abi_bridge.dart';
import 'package:tometone/platform/device/platform_package_installer.dart';
import 'package:tometone/platform/saf/saf_bridge.dart';
import 'package:tometone/ui/app.dart';

/// TomeTone（听卷）装配入口 —— 全仓库唯一的 composition root。
///
/// 依赖方向铁律（《架构需求文档》§5.2）：UI / 应用 / 领域层只依赖契约层
/// （`lib/contracts/`），具体模块实现（`lib/modules/`）只能在这里注入。
/// 本文件由 `tool/ci/check_import_boundaries.dart` 显式豁免。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefsStore = SharedPreferencesAppPreferencesStore();
  final initialPrefs = await prefsStore.load();

  // 数据库与引擎是进程级单例：随进程生命周期存在，退出即由系统回收。
  final database = TomeToneDatabase(openTomeToneDatabaseConnection());
  final engine = JustAudioPlaybackEngine();
  final audioCache = AudioCacheRepositoryImpl(
    cacheRoot: Directory('${Directory.systemTemp.path}/tometone_audio_cache'),
  );

  // 平台桥同时承担「目录选择」与「放弃授权」两种能力（接口见契约层），
  // 复用同一份 const 实例：两处共用一条 MethodChannel，不必 new 第二份。
  const safBridge = SafBridge();

  runApp(
    ProviderScope(
      overrides: [
        preferencesStoreProvider.overrideWithValue(prefsStore),
        initialPreferencesProvider.overrideWithValue(initialPrefs),
        databaseProvider.overrideWithValue(database),
        playbackEngineProvider.overrideWithValue(engine),
        sourceHttpClientProvider.overrideWithValue(IoSourceHttpClient()),
        storageProviderFactoryProvider.overrideWithValue(_createProvider),
        bookMetadataFileStoreFactoryProvider.overrideWithValue(
          _createMetadataStore,
        ),
        mediaSourceResolverFactoryProvider.overrideWithValue(_createResolver),
        directoryPickerProvider.overrideWithValue(safBridge),
        networkMonitorProvider.overrideWithValue(NetworkMonitorImpl()),
        audioCacheRepositoryProvider.overrideWithValue(audioCache),
        deviceArchitectureProvider.overrideWithValue(const AbiBridge()),
        packageInstallerProvider.overrideWithValue(
          const PlatformPackageInstaller(),
        ),
        updateSourceProvider.overrideWithValue(
          GithubReleasesSource(
            client: http.Client(),
            owner: AppInfo.githubOwner,
            repo: AppInfo.githubRepo,
            userAgent: 'TomeTone/${AppInfo.version}',
          ),
        ),
        // 书库根服务默认装配（`lib/app/providers/` 内）拿不到平台桥，
        // 因此在装配入口 override，注入 authorization 让「移除 SAF 根」能放弃授权。
        libraryRootServiceProvider.overrideWithValue(
          LibraryRootService(
            database: database,
            idGenerator: UlidIdGenerator(),
            providerFactory: _createProvider,
            authorization: safBridge,
            metadataStoreFactory: _createMetadataStore,
          ),
        ),
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

/// 按根 URI 选 sidecar store：`content://` 走 SAF（只读），其余按本地绝对路径。
BookMetadataFileStore _createMetadataStore(String rootUri) {
  if (rootUri.startsWith('content://')) {
    return SafBookMetadataFileStore(rootUri);
  }
  return LocalBookMetadataFileStore(rootUri);
}

/// 按根类型选媒体源 resolver：SAF 走 document URI，其余按本地绝对路径处理。
///
/// WebDAV 等尚未适配的类型暂时回落本地实现 —— 未知类型至少不会让播放
/// 直接失效（与 `libraryRootKindOf` 的宽容口径一致）。
MediaSourceResolver _createResolver({
  required String libraryRootUri,
  required LibraryRootKind kind,
}) {
  return switch (kind) {
    LibraryRootKind.saf => SafMediaSourceResolver(libraryRootUri),
    _ => LocalMediaSourceResolver(libraryRootUri),
  };
}
