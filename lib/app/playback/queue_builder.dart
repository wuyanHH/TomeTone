import 'package:tometone/app/policy/chapter_sequencer.dart';
import 'package:tometone/contracts/media/media_source_resolver.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/domain/library/queries/library_views.dart';

/// 播放队列构建：把「书详情」翻译成引擎认识的 `QueueChapter` 列表。
///
/// ## 源解析
///
/// 领域层存的是**相对书库根**的路径，怎么变成引擎能打开的源由
/// [MediaSourceResolver] 决定：本地根拼绝对路径、SAF 根解析 document URI、
/// 将来 WebDAV 组装 URL。队列构建只调用契约，**不自己拼路径** ——
/// 三者语义完全不同，散在调用点必然漂移。
///
/// ## 缺失 / 不可读章节
///
/// - `missing == true` 的占位章：不进入队列（强行播放只会在引擎层抛
///   `sourceNotFound`）。
/// - [MediaSourceResolver.resolveAudio] 返回 `null` 的章（文件被移动、
///   授权失效、SAF 读取失败）：同样跳过 —— **不把「打不开」拖到引擎层**，
///   否则调用方只剩一个 `sourceNotFound`，拿不到可判断的信息。
///
/// 因此返回**空队列是合法结果**，由调用方决定文案（例如
/// 「没有可播放的章节（文件可能已缺失）」）。被跳过的章数可由调用方按
/// `detail.chapters` 与 `queue.chapters` 求差得到，本函数不额外回传计数，
/// 也不使用任何全局状态。
///
/// ## 缓存副本只针对指定章（重要边界）
///
/// [cachedCopyChapterIds] 是「要求 resolver 复制到本地缓存」的**章 ID 集合**，
/// 逐章透传给 [MediaSourceResolver.resolveAudio] 的 `preferCachedCopy`。
/// 只对**即将播放的那一章**置位的原因：SAF 直传打不开时，`copyToCache` 会把
/// 整章音频落盘；一本 30 小时的有声书有上千 MB，若对全书每章都复制，首次播放
/// 前就会静默吃光磁盘并长时间卡住。因此重试只复制起始章，其余章仍走直传
/// `content://`。
///
/// 若后续某章同样直传打不开：本函数**不**为它复制（它不在集合里），
/// 引擎会抛 `sourceNotFound`，由 `PlaybackController` 的切章加固收敛成
/// `lastError` 供 UI 提示 —— 后续可按需把失败章也纳入集合，或改成整书回退。
Future<ChapterSequencer> buildPlaybackQueue({
  required BookDetail detail,
  required MediaSourceResolver resolver,
  Set<String> cachedCopyChapterIds = const <String>{},
}) async {
  final List<QueueChapter> chapters = <QueueChapter>[];
  for (final ChapterView chapter in detail.chapters) {
    if (chapter.missing) {
      continue;
    }
    final AudioSourceRef? source = await resolver.resolveAudio(
      relativePath: chapter.filePath,
      preferCachedCopy: cachedCopyChapterIds.contains(chapter.id),
    );
    if (source == null) {
      continue;
    }
    chapters.add(
      QueueChapter(
        chapterId: chapter.id,
        volumeId: chapter.volumeId,
        title: chapter.title,
        source: source,
        duration: chapter.durationMs == null
            ? null
            : Duration(milliseconds: chapter.durationMs!),
      ),
    );
  }
  return ChapterSequencer(chapters);
}
