import 'dart:io';
import 'dart:typed_data';

import 'package:tometone/contracts/storage/book_metadata_file_store.dart';

/// 本地目录的 `BookMetadataFileStore` 实现（§2.1）。
///
/// 只读写 `tometone.meta.json` 一个文件，绝不触碰音频 / 封面。写走
/// 「同目录临时文件 → flush → rename」的原子路径，失败清理临时文件并返回
/// [BookMetadataWriteStatus.failed]；读超过 [maxReadBytes] 一律按「读不到」
/// 处理，返回 `null`。
class LocalBookMetadataFileStore implements BookMetadataFileStore {
  /// 以绝对根目录创建 store。
  LocalBookMetadataFileStore(String rootPath)
    : rootPath = _trimTrailingSeparators(rootPath);

  /// 书库根绝对路径。
  final String rootPath;

  /// sidecar 文件名（固定）。
  static const String sidecarFileName = 'tometone.meta.json';

  /// 读取上限：超过则按「读不到」处理（§2.1）。
  static const int maxReadBytes = 256 * 1024;

  @override
  Future<Uint8List?> read(String bookRootPath) async {
    final path = _sidecarPath(bookRootPath);
    if (path == null) {
      return null;
    }
    final file = File(path);
    try {
      final length = file.lengthSync();
      if (length > maxReadBytes) {
        return null;
      }
      return file.readAsBytesSync();
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<BookMetadataWriteStatus> write(
    String bookRootPath,
    Uint8List bytes,
  ) async {
    final path = _sidecarPath(bookRootPath);
    if (path == null) {
      return BookMetadataWriteStatus.failed;
    }
    final target = File(path);
    final temp = File('${target.path}.tmp');
    try {
      if (!target.parent.existsSync()) {
        return BookMetadataWriteStatus.failed;
      }
      final raf = await temp.open(mode: FileMode.write);
      try {
        await raf.writeFrom(bytes);
        await raf.flush();
      } finally {
        await raf.close();
      }
      await temp.rename(target.path);
      return BookMetadataWriteStatus.written;
    } on FileSystemException {
      await _deleteQuietly(temp);
      return BookMetadataWriteStatus.failed;
    }
  }

  /// 把「根 + 书根相对路径 + sidecar 文件名」拼成绝对路径；不安全返回 `null`。
  ///
  /// 拒绝 `..`（路径穿越）与含 `:` 的段（Windows 盘符），防止写到书库根之外。
  String? _sidecarPath(String bookRootPath) {
    final normalized = bookRootPath.replaceAll('\\', '/');
    final segments = <String>[];
    for (final segment in normalized.split('/')) {
      if (segment.isEmpty) {
        continue;
      }
      if (segment == '..' || segment.contains(':')) {
        return null;
      }
      segments.add(segment);
    }
    return <String>[rootPath, ...segments, sidecarFileName].join(
      Platform.pathSeparator,
    );
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (file.existsSync()) {
        file.deleteSync();
      }
    } on FileSystemException {
      // 清理失败不掩盖原始错误。
    }
  }

  static String _trimTrailingSeparators(String path) {
    var value = path;
    while (value.length > 1 && (value.endsWith('/') || value.endsWith('\\'))) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
