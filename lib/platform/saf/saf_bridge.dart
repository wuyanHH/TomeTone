import 'package:flutter/services.dart';
import 'package:tometone/contracts/storage/directory_picker.dart';

/// SAF 的一项（目录或文件）。
class SafEntry {
  /// 创建条目。
  const SafEntry({
    required this.name,
    required this.documentUri,
    required this.isDirectory,
    this.sizeBytes,
    this.lastModified,
  });

  /// 名称。
  final String name;

  /// SAF 文档 URI（后续 list / stat 要用它，而不是拼路径）。
  final String documentUri;

  /// 是否目录。
  final bool isDirectory;

  /// 字节数（部分 provider 不提供）。
  final int? sizeBytes;

  /// 修改时间。
  final DateTime? lastModified;

  @override
  String toString() => 'SafEntry($name, dir: $isDirectory)';
}

/// 用户选中的目录。
class SafDirectory {
  /// 创建目录。
  const SafDirectory({required this.treeUri, required this.name});

  /// tree URI（已持久化读权限）。
  final String treeUri;

  /// 展示名。
  final String name;

  @override
  String toString() => 'SafDirectory($name, $treeUri)';
}

/// SAF 平台通道（Android 侧见 `MainActivity.kt`）。
///
/// 单独一层的原因：SAF 是平台能力，**不允许**上层直接碰 MethodChannel；
/// 存储模块只面对 [SafBridge] 的强类型方法。
class SafBridge implements DirectoryPicker {
  /// 创建桥。
  const SafBridge({this._channel = _defaultChannel});

  static const MethodChannel _defaultChannel = MethodChannel('tometone/saf');

  final MethodChannel _channel;

  /// 弹出系统目录选择器。用户取消返回 `null`。
  @override
  Future<PickedDirectory?> pickDirectory() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'openDirectory',
    );
    if (result == null) {
      return null;
    }
    final uri = result['uri'] as String?;
    if (uri == null || uri.isEmpty) {
      return null;
    }
    return PickedDirectory(uri: uri, name: (result['name'] as String?) ?? uri);
  }

  /// 列出目录子项。
  Future<List<SafEntry>> list(String documentUri) async {
    final raw = await _channel.invokeListMethod<Object?>(
      'list',
      <String, Object?>{'documentUri': documentUri},
    );
    if (raw == null) {
      return const <SafEntry>[];
    }
    return <SafEntry>[
      for (final item in raw)
        if (item is Map)
          SafEntry(
            name: (item['name'] as String?) ?? '',
            documentUri: (item['documentUri'] as String?) ?? '',
            isDirectory: (item['isDirectory'] as bool?) ?? false,
            sizeBytes: (item['size'] as num?)?.toInt(),
            lastModified: _toDateTime(item['lastModified']),
          ),
    ];
  }

  /// 单个条目的元信息；不存在返回 `null`。
  Future<SafEntry?> stat(String documentUri) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'stat',
      <String, Object?>{'documentUri': documentUri},
    );
    if (result == null) {
      return null;
    }
    return SafEntry(
      name: (result['name'] as String?) ?? '',
      documentUri: (result['documentUri'] as String?) ?? documentUri,
      isDirectory: (result['isDirectory'] as bool?) ?? false,
      sizeBytes: (result['size'] as num?)?.toInt(),
      lastModified: _toDateTime(result['lastModified']),
    );
  }

  static DateTime? _toDateTime(Object? millisecondsSinceEpoch) {
    final millis = (millisecondsSinceEpoch as num?)?.toInt();
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
}
