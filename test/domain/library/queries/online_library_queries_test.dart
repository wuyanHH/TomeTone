import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/common/id_generator.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';

void main() {
  late TomeToneDatabase db;
  late DriftOnlineLibraryQueries queries;

  setUp(() {
    db = TomeToneDatabase(NativeDatabase.memory());
    queries = DriftOnlineLibraryQueries(
      db,
      idGenerator: _SequenceIds(),
      clock: () => DateTime.utc(2026, 10, 21, 12),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('新书入库：书/卷/章/标签，章 URL 保留 options，file_path 用规范化哈希', () async {
    final source = await _seedSource(db);
    final id = await queries.upsertOnlineBook(
      OnlineBookUpsert(
        source: source,
        summary: const SourceBookSummary(
          title: '摘要书名',
          bookUrl: 'https://e.test/book/1',
        ),
        info: const SourceBookInfo(
          title: '详情书名',
          bookUrl: 'https://e.test/book/1',
          tocUrl: 'https://e.test/toc',
          author: '作者',
          narrator: '演播',
          coverUrl: 'https://img.test/1.jpg',
          intro: '简介',
          kind: '历史',
          wordCount: '10 万字',
          status: '完结',
          lastChapter: '第 2 章',
        ),
        toc: const SourceToc(
          complete: true,
          chapters: <SourceChapter>[
            SourceChapter(
              index: 0,
              title: '第一章',
              rawUrl: 'https://e.test/play/1,{"headers":{"X":"1"}}',
              url: 'https://e.test/play/1',
              isVip: true,
            ),
            SourceChapter(
              index: 1,
              title: '第二章',
              rawUrl: 'https://e.test/play/2',
              url: 'https://e.test/play/2',
              isVip: false,
            ),
          ],
        ),
        onShelf: true,
        tags: const <String>['历史', '在听'],
      ),
    );

    final book = await db.select(db.books).getSingle();
    expect(book.id, id);
    expect(book.sourceType, 'online');
    expect(book.sourceId, source.id);
    expect(book.libraryRootId, source.libraryRootId);
    expect(book.rootPath, 'https://e.test/book/1');
    expect(book.onShelf, isTrue);
    expect(book.title, '详情书名');
    expect(book.author, '作者');
    expect(book.narrator, '演播');
    expect(book.coverUrl, 'https://img.test/1.jpg');
    expect(book.description, '简介');
    expect(book.kind, '历史');
    expect(book.wordCount, '10 万字');
    expect(book.sourceStatus, '完结');
    expect(book.lastChapter, '第 2 章');
    expect(book.lastRefreshOk, isTrue);

    final volume = await db.select(db.volumes).getSingle();
    expect(volume.title, '正文');
    expect(volume.volumeIndex, 0);

    final chapters = await db.select(db.chapters).get();
    expect(chapters, hasLength(2));
    expect(chapters.first.sourceUri, contains(',{'));
    expect(chapters.first.isVip, isTrue);
    expect(chapters.first.filePath, startsWith('online/'));
    expect(chapters.first.filePath, isNot(contains(',')));
    expect(chapters.last.sourceUri, 'https://e.test/play/2');

    final tags = await db.select(db.bookTags).get();
    expect(tags.map((row) => row.tag).toSet(), <String>{'历史', '在听'});
  });

  test('重复入库复用 bookId，不重复卷/章/标签；再次上架更新 onShelf', () async {
    final source = await _seedSource(db);
    final first = await queries.upsertOnlineBook(
      OnlineBookUpsert(source: source, summary: _summary, toc: _toc),
    );
    final second = await queries.upsertOnlineBook(
      OnlineBookUpsert(
        source: source,
        summary: _summary,
        toc: _toc,
        onShelf: true,
        tags: const <String>['历史'],
      ),
    );

    expect(second, first);
    expect(await db.select(db.books).get(), hasLength(1));
    expect(await db.select(db.volumes).get(), hasLength(1));
    expect(await db.select(db.chapters).get(), hasLength(1));
    expect(await db.select(db.bookTags).get(), hasLength(1));
    final book = await db.select(db.books).getSingle();
    expect(book.onShelf, isTrue);
  });

  test('setBookShelf 只改上架与标签，不删书目', () async {
    final source = await _seedSource(db);
    final id = await queries.upsertOnlineBook(
      OnlineBookUpsert(source: source, summary: _summary, toc: _toc),
    );

    await queries.setBookShelf(id, onShelf: true, tags: const <String>['历史']);
    var book = await db.select(db.books).getSingle();
    expect(book.onShelf, isTrue);
    expect(await db.select(db.bookTags).get(), hasLength(1));

    await queries.setBookShelf(id, onShelf: false);
    book = await db.select(db.books).getSingle();
    expect(book.onShelf, isFalse);
    expect(await db.select(db.chapters).get(), hasLength(1));
  });

  test('bookStatuses 按规范化 bookUrl 返回 bookId/onShelf', () async {
    final source = await _seedSource(db);
    final id = await queries.upsertOnlineBook(
      OnlineBookUpsert(source: source, summary: _summary, toc: _toc),
    );

    final statuses = await queries.bookStatuses(
      sourceId: source.id,
      bookUrls: const <String>['https://e.test/book/1'],
    );
    expect(statuses['https://e.test/book/1']!.bookId, id);
    expect(statuses['https://e.test/book/1']!.onShelf, isFalse);
  });

  test('saveOnlineMetadata 只写覆盖层', () async {
    final source = await _seedSource(db);
    final id = await queries.upsertOnlineBook(
      OnlineBookUpsert(source: source, summary: _summary, toc: _toc),
    );

    await queries.saveOnlineMetadata(
      id,
      const BookMetadataDraft(title: '手填书名', tags: <String>['手填']),
    );

    final book = await db.select(db.books).getSingle();
    expect(book.title, '摘要书名');
    final override = await db.select(db.bookMetadataOverrides).getSingle();
    expect(override.title, '手填书名');
    expect(await db.select(db.bookTags).get(), hasLength(1));
  });
}

const SourceBookSummary _summary = SourceBookSummary(
  title: '摘要书名',
  bookUrl: 'https://e.test/book/1',
);

const SourceToc _toc = SourceToc(
  complete: true,
  chapters: <SourceChapter>[
    SourceChapter(
      index: 0,
      title: '第一章',
      rawUrl: 'https://e.test/play/1',
      url: 'https://e.test/play/1',
      isVip: false,
    ),
  ],
);

Future<BookSource> _seedSource(TomeToneDatabase db) async {
  final now = DateTime.utc(2026, 10, 21);
  await db
      .into(db.libraryRoots)
      .insert(
        LibraryRootsCompanion.insert(
          id: 'online-root',
          type: 'online',
          uri: 'https://e.test',
          displayName: '听友听书',
          createdAt: now,
        ),
      );
  await db
      .into(db.bookSources)
      .insert(
        BookSourcesCompanion.insert(
          id: 'source-1',
          libraryRootId: 'online-root',
          sourceUrl: 'https://e.test',
          name: '听友听书',
          sourceType: 1,
          rawJson: '{}',
          createdAt: now,
          updatedAt: now,
        ),
      );
  return BookSource(
    id: 'source-1',
    libraryRootId: 'online-root',
    name: '听友听书',
    sourceUrl: 'https://e.test',
    sourceType: 1,
    rawJson: '{}',
    header: const <String, String>{},
    enabled: true,
    enabledExplore: true,
    customOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
}

class _SequenceIds implements IdGenerator {
  int _next = 0;

  @override
  String next() {
    _next++;
    return 'id-$_next';
  }
}
