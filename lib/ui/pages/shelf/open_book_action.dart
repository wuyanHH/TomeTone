import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/playback_providers.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/pages/player/player_page.dart';

/// 打开一本书并展开播放台（书架与详情页共用）。
///
/// 根解析、resolver 取用、`openBook`、失败 SnackBar、`showPlayerPage` 都集中
/// 在这里，避免书架与详情页各写一套起播口径。
///
/// [startChapterId] 非空时从指定章起播（详情页点章入口）；为空时走续播进度。
Future<void> openBookAndShowPlayer({
  required BuildContext context,
  required WidgetRef ref,
  required BookDetail detail,
  String? startChapterId,
}) async {
  final BookSummary book = detail.summary;
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  // 根缺失（或根还没加载出来）：走可区分的「根已移除」文案。
  final String? rootUri = _rootUriFor(ref, book.libraryRootId);
  final resolver = ref.read(
    mediaSourceResolverForRootProvider(book.libraryRootId),
  );
  if (rootUri == null || rootUri.isEmpty || resolver == null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('找不到这本书的书库根目录，可能已被移除')),
    );
    return;
  }

  final OpenBookResult result = await openBook(
    controller: ref.read(playbackControllerProvider),
    currentBook: ref.read(currentBookProvider.notifier),
    resolver: resolver,
    detail: detail,
    startChapterId: startChapterId,
  );

  switch (result.status) {
    case OpenBookStatus.failed:
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? '打不开《${book.title}》，请稍后再试')),
      );
    case OpenBookStatus.alreadyOpen:
    case OpenBookStatus.opened:
      if (!context.mounted) {
        return;
      }
      await showPlayerPage(context);
  }
}

/// 由书架列表项起播：先取书详情，再转调 [openBookAndShowPlayer]。
Future<void> playBookFromSummary({
  required BuildContext context,
  required WidgetRef ref,
  required BookSummary book,
}) async {
  final BookDetail? detail = await ref.read(bookDetailProvider(book.id).future);
  if (!context.mounted) {
    return;
  }
  if (detail == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('《${book.title}》的书目信息不完整，无法打开')));
    return;
  }
  await openBookAndShowPlayer(context: context, ref: ref, detail: detail);
}

/// 从已加载的书库根里找某本书的根 URI；根不存在 / 还没加载出来返回 `null`。
String? _rootUriFor(WidgetRef ref, String rootId) {
  final List<LibraryRootView> roots =
      ref.read(libraryRootsProvider).value ?? const <LibraryRootView>[];
  for (final LibraryRootView root in roots) {
    if (root.id == rootId) {
      return root.uri;
    }
  }
  return null;
}
