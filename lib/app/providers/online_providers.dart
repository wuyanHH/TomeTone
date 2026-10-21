import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/online_book_service.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/source_engine_providers.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';

final Provider<OnlineLibraryQueries> onlineLibraryQueriesProvider =
    Provider<OnlineLibraryQueries>((Ref ref) {
      return DriftOnlineLibraryQueries(
        ref.watch(databaseProvider),
        idGenerator: UlidIdGenerator(),
      );
    });

final Provider<OnlineBookService> onlineBookServiceProvider =
    Provider<OnlineBookService>((Ref ref) {
      return OnlineBookService(
        queries: ref.watch(onlineLibraryQueriesProvider),
        discovery: ref.watch(sourceDiscoveryProvider),
      );
    });
