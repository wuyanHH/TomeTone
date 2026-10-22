import 'dart:io';
import '../../contracts/audio/audio_cache_repository.dart';

class AudioCacheRepositoryImpl implements AudioCacheRepository {
  final Directory cacheRoot;

  AudioCacheRepositoryImpl({required this.cacheRoot});

  Directory get _preloadDir =>
      Directory('${cacheRoot.path}${Platform.pathSeparator}audio_preload');

  File _audioFile(String bookId, String chapterId) {
    return File(
      '${_preloadDir.path}${Platform.pathSeparator}$bookId${Platform.pathSeparator}$chapterId.audio',
    );
  }

  @override
  Future<File?> getCachedAudioFile(String bookId, String chapterId) async {
    final file = _audioFile(bookId, chapterId);
    if (file.existsSync()) {
      try {
        file.setLastModifiedSync(DateTime.now());
      } catch (_) {}
      return file;
    }
    return null;
  }

  @override
  Future<File> saveAudioCache(
    String bookId,
    String chapterId,
    List<int> bytes,
  ) async {
    final file = _audioFile(bookId, chapterId);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    await file.writeAsBytes(bytes, flush: true);
    try {
      file.setLastModifiedSync(DateTime.now());
    } catch (_) {}
    return file;
  }

  @override
  Future<void> clearBookCache(String bookId) async {
    final bookDir = Directory(
      '${_preloadDir.path}${Platform.pathSeparator}$bookId',
    );
    if (bookDir.existsSync()) {
      bookDir.deleteSync(recursive: true);
    }
  }

  @override
  Future<int> getTotalCacheSize() async {
    if (!_preloadDir.existsSync()) return 0;
    int total = 0;
    final entities = _preloadDir.listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.audio')) {
        total += entity.lengthSync();
      }
    }
    return total;
  }

  @override
  Future<void> enforceCacheLimit({
    required int maxBytes,
    Set<String> activeChapterKeys = const {},
  }) async {
    if (!_preloadDir.existsSync()) return;

    final targetBytes = (maxBytes * 0.85).toInt();
    final candidateFiles = <_CacheEntry>[];
    int totalBytes = 0;

    final entities = _preloadDir.listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.audio')) {
        final length = entity.lengthSync();
        totalBytes += length;

        // 提取 bookId 与 chapterId
        // path 格式: .../audio_preload/<bookId>/<chapterId>.audio
        final parts = entity.uri.pathSegments;
        if (parts.length >= 2) {
          final bookId = parts[parts.length - 2];
          final fileName = parts.last;
          final chapterId = fileName.substring(
            0,
            fileName.length - '.audio'.length,
          );
          final key = '$bookId:$chapterId';
          if (!activeChapterKeys.contains(key)) {
            final mtime = entity.lastModifiedSync();
            candidateFiles.add(
              _CacheEntry(file: entity, bytes: length, lastModified: mtime),
            );
          }
        }
      }
    }

    if (totalBytes <= maxBytes) {
      return;
    }

    // 按访问时间从旧到新排序（最早访问的先删）
    candidateFiles.sort((a, b) => a.lastModified.compareTo(b.lastModified));

    for (final entry in candidateFiles) {
      if (totalBytes <= targetBytes) break;
      try {
        entry.file.deleteSync();
        totalBytes -= entry.bytes;
      } catch (_) {}
    }
  }

  @override
  Future<void> clearAllCache() async {
    if (_preloadDir.existsSync()) {
      _preloadDir.deleteSync(recursive: true);
    }
  }
}

class _CacheEntry {
  final File file;
  final int bytes;
  final DateTime lastModified;

  _CacheEntry({
    required this.file,
    required this.bytes,
    required this.lastModified,
  });
}
