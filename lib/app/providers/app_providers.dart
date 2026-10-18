import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/contracts/playback/playback_engine.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/domain/library/queries/library_views.dart';

/// 数据库实例。**必须**在 `main.dart` 的 `ProviderScope` 中 override。
///
/// 默认实现直接抛错而不是返回一个内存库：漏装配应该在启动时就炸，
/// 而不是让应用静默跑在一个空数据库上、用户以为书库丢了。
final Provider<TomeToneDatabase> databaseProvider = Provider<TomeToneDatabase>(
  (Ref ref) => throw UnimplementedError(
    'databaseProvider 未装配：请在 ProviderScope.overrides 中注入',
  ),
);

/// 播放引擎。**必须**在 `main.dart` 中 override（注入具体实现，§5.2）。
final Provider<PlaybackEngine> playbackEngineProvider =
    Provider<PlaybackEngine>(
      (Ref ref) => throw UnimplementedError(
        'playbackEngineProvider 未装配：请在 ProviderScope.overrides 中注入',
      ),
    );

/// 书库查询（UI 只依赖这个端口，不感知 Drift）。
final Provider<LibraryQueries> libraryQueriesProvider =
    Provider<LibraryQueries>(
      (Ref ref) => DriftLibraryQueries(ref.watch(databaseProvider)),
    );

/// 书架列表。扫描完成后用 `ref.invalidate(booksProvider)` 刷新。
final FutureProvider<List<BookSummary>> booksProvider =
    FutureProvider<List<BookSummary>>(
      (Ref ref) => ref.watch(libraryQueriesProvider).listBooks(),
    );

/// 书详情。
final bookDetailProvider = FutureProvider.family<BookDetail?, String>(
  (Ref ref, String bookId) =>
      ref.watch(libraryQueriesProvider).bookDetail(bookId),
);

/// 书库根列表（设置页 / 筛选用）。
final FutureProvider<List<LibraryRootView>> libraryRootsProvider =
    FutureProvider<List<LibraryRootView>>(
      (Ref ref) => ref.watch(libraryQueriesProvider).libraryRoots(),
    );
