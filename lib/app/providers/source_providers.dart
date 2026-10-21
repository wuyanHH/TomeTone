import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/sources/book_source_service.dart';
import 'package:tometone/app/sources/io_source_import_loader.dart';
import 'package:tometone/contracts/sources/source_import_loader.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/book_source_queries.dart';

final Provider<BookSourceQueries> bookSourceQueriesProvider =
    Provider<BookSourceQueries>((Ref ref) {
      return DriftBookSourceQueries(ref.watch(databaseProvider));
    });

final Provider<BookSourceService> bookSourceServiceProvider =
    Provider<BookSourceService>((Ref ref) {
      return BookSourceService(
        database: ref.watch(databaseProvider),
        queries: ref.watch(bookSourceQueriesProvider),
        idGenerator: UlidIdGenerator(),
      );
    });

final Provider<SourceImportLoader> sourceImportLoaderProvider =
    Provider<SourceImportLoader>((Ref ref) {
      return const IoSourceImportLoader();
    });

/// 按 ID 读取书源；在线书封面/详情需要源 header。
final bookSourceByIdProvider = FutureProvider.family<BookSource?, String>((
  Ref ref,
  String id,
) {
  return ref.watch(bookSourceQueriesProvider).sourceById(id);
});
