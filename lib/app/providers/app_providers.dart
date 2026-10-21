import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/cover_art.dart';
import 'package:tometone/app/library/cover_paths.dart';
import 'package:tometone/contracts/media/media_source_resolver.dart';
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
      (Ref ref) => ref.watch(libraryQueriesProvider).listAllBooks(),
    );

/// 书架列表：只保留 `onShelf=true` 的书（在线书默认不入书架）。
final FutureProvider<List<BookSummary>> shelfBooksProvider =
    FutureProvider<List<BookSummary>>((Ref ref) async {
      final List<BookSummary> all = await ref.watch(booksProvider.future);
      return <BookSummary>[
        for (final BookSummary book in all)
          if (book.onShelf) book,
      ];
    });

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

/// 媒体源 resolver 工厂。**必须**在 `main.dart` 中 override ——
/// 应用层不允许直接依赖 `lib/modules/` 里的具体实现。
final Provider<MediaSourceResolverFactory> mediaSourceResolverFactoryProvider =
    Provider<MediaSourceResolverFactory>(
      (Ref ref) => throw UnimplementedError(
        'mediaSourceResolverFactoryProvider 未装配：请在 ProviderScope.overrides 中注入',
      ),
    );

/// 按书库根 ID 构造媒体源 resolver；根还没加载出来 / 找不到时返回 `null`。
///
/// 根元数据来自 [libraryRootsProvider]，类型经 [libraryRootKindOf] 归一化；
/// 具体实现（本地 / SAF）由 [mediaSourceResolverFactoryProvider] 注入。
/// 根尚未加载完成时返回 `null`，调用方据此走「根缺失」文案而不是崩溃。
final mediaSourceResolverForRootProvider =
    Provider.family<MediaSourceResolver?, String>((Ref ref, String rootId) {
      final List<LibraryRootView>? roots = ref
          .watch(libraryRootsProvider)
          .value;
      if (roots == null) {
        return null;
      }
      for (final LibraryRootView root in roots) {
        if (root.id == rootId) {
          final MediaSourceResolverFactory factory = ref.watch(
            mediaSourceResolverFactoryProvider,
          );
          return factory(
            libraryRootUri: root.uri,
            kind: libraryRootKindOf(root.type),
          );
        }
      }
      return null;
    });

/// 封面来源：本地根走绝对路径（省内存），SAF 根读字节；取不到返回 `null`。
///
/// 无封面（`coverPath` 为空）/ 根缺失 / SAF 读不出字节都返回 `null`，
/// UI 据此只画字标兜底，绝不留空白或闪烁占位。
final coverArtProvider = FutureProvider.autoDispose
    .family<CoverArt?, CoverArtKey>((Ref ref, CoverArtKey key) async {
      final String? relative = key.coverPath;
      if (relative == null || relative.isEmpty) {
        return null;
      }
      final List<LibraryRootView> roots =
          ref.watch(libraryRootsProvider).value ?? const <LibraryRootView>[];
      LibraryRootView? root;
      for (final LibraryRootView candidate in roots) {
        if (candidate.id == key.rootId) {
          root = candidate;
          break;
        }
      }
      if (root == null) {
        return null;
      }
      if (libraryRootKindOf(root.type) == LibraryRootKind.saf) {
        final MediaSourceResolver? resolver = ref.watch(
          mediaSourceResolverForRootProvider(key.rootId),
        );
        if (resolver == null) {
          return null;
        }
        final Uint8List? bytes = await resolver.readBytes(
          relativePath: relative,
        );
        return bytes == null ? null : CoverArtBytes(bytes);
      }
      final String? absolute = absoluteCoverPath(
        relativePath: relative,
        libraryRootUri: root.uri,
      );
      return absolute == null ? null : CoverArtFile(absolute);
    });
