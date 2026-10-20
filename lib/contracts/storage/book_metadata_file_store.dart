import 'dart:typed_data';

/// 书架元数据 sidecar 的写入结果（§2.1「书架与元数据」）。
enum BookMetadataWriteStatus {
  /// 已写入。
  written,

  /// 该存储后端不支持写入（如 SAF 只读根）。
  unsupported,

  /// 写入失败（目标目录不存在、IO 错误等）。
  failed,
}

/// 以存储根 URI 构造 [BookMetadataFileStore] 的工厂。
///
/// 本地根传入绝对路径，SAF 根传入 tree URI；上层（装配层）据此选择实现。
typedef BookMetadataFileStoreFactory = BookMetadataFileStore Function(
  String rootUri,
);

/// 书架元数据 sidecar 的存储端口（§2.1）。
///
/// 每个「书根」对应一个 `tometone.meta.json` sidecar 文件；本端口只负责
/// 该文件的**原始字节**读写，编解码交给领域层的 codec，因此契约层
/// 不 import 领域层，只依赖 [Uint8List]。
///
/// ## 规范行为
///
/// - [read]：文件不存在 / 读不到 / 超过大小上限，一律返回 `null`
///   （调用方回落「暂不可用」）。
/// - [write]：只读后端（SAF）返回 [BookMetadataWriteStatus.unsupported]，
///   且**绝不调用**任何平台写方法；失败返回 [BookMetadataWriteStatus.failed]。
abstract interface class BookMetadataFileStore {
  /// 读取 [bookRootPath] 对应的 sidecar 原始字节；不存在返回 `null`。
  Future<Uint8List?> read(String bookRootPath);

  /// 写入 [bookRootPath] 对应的 sidecar 原始字节。
  Future<BookMetadataWriteStatus> write(String bookRootPath, Uint8List bytes);
}
