// ignore_for_file: prefer_initializing_formals
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/domain/sources/url_normalizer.dart';

/// 在线章播放源解析：缓存/网络细节留给 M1-D，M1-C 只解析远程 URL。
class OnlineChapterSourceResolver {
  OnlineChapterSourceResolver({required SourceDiscovery discovery})
    : _discovery = discovery;

  final SourceDiscovery _discovery;

  Future<AudioSourceRef?> resolve({
    required BookSource source,
    required ChapterView chapter,
  }) async {
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
