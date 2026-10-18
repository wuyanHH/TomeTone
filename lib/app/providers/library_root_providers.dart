import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/library_root_service.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';

/// 按根 URI 构造 provider 的工厂。**必须**在 `main.dart` 中 override ——
/// 应用层不允许直接依赖 `lib/modules/`。
final Provider<StorageProviderFactory> storageProviderFactoryProvider =
    Provider<StorageProviderFactory>(
      (Ref ref) => throw UnimplementedError(
        'storageProviderFactoryProvider 未装配：请在 ProviderScope.overrides 中注入',
      ),
    );

/// 书库根管理与扫描触发。
final Provider<LibraryRootService> libraryRootServiceProvider =
    Provider<LibraryRootService>(
      (Ref ref) => LibraryRootService(
        database: ref.watch(databaseProvider),
        idGenerator: UlidIdGenerator(),
        providerFactory: ref.watch(storageProviderFactoryProvider),
      ),
    );
