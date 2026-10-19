import 'dart:typed_data';

import 'package:tometone/contracts/media/media_source_resolver.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/platform/saf/saf_bridge.dart';

/// SAF 书库根的 [MediaSourceResolver] 实现。
///
/// ## 为什么播放源也是 `LocalFileSource`
///
/// 这是一次**语义借用**，不是「本地绝对路径」：引擎只做
/// `Uri.parse(source.uri)` → `AudioSource.uri`，而 `content://…/document/…`
/// 是 JustAudio / ExoPlayer 能直接打开的内容 URI。
/// [LocalFileSource] 只是「单个可直接打开的 URI」这一容器，URI 的 scheme
/// 由解析结果决定 —— 本地根是 `file://`，SAF 根是 `content://`。
///
/// 注意：**不能**用 [LocalFileSource.fromPath] 传 document URI，
/// 它会把参数当成文件系统路径再包一层 `file://`，结果必然打不开；
/// 这里用 `LocalFileSource(uri: …)` 原样保留 document URI。
///
/// ## 缓存副本
///
/// 部分 provider / 引擎组合无法直接打开 document URI，调用方可用
/// `preferCachedCopy: true` 重试：先解析出 document URI，再让平台侧流式复制
/// 到应用私有缓存，返回本地绝对路径。缓存文件名带上库内相对路径，
/// 避免不同书的同名章节互相覆盖。
class SafMediaSourceResolver implements MediaSourceResolver {
  /// 以 tree URI 创建 resolver。
  SafMediaSourceResolver(this.rootUri, {this._bridge = const SafBridge()});

  /// 书库根 tree URI。
  final String rootUri;

  final SafBridge _bridge;

  @override
  Future<AudioSourceRef?> resolveAudio({
    required String relativePath,
    bool preferCachedCopy = false,
  }) async {
    if (_isBlank(relativePath)) {
      return null;
    }
    final documentUri = await _documentUriOf(relativePath);
    if (documentUri == null) {
      return null;
    }

    if (!preferCachedCopy) {
      // 直接给引擎 content:// document URI（见类注释的语义借用说明）。
      return LocalFileSource(uri: documentUri);
    }

    final cachedPath = await _copyToCache(documentUri, relativePath);
    if (cachedPath == null) {
      return null;
    }
    // 这一步才是真正的本地绝对路径。
    return LocalFileSource.fromPath(cachedPath);
  }

  @override
  Future<Uint8List?> readBytes({required String relativePath}) async {
    if (_isBlank(relativePath)) {
      return null;
    }
    final documentUri = await _documentUriOf(relativePath);
    if (documentUri == null) {
      return null;
    }
    try {
      return await _bridge.readBytes(documentUri);
    } on Exception {
      return null;
    }
  }

  Future<String?> _documentUriOf(String relativePath) async {
    try {
      return await _bridge.documentUri(
        treeUri: rootUri,
        relativePath: relativePath,
      );
    } on Exception {
      return null;
    }
  }

  Future<String?> _copyToCache(String documentUri, String relativePath) async {
    try {
      return await _bridge.copyToCache(
        documentUri: documentUri,
        name: _cacheNameOf(relativePath),
      );
    } on Exception {
      return null;
    }
  }

  /// 把库内相对路径压成单段缓存文件名，保留路径信息以避免同名覆盖。
  static String _cacheNameOf(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/');
    final trimmed = normalized.replaceAll(RegExp(r'^/+|/+$'), '');
    if (trimmed.isEmpty) {
      return 'media';
    }
    return trimmed.replaceAll('/', '__');
  }

  static bool _isBlank(String value) => value.trim().isEmpty;
}
