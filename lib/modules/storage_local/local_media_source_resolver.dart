import 'dart:io';
import 'dart:typed_data';

import 'package:tometone/contracts/media/media_source_resolver.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';

/// 本地书库根的 [MediaSourceResolver] 实现。
///
/// 根是绝对文件系统路径（Android 私有目录或可直接读取的外置存储），
/// 因此播放源就是「根 + 相对路径」；不需要 document URI，也不需要缓存副本
/// （[MediaSourceResolver.resolveAudio] 的 `preferCachedCopy` 在这里无意义）。
class LocalMediaSourceResolver implements MediaSourceResolver {
  /// 以书库根绝对路径创建 resolver。
  LocalMediaSourceResolver(this.rootUri);

  /// 书库根绝对路径。
  final String rootUri;

  /// 单次内存读取上限：封面之类的图片远小于此值，音频不应走 [readBytes]。
  static const int maxReadBytes = 12 * 1024 * 1024;

  @override
  Future<AudioSourceRef?> resolveAudio({
    required String relativePath,
    bool preferCachedCopy = false,
  }) async {
    final path = _absolutePathOf(relativePath);
    if (path == null) {
      return null;
    }
    try {
      // 先判存在：把不存在的文件交给引擎只会得到 sourceNotFound，
      // 调用方无法区分「路径解析错了」和「文件真的没了」。
      final type = FileSystemEntity.typeSync(path);
      if (type != FileSystemEntityType.file) {
        return null;
      }
    } on FileSystemException {
      return null;
    }
    return LocalFileSource.fromPath(path);
  }

  @override
  Future<Uint8List?> readBytes({required String relativePath}) async {
    final path = _absolutePathOf(relativePath);
    if (path == null) {
      return null;
    }
    try {
      final file = File(path);
      // 先看长度再读：封面解析失败可以优雅回落，不该让一张异常大的图把内存吃光。
      if (await file.length() > maxReadBytes) {
        return null;
      }
      return await file.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  /// 把库内相对路径解析成绝对路径；非法路径返回 `null`。
  ///
  /// 与 `LocalStorageProvider` 保持同一套安全口径：拒绝绝对路径、盘符与 `..`，
  /// 避免相对路径被用来越出书库根。
  String? _absolutePathOf(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/');
    if (normalized.isEmpty || normalized.startsWith('/')) {
      return null;
    }
    final segments = <String>[];
    for (final segment in normalized.split('/')) {
      if (segment.isEmpty || segment == '.') {
        continue;
      }
      if (segment == '..' || segment.contains(':')) {
        return null;
      }
      segments.add(segment);
    }
    if (segments.isEmpty) {
      return null;
    }
    var base = rootUri;
    while (base.length > 1 && (base.endsWith('/') || base.endsWith('\\'))) {
      base = base.substring(0, base.length - 1);
    }
    return <String>[base, ...segments].join(Platform.pathSeparator);
  }
}
