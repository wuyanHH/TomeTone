import 'dart:convert';

import 'package:drift/drift.dart';

import '../library/database/tometone_database.dart';
import 'book_source.dart';
import 'url_normalizer.dart';

/// 书源持久化端口。
///
/// 应用服务只依赖这个接口；UI 不直接访问 Drift。`sourceByUrl` 在实现侧负责
/// 规范化 URL，调用方传入用户输入即可。
abstract interface class BookSourceQueries {
  Future<List<BookSource>> listSources({bool includeDeleted = false});

  Future<BookSource?> sourceById(String id);

  Future<BookSource?> sourceByUrl(String sourceUrl);

  /// 记录一次源级探测结果；不更新 `updatedAt`。
  Future<void> recordProbe(
    String sourceId, {
    required bool ok,
    String? error,
    DateTime? checkedAt,
  });

  Future<int> countBooks(String sourceId);

  Future<void> insertSource(BookSource source);

  Future<void> updateSource(BookSource source);

  Future<void> setEnabled(String sourceId, bool enabled, {DateTime? updatedAt});

  Future<void> revive(String sourceId, {DateTime? updatedAt});

  Future<void> softDelete(
    String sourceId, {
    required bool deleteBooks,
    DateTime? deletedAt,
  });
}

class DriftBookSourceQueries implements BookSourceQueries {
  DriftBookSourceQueries(this._database);

  final TomeToneDatabase _database;

  @override
  Future<List<BookSource>> listSources({bool includeDeleted = false}) async {
    final query = _database.select(_database.bookSources);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    query.orderBy(<OrderClauseGenerator<$BookSourcesTable>>[
      (tbl) => OrderingTerm(expression: tbl.customOrder),
      (tbl) => OrderingTerm(expression: tbl.name),
    ]);

    final rows = await query.get();
    return <BookSource>[for (final row in rows) _toDomain(row)];
  }

  @override
  Future<BookSource?> sourceById(String id) async {
    final row = await (_database.select(
      _database.bookSources,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<BookSource?> sourceByUrl(String sourceUrl) async {
    final String normalized;
    try {
      normalized = normalizeNetworkUrl(sourceUrl);
    } on FormatException {
      return null;
    }
    final row = await (_database.select(
      _database.bookSources,
    )..where((tbl) => tbl.sourceUrl.equals(normalized))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> recordProbe(
    String sourceId, {
    required bool ok,
    String? error,
    DateTime? checkedAt,
  }) async {
    final at = (checkedAt ?? DateTime.now()).toUtc();
    await _database.transaction(() async {
      final row = await (_database.select(
        _database.bookSources,
      )..where((tbl) => tbl.id.equals(sourceId))).getSingleOrNull();
      if (row == null) {
        throw StateError('书源不存在：$sourceId');
      }

      await (_database.update(
        _database.bookSources,
      )..where((tbl) => tbl.id.equals(sourceId))).write(
        BookSourcesCompanion(
          lastTestAt: Value<DateTime?>(at),
          lastTestOk: Value<bool?>(ok),
          lastError: Value<String?>(ok ? null : error),
          consecutiveFailures: Value<int>(ok ? 0 : row.consecutiveFailures + 1),
        ),
      );
    });
  }

  @override
  Future<int> countBooks(String sourceId) async {
    final count = _database.books.id.count();
    final query = _database.selectOnly(_database.books)
      ..addColumns(<Expression<Object>>[count])
      ..where(_database.books.sourceId.equals(sourceId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Future<void> insertSource(BookSource source) async {
    await _database.into(_database.bookSources).insert(_companion(source));
  }

  @override
  Future<void> updateSource(BookSource source) async {
    final updated =
        await (_database.update(_database.bookSources)
              ..where((tbl) => tbl.id.equals(source.id)))
            .write(_companion(source, includeId: false));
    if (updated == 0) {
      throw StateError('书源不存在：${source.id}');
    }
  }

  @override
  Future<void> setEnabled(
    String sourceId,
    bool enabled, {
    DateTime? updatedAt,
  }) async {
    final updated =
        await (_database.update(
          _database.bookSources,
        )..where((tbl) => tbl.id.equals(sourceId))).write(
          BookSourcesCompanion(
            enabled: Value<bool>(enabled),
            updatedAt: Value<DateTime>((updatedAt ?? DateTime.now()).toUtc()),
          ),
        );
    if (updated == 0) {
      throw StateError('书源不存在：$sourceId');
    }
  }

  @override
  Future<void> revive(String sourceId, {DateTime? updatedAt}) async {
    final updated =
        await (_database.update(
          _database.bookSources,
        )..where((tbl) => tbl.id.equals(sourceId))).write(
          BookSourcesCompanion(
            deletedAt: const Value<DateTime?>(null),
            updatedAt: Value<DateTime>((updatedAt ?? DateTime.now()).toUtc()),
          ),
        );
    if (updated == 0) {
      throw StateError('书源不存在：$sourceId');
    }
  }

  @override
  Future<void> softDelete(
    String sourceId, {
    required bool deleteBooks,
    DateTime? deletedAt,
  }) async {
    final DateTime now = (deletedAt ?? DateTime.now()).toUtc();
    await _database.transaction(() async {
      if (deleteBooks) {
        await (_database.delete(
          _database.books,
        )..where((tbl) => tbl.sourceId.equals(sourceId))).go();
      }

      final updated =
          await (_database.update(
            _database.bookSources,
          )..where((tbl) => tbl.id.equals(sourceId))).write(
            BookSourcesCompanion(
              deletedAt: Value<DateTime?>(now),
              updatedAt: Value<DateTime>(now),
            ),
          );
      if (updated == 0) {
        throw StateError('书源不存在：$sourceId');
      }
    });
  }

  BookSourcesCompanion _companion(BookSource source, {bool includeId = true}) {
    return BookSourcesCompanion(
      id: includeId ? Value<String>(source.id) : const Value<String>.absent(),
      libraryRootId: Value<String>(source.libraryRootId),
      sourceUrl: Value<String>(source.sourceUrl),
      name: Value<String>(source.name),
      groupName: Value<String?>(source.groupName),
      sourceType: Value<int>(source.sourceType),
      rawJson: Value<String>(source.rawJson),
      headerJson: Value<String?>(_encodeHeader(source.header)),
      exploreUrl: Value<String?>(source.exploreUrl),
      searchUrl: Value<String?>(source.searchUrl),
      jsLib: Value<String?>(source.jsLib),
      enabled: Value<bool>(source.enabled),
      enabledExplore: Value<bool>(source.enabledExplore),
      customOrder: Value<int>(source.customOrder),
      concurrentRate: Value<int?>(source.concurrentRate),
      lastTestAt: Value<DateTime?>(source.lastTestAt),
      lastTestOk: Value<bool?>(source.lastTestOk),
      lastError: Value<String?>(source.lastError),
      consecutiveFailures: Value<int>(source.consecutiveFailures),
      createdAt: Value<DateTime>(source.createdAt),
      updatedAt: Value<DateTime>(source.updatedAt),
      deletedAt: Value<DateTime?>(source.deletedAt),
    );
  }

  BookSource _toDomain(BookSourceRow row) {
    return BookSource(
      id: row.id,
      libraryRootId: row.libraryRootId,
      name: row.name,
      sourceUrl: row.sourceUrl,
      sourceType: row.sourceType,
      rawJson: row.rawJson,
      header: _decodeHeader(row.headerJson),
      groupName: row.groupName,
      exploreUrl: row.exploreUrl,
      searchUrl: row.searchUrl,
      jsLib: row.jsLib,
      enabled: row.enabled,
      enabledExplore: row.enabledExplore,
      customOrder: row.customOrder,
      concurrentRate: row.concurrentRate,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      lastTestAt: row.lastTestAt,
      lastTestOk: row.lastTestOk,
      lastError: row.lastError,
      consecutiveFailures: row.consecutiveFailures,
    );
  }
}

String _encodeHeader(Map<String, String> header) => jsonEncode(header);

Map<String, String> _decodeHeader(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const <String, String>{};
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const <String, String>{};
    }
    return <String, String>{
      for (final entry in decoded.entries)
        if (entry.key is String)
          entry.key as String: entry.value?.toString() ?? '',
    };
  } on FormatException {
    return const <String, String>{};
  }
}
