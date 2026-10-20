import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/book_source_service.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/book_source_queries.dart';

const String _fixturePath = 'test/fixtures/sources/tingyou/source.json';

final DateTime _t0 = DateTime.utc(2026, 10, 20, 10);

String _fixtureText({String? name, String? sourceUrl}) {
  final map =
      jsonDecode(File(_fixturePath).readAsStringSync()) as Map<String, dynamic>;
  if (name != null) {
    map['bookSourceName'] = name;
  }
  if (sourceUrl != null) {
    map['bookSourceUrl'] = sourceUrl;
  }
  return jsonEncode(map);
}

BookSourceDraft _draftFrom(
  BookSourceRow row, {
  String? name,
  String? sourceUrl,
  String? groupName,
  Map<String, String> header = const <String, String>{},
  bool enabled = true,
  bool enabledExplore = true,
  int customOrder = 0,
  int? concurrentRate,
}) {
  return BookSourceDraft(
    name: name ?? row.name,
    sourceUrl: sourceUrl ?? row.sourceUrl,
    sourceType: row.sourceType,
    rawJson: row.rawJson,
    header: header,
    groupName: groupName,
    exploreUrl: row.exploreUrl,
    searchUrl: row.searchUrl,
    jsLib: row.jsLib,
    enabled: enabled,
    enabledExplore: enabledExplore,
    customOrder: customOrder,
    concurrentRate: concurrentRate,
  );
}

Future<void> _seedOnlineBook(
  TomeToneDatabase db, {
  required String sourceId,
  required String libraryRootId,
  bool onShelf = false,
}) async {
  await db
      .into(db.books)
      .insert(
        BooksCompanion.insert(
          id: 'book-1',
          libraryRootId: libraryRootId,
          title: '在线书',
          rootPath: 'online/book-1',
          sourceType: 'online',
          sourceUri: const Value<String?>('https://www.tingyou.fm/book/1'),
          onShelf: Value<bool>(onShelf),
          sourceId: Value<String?>(sourceId),
          createdAt: _t0,
          updatedAt: _t0,
        ),
      );
  await db
      .into(db.volumes)
      .insert(
        VolumesCompanion.insert(
          id: 'vol-1',
          bookId: 'book-1',
          title: '第一卷',
          volumeIndex: 0,
          path: '',
          updatedAt: _t0,
        ),
      );
  await db
      .into(db.chapters)
      .insert(
        ChaptersCompanion.insert(
          id: 'ch-1',
          bookId: 'book-1',
          volumeId: 'vol-1',
          libraryRootId: libraryRootId,
          title: '第一章',
          chapterIndex: 0,
          filePath: 'online/ch-1',
          updatedAt: _t0,
        ),
      );
  await db
      .into(db.playbackProgress)
      .insert(
        PlaybackProgressCompanion.insert(
          bookId: 'book-1',
          chapterId: 'ch-1',
          positionMs: 1000,
          updatedAt: _t0,
        ),
      );
}

void main() {
  late TomeToneDatabase db;
  late DriftBookSourceQueries queries;
  late BookSourceService service;
  late DateTime now;

  setUp(() {
    db = TomeToneDatabase(NativeDatabase.memory());
    queries = DriftBookSourceQueries(db);
    now = _t0;
    service = BookSourceService(
      database: db,
      queries: queries,
      idGenerator: UlidIdGenerator(random: Random(1), clock: () => now),
      clock: () => now,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> importFixture({String? name, bool overwrite = false}) async {
    final outcomes = await service.importText(
      _fixtureText(name: name),
      overwrite: overwrite,
    );
    expect(outcomes, hasLength(1));
    expect(outcomes.single.status, isNot(SourceImportStatus.invalid));
    return outcomes.single.sourceId!;
  }

  test('导入新源：创建在线虚拟根与 book_sources 行', () async {
    final outcomes = await service.importText(_fixtureText());

    expect(outcomes.single.status, SourceImportStatus.imported);
    expect(outcomes.single.name, '听友听书');
    final source = await db.select(db.bookSources).getSingle();
    final root = await db.select(db.libraryRoots).getSingle();

    expect(source.id, outcomes.single.sourceId);
    expect(source.sourceUrl, 'https://www.tingyou.fm/');
    expect(source.sourceType, 1);
    expect(source.headerJson, contains('test-session'));
    expect(source.createdAt.toUtc(), _t0);
    expect(source.updatedAt.toUtc(), _t0);

    expect(root.id, source.libraryRootId);
    expect(root.type, 'online');
    expect(root.uri, source.sourceUrl);
    expect(root.displayName, source.name);
    expect(root.lastScanAt, isNull);
  });

  test('同 URL 再导入且 overwrite=false：skipped 且不增加源', () async {
    final id = await importFixture();
    now = _t0.add(const Duration(minutes: 1));

    final outcomes = await service.importText(_fixtureText(name: '不应覆盖'));

    expect(outcomes.single.status, SourceImportStatus.skipped);
    expect(outcomes.single.sourceId, id);
    expect(await db.select(db.bookSources).get(), hasLength(1));
    final source = await db.select(db.bookSources).getSingle();
    expect(source.name, '听友听书');
    expect(source.updatedAt.toUtc(), _t0);
  });

  test('同 URL overwrite=true：保留 id / 根 / createdAt，更新名称与根名', () async {
    final id = await importFixture();
    final before = await db.select(db.bookSources).getSingle();
    now = _t0.add(const Duration(minutes: 1));

    final outcomes = await service.importText(
      _fixtureText(name: '新名称'),
      overwrite: true,
    );

    expect(outcomes.single.status, SourceImportStatus.updated);
    expect(outcomes.single.sourceId, id);
    final after = await db.select(db.bookSources).getSingle();
    final root = await db.select(db.libraryRoots).getSingle();
    expect(after.id, id);
    expect(after.libraryRootId, before.libraryRootId);
    expect(after.createdAt, before.createdAt);
    expect(after.name, '新名称');
    expect(after.updatedAt.toUtc(), now);
    expect(root.displayName, '新名称');
  });

  test('软删除后重新导入：同一 id 复活并更新字段', () async {
    final id = await importFixture();
    final before = await db.select(db.bookSources).getSingle();
    await service.deleteSource(id);
    expect((await db.select(db.bookSources).getSingle()).deletedAt, isNotNull);
    now = _t0.add(const Duration(minutes: 2));

    final outcomes = await service.importText(
      _fixtureText(name: '复活名称'),
      overwrite: false,
    );

    expect(outcomes.single.status, SourceImportStatus.updated);
    expect(outcomes.single.sourceId, id);
    final after = await db.select(db.bookSources).getSingle();
    expect(after.id, id);
    expect(after.libraryRootId, before.libraryRootId);
    expect(after.createdAt, before.createdAt);
    expect(after.name, '复活名称');
    expect(after.deletedAt, isNull);
    expect(after.updatedAt.toUtc(), now);
  });

  test('deleteSource 默认保留书目与进度', () async {
    final id = await importFixture();
    final source = await db.select(db.bookSources).getSingle();
    await _seedOnlineBook(
      db,
      sourceId: source.id,
      libraryRootId: source.libraryRootId,
    );

    await service.deleteSource(id);

    final after = await db.select(db.bookSources).getSingle();
    expect(after.deletedAt, isNotNull);
    expect(await db.select(db.books).get(), hasLength(1));
    expect(await db.select(db.chapters).get(), hasLength(1));
    expect(await db.select(db.playbackProgress).get(), hasLength(1));
  });

  test('deleteSource(deleteBooks: true) 删除书、章、进度', () async {
    final id = await importFixture();
    final source = await db.select(db.bookSources).getSingle();
    await _seedOnlineBook(
      db,
      sourceId: source.id,
      libraryRootId: source.libraryRootId,
    );

    await service.deleteSource(id, deleteBooks: true);

    expect((await db.select(db.bookSources).getSingle()).deletedAt, isNotNull);
    expect(await db.select(db.books).get(), isEmpty);
    expect(await db.select(db.chapters).get(), isEmpty);
    expect(await db.select(db.playbackProgress).get(), isEmpty);
  });

  test('setEnabled 更新 enabled', () async {
    final id = await importFixture();

    await service.setEnabled(id, false);

    final source = await db.select(db.bookSources).getSingle();
    expect(source.enabled, isFalse);
  });

  test('countBooks 包含未上架书', () async {
    final id = await importFixture();
    final source = await db.select(db.bookSources).getSingle();
    await _seedOnlineBook(
      db,
      sourceId: source.id,
      libraryRootId: source.libraryRootId,
      onShelf: false,
    );

    expect(await service.countBooks(id), 1);
    final list = await service.listSources();
    expect(list.single.bookCount, 1);
  });

  test('listSources 默认隐藏软删除源，includeDeleted 可见', () async {
    final id = await importFixture();
    await service.deleteSource(id);

    expect(await service.listSources(), isEmpty);
    expect(await service.listSources(includeDeleted: true), hasLength(1));
  });

  test('updateFromDraft 改 URL 抛 ArgumentError', () async {
    final id = await importFixture();
    final source = await db.select(db.bookSources).getSingle();
    final draft = _draftFrom(
      source,
      sourceUrl: 'https://other.example/source.json',
    );

    await expectLater(service.updateFromDraft(id, draft), throwsArgumentError);
  });

  test('updateFromDraft 覆盖字段、真正清空 null 并同步根名', () async {
    final id = await importFixture();
    final before = await db.select(db.bookSources).getSingle();
    now = _t0.add(const Duration(minutes: 3));
    final draft = _draftFrom(
      before,
      name: '改名',
      groupName: null,
      header: const <String, String>{'X-Test': '1'},
      enabled: false,
      enabledExplore: false,
      customOrder: 7,
      concurrentRate: 1500,
    );

    await service.updateFromDraft(id, draft);

    final after = await db.select(db.bookSources).getSingle();
    final root = await db.select(db.libraryRoots).getSingle();
    expect(after.id, id);
    expect(after.libraryRootId, before.libraryRootId);
    expect(after.createdAt, before.createdAt);
    expect(after.name, '改名');
    expect(after.groupName, isNull);
    expect(after.headerJson, '{"X-Test":"1"}');
    expect(after.enabled, isFalse);
    expect(after.enabledExplore, isFalse);
    expect(after.customOrder, 7);
    expect(after.concurrentRate, 1500);
    expect(after.updatedAt.toUtc(), now);
    expect(root.displayName, '改名');
  });

  test('importText 的 invalid outcome 与输入顺序一致', () async {
    final mixed =
        '['
        '{"bookSourceName":"坏源","bookSourceUrl":"https://bad.example/",'
        '"bookSourceType":0},'
        '${_fixtureText()}'
        ']';

    final outcomes = await service.importText(mixed);

    expect(outcomes, hasLength(2));
    expect(outcomes[0].status, SourceImportStatus.invalid);
    expect(outcomes[0].message, isNotEmpty);
    expect(outcomes[1].status, SourceImportStatus.imported);
  });
}
