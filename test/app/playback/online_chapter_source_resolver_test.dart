import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/playback/online_chapter_source_resolver.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/contracts/audio/audio_cache_repository.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';

class _FakeCacheRepository implements AudioCacheRepository {
  final Map<String, File> files = {};

  @override
  Future<File?> getCachedAudioFile(String bookId, String chapterId) async {
    return files['$bookId:$chapterId'];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDiscovery implements SourceDiscovery {
  @override
  Future<ResolvedAudio> resolveAudio(BookSource source, SourceChapter chapter) async {
    return const ResolvedAudio(url: 'http://remote.mp3', headers: {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime(2026, 10, 22);
  final source = BookSource(
    id: 'src_1',
    libraryRootId: 'root_1',
    name: 'Test Source',
    sourceUrl: 'http://test.com',
    sourceType: 1,
    rawJson: '{}',
    header: const {},
    enabled: true,
    enabledExplore: true,
    customOrder: 0,
    createdAt: now,
    updatedAt: now,
  );

  const chapter = ChapterView(
    id: 'c1',
    volumeId: 'v1',
    chapterIndex: 0,
    title: 'Chapter 1',
    filePath: 'online/c1',
    missing: false,
    sourceUri: 'http://test.com/c1',
  );

  test('resolves to LocalFileSource when audioCacheRepository contains file', () async {
    final tempDir = await Directory.systemTemp.createTemp('resolver_test_');
    final dummyFile = File('${tempDir.path}/c1.audio');
    await dummyFile.writeAsBytes([1, 2, 3]);

    final cache = _FakeCacheRepository();
    cache.files['b1:c1'] = dummyFile;

    final resolver = OnlineChapterSourceResolver(
      discovery: _FakeDiscovery(),
      cacheRepository: cache,
    );

    final result = await resolver.resolve(source: source, chapter: chapter, bookId: 'b1');
    expect(result, isA<LocalFileSource>());
    expect(result!.uri, dummyFile.uri.toString());

    await tempDir.delete(recursive: true);
  });

  test('resolves to RemoteUrlSource when audioCacheRepository has no cache', () async {
    final resolver = OnlineChapterSourceResolver(
      discovery: _FakeDiscovery(),
      cacheRepository: _FakeCacheRepository(),
    );

    final result = await resolver.resolve(source: source, chapter: chapter, bookId: 'b1');
    expect(result, isA<RemoteUrlSource>());
    expect(result!.uri, 'http://remote.mp3');
  });
}
