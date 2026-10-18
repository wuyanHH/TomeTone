import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:tometone/contracts/storage/provider_capabilities.dart';
import 'package:tometone/contracts/storage/stat_info.dart';
import 'package:tometone/contracts/storage/storage_entry.dart';
import 'package:tometone/contracts/storage/storage_error.dart';
import 'package:tometone/contracts/storage/storage_provider.dart';

/// 本地目录的 `StorageProvider` 实现（M1 的书库扫描后端）。
///
/// 作用域是**单个书库根**：所有路径都是相对根目录的路径，绝对路径会被拒绝。
///
/// ## 安全边界（必须守住）
///
/// - **拒绝 `..` 段**：不做"解析后判断是否越界"，而是直接拒绝 ——
///   路径穿越是最容易写错的一类漏洞，越界解析 + 前缀比较在大小写不敏感、
///   符号链接、Windows 短路径下都可能失效。
/// - 拒绝空路径（根目录本身由 `list('')` 表达，不是文件）。
/// - 任何 `FileSystemException` 都必须折算成 `StorageError`，
///   不让平台异常泄漏到领域层。
class LocalStorageProvider implements StorageProvider {
  /// 以绝对根目录创建 provider。
  LocalStorageProvider(String rootPath)
    : rootPath = _trimTrailingSeparators(rootPath);

  /// 书库根绝对路径。
  final String rootPath;

  /// 单次读取 / 下载的分片大小。
  static const int chunkSize = 64 * 1024;

  static const ProviderCapabilities _capabilities = ProviderCapabilities(
    providerType: 'local',
    supportsRange: true,
    supportsWrite: false,
    supportsDigest: false,
    supportsAuth: false,
  );

  bool _disposed = false;

  @override
  ProviderCapabilities get capabilities => _capabilities;

  @override
  Future<List<StorageEntry>> list(String path) async {
    _ensureUsable();
    final directory = Directory(_absoluteOf(path));
    final List<FileSystemEntity> children;
    try {
      children = directory.listSync(followLinks: false);
    } on FileSystemException catch (error) {
      throw _mapIoError(error, path);
    }

    final entries = <StorageEntry>[];
    for (final child in children) {
      final name = _baseName(child.path);
      final isDirectory = child is Directory;
      entries.add(
        StorageEntry(
          name: name,
          path: _joinRelative(path, name),
          isDirectory: isDirectory,
          sizeBytes: isDirectory ? null : _lengthOrNull(child),
          lastModified: _modifiedOrNull(child),
        ),
      );
    }
    return entries;
  }

  @override
  Future<StatInfo> stat(String path) async {
    _ensureUsable();
    final target = FileSystemEntity.typeSync(_absoluteOf(path));
    if (target == FileSystemEntityType.notFound) {
      throw StorageError(code: StorageErrorCode.notFound, path: path);
    }
    if (target == FileSystemEntityType.directory) {
      return StatInfo(path: path, isDirectory: true);
    }

    final file = File(_absoluteOf(path));
    try {
      return StatInfo(
        path: path,
        isDirectory: false,
        sizeBytes: file.lengthSync(),
        lastModified: file.lastModifiedSync(),
      );
    } on FileSystemException catch (error) {
      throw _mapIoError(error, path);
    }
  }

  @override
  Future<Stream<List<int>>> readRange(String path, int start, int? end) async {
    _ensureUsable();
    if (start < 0 || (end != null && end < start)) {
      throw StorageError(code: StorageErrorCode.invalidPath, path: path);
    }

    final file = File(_absoluteOf(path));
    try {
      final length = file.lengthSync();
      if (start > length) {
        throw StorageError(code: StorageErrorCode.invalidPath, path: path);
      }
      final lastIndex = length - 1;
      final effectiveEnd = end == null ? lastIndex : math.min(end, lastIndex);
      // dart:io 的结束位置是**开区间**，契约是闭区间。
      return file.openRead(start, effectiveEnd + 1);
    } on FileSystemException catch (error) {
      throw _mapIoError(error, path);
    }
  }

  @override
  Future<void> downloadTo(
    String path,
    File target, {
    void Function(int received, int total)? onProgress,
  }) async {
    _ensureUsable();
    final source = File(_absoluteOf(path));
    final int total;
    try {
      total = source.lengthSync();
    } on FileSystemException catch (error) {
      throw _mapIoError(error, path);
    }

    final sink = target.openWrite();
    var received = 0;
    try {
      await for (final chunk in source.openRead()) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      if (total == 0) {
        onProgress?.call(0, 0);
      }
      await sink.flush();
    } on FileSystemException catch (error) {
      throw _mapIoError(error, path);
    } finally {
      await sink.close();
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
  }

  // ---------------------------------------------------------------------------

  void _ensureUsable() {
    if (_disposed) {
      throw const StorageError(code: StorageErrorCode.unsupportedOperation);
    }
  }

  /// 把相对路径解析成绝对路径，**拒绝任何越界尝试**。
  String _absoluteOf(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/');
    // 绝对路径 / 盘符出现在"相对路径"里一定是调用方搞错了，
    // 静默当成相对路径只会让 bug 变成莫名的 notFound。
    if (normalized.startsWith('/') ||
        RegExp(r'^[A-Za-z]:').hasMatch(normalized)) {
      throw StorageError(
        code: StorageErrorCode.invalidPath,
        path: relativePath,
      );
    }
    final segments = <String>[];
    for (final segment in normalized.split('/')) {
      if (segment.isEmpty || segment == '.') {
        continue;
      }
      if (segment == '..') {
        throw StorageError(
          code: StorageErrorCode.invalidPath,
          path: relativePath,
        );
      }
      // 绝对路径片段（含 Windows 盘符）不允许出现在相对路径里。
      if (segment.contains(':')) {
        throw StorageError(
          code: StorageErrorCode.invalidPath,
          path: relativePath,
        );
      }
      segments.add(segment);
    }
    if (segments.isEmpty) {
      return rootPath;
    }
    return <String>[rootPath, ...segments].join(Platform.pathSeparator);
  }

  static String _joinRelative(String parent, String name) {
    final normalized = parent.replaceAll('\\', '/');
    final trimmed = normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
    return trimmed.isEmpty ? name : '$trimmed/$name';
  }

  static String _baseName(String absolutePath) {
    final normalized = absolutePath.replaceAll('\\', '/');
    final slash = normalized.lastIndexOf('/');
    return slash < 0 ? normalized : normalized.substring(slash + 1);
  }

  static String _trimTrailingSeparators(String path) {
    var value = path;
    while (value.length > 1 && (value.endsWith('/') || value.endsWith('\\'))) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  static int? _lengthOrNull(FileSystemEntity entity) {
    try {
      return entity is File ? entity.lengthSync() : null;
    } on FileSystemException {
      return null;
    }
  }

  static DateTime? _modifiedOrNull(FileSystemEntity entity) {
    try {
      return entity.statSync().modified;
    } on FileSystemException {
      return null;
    }
  }

  static StorageError _mapIoError(FileSystemException error, String path) {
    final code = error.osError?.errorCode;
    // ENOENT: POSIX 2 / Windows 3；EACCES: POSIX 13 / Windows 5。
    if (code == 2 || code == 3) {
      return StorageError(
        code: StorageErrorCode.notFound,
        path: path,
        cause: error,
      );
    }
    if (code == 13 || code == 5) {
      return StorageError(
        code: StorageErrorCode.permission,
        path: path,
        cause: error,
      );
    }
    return StorageError(code: StorageErrorCode.io, path: path, cause: error);
  }
}
