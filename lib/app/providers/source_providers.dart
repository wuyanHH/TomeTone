import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/sources/book_source_service.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
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
