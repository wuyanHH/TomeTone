import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/playback/queue_builder.dart';
import 'package:tometone/app/policy/chapter_sequencer.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/queries/library_views.dart';

import 'fake_media_source_resolver.dart';

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
  test('缺失章节不进入播放队列（占位章强行播放只会报 sourceNotFound）', () async {
    final queue = await buildPlaybackQueue(
      detail: _detail(),
      resolver: localFakeResolver('/books'),
    );

    expect(
      queue.chapters.map((QueueChapter c) => c.chapterId).toList(),
      <String>['ch-0', 'ch-2'],
    );
  });

  test('把相对路径交给 resolver 解析（本地根 → 绝对文件路径）', () async {
    final queue = await buildPlaybackQueue(
      detail: _detail(),
      resolver: localFakeResolver('/storage/emulated/0/Books'),
    );

    final source = queue.first!.source;
    expect(source, isA<LocalFileSource>());
    expect(
      source.uri,
      'file:///storage/emulated/0/Books/%E4%B8%89%E4%BD%93/ch-0.mp3',
    );
  });

  test('SAF 直传：resolver 返回 content:// 时原样进入队列', () async {
    final resolver = FakeMediaSourceResolver(
      resolve: (String path, bool _) =>
          LocalFileSource(uri: 'content://tree/三体/$path'),
    );
    final queue = await buildPlaybackQueue(
      detail: _detail(),
      resolver: resolver,
    );

    expect(queue.first!.source.uri, startsWith('content://'));
    expect(
      resolver.resolveCalls.every((c) => c.preferCachedCopy == false),
      isTrue,
      reason: '默认不要求缓存副本',
    );
  });

  test('缓存副本只针对传入的章 ID（其余章仍直传，不整书复制）', () async {
    final resolver = FakeMediaSourceResolver(
      resolve: (String path, bool cached) =>
          LocalFileSource.fromPath(cached ? '/cache/$path' : path),
    );
    await buildPlaybackQueue(
      detail: _detail(),
      resolver: resolver,
      cachedCopyChapterIds: <String>{'ch-2'},
    );

    final cachedPaths = resolver.resolveCalls
        .where((c) => c.preferCachedCopy)
        .map((c) => c.relativePath)
        .toSet();
    expect(cachedPaths, <String>{
      '三体/ch-2.mp3',
    }, reason: '只有 ch-2 走缓存副本，其余章必须直传');
    expect(
      resolver.resolveCalls
          .where((c) => c.relativePath == '三体/ch-0.mp3')
          .every((c) => !c.preferCachedCopy),
      isTrue,
      reason: '不在集合里的章永远直传（否则会整书复制）',
    );
  });

  test('resolver 解析不出的章被跳过（源不可读不拖到引擎）', () async {
    final resolver = FakeMediaSourceResolver(
      resolve: (String path, bool _) => path.endsWith('ch-2.mp3')
          ? null
          : LocalFileSource.fromPath('/books/三体/$path'),
    );
    final queue = await buildPlaybackQueue(
      detail: _detail(),
      resolver: resolver,
    );

    expect(
      queue.chapters.map((QueueChapter c) => c.chapterId).toList(),
      <String>['ch-0'],
    );
  });

  test('时长映射到队列章节', () async {
    final queue = await buildPlaybackQueue(
      detail: _detail(),
      resolver: localFakeResolver('/books'),
    );
    expect(queue.first!.duration, const Duration(minutes: 5));
  });

  test('整本书都缺文件时队列为空', () async {
    final queue = await buildPlaybackQueue(
      detail: _detail(allMissing: true),
      resolver: localFakeResolver('/books'),
    );
    expect(queue.isEmpty, isTrue);
  });
}
