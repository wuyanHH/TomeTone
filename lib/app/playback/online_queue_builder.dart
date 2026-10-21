import 'package:tometone/app/policy/chapter_sequencer.dart';
import 'package:tometone/app/playback/online_chapter_source_resolver.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';

/// 在线书队列：只放 active、非 VIP、有章 URL 的章；源在播放到该章时才解析。
Future<ChapterSequencer> buildOnlinePlaybackQueue({
  required BookDetail detail,
  required BookSource source,
  required OnlineChapterSourceResolver resolver,
}) async {
  final chapters = <QueueChapter>[];
  for (final ChapterView chapter in detail.chapters) {
    if (chapter.missing || chapter.isVip || chapter.retired) {
      continue;
    }
    if (chapter.sourceUri == null || chapter.sourceUri!.trim().isEmpty) {
      continue;
    }
    chapters.add(
      QueueChapter(
        chapterId: chapter.id,
        volumeId: chapter.volumeId,
        title: chapter.title,
        duration: chapter.durationMs == null
            ? null
            : Duration(milliseconds: chapter.durationMs!),
        resolveSource: () => resolver.resolve(source: source, chapter: chapter),
      ),
    );
  }
  return ChapterSequencer(chapters);
}
