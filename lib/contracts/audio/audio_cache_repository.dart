import 'dart:io';

/// 沙盒音频缓存仓储（管理在线音频预下载文件与 LRU 淘汰）
abstract class AudioCacheRepository {
  /// 获取已缓存的音频文件；若不存在返回 null
  Future<File?> getCachedAudioFile(String bookId, String chapterId);

  /// 写入音频缓存
  Future<File> saveAudioCache(String bookId, String chapterId, List<int> bytes);

  /// 清理指定书籍的所有音频缓存（换源或删书时使用）
  Future<void> clearBookCache(String bookId);

  /// 获取当前所有预载音频缓存占用的总字节数
  Future<int> getTotalCacheSize();

  /// 执行 LRU 水位控制：当总字节数超过 [maxBytes] 时，
  /// 淘汰非 [activeChapterKeys]（格式：'bookId:chapterId'）的最久未访问音频，
  /// 直至总大小降到 [maxBytes] * 0.85
  Future<void> enforceCacheLimit({
    required int maxBytes,
    Set<String> activeChapterKeys = const {},
  });

  /// 清空所有预下载缓存
  Future<void> clearAllCache();
}
