import 'dart:io';

import 'package:drift/drift.dart';
import 'package:tometone/contracts/storage/storage_provider.dart';
import 'package:tometone/domain/common/id_generator.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/scan/library_scanner.dart';
import 'package:tometone/domain/library/scan/scan_report.dart';

/// 按书库根 URI 造一个 provider（本地 / SAF / WebDAV 各自的实现）。
///
/// 由装配层注入：应用层不能 import `modules`（§5.2 依赖方向铁律）。
typedef StorageProviderFactory = StorageProvider Function(String rootUri);

/// 书库根管理 + 扫描触发（设置页的后端能力）。
///
/// 只做编排：根记录的读写、provider 的生命周期、扫描器调用。
/// 扫描规则本身在 `LibraryScanner`，这里不再重复。
class LibraryRootService {
  /// 创建服务。
  LibraryRootService({
    required this._database,
    required IdGenerator idGenerator,
    required this._providerFactory,
    DateTime Function()? clock,
  }) : _idGenerator = idGenerator,
       _clock = clock ?? DateTime.now,
       _scanner = LibraryScanner(
         database: _database,
         idGenerator: idGenerator,
         clock: clock,
       );

  final TomeToneDatabase _database;
  final IdGenerator _idGenerator;
  final StorageProviderFactory _providerFactory;
  final DateTime Function() _clock;
  final LibraryScanner _scanner;

  /// 添加本地书库根，返回新根的 ID。
  ///
  /// 只做**校验 + 落库**，不自动扫描 —— 扫描可能持续数秒到数十秒，
  /// 由 UI 显式触发并显示进度（§2.1 两阶段：先结构，后回填）。
  Future<String> addLocalRoot({
    required String absolutePath,
    String? displayName,
  }) async {
    final path = absolutePath.trim();
    if (path.isEmpty) {
      throw ArgumentError.value(absolutePath, 'absolutePath', '不能为空');
    }
    if (!Directory(path).existsSync()) {
      throw StateError('目录不存在：$path');
    }

    final id = _idGenerator.next();
    await _database
        .into(_database.libraryRoots)
        .insert(
          LibraryRootsCompanion.insert(
            id: id,
            type: 'local',
            uri: path,
            displayName: (displayName ?? _suggestName(path)).trim(),
            createdAt: _clock().toUtc(),
          ),
        );
    return id;
  }

  /// 添加 SAF 书库根（tree URI 已由平台层持久化读权限）。
  ///
  /// 与 [addLocalRoot] 的差别：SAF 目录无法用 `Directory.existsSync` 校验，
  /// 授权是否有效只能等真正列举时才知道（失败会体现在扫描报告的 `failedPaths`）。
  Future<String> addSafRoot({
    required String treeUri,
    required String displayName,
  }) async {
    final uri = treeUri.trim();
    if (uri.isEmpty) {
      throw ArgumentError.value(treeUri, 'treeUri', '不能为空');
    }
    final id = _idGenerator.next();
    await _database
        .into(_database.libraryRoots)
        .insert(
          LibraryRootsCompanion.insert(
            id: id,
            type: 'saf',
            uri: uri,
            displayName: displayName.trim().isEmpty ? uri : displayName.trim(),
            createdAt: _clock().toUtc(),
          ),
        );
    return id;
  }

  /// 扫描指定书库根（Phase 1 结构扫描）。
  ///
  /// provider 的创建与释放都在这里完成；扫描器不感知实现。
  Future<ScanReport> scan(String libraryRootId) async {
    final root = await (_database.select(
      _database.libraryRoots,
    )..where((tbl) => tbl.id.equals(libraryRootId))).getSingleOrNull();
    if (root == null) {
      throw StateError('书库根不存在：$libraryRootId');
    }

    final provider = _providerFactory(root.uri);
    try {
      return await _scanner.scanStructure(
        libraryRootId: root.id,
        provider: provider,
        sourceType: root.type,
      );
    } finally {
      await provider.dispose();
    }
  }

  /// 重命名书库根：只改展示名，不动 URI、书目与任何文件。
  ///
  /// 名字是给用户认的标签，空名会让列表认不出这条根，所以这里拒绝空值。
  Future<void> renameRoot(String id, String displayName) async {
    final String name = displayName.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(displayName, 'displayName', '不能为空');
    }
    final int updated =
        await (_database.update(_database.libraryRoots)
              ..where((tbl) => tbl.id.equals(id)))
            .write(LibraryRootsCompanion(displayName: Value<String>(name)));
    if (updated == 0) {
      throw StateError('书库根不存在：$id');
    }
  }

  /// 移除书库根的**登记**，连带清掉它扫出来的书 / 卷 / 章（外键级联）。
  ///
  /// 数据安全（§9.2）：这里只有一条 `DELETE`，不调用 provider 的任何
  /// 写方法、不传任何路径 —— 用户目录里的文件不会被移动、改名或删除。
  /// 移除前应当由界面把「将影响多少册 / 多少章」说清楚。
  Future<void> removeRoot(String id) async {
    final int removed = await (_database.delete(
      _database.libraryRoots,
    )..where((tbl) => tbl.id.equals(id))).go();
    if (removed == 0) {
      throw StateError('书库根不存在：$id');
    }
  }

  /// 最近一次扫描时间（设置页展示用）。
  Future<DateTime?> lastScanAt(String libraryRootId) async {
    final row = await (_database.select(
      _database.libraryRoots,
    )..where((tbl) => tbl.id.equals(libraryRootId))).getSingleOrNull();
    return row?.lastScanAt;
  }

  static String _suggestName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final trimmed = normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
    final slash = trimmed.lastIndexOf('/');
    final name = slash < 0 ? trimmed : trimmed.substring(slash + 1);
    return name.isEmpty ? path : name;
  }
}
