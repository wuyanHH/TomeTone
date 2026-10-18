import 'dart:io';

import 'package:tometone/contracts/storage/provider_capabilities.dart';
import 'package:tometone/contracts/storage/stat_info.dart';
import 'package:tometone/contracts/storage/storage_entry.dart';
import 'package:tometone/contracts/storage/storage_error.dart';
import 'package:tometone/contracts/storage/storage_provider.dart';
import 'package:tometone/platform/saf/saf_bridge.dart';

/// SAF（Android Storage Access Framework）书库根的 `StorageProvider` 实现。
///
/// ## 路径语义
///
/// SAF 没有"相对路径"概念，只有 document URI。这里维护
/// `相对路径 → document URI` 的缓存：扫描器是**深度优先自上而下**遍历的，
/// 因此列出某个目录时它的父目录一定已经被列过，缓存必然命中。
///
/// 这也意味着本实现**不适合随机访问**（例如按路径直接取一个深层文件）——
/// `stat` 会逐段回退列目录。当前只有扫描器用它，够用且行为确定。
///
/// ## 读取能力
///
/// v1 只读 + 复制出（§7.1）。`readRange` / `downloadTo` 目前抛
/// `unsupportedOperation`：SAF 的字节读取要等入库通道（M2）统一做进
/// 字节管道，避免现在造一套"半可用"的读取路径。
class SafStorageProvider implements StorageProvider {
  /// 以 tree URI 创建 provider。
  SafStorageProvider(this.rootUri, {this._bridge = const SafBridge()}) {
    _documentUriByPath[''] = rootUri;
  }

  /// 根 tree URI。
  final String rootUri;

  final SafBridge _bridge;
  final Map<String, String> _documentUriByPath = <String, String>{};

  static const ProviderCapabilities _capabilities = ProviderCapabilities(
    providerType: 'saf',
    supportsRange: false,
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
    final normalized = _normalize(path);
    final documentUri = _documentUriByPath[normalized];
    if (documentUri == null) {
      // 父子顺序被破坏（调用方不是深度优先遍历）时，不要静默返回空列表 ——
      // 那会让扫描器以为这本书是空的。
      throw StorageError(code: StorageErrorCode.notFound, path: path);
    }

    final List<SafEntry> children;
    try {
      children = await _bridge.list(documentUri);
    } catch (_) {
      throw StorageError(code: StorageErrorCode.io, path: path);
    }

    return <StorageEntry>[
      for (final child in children)
        if (child.name.isNotEmpty) _toEntry(normalized, child),
    ];
  }

  @override
  Future<StatInfo> stat(String path) async {
    _ensureUsable();
    final normalized = _normalize(path);
    final documentUri = await _resolve(normalized);
    if (documentUri == null) {
      throw StorageError(code: StorageErrorCode.notFound, path: path);
    }

    final SafEntry? entry;
    try {
      entry = await _bridge.stat(documentUri);
    } catch (_) {
      throw StorageError(code: StorageErrorCode.io, path: path);
    }
    if (entry == null) {
      throw StorageError(code: StorageErrorCode.notFound, path: path);
    }
    return StatInfo(
      path: path,
      isDirectory: entry.isDirectory,
      sizeBytes: entry.sizeBytes,
      lastModified: entry.lastModified,
    );
  }

  @override
  Future<Stream<List<int>>> readRange(String path, int start, int? end) async {
    throw const StorageError(
      code: StorageErrorCode.unsupportedOperation,
      path: null,
    );
  }

  @override
  Future<void> downloadTo(
    String path,
    File target, {
    void Function(int received, int total)? onProgress,
  }) async {
    throw const StorageError(
      code: StorageErrorCode.unsupportedOperation,
      path: null,
    );
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _documentUriByPath.clear();
  }

  // ---------------------------------------------------------------------------

  StorageEntry _toEntry(String parentPath, SafEntry child) {
    final childPath = parentPath.isEmpty
        ? child.name
        : '$parentPath/${child.name}';
    _documentUriByPath[childPath] = child.documentUri;
    return StorageEntry(
      name: child.name,
      path: childPath,
      isDirectory: child.isDirectory,
      sizeBytes: child.sizeBytes,
      lastModified: child.lastModified,
    );
  }

  /// 逐段解析出 document URI（缓存未命中时回退列目录）。
  Future<String?> _resolve(String normalizedPath) async {
    if (normalizedPath.isEmpty) {
      return rootUri;
    }
    final segments = normalizedPath.split('/');
    var currentPath = '';
    var currentUri = rootUri;

    for (final segment in segments) {
      if (segment == '..') {
        throw const StorageError(code: StorageErrorCode.invalidPath);
      }
      final nextPath = currentPath.isEmpty ? segment : '$currentPath/$segment';
      final cached = _documentUriByPath[nextPath];
      if (cached != null) {
        currentPath = nextPath;
        currentUri = cached;
        continue;
      }

      final children = await _bridge.list(currentUri);
      SafEntry? match;
      for (final child in children) {
        if (child.name == segment) {
          match = child;
          break;
        }
      }
      if (match == null) {
        return null;
      }
      _documentUriByPath[nextPath] = match.documentUri;
      currentPath = nextPath;
      currentUri = match.documentUri;
    }
    return currentUri;
  }

  void _ensureUsable() {
    if (_disposed) {
      throw const StorageError(code: StorageErrorCode.unsupportedOperation);
    }
  }

  static String _normalize(String path) {
    final replaced = path.replaceAll('\\', '/');
    if (replaced.startsWith('/')) {
      throw const StorageError(code: StorageErrorCode.invalidPath);
    }
    final segments = <String>[];
    for (final segment in replaced.split('/')) {
      if (segment.isEmpty || segment == '.') {
        continue;
      }
      if (segment == '..') {
        throw const StorageError(code: StorageErrorCode.invalidPath);
      }
      segments.add(segment);
    }
    return segments.join('/');
  }
}
