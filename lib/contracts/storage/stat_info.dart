/// 路径元信息（《架构需求文档》§7.1）。
class StatInfo {
  /// 创建元信息。
  const StatInfo({
    required this.path,
    required this.isDirectory,
    this.sizeBytes,
    this.lastModified,
    this.etag,
  });

  /// provider 内的路径。
  final String path;

  /// 是否为目录。
  final bool isDirectory;

  /// 字节数；目录或未知时为 `null`。
  final int? sizeBytes;

  /// 最后修改时间；未知时为 `null`。
  final DateTime? lastModified;

  /// 服务端校验标识（HTTP ETag / WebDAV getetag）。
  ///
  /// 增量扫描可用它判断"内容是否变化"，避免仅凭时间戳误判。
  final String? etag;

  @override
  String toString() =>
      'StatInfo($path, dir: $isDirectory, size: $sizeBytes, etag: $etag)';
}
