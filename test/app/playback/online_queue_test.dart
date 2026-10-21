import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/playback/online_chapter_source_resolver.dart';
import 'package:tometone/app/playback/online_queue_builder.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';

void main() {
  test('在线队列跳过 VIP/retired/missing，惰性解析远程源', () async {
    final discovery = _FakeDiscovery();
    final resolver = OnlineChapterSourceResolver(discovery: discovery);
    final source = _source();
    final detail = _detail();

    final queue = await buildOnlinePlaybackQueue(
      detail: detail,
      source: source,
      resolver: resolver,
    );

    expect(queue.chapters, hasLength(1));
    final AudioSourceRef? audio = await queue.first!.resolve();
    expect(audio, isA<RemoteUrlSource>());
    expect((audio! as RemoteUrlSource).uri, 'https://e.test/audio/1.mp3');
    expect((audio as RemoteUrlSource).headers['X-Audio'], '1');
    expect(discovery.calls, <String>[
      'https://e.test/play/1,{"headers":{"X":"1"}}',
    ]);
  });

  test('音频解析失败的章保留队列项，解析时返回 null', () async {
    final discovery = _FakeDiscovery(fail: true);
    final resolver = OnlineChapterSourceResolver(discovery: discovery);

    final queue = await buildOnlinePlaybackQueue(
      detail: _detail(),
      source: _source(),
      resolver: resolver,
    );

    expect(queue.chapters, hasLength(1));
    expect(await queue.first!.resolve(), isNull);
  });
}

class _FakeDiscovery implements SourceDiscovery {
  _FakeDiscovery({this.fail = false});

  final bool fail;
  final List<String> calls = <String>[];

  @override
  Future<ResolvedAudio> resolveAudio(
    BookSource source,
    SourceChapter chapter,
  ) async {
    calls.add(chapter.rawUrl);
    if (fail) {
      throw const SourceFailureStub();
    }
    return const ResolvedAudio(
      url: 'https://e.test/audio/1.mp3',
      headers: <String, String>{'X-Audio': '1'},
    );
  }

  @override
  Future<SourcePage<SourceBookSummary>> explore(
    BookSource source,
    ExploreCategory category,
    int page,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<SourcePage<SourceBookSummary>> search(
    BookSource source,
    String keyword,
    int page,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) {
    throw UnimplementedError();
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) {
    throw UnimplementedError();
  }

  @override
  Future<SourceTestReport> test(BookSource source) {
    throw UnimplementedError();
  }
}

class SourceFailureStub implements Exception {
  const SourceFailureStub();
}

BookSource _source() {
  final now = DateTime.utc(2026);
  return BookSource(
    id: 'source-1',
    libraryRootId: 'root-1',
    name: '听友听书',
    sourceUrl: 'https://e.test',
    sourceType: 1,
    rawJson: '{}',
    header: const <String, String>{},
    enabled: true,
    enabledExplore: true,
    customOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
}

BookDetail _detail() {
  return const BookDetail(
    summary: BookSummary(
      id: 'book-1',
      title: '在线书',
      libraryRootId: 'root-1',
      rootPath: 'https://e.test/book/1',
      coverSource: CoverSource.typography,
      totalChapters: 3,
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
            id: 'active',
            volumeId: 'vol-1',
            title: '可播章',
            chapterIndex: 0,
            filePath: 'online/active',
            missing: false,
            sourceUri: 'https://e.test/play/1,{"headers":{"X":"1"}}',
          ),
          ChapterView(
            id: 'vip',
            volumeId: 'vol-1',
            title: 'VIP',
            chapterIndex: 1,
            filePath: 'online/vip',
            missing: false,
            sourceUri: 'https://e.test/play/2',
            isVip: true,
          ),
          ChapterView(
            id: 'retired',
            volumeId: 'vol-1',
            title: '旧章',
            chapterIndex: 2,
            filePath: 'online/retired',
            missing: false,
            sourceUri: 'https://e.test/play/3',
            retired: true,
          ),
        ],
      ),
    ],
    preferences: PerBookPrefsSnapshot(),
  );
}
