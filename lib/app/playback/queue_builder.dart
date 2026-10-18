import 'package:tometone/app/policy/chapter_sequencer.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/domain/library/queries/library_views.dart';

/// 播放队列构建：把「书详情」翻译成引擎认识的 `QueueChapter` 列表。
///
/// ## 路径解析
///
/// 领域层存的是**相对书库根**的路径，引擎需要绝对路径。`buildPlaybackQueue`
/// 只支持**本地根**（M1 范围）：`libraryRootUri` 是本地绝对路径。
/// SAF / WebDAV 需要各自的 source 解析（SAF 走文件描述符、远程走 URL + 请求头），
/// 等对应里程碑接入时在这里加分支，调用方签名不变。
///
/// ## 缺失章节
///
/// 文件缺失的章（`missing == true`）**不进入播放队列** —— 它们只是占位，
/// 强行播放只会在引擎层抛 `sourceNotFound`。索引连续性由 `chapterIndex` 保证，
/// 队列本身不需要是等长的。
ChapterSequencer buildPlaybackQueue({
  required BookDetail detail,
  required String libraryRootUri,
}) {
  final base = libraryRootUri.endsWith('/')
      ? libraryRootUri.substring(0, libraryRootUri.length - 1)
      : libraryRootUri;

  final chapters = <QueueChapter>[];
  for (final chapter in detail.chapters) {
    if (chapter.missing) {
      continue;
    }
    chapters.add(
      QueueChapter(
        chapterId: chapter.id,
        volumeId: chapter.volumeId,
        title: chapter.title,
        source: LocalFileSource.fromPath('$base/${chapter.filePath}'),
        duration: chapter.durationMs == null
            ? null
            : Duration(milliseconds: chapter.durationMs!),
      ),
    );
  }
  return ChapterSequencer(chapters);
}
