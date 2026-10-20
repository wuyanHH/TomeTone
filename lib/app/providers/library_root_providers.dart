import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/library_root_service.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/contracts/storage/book_metadata_file_store.dart';
import 'package:tometone/contracts/storage/directory_picker.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';

/// 按根 URI 构造 provider 的工厂。**必须**在 `main.dart` 中 override ——
/// 应用层不允许直接依赖 `lib/modules/`。
final Provider<StorageProviderFactory> storageProviderFactoryProvider =
    Provider<StorageProviderFactory>(
      (Ref ref) => throw UnimplementedError(
        'storageProviderFactoryProvider 未装配：请在 ProviderScope.overrides 中注入',
      ),
    );

/// 按根 URI 构造 sidecar store 的工厂。**必须**在 `main.dart` 中 override ——
/// 应用层不允许直接依赖 `lib/modules/` 里的具体实现。
final Provider<BookMetadataFileStoreFactory>
bookMetadataFileStoreFactoryProvider =
    Provider<BookMetadataFileStoreFactory>(
      (Ref ref) => throw UnimplementedError(
        'bookMetadataFileStoreFactoryProvider 未装配：请在 ProviderScope.overrides 中注入',
      ),
    );

/// 书库根管理与扫描触发。
final Provider<LibraryRootService> libraryRootServiceProvider =
    Provider<LibraryRootService>(
      (Ref ref) => LibraryRootService(
        database: ref.watch(databaseProvider),
        idGenerator: UlidIdGenerator(),
        providerFactory: ref.watch(storageProviderFactoryProvider),
        metadataStoreFactory: ref.watch(bookMetadataFileStoreFactoryProvider),
      ),
    );

/// 目录选择器（SAF）。**必须**在 `main.dart` 中 override。
final Provider<DirectoryPicker> directoryPickerProvider =
    Provider<DirectoryPicker>(
      (Ref ref) => throw UnimplementedError(
        'directoryPickerProvider 未装配：请在 ProviderScope.overrides 中注入',
      ),
    );
