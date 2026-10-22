import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/online_book_service.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';

class _FakeDiscovery implements SourceDiscovery {
  SourceBookInfo? nextBookInfo;
  SourceToc? nextToc;
  bool tocError = false;

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) async {
    return nextBookInfo ??
        SourceBookInfo(
          bookUrl: bookUrl,
          tocUrl: '$bookUrl/toc',
          title: 'Remote Title',
          author: 'Remote Author',
          intro: 'Remote Intro',
          coverUrl: 'http://remote/cover.jpg',
        );
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) async {
    if (tocError) {
      throw Exception('网络连接中断');
    }
    return nextToc ??
        const SourceToc(
          chapters: <SourceChapter>[
            SourceChapter(
              index: 0,
              title: '第一章',
              rawUrl: '/c1',
              url: 'http://source.test/c1',
              isVip: false,
            ),
          ],
          complete: true,
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late TomeToneDatabase db;
  late DriftOnlineLibraryQueries onlineQueries;
  late DriftLibraryQueries libraryQueries;
  late _FakeDiscovery discovery;
  late OnlineBookService service;
  late BookSource source;
  late String bookId;

  setUp(() async {
    db = TomeToneDatabase(NativeDatabase.memory());
    onlineQueries = DriftOnlineLibraryQueries(db, idGenerator: UlidIdGenerator());
    libraryQueries = DriftLibraryQueries(db);
    discovery = _FakeDiscovery();
    service = OnlineBookService(queries: onlineQueries, discovery: discovery);

    // 建立测试基础数据
    await db.into(db.libraryRoots).insert(
      LibraryRootsCompanion.insert(
        id: 'root_test',
        type: 'online',
        uri: 'online://legado',
        displayName: 'Online Root',
        createdAt: DateTime.now().toUtc(),
      ),
    );

    await db.into(db.bookSources).insert(
      BookSourcesCompanion.insert(
        id: 'src_1',
        libraryRootId: 'root_test',
        name: '测试书源',
        sourceUrl: 'http://source.test',
        sourceType: 1,
        rawJson: '{}',
        enabled: const Value(true),
        enabledExplore: const Value(true),
        customOrder: const Value(0),
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    source = BookSource(
      id: 'src_1',
      libraryRootId: 'root_test',
      name: '测试书源',
      sourceUrl: 'http://source.test',
      sourceType: 1,
      rawJson: '{}',
      header: const {},
      enabled: true,
      enabledExplore: true,
      customOrder: 0,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    bookId = await service.addToShelf(
      source: source,
      item: const SourceBookSummary(
        bookUrl: 'http://source.test/book/1',
        title: '初始书名',
        author: '初始作者',
      ),
      toc: const SourceToc(
        chapters: <SourceChapter>[
          SourceChapter(
            index: 0,
            title: '第 1 章',
            rawUrl: '/c1',
            url: 'http://source.test/c1',
            isVip: false,
          ),
          SourceChapter(
            index: 1,
            title: '第 2 章',
            rawUrl: '/c2',
            url: 'http://source.test/c2',
            isVip: false,
          ),
        ],
        complete: true,
      ),
      tags: const <String>[],
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('refreshBookInfo updates remote metadata but preserves user overrides', () async {
    // 用户手动覆盖了书名和作者
    await libraryQueries.saveBookMetadata(
      bookId: bookId,
      metadata: const BookMetadataDraft(
        title: '我的手动书名',
        author: '我的手动作者',
      ),
      manual: true,
    );

    discovery.nextBookInfo = const SourceBookInfo(
      bookUrl: 'http://source.test/book/1',
      tocUrl: 'http://source.test/book/1/toc',
      title: '远端更新书名',
      author: '远端更新作者',
      intro: '远端更新简介',
      coverUrl: 'http://source.test/new_cover.jpg',
    );

    await service.refreshBookInfo(bookId, source: source);

    // 验证底层 books 表已写入最新远端元数据
    final rawBook = await (db.select(db.books)..where((t) => t.id.equals(bookId))).getSingle();
    expect(rawBook.title, '远端更新书名');
    expect(rawBook.author, '远端更新作者');
    expect(rawBook.description, '远端更新简介');
    expect(rawBook.coverUrl, 'http://source.test/new_cover.jpg');

    // 验证面向 UI 的查询视图依然保留用户的手动覆盖！
    final detail = await libraryQueries.bookDetail(bookId);
    expect(detail!.summary.title, '我的手动书名');
    expect(detail.summary.author, '我的手动作者');
  });

  test('refreshBookToc with complete==true retires disappearing chapters and adds new ones', () async {
    // 远端章节变更为：第 2 章、第 3 章（第 1 章下架消失，第 3 章新增）
    discovery.nextToc = const SourceToc(
      chapters: <SourceChapter>[
        SourceChapter(
          index: 0,
          title: '第 2 章（修正）',
          rawUrl: '/c2',
          url: 'http://source.test/c2',
          isVip: false,
        ),
        SourceChapter(
          index: 1,
          title: '第 3 章',
          rawUrl: '/c3',
          url: 'http://source.test/c3',
          isVip: false,
        ),
      ],
      complete: true,
    );

    final result = await service.refreshBookToc(bookId, source: source);

    expect(result.isComplete, isTrue);
    expect(result.newChaptersCount, 1); // 第 3 章

    final allChapters = await (db.select(db.chapters)..where((t) => t.bookId.equals(bookId))).get();
    expect(allChapters, hasLength(3));

    final ch1 = allChapters.firstWhere((c) => c.title == '第 1 章');
    expect(ch1.retired, isTrue);
    expect(ch1.missing, isTrue);

    final ch2 = allChapters.firstWhere((c) => c.title == '第 2 章（修正）');
    expect(ch2.retired, isFalse);
    expect(ch2.missing, isFalse);

    final ch3 = allChapters.firstWhere((c) => c.title == '第 3 章');
    expect(ch3.retired, isFalse);
    expect(ch3.missing, isFalse);
  });

  test('Review Focus 2: refreshBookToc with complete==false NEVER marks missing chapters retired/missing', () async {
    // 抓取到第 1 页中断：只拿到了第 1 章，complete == false
    discovery.nextToc = const SourceToc(
      chapters: <SourceChapter>[
        SourceChapter(
          index: 0,
          title: '第 1 章',
          rawUrl: '/c1',
          url: 'http://source.test/c1',
          isVip: false,
        ),
      ],
      complete: false,
      warnings: ['网络中断，仅获取第一页'],
    );

    final result = await service.refreshBookToc(bookId, source: source);

    expect(result.isComplete, isFalse);

    // 重点验证：虽然返回的列表中缺少了第 2 章，但因为 complete==false，第 2 章绝不能被 retired 或 missing！
    final allChapters = await (db.select(db.chapters)..where((t) => t.bookId.equals(bookId))).get();
    expect(allChapters, hasLength(2));

    final ch2 = allChapters.firstWhere((c) => c.title == '第 2 章');
    expect(ch2.retired, isFalse);
    expect(ch2.missing, isFalse);

    final rawBook = await (db.select(db.books)..where((t) => t.id.equals(bookId))).getSingle();
    expect(rawBook.lastRefreshOk, isFalse);
    expect(rawBook.lastRefreshError, isNotNull);
  });

  test('refreshBookToc on fetch error records failure and preserves all existing chapters', () async {
    discovery.tocError = true;

    final result = await service.refreshBookToc(bookId, source: source);
    expect(result.isComplete, isFalse);
    expect(result.error, isNotNull);

    final allChapters = await (db.select(db.chapters)..where((t) => t.bookId.equals(bookId))).get();
    expect(allChapters, hasLength(2));
    expect(allChapters.every((c) => !c.retired && !c.missing), isTrue);

    final rawBook = await (db.select(db.books)..where((t) => t.id.equals(bookId))).getSingle();
    expect(rawBook.lastRefreshOk, isFalse);
    expect(rawBook.lastRefreshError, contains('网络连接中断'));
  });
}
