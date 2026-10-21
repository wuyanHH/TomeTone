import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/online_book_service.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';

void main() {
  late TomeToneDatabase db;
  late DriftOnlineLibraryQueries queries;
  late _FakeDiscovery discovery;
  late OnlineBookService service;
  late BookSource source;

  setUp(() async {
    db = TomeToneDatabase(NativeDatabase.memory());
    queries = DriftOnlineLibraryQueries(db, idGenerator: UlidIdGenerator());
    discovery = _FakeDiscovery();
    service = OnlineBookService(queries: queries, discovery: discovery);
    source = await _seedSource(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('预览数据齐全时直接入库，不再请求详情/目录', () async {
    final id = await service.addToShelf(
      source: source,
      item: _summary,
      info: _info,
      toc: _toc,
      tags: const <String>['历史'],
    );

    expect(id, isNotEmpty);
    expect(discovery.bookInfoCalls, 0);
    expect(discovery.tocCalls, 0);
    expect(await db.select(db.books).get(), hasLength(1));
    expect(await db.select(db.bookTags).get(), hasLength(1));
  });

  test('缺详情/目录时补抓；目录失败仍允许加入，但标记待刷新', () async {
    discovery.tocError = true;
    final id = await service.addToShelf(
      source: source,
      item: _summary,
      tags: const <String>[],
    );

    expect(discovery.bookInfoCalls, 1);
    expect(discovery.tocCalls, 1);
    final book = await db.select(db.books).getSingle();
    expect(book.id, id);
    expect(book.lastRefreshOk, isFalse);
    expect(await db.select(db.chapters).get(), isEmpty);
  });

  test('立即收听目录仍失败：抛错且不写库', () async {
    discovery.tocError = true;

    await expectLater(
      service.startListening(source: source, item: _summary),
      throwsA(isA<OnlineBookNotPlayable>()),
    );
    expect(await db.select(db.books).get(), isEmpty);
  });

  test('重复立即收听复用同一 bookId', () async {
    final first = await service.startListening(
      source: source,
      item: _summary,
      info: _info,
      toc: _toc,
    );
    final second = await service.startListening(
      source: source,
      item: _summary,
      info: _info,
      toc: _toc,
    );

    expect(second, first);
    expect(await db.select(db.books).get(), hasLength(1));
  });
}

const SourceBookSummary _summary = SourceBookSummary(
  title: '摘要书名',
  bookUrl: 'https://e.test/book/1',
);

const SourceBookInfo _info = SourceBookInfo(
  title: '详情书名',
  bookUrl: 'https://e.test/book/1',
  tocUrl: 'https://e.test/toc',
  author: '作者',
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

class _FakeDiscovery implements SourceDiscovery {
  bool tocError = false;
  int bookInfoCalls = 0;
  int tocCalls = 0;

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) async {
    bookInfoCalls++;
    return _info;
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) async {
    tocCalls++;
    if (tocError) {
      throw StateError('toc failed');
    }
    return _toc;
  }

  @override
  Future<SourcePage<SourceBookSummary>> explore(
    BookSource source,
    ExploreCategory category,
    int page,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<SourcePage<SourceBookSummary>> search(
    BookSource source,
    String keyword,
    int page,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<SourceTestReport> test(BookSource source) {
    throw UnimplementedError();
  }
}

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
