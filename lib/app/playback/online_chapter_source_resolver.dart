// ignore_for_file: prefer_initializing_formals
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/contracts/audio/audio_cache_repository.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/domain/sources/url_normalizer.dart';

/// 在线章播放源解析：优先命中本地预载缓存，未命中则解析远程 URL。
class OnlineChapterSourceResolver {
  OnlineChapterSourceResolver({
    required SourceDiscovery discovery,
    AudioCacheRepository? cacheRepository,
  })  : _discovery = discovery,
        _cacheRepository = cacheRepository;

  final SourceDiscovery _discovery;
  final AudioCacheRepository? _cacheRepository;

  Future<AudioSourceRef?> resolve({
    required BookSource source,
    required ChapterView chapter,
    String? bookId,
  }) async {
    // 优先检查本地预下载缓存
    if (_cacheRepository != null && bookId != null) {
      try {
        final cached = await _cacheRepository.getCachedAudioFile(bookId, chapter.id);
        if (cached != null && cached.existsSync() && cached.lengthSync() > 0) {
          return LocalFileSource(uri: cached.uri.toString());
        }
      } catch (_) {}
    }

    final String? raw = chapter.sourceUri;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final Uri? baseUrl = Uri.tryParse(source.sourceUrl);
      final ResolvedAudio audio = await _discovery.resolveAudio(
        source,
        SourceChapter(
          index: chapter.chapterIndex,
          title: chapter.title,
          rawUrl: raw,
          url: _normalized(raw, baseUrl: baseUrl),
          isVip: chapter.isVip,
        ),
      );
      return RemoteUrlSource(uri: audio.url, headers: audio.headers);
    } on Object {
      return null;
    }
  }

  static String _normalized(String raw, {Uri? baseUrl}) {
    final int options = raw.lastIndexOf(',{');
    final String base = options >= 0 ? raw.substring(0, options) : raw;
    try {
      return normalizeNetworkUrl(base.trim(), baseUrl: baseUrl);
    } on FormatException {
      return base.trim();
    }
  }
}
