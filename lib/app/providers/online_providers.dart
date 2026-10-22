import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/online_book_service.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/source_engine_providers.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/contracts/audio/audio_cache_repository.dart';
import 'package:tometone/contracts/network/network_monitor.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';

final Provider<AudioCacheRepository> audioCacheRepositoryProvider =
    Provider<AudioCacheRepository>((Ref ref) {
      throw UnimplementedError(
        'audioCacheRepositoryProvider 未装配：请在 ProviderScope.overrides 中注入',
      );
    });

final Provider<NetworkMonitor> networkMonitorProvider =
    Provider<NetworkMonitor>((Ref ref) {
      throw UnimplementedError(
        'networkMonitorProvider 未装配：请在 ProviderScope.overrides 中注入',
      );
    });

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
        sourceQueries: ref.watch(bookSourceQueriesProvider),
        cacheRepository: ref.watch(audioCacheRepositoryProvider),
      );
    });
