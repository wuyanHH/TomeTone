import 'dart:typed_data';

import 'package:tometone/contracts/storage/book_metadata_file_store.dart';
import 'package:tometone/platform/saf/saf_bridge.dart';

/// SAF（Android Storage Access Framework）书库根的 `BookMetadataFileStore` 实现。
///
/// SAF 根只读：`write` 直接返回 [BookMetadataWriteStatus.unsupported]，
/// 绝不调用任何平台写方法；`read` 先 [SafBridge.documentUri] 解析出
/// document URI，再 [SafBridge.readBytes] 读取原始字节。
class SafBookMetadataFileStore implements BookMetadataFileStore {
  /// 以 tree URI 创建 store。
  SafBookMetadataFileStore(this.rootUri, {SafBridge? bridge})
    : _bridge = bridge ?? const SafBridge();

  /// 根 tree URI。
  final String rootUri;

  final SafBridge _bridge;

  /// sidecar 文件名（固定）。
  static const String sidecarFileName = 'tometone.meta.json';

  @override
  Future<Uint8List?> read(String bookRootPath) async {
    final documentUri = await _bridge.documentUri(
      treeUri: rootUri,
      relativePath: _sidecarRelativePath(bookRootPath),
    );
    if (documentUri == null) {
      return null;
    }
    return _bridge.readBytes(documentUri);
  }

  @override
  Future<BookMetadataWriteStatus> write(
    String bookRootPath,
    Uint8List bytes,
  ) async {
    return BookMetadataWriteStatus.unsupported;
  }

  /// 书根相对路径 + 固定 sidecar 文件名 → SAF 库内相对路径。
  String _sidecarRelativePath(String bookRootPath) {
    final normalized = bookRootPath.replaceAll('\\', '/');
    if (normalized.isEmpty) {
      return sidecarFileName;
    }
    return '$normalized/$sidecarFileName';
  }
}
