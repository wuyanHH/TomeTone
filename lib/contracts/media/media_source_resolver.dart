import 'dart:typed_data';

import 'package:tometone/contracts/playback/audio_source_ref.dart';

/// 书库根类型。
enum LibraryRootKind {
  /// 本地绝对路径（Android 私有目录 / 外置存储直读）。
  local,

  /// Android Storage Access Framework 的 tree URI。
  saf,

  /// WebDAV / HTTP 远程根。
  webdav,
}

/// 把数据库里的 `library_roots.type` 归一化成 [LibraryRootKind]。
///
/// 只认两个已知类型：`'saf'` → [LibraryRootKind.saf]，`'webdav'` →
/// [LibraryRootKind.webdav]；其余（含 `null`、空串、未来新增但尚未适配的类型）
/// 一律按本地根处理 —— 与 M1 的行为保持一致，未知类型至少不会让播放直接失效。
LibraryRootKind libraryRootKindOf(String? type) {
  return switch (type) {
    'saf' => LibraryRootKind.saf,
    'webdav' => LibraryRootKind.webdav,
    _ => LibraryRootKind.local,
  };
}

/// 媒体源解析端口：把「书库根 + 库内相对路径」解析成引擎 / 图片可用的源。
///
/// 上层（播放队列、封面）只依赖本契约，**不允许**自己拼路径：本地根拼接、
/// SAF 的 document URI 解析、WebDAV 的 URL 组装是完全不同的语义，
/// 在调用点各写一遍必然漂移。
///
/// 实现按 [LibraryRootKind] 分属不同模块（`storage_local` / `storage_saf`），
/// 由 `lib/main.dart` 装配后注入。
abstract interface class MediaSourceResolver {
  /// 解析可播放源；解析不出（文件不存在 / 授权失效）返回 `null`。
  ///
  /// 实现**不得**把「文件不存在」拖到引擎层：引擎抛错只会退化成
  /// 「这本书暂时打不开」，调用方拿不到可判断的信息。
  ///
  /// [preferCachedCopy]：SAF 根在「直传 document URI 打不开」后由调用方重试时
  /// 置 `true`，表示「复制到应用私有缓存，返回本地路径」。本地 / 远程实现
  /// 可以忽略该参数（本地本来就是可直读路径）。
  Future<AudioSourceRef?> resolveAudio({
    required String relativePath,
    bool preferCachedCopy = false,
  });

  /// 读封面等小文件的字节；读不到返回 `null`。实现必须对过大文件设上限。
  Future<Uint8List?> readBytes({required String relativePath});
}

/// 按根构造 resolver（由 `lib/main.dart` 注入）。
typedef MediaSourceResolverFactory = MediaSourceResolver Function({
  required String libraryRootUri,
  required LibraryRootKind kind,
});
