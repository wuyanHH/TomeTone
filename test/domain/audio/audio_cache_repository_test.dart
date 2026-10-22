import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/modules/audio/audio_cache_repository_impl.dart';

void main() {
  late Directory tempDir;
  late AudioCacheRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tometone_audio_cache_test_');
    repository = AudioCacheRepositoryImpl(cacheRoot: tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('saves and retrieves cached audio file', () async {
    final file = await repository.saveAudioCache('book_1', 'ch_1', [1, 2, 3, 4]);
    expect(file.existsSync(), isTrue);

    final cached = await repository.getCachedAudioFile('book_1', 'ch_1');
    expect(cached, isNotNull);
    expect(cached!.readAsBytesSync(), [1, 2, 3, 4]);
  });

  test('clearBookCache removes all files for given book', () async {
    await repository.saveAudioCache('book_1', 'ch_1', [1, 2]);
    await repository.saveAudioCache('book_1', 'ch_2', [3, 4]);
    await repository.saveAudioCache('book_2', 'ch_1', [5, 6]);

    await repository.clearBookCache('book_1');

    expect(await repository.getCachedAudioFile('book_1', 'ch_1'), isNull);
    expect(await repository.getCachedAudioFile('book_1', 'ch_2'), isNull);
    expect(await repository.getCachedAudioFile('book_2', 'ch_1'), isNotNull);
  });

  test('enforceCacheLimit evicts oldest unreserved files down to 85% water mark', () async {
    await repository.saveAudioCache('b1', 'c1', List.filled(500, 1));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await repository.saveAudioCache('b1', 'c2', List.filled(400, 2));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await repository.saveAudioCache('b1', 'c3', List.filled(400, 3));

    // Total = 1300 bytes. Limit = 1000 bytes. Target = 850 bytes.
    // Evicting c1 (500 bytes) reduces total to 800 <= 850.
    // c1 is oldest, should be deleted; c2 (active) and c3 (newer) survive.
    await repository.enforceCacheLimit(maxBytes: 1000, activeChapterKeys: {'b1:c2'});

    expect(await repository.getCachedAudioFile('b1', 'c1'), isNull);
    expect(await repository.getCachedAudioFile('b1', 'c2'), isNotNull);
    expect(await repository.getCachedAudioFile('b1', 'c3'), isNotNull);
  });

  test('clearAllCache removes all audio files across all books', () async {
    await repository.saveAudioCache('b1', 'c1', [1]);
    await repository.saveAudioCache('b2', 'c1', [2]);

    expect(await repository.getTotalCacheSize(), 2);
    await repository.clearAllCache();
    expect(await repository.getTotalCacheSize(), 0);
  });
}
