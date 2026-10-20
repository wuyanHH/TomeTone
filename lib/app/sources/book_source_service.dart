import 'package:drift/drift.dart';

import '../../domain/common/id_generator.dart';
import '../../domain/library/database/tometone_database.dart';
import '../../domain/sources/book_source.dart';
import '../../domain/sources/book_source_queries.dart';
import '../../domain/sources/source_import.dart';

enum SourceImportStatus { imported, updated, skipped, invalid }

class SourceImportOutcome {
  const SourceImportOutcome({
    required this.status,
    this.sourceId,
    this.name,
    this.message,
  });

  final SourceImportStatus status;
  final String? sourceId;
  final String? name;
  final String? message;
}

class BookSourceListItem {
  const BookSourceListItem({required this.source, required this.bookCount});

  final BookSource source;
  final int bookCount;
}

/// 在线书源导入与管理编排。
///
/// 导入时每个源绑定一条 `library_roots.type = 'online'` 的虚拟根；删除源只
/// 软删除源记录，默认保留书目、进度与缓存。根的生命周期跟随源，但删除源时
/// 不删除根，便于复活。
class BookSourceService {
  BookSourceService({
    required this._database,
    required this._queries,
    required this._idGenerator,
    this._parser = const LegadoSourceImportParser(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final TomeToneDatabase _database;
  final BookSourceQueries _queries;
  final IdGenerator _idGenerator;
  final SourceImportParser _parser;
  final DateTime Function() _clock;

  Future<SourceImportParseResult> parse(String text) async =>
      _parser.parse(text);

  Future<List<SourceImportOutcome>> importText(
    String text, {
    bool overwrite = false,
  }) async {
    final result = await parse(text);
    if (result.candidates.isEmpty && result.issues.isEmpty) {
      return const <SourceImportOutcome>[];
    }

    var maxIndex = 0;
    for (final candidate in result.candidates) {
      if (candidate.index > maxIndex) {
        maxIndex = candidate.index;
      }
    }
    for (final issue in result.issues) {
      if (issue.index > maxIndex) {
        maxIndex = issue.index;
      }
    }

    final outcomes = List<SourceImportOutcome?>.filled(maxIndex + 1, null);
    for (final issue in result.issues) {
      outcomes[issue.index] = SourceImportOutcome(
        status: SourceImportStatus.invalid,
        message: issue.message,
      );
    }

    final candidates = <SourceImportCandidate>[...result.candidates]
      ..sort((a, b) => a.index.compareTo(b.index));
    for (final candidate in candidates) {
      outcomes[candidate.index] = await importCandidate(
        candidate,
        overwrite: overwrite,
      );
    }

    return <SourceImportOutcome>[for (final outcome in outcomes) ?outcome];
  }

  Future<SourceImportOutcome> importCandidate(
    SourceImportCandidate candidate, {
    bool overwrite = false,
  }) async {
    final draft = candidate.draft;
    final now = _now();
    final existing = await _queries.sourceByUrl(draft.sourceUrl);

    if (existing == null) {
      final rootId = _idGenerator.next();
      final sourceId = _idGenerator.next();
      final source = _newSource(
        id: sourceId,
        libraryRootId: rootId,
        draft: draft,
        now: now,
      );

      await _database.transaction(() async {
        await _database
            .into(_database.libraryRoots)
            .insert(
              LibraryRootsCompanion.insert(
                id: rootId,
                type: 'online',
                uri: draft.sourceUrl,
                displayName: draft.name,
                createdAt: now,
              ),
            );
        await _queries.insertSource(source);
      });

      return SourceImportOutcome(
        status: SourceImportStatus.imported,
        sourceId: sourceId,
        name: draft.name,
      );
    }

    if (existing.isDeleted) {
      final updated = existing.applyDraft(draft, updatedAt: now);
      await _database.transaction(() async {
        await _queries.updateSource(updated);
        await _queries.revive(existing.id, updatedAt: now);
        await _syncRootName(existing.libraryRootId, draft.name);
      });
      return SourceImportOutcome(
        status: SourceImportStatus.updated,
        sourceId: existing.id,
        name: draft.name,
      );
    }

    if (!overwrite) {
      return SourceImportOutcome(
        status: SourceImportStatus.skipped,
        sourceId: existing.id,
        name: existing.name,
      );
    }

    final updated = existing.applyDraft(draft, updatedAt: now);
    await _database.transaction(() async {
      await _queries.updateSource(updated);
      await _syncRootName(existing.libraryRootId, draft.name);
    });
    return SourceImportOutcome(
      status: SourceImportStatus.updated,
      sourceId: existing.id,
      name: draft.name,
    );
  }

  Future<List<BookSourceListItem>> listSources({
    bool includeDeleted = false,
  }) async {
    final sources = await _queries.listSources(includeDeleted: includeDeleted);
    final items = <BookSourceListItem>[];
    for (final source in sources) {
      items.add(
        BookSourceListItem(
          source: source,
          bookCount: await _queries.countBooks(source.id),
        ),
      );
    }
    return items;
  }

  Future<BookSource?> getSource(String id) => _queries.sourceById(id);

  Future<void> setEnabled(String id, bool enabled) {
    return _queries.setEnabled(id, enabled, updatedAt: _now());
  }

  Future<void> updateFromDraft(String id, BookSourceDraft draft) async {
    final existing = await _queries.sourceById(id);
    if (existing == null) {
      throw StateError('书源不存在：$id');
    }
    if (draft.sourceUrl != existing.sourceUrl) {
      throw ArgumentError.value(
        draft.sourceUrl,
        'draft.sourceUrl',
        '书源 URL 是身份，不能修改',
      );
    }

    final updated = existing.applyDraft(draft, updatedAt: _now());
    await _database.transaction(() async {
      await _queries.updateSource(updated);
      await _syncRootName(existing.libraryRootId, draft.name);
    });
  }

  Future<int> countBooks(String sourceId) => _queries.countBooks(sourceId);

  Future<void> deleteSource(String id, {bool deleteBooks = false}) {
    return _queries.softDelete(id, deleteBooks: deleteBooks, deletedAt: _now());
  }

  BookSource _newSource({
    required String id,
    required String libraryRootId,
    required BookSourceDraft draft,
    required DateTime now,
  }) {
    return BookSource(
      id: id,
      libraryRootId: libraryRootId,
      name: draft.name,
      sourceUrl: draft.sourceUrl,
      sourceType: draft.sourceType,
      rawJson: draft.rawJson,
      header: draft.header,
      groupName: draft.groupName,
      exploreUrl: draft.exploreUrl,
      searchUrl: draft.searchUrl,
      jsLib: draft.jsLib,
      enabled: draft.enabled,
      enabledExplore: draft.enabledExplore,
      customOrder: draft.customOrder,
      concurrentRate: draft.concurrentRate,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _syncRootName(String rootId, String displayName) async {
    final updated =
        await (_database.update(
          _database.libraryRoots,
        )..where((tbl) => tbl.id.equals(rootId))).write(
          LibraryRootsCompanion(displayName: Value<String>(displayName)),
        );
    if (updated == 0) {
      throw StateError('虚拟书库根不存在：$rootId');
    }
  }

  DateTime _now() => _clock().toUtc();
}
