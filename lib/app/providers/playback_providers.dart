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
/// - 队列由 [buildPlaybackQueue] 从书详情构建（缺失章自动跳过）；
/// - 恢复位置来自 `playback_progress`，中断间隔用进度写入时间近似
///   （应用在暂停 / 退后台时立即写，因此该值接近真实的暂停时长）；
/// - 队列为空（整本书都缺文件）时抛 [StateError]，由 UI 提示。
Future<void> startBook(
  Ref ref, {
  required BookDetail detail,
  required String libraryRootUri,
}) async {
  final controller = ref.read(playbackControllerProvider);
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

  ref.read(currentBookProvider.notifier).set(detail);

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
