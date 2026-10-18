import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/playback/queue_builder.dart';
import 'package:tometone/app/policy/per_book_preferences.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/domain/library/queries/library_views.dart';

/// 播放控制器（进程级单例）。
///
/// 进度写入走节流后的 `saveProgress`（关键事件 + 10 秒），因此这里可以
/// fire-and-forget；失败不能打断播放。
final Provider<PlaybackController> playbackControllerProvider =
    Provider<PlaybackController>((Ref ref) {
      final queries = ref.watch(libraryQueriesProvider);
      final controller = PlaybackController(
        engine: ref.watch(playbackEngineProvider),
        writeProgress: (String bookId, String chapterId, Duration position) {
          unawaited(
            queries
                .saveProgress(
                  bookId: bookId,
                  chapterId: chapterId,
                  position: position,
                )
                .catchError((Object _) {}),
          );
        },
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

/// 当前打开的书（播放台标题 / 封面 / 章节列表用）。
class CurrentBookNotifier extends Notifier<BookDetail?> {
  @override
  BookDetail? build() => null;

  /// 设置当前书；传 `null` 表示关闭播放台。
  void set(BookDetail? detail) => state = detail;
}

/// 当前书 Provider。
final NotifierProvider<CurrentBookNotifier, BookDetail?> currentBookProvider =
    NotifierProvider<CurrentBookNotifier, BookDetail?>(CurrentBookNotifier.new);

/// 打开一本书并开始播放（书架点击入口）。
///
/// 依赖显式传入而不是收一个 `Ref`：应用层不应该替 UI 层保管 Riverpod 的
/// 生命周期对象（`Ref` 只在其 Provider 存活期间有效）。
Future<void> startBook({
  required PlaybackController controller,
  required CurrentBookNotifier currentBook,
  required BookDetail detail,
  required String libraryRootUri,
}) async {
  final queue = buildPlaybackQueue(
    detail: detail,
    libraryRootUri: libraryRootUri,
  );
  if (queue.isEmpty) {
    throw StateError('《${detail.summary.title}》没有可播放的章节（文件可能已缺失）');
  }

  final progress = detail.progress;
  final now = DateTime.now().toUtc();
  final interruption = progress == null
      ? Duration.zero
      : now.difference(progress.updatedAt.toUtc());

  currentBook.set(detail);

  await controller.open(
    PlaybackRequest(
      bookId: detail.summary.id,
      queue: queue,
      startChapterId: progress?.chapterId ?? queue.first!.chapterId,
      savedPosition: progress?.position ?? Duration.zero,
      interruption: interruption,
      preferences: PerBookPreferences(
        speed: detail.preferences.speed,
        skipIntro: detail.preferences.skipIntro,
        skipOutro: detail.preferences.skipOutro,
      ),
    ),
  );
  await controller.play();
}
