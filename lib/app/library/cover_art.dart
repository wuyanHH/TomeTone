import 'dart:typed_data';

/// 封面来源（应用层语义）：UI 据此选择 `Image.file` 还是 `Image.memory`。
///
/// 本地根用**绝对路径**省内存（大图不整块读进内存），SAF 根读不出本地路径，
/// 只能读出字节。两种形态在这里统一，UI 不再关心「根是什么类型」。
sealed class CoverArt {
  /// 创建封面来源。
  const CoverArt();
}

/// 本地文件路径形式的封面（绝对路径，`Image.file` 可直接读）。
class CoverArtFile extends CoverArt {
  /// 以绝对文件路径创建。
  const CoverArtFile(this.absolutePath);

  /// 绝对文件路径（`BookCover.coverPath` 的 debug assert 要求绝对路径）。
  final String absolutePath;
}

/// 内存字节形式的封面（SAF 等无法用 `Image.file` 读取的根）。
class CoverArtBytes extends CoverArt {
  /// 以图片字节创建。
  const CoverArtBytes(this.bytes);

  /// 图片字节（交给 `MemoryImage`）。
  final Uint8List bytes;
}

/// 封面 Provider 的族键：书库根 ID + 库内相对封面路径。
///
/// 用值相等（`==` / `hashCode`）而不是对象标识：同一个根 / 同一张封面
/// 必须命中同一个缓存条目，否则每次 rebuild 都会重复解析。
class CoverArtKey {
  /// 创建封面键。
  const CoverArtKey({required this.rootId, required this.coverPath});

  /// 书库根 ID。
  final String rootId;

  /// 库内相对封面路径；`null` / 空表示这本书没有封面。
  final String? coverPath;

  @override
  bool operator ==(Object other) =>
      other is CoverArtKey &&
      other.rootId == rootId &&
      other.coverPath == coverPath;

  @override
  int get hashCode => Object.hash(rootId, coverPath);

  @override
  String toString() => 'CoverArtKey($rootId, $coverPath)';
}
