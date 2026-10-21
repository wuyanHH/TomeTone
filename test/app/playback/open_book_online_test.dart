import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/chapter_sequencer.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/providers/playback_providers.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/queries/library_views.dart';

void main() {
  test('在线书使用注入的队列构建器，不依赖本机根 resolver', () async {
    final engine = FakePlaybackEngine();
    final controller = PlaybackController(
      engine: engine,
      writeProgress: (String bookId, String chapterId, Duration position) {},
    );
    addTearDown(controller.dispose);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final currentBook = container.read(currentBookProvider.notifier);

    final result = await openBook(
      controller: controller,
      currentBook: currentBook,
      detail: _detail(),
      buildQueue: () async {
        return ChapterSequencer(<QueueChapter>[
          QueueChapter(
            chapterId: 'ch-1',
            volumeId: 'vol-1',
            title: '第一章',
            resolveSource: () async => const RemoteUrlSource(
              uri: 'https://e.test/audio/1.mp3',
              headers: <String, String>{'X-Audio': '1'},
            ),
          ),
        ]);
      },
    );

    expect(result.status, OpenBookStatus.opened);
    expect(engine.currentSource, isA<RemoteUrlSource>());
    expect((engine.currentSource! as RemoteUrlSource).headers['X-Audio'], '1');
  });
}

BookDetail _detail() {
  return const BookDetail(
    summary: BookSummary(
      id: 'book-1',
      title: '在线书',
      libraryRootId: 'root-1',
      rootPath: 'https://e.test/book/1',
      coverSource: CoverSource.typography,
      totalChapters: 1,
      totalDurationMs: 0,
      missingChapters: 0,
      sourceType: 'online',
      sourceId: 'source-1',
    ),
    volumes: <VolumeView>[
      VolumeView(
        id: 'vol-1',
        title: '正文',
        volumeIndex: 0,
        chapters: <ChapterView>[
          ChapterView(
            id: 'ch-1',
            volumeId: 'vol-1',
            title: '第一章',
            chapterIndex: 0,
            filePath: 'online/ch-1',
            missing: false,
            sourceUri: 'https://e.test/play/1',
          ),
        ],
      ),
    ],
    preferences: PerBookPrefsSnapshot(),
  );
}
