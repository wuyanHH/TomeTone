/// 媒体格式白名单（《架构需求文档》§2.1「媒体格式兼容」）。
///
/// 白名单而非黑名单：非音频文件一律忽略（封面、字幕、说明、系统缩略图等），
/// 避免把 `cover.jpg` / `.nomedia` / macOS `._xxx.mp3` 之类的东西当章节。
library;

/// 支持的音频容器 / 编码扩展名（不含点，全小写）。
const Set<String> supportedMediaExtensions = <String>{
  'mp3',
  'm4a',
  'm4b',
  'aac',
  'flac',
  'wav',
  'ogg',
  'opus',
};

/// 媒体格式判定。
abstract final class MediaFormat {
  /// 是否受支持。`fileName` 可以是文件名或完整路径。
  ///
  /// 判定为 false 的常见情形：
  /// - 非音频扩展名（`cover.jpg`）；
  /// - 无扩展名；
  /// - 隐藏文件 / 系统垃圾文件（`.nomedia`、macOS 资源分叉 `._001.mp3`）——
  ///   这类文件在 SD 卡上极常见，且**扩展名合法**，只靠白名单会误收。
  static bool isSupported(String fileName) {
    final name = _baseName(fileName);
    if (name.isEmpty || name.startsWith('.')) {
      return false;
    }
    final extension = extensionOf(name);
    return extension != null && supportedMediaExtensions.contains(extension);
  }

  /// 取小写扩展名（不含点）；无扩展名时返回 `null`。
  ///
  /// 以点开头的隐藏文件（`.mp3`）视为无扩展名。
  static String? extensionOf(String fileName) {
    final name = _baseName(fileName);
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) {
      return null;
    }
    return name.substring(dot + 1).toLowerCase();
  }

  /// 去掉目录与扩展名的显示用标题。
  ///
  /// `三体/001.mp3` → `001`。扩展名大小写不敏感。
  static String titleOf(String fileName) {
    final name = _baseName(fileName);
    final dot = name.lastIndexOf('.');
    if (dot <= 0) {
      return name;
    }
    return name.substring(0, dot);
  }

  static String _baseName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final slash = normalized.lastIndexOf('/');
    return slash < 0 ? normalized : normalized.substring(slash + 1);
  }
}
