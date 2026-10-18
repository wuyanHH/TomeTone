import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/playback/queue_builder.dart';
import 'package:tometone/app/policy/chapter_sequencer.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/queries/library_views.dart';

BookSummary _summary() {
  return const BookSummary(
    id: 'book-1',
    title: '三体',
    libraryRootId: 'root-1',
    rootPath: '三体',
    coverSource: CoverSource.typography,
    totalChapters: 3,
    totalDurationMs: 600000,
    missingChapters: 1,
  );
}

BookDetail _detail({bool allMissing = false}) {
  ChapterView chapter(String id, int index, {bool missing = false, int? ms}) {
    return ChapterView(
      id: id,
      volumeId: 'vol-1',
      title: '第 $index 章',
      chapterIndex: index,
      filePath: '三体/$id.mp3',
      missing: missing,
      durationMs: ms,
    );
  }

  return BookDetail(
    summary: _summary(),
    volumes: <VolumeView>[
      VolumeView(
        id: 'vol-1',
        title: '三体',
        volumeIndex: 0,
        chapters: <ChapterView>[
          chapter('ch-0', 0, ms: 300000, missing: allMissing),
          chapter('ch-1', 1, missing: true),
          chapter('ch-2', 2, ms: 300000, missing: allMissing),
        ],
      ),
    ],
    preferences: const PerBookPrefsSnapshot(),
  );
}

void main() {
  test('缺失章节不进入播放队列（占位章强行播放只会报 sourceNotFound）', () {
    final queue = buildPlaybackQueue(
      detail: _detail(),
      libraryRootUri: '/books',
    );

    expect(
      queue.chapters.map((QueueChapter c) => c.chapterId).toList(),
      <String>['ch-0', 'ch-2'],
    );
  });

  test('把相对路径解析成绝对文件路径', () {
    final queue = buildPlaybackQueue(
      detail: _detail(),
      libraryRootUri: '/storage/emulated/0/Books',
    );

    final source = queue.first!.source;
    expect(source, isA<LocalFileSource>());
    expect(
      source.uri,
      'file:///storage/emulated/0/Books/%E4%B8%89%E4%BD%93/ch-0.mp3',
    );
  });

  test('书库根带尾斜杠不会产生双斜杠', () {
    final queue = buildPlaybackQueue(
      detail: _detail(),
      libraryRootUri: '/books/',
    );

    expect(
      queue.first!.source.uri,
      'file:///books/%E4%B8%89%E4%BD%93/ch-0.mp3',
    );
  });

  test('时长映射到队列章节', () {
    final queue = buildPlaybackQueue(
      detail: _detail(),
      libraryRootUri: '/books',
    );
    expect(queue.first!.duration, const Duration(minutes: 5));
  });

  test('整本书都缺文件时队列为空', () {
    final queue = buildPlaybackQueue(
      detail: _detail(allMissing: true),
      libraryRootUri: '/books',
    );
    expect(queue.isEmpty, isTrue);
  });
}
