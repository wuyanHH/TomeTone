import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/playback/queue_builder.dart';
import 'package:tometone/app/policy/chapter_sequencer.dart';
import 'package:tometone/app/policy/per_book_preferences.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/contracts/media/media_source_resolver.dart';
import 'package:tometone/contracts/playback/engine_error.dart';
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

  /// 当前书的只读访问。
  ///
  /// `Notifier.state` 是 protected，应用层（`openBook`）不能直接读，
  /// 这里暴露一个公开 getter 作为「alreadyOpen」判定的入口。
  BookDetail? get current => state;

  /// 设置当前书；传 `null` 表示关闭播放台。
  void set(BookDetail? detail) => state = detail;
}

/// 当前书 Provider。
final NotifierProvider<CurrentBookNotifier, BookDetail?> currentBookProvider =
    NotifierProvider<CurrentBookNotifier, BookDetail?>(CurrentBookNotifier.new);

/// 打开一本书的结果状态。
enum OpenBookStatus {
  /// 这本书已经是当前书且在播：只展开播放台，不重建 / 不重定位 / 不重播。
  alreadyOpen,

  /// 打开成功（已开始播放）。
  opened,

  /// 打开失败（[OpenBookResult.message] 带可区分的原因）。
  failed,
}

/// [openBook] 的结果。
class OpenBookResult {
  /// 创建结果。
  const OpenBookResult({required this.status, this.message});

  /// 状态。
  final OpenBookStatus status;

  /// 失败原因（仅 [OpenBookStatus.failed] 非空）。
  final String? message;
}

/// 原子地打开一本书（书架点击入口）。
///
/// 语义（逐条实现，互不合并）：
///
/// 1. 已经是当前书且控制器里还有会话 → 直接 [OpenBookStatus.alreadyOpen]，
///    不重建队列、不重定位、不暂停、不重新 play。
/// 2. 否则建队列；空队列 → 失败且**零副作用**（不 set currentBook、
///    不动 controller）。
/// 3. [PlaybackController.open] 抛错 → **回滚**（`currentBook.set(null)` +
///    `clearSession()`），再按错误类型给可区分文案。
/// 4. 首次失败且是 SAF 直传（源为 `content://`）时，用
///    `preferCachedCopy: true` 重建队列重试**一次**；仍失败 → 回滚 + 失败。
/// 5. 只有加载成功之后才 `currentBook.set(detail)` + `controller.play()`。
///
/// 依赖显式传入而不是收一个 `Ref`：应用层不应该替 UI 层保管 Riverpod 的
/// 生命周期对象（`Ref` 只在其 Provider 存活期间有效）。
Future<OpenBookResult> openBook({
  required PlaybackController controller,
  required CurrentBookNotifier currentBook,
  required MediaSourceResolver resolver,
  required BookDetail detail,
}) async {
  final String title = detail.summary.title;

  // 1. 已是当前书、控制器里还有会话、且**无残留错误**：只展开播放台。
  //
  // 加上 `lastError == null` 的原因：某章打不开时 `_current` 仍指向那一章
  // （UI 才能显示是哪一章），若此时仍短路成 alreadyOpen，用户点同一本书
  // 既不会重试也无法恢复。带错误时走完整 open 路径（重建队列、丢弃不可解析
  // 的章、必要时缓存副本重试），用户才能自然恢复。
  // 正常播放态 `lastError == null`，短路照旧生效，不会误重开。
  if (currentBook.current?.summary.id == detail.summary.id &&
      controller.current != null &&
      controller.lastError == null) {
    return const OpenBookResult(status: OpenBookStatus.alreadyOpen);
  }

  // 2. 建队列；空队列 = 没有可播章节，零副作用返回。
  final ChapterSequencer queue = await buildPlaybackQueue(
    detail: detail,
    resolver: resolver,
  );
  if (queue.isEmpty) {
    return OpenBookResult(
      status: OpenBookStatus.failed,
      message: _emptyQueueMessage(title),
    );
  }

  final ProgressSnapshot? progress = detail.progress;
  final DateTime now = DateTime.now().toUtc();
  final String startChapterId = progress?.chapterId ?? queue.first!.chapterId;
  final Duration savedPosition = progress?.position ?? Duration.zero;
  final Duration interruption = progress == null
      ? Duration.zero
      : now.difference(progress.updatedAt.toUtc());
  // 真正会被加载的章：`open` 对不在队列的起始章会回落到第一章。
  // 缓存副本重试只针对这一章（见下方注释）。
  final QueueChapter target = queue.byId(startChapterId) ?? queue.first!;

  PlaybackRequest requestFor(ChapterSequencer q) => PlaybackRequest(
    bookId: detail.summary.id,
    queue: q,
    startChapterId: startChapterId,
    savedPosition: savedPosition,
    interruption: interruption,
    preferences: PerBookPreferences(
      speed: detail.preferences.speed,
      skipIntro: detail.preferences.skipIntro,
      skipOutro: detail.preferences.skipOutro,
    ),
  );

  // 3. 第一次尝试：SAF 走 content:// document URI，本地走绝对路径。
  try {
    await controller.open(requestFor(queue));
  } on Object catch (error) {
    // 4. 只有 SAF 直传（起始章仍是 content://）才值得缓存副本重试，且
    //    **只复制起始章** —— 对全书逐章复制会把上千 MB 静默写进缓存。
    if (_isDirectContentUri(target)) {
      final ChapterSequencer retryQueue = await buildPlaybackQueue(
        detail: detail,
        resolver: resolver,
        cachedCopyChapterIds: <String>{target.chapterId},
      );
      // 目标章复制失败（copyToCache 返回 null → resolveAudio 返回 null）：
      // 队列里没有这一章，重试也没有意义 → 按「源不可读」处理。
      if (retryQueue.byId(target.chapterId) == null) {
        _rollback(controller, currentBook);
        return OpenBookResult(
          status: OpenBookStatus.failed,
          message: _unreadableMessage(title),
        );
      }
      try {
        await controller.open(requestFor(retryQueue));
      } on Object catch (retryError) {
        _rollback(controller, currentBook);
        return OpenBookResult(
          status: OpenBookStatus.failed,
          message: _messageForError(retryError, title),
        );
      }
    } else {
      _rollback(controller, currentBook);
      return OpenBookResult(
        status: OpenBookStatus.failed,
        message: _messageForError(error, title),
      );
    }
  }

  // 5. 加载成功之后才登记当前书并开始播放。
  currentBook.set(detail);
  await controller.play();
  return const OpenBookResult(status: OpenBookStatus.opened);
}

/// 起始章是否为 SAF 直传的 `content://` document URI（决定是否值得缓存副本重试）。
bool _isDirectContentUri(QueueChapter chapter) =>
    Uri.tryParse(chapter.source.uri)?.scheme == 'content';

/// 打开失败回滚：清当前书 + 清控制器会话，让 UI 立刻不再显示假的播放态。
void _rollback(PlaybackController controller, CurrentBookNotifier currentBook) {
  currentBook.set(null);
  controller.clearSession();
}

String _emptyQueueMessage(String title) => '《$title》没有可播放的章节（文件可能已缺失）';

String _unreadableMessage(String title) =>
    '打不开《$title》：音频读取失败，可能文件已移动，或这个书库根的授权已失效';

String _unknownMessage(String title) => '打不开《$title》，请稍后再试';

/// 按引擎错误码给可区分的失败文案；未知错误一律兜底。
String _messageForError(Object error, String title) {
  if (error is EngineError) {
    return switch (error.code) {
      EngineErrorCode.sourceNotFound ||
      EngineErrorCode.permissionDenied => _unreadableMessage(title),
      _ => _unknownMessage(title),
    };
  }
  return _unknownMessage(title);
}
