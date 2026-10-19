import 'package:flutter/services.dart';
import 'package:tometone/contracts/storage/directory_authorization.dart';
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
///
/// 媒体解析（[documentUri] / [readBytes] / [copyToCache]）同样走这里：
/// 上层只拿结果，不关心 `content://` 的细节。所有方法在平台侧失败时
/// 返回 `null`（而不是抛异常），调用方据此回落到「暂不可用」。
///
/// 除目录选择（[DirectoryPicker]）外，本桥还承担 [DirectoryAuthorization]：
/// 移除 SAF 书库根时要放弃对应的持久化读授权，见 [release]。
class SafBridge implements DirectoryPicker, DirectoryAuthorization {
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

  /// 放弃 tree URI 的持久化读授权（best-effort，失败返回 false）。
  ///
  /// 与 [pickDirectory] 相反：选择器负责「拿到并持久化」授权，这里负责「丢掉」它。
  /// 授权本来就不在、URI 非法或系统拒绝，一律返回 `false` —— 调用方的
  /// 「移除书库根登记」绝不能因此失败（契约见 [DirectoryAuthorization.release]）。
  @override
  Future<bool> release(String rootUri) async {
    try {
      final released = await _channel.invokeMethod<bool>(
        'releasePermission',
        <String, Object?>{'treeUri': rootUri},
      );
      return released ?? false;
    } on PlatformException {
      return false;
    }
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

  /// 把「tree URI + 库内相对路径」解析成 document URI；找不到返回 `null`。
  ///
  /// [relativePath] 是库内相对路径（`/` 分隔，可含中文、空格、`%`、`#`）。
  /// 这里**不做**任何 URL 编解码：平台侧按显示名逐段匹配，
  /// 编码 / 解码只会在 `%` 这类字符上制造二次转义。
  Future<String?> documentUri({
    required String treeUri,
    required String relativePath,
  }) async {
    try {
      return await _channel.invokeMethod<String>(
        'documentUri',
        <String, Object?>{'treeUri': treeUri, 'relativePath': relativePath},
      );
    } on PlatformException {
      return null;
    }
  }

  /// 读取 document URI 指向文件的字节（有大小上限）。
  ///
  /// 平台侧超过上限会返回 `too_large` 错误；对调用方而言与「读不到」等价，
  /// 统一折叠成 `null`。
  Future<Uint8List?> readBytes(String documentUri) async {
    try {
      final raw = await _channel.invokeMethod<Object?>(
        'readBytes',
        <String, Object?>{'documentUri': documentUri},
      );
      if (raw is Uint8List) {
        return raw;
      }
      if (raw is List<int>) {
        return Uint8List.fromList(raw);
      }
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// 把 document URI 复制进应用私有缓存，返回本地绝对路径；失败返回 `null`。
  ///
  /// [name] 只用于生成缓存文件名，必须由调用方保证在书库内唯一
  /// （同名文件会被「大小一致则复用」命中，从而拿到另一本书的内容）。
  Future<String?> copyToCache({
    required String documentUri,
    required String name,
  }) async {
    try {
      final path = await _channel.invokeMethod<String>(
        'copyToCache',
        <String, Object?>{'documentUri': documentUri, 'name': name},
      );
      if (path == null || path.isEmpty) {
        return null;
      }
      return path;
    } on PlatformException {
      return null;
    }
  }

  static DateTime? _toDateTime(Object? millisecondsSinceEpoch) {
    final millis = (millisecondsSinceEpoch as num?)?.toInt();
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
}
