import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/book_metadata_service.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/library_root_providers.dart';

/// 书架元数据服务（详情页编辑 / 从书根重新导入）。
///
/// 依赖 [libraryQueriesProvider]（DB 写入）与 [bookMetadataFileStoreFactoryProvider]
/// （sidecar 读写，由 `main.dart` 按根 URI 装配实现）。
final Provider<BookMetadataService> bookMetadataServiceProvider =
    Provider<BookMetadataService>(
      (Ref ref) => BookMetadataService(
        queries: ref.watch(libraryQueriesProvider),
        storeFactory: ref.watch(bookMetadataFileStoreFactoryProvider),
      ),
    );
