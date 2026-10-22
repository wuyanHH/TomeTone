import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/playback/audio_preload_manager.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/contracts/audio/audio_cache_repository.dart';
import 'package:tometone/contracts/network/network_monitor.dart';
import 'package:tometone/contracts/sources/source_http.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';

class MockNetworkMonitor implements NetworkMonitor {
  bool isWifi = true;
  final _ctrl = StreamController<bool>.broadcast();

  @override
  Future<bool> get isWifiConnected async => isWifi;

  @override
  Stream<bool> get isWifiConnectedStream => _ctrl.stream;

  void dispose() {
    _ctrl.close();
  }
}

class MockAudioCacheRepository implements AudioCacheRepository {
  final Map<String, List<int>> storage = {};

  @override
  Future<File?> getCachedAudioFile(String bookId, String chapterId) async {
    final key = '$bookId:$chapterId';
    if (storage.containsKey(key)) {
      return File('dummy/$key');
    }
    return null;
  }

  @override
  Future<File> saveAudioCache(String bookId, String chapterId, List<int> bytes) async {
    storage['$bookId:$chapterId'] = bytes;
    return File('dummy/$bookId:$chapterId');
  }

  @override
  Future<void> clearBookCache(String bookId) async {
    storage.removeWhere((k, _) => k.startsWith('$bookId:'));
  }

  @override
  Future<int> getTotalCacheSize() async {
    return storage.values.fold<int>(0, (sum, v) => sum + v.length);
  }

  @override
  Future<void> enforceCacheLimit({required int maxBytes, Set<String> activeChapterKeys = const {}}) async {}

  @override
  Future<void> clearAllCache() async {
    storage.clear();
  }
}

class MockSourceDiscovery implements SourceDiscovery {
  final Map<String, String> resolvedUrls = {};

  @override
  Future<ResolvedAudio> resolveAudio(BookSource source, SourceChapter chapter) async {
    final url = resolvedUrls[chapter.title] ?? 'http://test.audio/${chapter.title}.mp3';
    return ResolvedAudio(url: url, headers: const {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpClient implements SourceHttpClient {
  int downloadCalls = 0;
  final List<String> downloadedUrls = [];

  @override
  Future<SourceHttpResponse> send(SourceHttpRequest request) async {
    downloadCalls++;
    downloadedUrls.add(request.url.toString());
    return SourceHttpResponse(
      finalUrl: request.url,
      statusCode: 200,
      bytes: Uint8List.fromList([1, 2, 3]),
      headers: const {},
    );
  }
}

void main() {
  late MockNetworkMonitor networkMonitor;
  late MockAudioCacheRepository cacheRepo;
  late MockSourceDiscovery discovery;
  late MockHttpClient httpClient;
  late AudioPreloadManager manager;

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

  const ch1 = ChapterView(
    id: 'c1',
    volumeId: 'v1',
    chapterIndex: 0,
    title: 'Chapter 1',
    filePath: 'online/c1',
    missing: false,
    sourceUri: 'http://test.com/c1',
  );
  const ch2 = ChapterView(
    id: 'c2',
    volumeId: 'v1',
    chapterIndex: 1,
    title: 'Chapter 2',
    filePath: 'online/c2',
    missing: false,
    sourceUri: 'http://test.com/c2',
  );
  const ch3 = ChapterView(
    id: 'c3',
    volumeId: 'v1',
    chapterIndex: 2,
    title: 'Chapter 3',
    filePath: 'online/c3',
    missing: false,
    sourceUri: 'http://test.com/c3',
  );
  const ch4 = ChapterView(
    id: 'c4',
    volumeId: 'v1',
    chapterIndex: 3,
    title: 'Chapter 4',
    filePath: 'online/c4',
    missing: false,
    sourceUri: 'http://test.com/c4',
  );

  setUp(() {
    networkMonitor = MockNetworkMonitor();
    cacheRepo = MockAudioCacheRepository();
    discovery = MockSourceDiscovery();
    httpClient = MockHttpClient();
    manager = AudioPreloadManager(
      networkMonitor: networkMonitor,
      cacheRepository: cacheRepo,
      discovery: discovery,
      httpClient: httpClient,
      preloadCount: 2,
      wifiOnly: true,
    );
  });

  tearDown(() {
    networkMonitor.dispose();
  });

  test('does not preload when progress < 0.5', () async {
    await manager.onPlaybackPositionUpdate(
      bookId: 'b1',
      source: source,
      currentChapterId: 'c1',
      progress: 0.49,
      upcomingChapters: [ch1, ch2, ch3, ch4],
    );

    expect(httpClient.downloadCalls, 0);
  });

  test('does not preload when wifiOnly is true and not on wifi', () async {
    networkMonitor.isWifi = false;
    await manager.onPlaybackPositionUpdate(
      bookId: 'b1',
      source: source,
      currentChapterId: 'c1',
      progress: 0.55,
      upcomingChapters: [ch1, ch2, ch3, ch4],
    );

    expect(httpClient.downloadCalls, 0);
  });

  test('preloads upcoming N chapters when progress >= 0.5 on wifi, NEVER preloads current chapter', () async {
    networkMonitor.isWifi = true;
    await manager.onPlaybackPositionUpdate(
      bookId: 'b1',
      source: source,
      currentChapterId: 'c1',
      progress: 0.55,
      upcomingChapters: [ch1, ch2, ch3, ch4],
    );

    // preloadCount = 2, so it should download c2 and c3. Never c1!
    expect(httpClient.downloadCalls, 2);
    expect(httpClient.downloadedUrls, contains('http://test.audio/Chapter%202.mp3'));
    expect(httpClient.downloadedUrls, contains('http://test.audio/Chapter%203.mp3'));
    expect(httpClient.downloadedUrls.contains('http://test.audio/Chapter%201.mp3'), isFalse);

    expect(cacheRepo.storage.containsKey('b1:c2'), isTrue);
    expect(cacheRepo.storage.containsKey('b1:c3'), isTrue);
    expect(cacheRepo.storage.containsKey('b1:c1'), isFalse);
  });

  test('skips HLS m3u8 streams during preload', () async {
    discovery.resolvedUrls['Chapter 2'] = 'http://test.audio/stream.m3u8';
    networkMonitor.isWifi = true;

    await manager.onPlaybackPositionUpdate(
      bookId: 'b1',
      source: source,
      currentChapterId: 'c1',
      progress: 0.6,
      upcomingChapters: [ch1, ch2, ch3],
    );

    // ch2 is m3u8 -> skipped. ch3 is mp3 -> downloaded. Total download = 1.
    expect(httpClient.downloadCalls, 1);
    expect(httpClient.downloadedUrls, contains('http://test.audio/Chapter%203.mp3'));
  });
}
