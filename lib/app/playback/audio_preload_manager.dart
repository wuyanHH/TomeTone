// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/contracts/audio/audio_cache_repository.dart';
import 'package:tometone/contracts/network/network_monitor.dart';
import 'package:tometone/contracts/sources/source_http.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/domain/sources/url_normalizer.dart';

/// 智能预下载调度器（负责后台静默预载后续章节音频并触发 LRU 限制控制）
class AudioPreloadManager {
  final NetworkMonitor _networkMonitor;
  final AudioCacheRepository _cacheRepository;
  final SourceDiscovery _discovery;
  final SourceHttpClient _httpClient;
  int preloadCount;
  bool wifiOnly;
  int maxCacheBytes;

  final Set<String> _preloadedMarkers = <String>{};
  bool _cancelled = false;

  AudioPreloadManager({
    required NetworkMonitor networkMonitor,
    required AudioCacheRepository cacheRepository,
    required SourceDiscovery discovery,
    required SourceHttpClient httpClient,
    this.preloadCount = 3,
    this.wifiOnly = true,
    this.maxCacheBytes = 2 * 1024 * 1024 * 1024, // 2GB
  })  : _networkMonitor = networkMonitor,
        _cacheRepository = cacheRepository,
        _discovery = discovery,
        _httpClient = httpClient;

  Future<void> onPlaybackPositionUpdate({
    required String bookId,
    required BookSource source,
    required String currentChapterId,
    required double progress,
    required List<ChapterView> upcomingChapters,
  }) async {
    if (_cancelled) return;
    if (progress < 0.5) return;

    final marker = '$bookId:$currentChapterId';
    if (_preloadedMarkers.contains(marker)) return;
    _preloadedMarkers.add(marker);

    if (wifiOnly && !await _networkMonitor.isWifiConnected) {
      return;
    }

    final currentIndex = upcomingChapters.indexWhere((c) => c.id == currentChapterId);
    if (currentIndex < 0) return;

    // 严格只获取当前章节之后的章节，当前播放章节（currentIndex）绝不进入预下载队列
    final candidates = upcomingChapters
        .skip(currentIndex + 1)
        .take(preloadCount)
        .toList();

    if (candidates.isEmpty) return;

    final Uri? baseUrl = Uri.tryParse(source.sourceUrl);

    for (final chapter in candidates) {
      if (_cancelled) break;
      final cached = await _cacheRepository.getCachedAudioFile(bookId, chapter.id);
      if (cached != null) continue;

      final raw = chapter.sourceUri;
      if (raw == null || raw.trim().isEmpty) continue;

      try {
        final normalizedUrl = _normalizeUrl(raw, baseUrl);
        final resolved = await _discovery.resolveAudio(
          source,
          SourceChapter(
            index: chapter.chapterIndex,
            title: chapter.title,
            rawUrl: raw,
            url: normalizedUrl,
            isVip: chapter.isVip,
          ),
        );

        // HLS 流式直接跳过，不落盘预下载
        if (resolved.url.toLowerCase().contains('.m3u8')) {
          continue;
        }

        final targetUri = Uri.tryParse(resolved.url);
        if (targetUri == null) continue;

        final response = await _httpClient.send(
          SourceHttpRequest(
            url: targetUri,
            method: 'GET',
            headers: resolved.headers,
          ),
        );

        if (response.statusCode == 200 && response.bytes.isNotEmpty) {
          await _cacheRepository.saveAudioCache(bookId, chapter.id, response.bytes);
        }
      } on Object {
        // 预下载失败静默忽略，不打断播放
      }
    }

    // 下载完成后按水位执行 LRU 淘汰
    await _cacheRepository.enforceCacheLimit(
      maxBytes: maxCacheBytes,
      activeChapterKeys: {'$bookId:$currentChapterId'},
    );
  }

  void cancelAll() {
    _cancelled = true;
  }

  void reset() {
    _cancelled = false;
    _preloadedMarkers.clear();
  }

  static String _normalizeUrl(String raw, Uri? baseUrl) {
    final int options = raw.lastIndexOf(',{');
    final String base = options >= 0 ? raw.substring(0, options) : raw;
    try {
      return normalizeNetworkUrl(base.trim(), baseUrl: baseUrl);
    } on FormatException {
      return base.trim();
    }
  }
}
