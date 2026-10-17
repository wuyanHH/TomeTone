import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'provider_capabilities.dart';
import 'stat_info.dart';
import 'storage_entry.dart';
import 'storage_error.dart';
import 'storage_provider.dart';

/// StorageProvider 的 Fake 实现：纯内存、确定性、可观测资源生命周期。
///
/// [liveStreams] 让契约测试能断言"取消订阅后底层传输确实被释放"，
/// 这是真实 provider（HTTP 连接池 / 文件句柄）最容易泄漏的地方。
class FakeStorageProvider implements StorageProvider {
  /// 创建 Fake provider。
  ///
  /// - [directories]：`目录路径 → 直接子项`。
  /// - [contents]：`文件路径 → 完整字节`。
  FakeStorageProvider({
    Map<String, List<StorageEntry>> directories =
        const <String, List<StorageEntry>>{},
    Map<String, List<int>> contents = const <String, List<int>>{},
    ProviderCapabilities? capabilities,
  }) : _directories = Map<String, List<StorageEntry>>.of(directories),
       _contents = Map<String, List<int>>.of(contents),
       _capabilities = capabilities ?? defaultCapabilities;

  /// Fake provider 的默认能力声明。
  static const ProviderCapabilities defaultCapabilities = ProviderCapabilities(
    providerType: 'fake',
    supportsRange: true,
    supportsWrite: false,
    supportsDigest: false,
    supportsAuth: false,
  );

  /// 单次读取 / 写入的最大分片字节数。
  static const int chunkSize = 4096;

  final Map<String, List<StorageEntry>> _directories;
  final Map<String, List<int>> _contents;
  final ProviderCapabilities _capabilities;
  final List<String> _calls = <String>[];

  int _liveStreams = 0;
  int _disposeCount = 0;
  bool _disposed = false;

  /// 当前仍存活的 `readRange` 流数量。
  ///
  /// 归零即代表底层传输已释放；不为零说明调用方取消了订阅却把资源留在了原地。
  int get liveStreams => _liveStreams;

  /// [dispose] 被调用次数 —— 用于断言幂等性与"无重复释放"。
  int get disposeCount => _disposeCount;

  /// 是否已释放。
  bool get isDisposed => _disposed;

  /// 调用流水（仅测试与开发使用，会随运行增长）。
  List<String> get calls => List<String>.unmodifiable(_calls);

  @override
  ProviderCapabilities get capabilities => _capabilities;

  @override
  Future<List<StorageEntry>> list(String path) async {
    _ensureUsable();
    _calls.add('list:$path');
    final entries = _directories[_normalize(path)];
    if (entries == null) {
      throw StorageError(code: StorageErrorCode.notFound, path: path);
    }
    return List<StorageEntry>.unmodifiable(entries);
  }

  @override
  Future<StatInfo> stat(String path) async {
    _ensureUsable();
    _calls.add('stat:$path');
    final normalized = _normalize(path);
    if (_directories.containsKey(normalized)) {
      return StatInfo(path: path, isDirectory: true);
    }
    final bytes = _contents[normalized];
    if (bytes == null) {
      throw StorageError(code: StorageErrorCode.notFound, path: path);
    }
    return StatInfo(path: path, isDirectory: false, sizeBytes: bytes.length);
  }

  @override
  Future<Stream<List<int>>> readRange(String path, int start, int? end) async {
    _ensureUsable();
    _calls.add('readRange:$path:$start:$end');

    if (start < 0 || (end != null && end < start)) {
      throw StorageError(code: StorageErrorCode.invalidPath, path: path);
    }

    final bytes = _contentOf(path);

    if (!_capabilities.supportsRange && start > 0) {
      throw StorageError(code: StorageErrorCode.serverUnsupported, path: path);
    }
    if (start > bytes.length) {
      throw StorageError(code: StorageErrorCode.invalidPath, path: path);
    }

    final lastIndex = bytes.length - 1;
    final effectiveEnd = end == null ? lastIndex : math.min(end, lastIndex);
    return _chunked(bytes.sublist(start, effectiveEnd + 1));
  }

  @override
  Future<void> downloadTo(
    String path,
    File target, {
    void Function(int received, int total)? onProgress,
  }) async {
    _ensureUsable();
    _calls.add('downloadTo:$path');

    final bytes = _contentOf(path);
    final total = bytes.length;
    final sink = target.openWrite();
    var received = 0;
    try {
      for (var offset = 0; offset < total; offset += chunkSize) {
        final stop = math.min(offset + chunkSize, total);
        final chunk = bytes.sublist(offset, stop);
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      if (total == 0) {
        onProgress?.call(0, 0);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  @override
  Future<void> dispose() async {
    _disposeCount++;
    _disposed = true;
  }

  // ---------------------------------------------------------------------------

  /// 分片读取。计数在**生成器体首次执行时**自增，因此"拿到流但不订阅"
  /// 不会污染 [liveStreams]；取消订阅会触发 `finally`，计数随之归还。
  Stream<List<int>> _chunked(List<int> bytes) async* {
    _liveStreams++;
    try {
      for (var offset = 0; offset < bytes.length; offset += chunkSize) {
        yield bytes.sublist(offset, math.min(offset + chunkSize, bytes.length));
      }
    } finally {
      _liveStreams--;
    }
  }

  List<int> _contentOf(String path) {
    final bytes = _contents[_normalize(path)];
    if (bytes == null) {
      throw StorageError(code: StorageErrorCode.notFound, path: path);
    }
    return bytes;
  }

  void _ensureUsable() {
    if (_disposed) {
      throw const StorageError(code: StorageErrorCode.unsupportedOperation);
    }
  }

  static String _normalize(String path) {
    var value = path.trim();
    while (value.length > 1 && value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
