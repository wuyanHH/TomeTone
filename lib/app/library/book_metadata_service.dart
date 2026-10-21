import 'dart:typed_data';

import 'package:tometone/contracts/storage/book_metadata_file_store.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';
import 'package:tometone/domain/library/metadata/book_metadata_codec.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/domain/library/queries/library_views.dart';

/// `save` 的结果：数据库写入是否成功由异常表达，这里只报告 sidecar 写入状态。
class MetadataSaveResult {
  const MetadataSaveResult({required this.sidecarStatus});

  /// sidecar 写入结果（written / unsupported / failed）。
  final BookMetadataWriteStatus sidecarStatus;
}

/// 书架元数据服务（详情页编辑 / 从书根重新导入）。
///
/// 元数据双写：SQLite 覆盖层是显示真源；本地可写根同步 `tometone.meta.json`，
/// SAF 只读根跳过 sidecar 写入。DB 保存成功不因 sidecar 失败回滚。
class BookMetadataService {
  /// 创建服务。
  BookMetadataService({
    required this._queries,
    required this._storeFactory,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LibraryQueries _queries;
  final BookMetadataFileStoreFactory _storeFactory;
  final DateTime Function() _clock;

  /// 保存手动编辑的元数据：先写库（manual: true），再写 sidecar。
  ///
  /// 库异常直接向上抛；sidecar 写异常折叠为 [BookMetadataWriteStatus.failed]，
  /// 不因 sidecar 失败回滚已成功的库写入。
  Future<MetadataSaveResult> save({
    required BookSummary book,
    required String rootUri,
    required BookMetadataDraft draft,
  }) async {
    final BookMetadataDraft normalized = draft.normalized();
    await _queries.saveBookMetadata(
      bookId: book.id,
      metadata: normalized,
      manual: true,
    );

    final store = _storeFactory(rootUri);
    BookMetadataWriteStatus status;
    try {
      status = await store.write(
        book.rootPath,
        BookMetadataCodec.encode(normalized, updatedAt: _clock()),
      );
    } catch (_) {
      status = BookMetadataWriteStatus.failed;
    }
    return MetadataSaveResult(sidecarStatus: status);
  }

  /// 在线书只写覆盖层，不写 sidecar。
  Future<MetadataSaveResult> saveOnline({
    required BookSummary book,
    required BookMetadataDraft draft,
  }) async {
    await _queries.saveBookMetadata(
      bookId: book.id,
      metadata: draft.normalized(),
      manual: true,
    );
    return const MetadataSaveResult(
      sidecarStatus: BookMetadataWriteStatus.unsupported,
    );
  }

  /// 从书根 sidecar 重新导入元数据；读到 / 解码不到返回 `null`。
  ///
  /// [overwriteManual] 为 `false`（默认）时走「只填空」：用户手填过的字段绝不被
  /// 覆盖；为 `true` 时（详情页确认后）只覆盖 JSON 中出现的字段，缺字段不清空。
  Future<BookMetadataDraft?> importFromBookRoot({
    required BookSummary book,
    required String rootUri,
    bool overwriteManual = false,
  }) async {
    final store = _storeFactory(rootUri);
    final Uint8List? bytes;
    try {
      bytes = await store.read(book.rootPath);
    } catch (_) {
      // 读不到（权限 / IO 异常）视为「暂不可用」，与 store 契约一致回落 null。
      return null;
    }
    if (bytes == null) {
      return null;
    }
    final BookMetadataDraft? draft = BookMetadataCodec.decode(bytes);
    if (draft == null) {
      return null;
    }
    await _queries.saveBookMetadata(
      bookId: book.id,
      metadata: draft,
      manual: false,
      onlyFillEmpty: !overwriteManual,
    );
    return draft;
  }
}
