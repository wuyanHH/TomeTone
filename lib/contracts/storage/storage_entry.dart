/// 目录项（《架构需求文档》§7.1）。
class StorageEntry {
  /// 创建目录项。
  const StorageEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.sizeBytes,
    this.lastModified,
  });

  /// 条目名（不含父路径）。
  final String name;

  /// provider 内的路径。语义由各 provider 定义（本地绝对路径 / WebDAV 相对路径），
  /// **不得**跨 provider 混用。
  final String path;

  /// 是否为目录。
  final bool isDirectory;

  /// 字节数；目录或未知时为 `null`。
  final int? sizeBytes;

  /// 最后修改时间；未知时为 `null`。
  final DateTime? lastModified;

  @override
  String toString() =>
      'StorageEntry($name, dir: $isDirectory, size: $sizeBytes)';
}
