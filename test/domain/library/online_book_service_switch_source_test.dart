import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/online_book_service.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/contracts/audio/audio_cache_repository.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/book_source_queries.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';

class _FakeDiscovery implements SourceDiscovery {
  final Map<String, SourceToc> tocsByUrl = {};

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) async {
    return SourceBookInfo(
      bookUrl: bookUrl,
      tocUrl: '$bookUrl/toc',
      title: 'Book Info Title',
    );
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) async {
    final toc = tocsByUrl[info.bookUrl];
    if (toc != null) return toc;
    return const SourceToc(chapters: [], complete: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCacheRepository implements AudioCacheRepository {
  final List<String> clearedBooks = [];

  @override
  Future<void> clearBookCache(String bookId) async {
    clearedBooks.add(bookId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late TomeToneDatabase db;
  late DriftOnlineLibraryQueries onlineQueries;
  late DriftLibraryQueries libraryQueries;
  late BookSourceQueries sourceQueries;
  late _FakeDiscovery discovery;
  late _FakeCacheRepository cacheRepo;
  late OnlineBookService service;

  late BookSource sourceA;
  late BookSource sourceB;
  late String bookId;

  setUp(() async {
    db = TomeToneDatabase(NativeDatabase.memory());
    onlineQueries = DriftOnlineLibraryQueries(db, idGenerator: UlidIdGenerator());
    libraryQueries = DriftLibraryQueries(db);
    sourceQueries = DriftBookSourceQueries(db);
    discovery = _FakeDiscovery();
    cacheRepo = _FakeCacheRepository();
    service = OnlineBookService(
      queries: onlineQueries,
      discovery: discovery,
      sourceQueries: sourceQueries,
      cacheRepository: cacheRepo,
    );

    final now = DateTime.now().toUtc();

    // 建立两个虚拟书库根和两个书源
    await db.into(db.libraryRoots).insert(
      LibraryRootsCompanion.insert(
        id: 'root_a',
        type: 'online',
        uri: 'online://legado_a',
        displayName: '源 A 书库根',
        createdAt: now,
      ),
    );
    await db.into(db.libraryRoots).insert(
      LibraryRootsCompanion.insert(
        id: 'root_b',
        type: 'online',
        uri: 'online://legado_b',
        displayName: '源 B 书库根',
        createdAt: now,
      ),
    );

    await db.into(db.bookSources).insert(
      BookSourcesCompanion.insert(
        id: 'src_a',
        libraryRootId: 'root_a',
        name: '书源 A',
        sourceUrl: 'http://source-a.test',
        sourceType: 1,
        rawJson: '{}',
        enabled: const Value(true),
        enabledExplore: const Value(true),
        customOrder: const Value(0),
        createdAt: now,
        updatedAt: now,
      ),
    );
    sourceA = (await sourceQueries.sourceById('src_a'))!;

    await db.into(db.bookSources).insert(
      BookSourcesCompanion.insert(
        id: 'src_b',
        libraryRootId: 'root_b',
        name: '书源 B',
        sourceUrl: 'http://source-b.test',
        sourceType: 1,
        rawJson: '{}',
        enabled: const Value(true),
        enabledExplore: const Value(true),
        customOrder: const Value(1),
        createdAt: now,
        updatedAt: now,
      ),
    );
    sourceB = (await sourceQueries.sourceById('src_b'))!;

    // 源 A 目录
    discovery.tocsByUrl['http://source-a.test/book/1'] = const SourceToc(
      chapters: [
        SourceChapter(
          index: 0,
          title: '第 1 章 初入江湖',
          rawUrl: '/a/c1',
          url: 'http://source-a.test/c1',
          isVip: false,
        ),
        SourceChapter(
          index: 1,
          title: '第 2 章 风起云涌',
          rawUrl: '/a/c2',
          url: 'http://source-a.test/c2',
          isVip: false,
        ),
      ],
      complete: true,
    );

    // 源 B 目录
    discovery.tocsByUrl['http://source-b.test/book/99'] = const SourceToc(
      chapters: [
        SourceChapter(
          index: 0,
          title: '001 初入江湖',
          rawUrl: '/b/c1',
          url: 'http://source-b.test/c1',
          isVip: false,
        ),
        SourceChapter(
          index: 1,
          title: '002 风起云涌',
          rawUrl: '/b/c2',
          url: 'http://source-b.test/c2',
          isVip: false,
        ),
        SourceChapter(
          index: 2,
          title: '003 峰回路转',
          rawUrl: '/b/c3',
          url: 'http://source-b.test/c3',
          isVip: false,
        ),
      ],
      complete: true,
    );

    // 初始化加入源 A
    bookId = await service.addToShelf(
      source: sourceA,
      item: const SourceBookSummary(
        bookUrl: 'http://source-a.test/book/1',
        title: '江湖恩仇录',
        author: '金大侠',
      ),
      toc: discovery.tocsByUrl['http://source-a.test/book/1'],
      tags: const ['武侠', '热血'],
    );

    // 设置用户手动覆盖和播放进度（在第 2 章）
    await libraryQueries.saveBookMetadata(
      bookId: bookId,
      metadata: const BookMetadataDraft(
        title: '我的自定武侠书',
        author: '金大侠（珍藏版）',
        tags: ['武侠', '热血'],
      ),
      manual: true,
    );

    final chA2 = await (db.select(db.chapters)
          ..where((t) => t.bookId.equals(bookId) & t.chapterIndex.equals(1)))
        .getSingle();

    await db.into(db.playbackProgress).insert(
      PlaybackProgressCompanion.insert(
        bookId: bookId,
        chapterId: chA2.id,
        positionMs: 35000,
        updatedAt: now,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('switchSource preserves bookId, tags, overrides, and aligns progress to matching new chapter by title', () async {
    final result = await service.switchSource(
      bookId: bookId,
      targetSourceId: 'src_b',
      targetSource: sourceB,
      targetBookUrl: 'http://source-b.test/book/99',
    );

    expect(result.isProgressMapped, isTrue);
    expect(result.totalChapters, 3);

    // 1. 验证元数据与覆盖保留
    final detail = await libraryQueries.bookDetail(bookId);
    expect(detail!.summary.title, '我的自定武侠书');
    expect(detail.summary.author, '金大侠（珍藏版）');
    expect(detail.summary.tags, containsAll(['武侠', '热血']));
    expect(detail.summary.sourceId, 'src_b');

    // 2. 验证源 A 的老章节已 retire
    final allChapters = await (db.select(db.chapters)..where((t) => t.bookId.equals(bookId))).get();
    final oldChapters = allChapters.where((c) => c.sourceUri?.contains('/a/') == true).toList();
    expect(oldChapters, hasLength(2));
    expect(oldChapters.every((c) => c.retired == true), isTrue);

    // 3. 验证源 B 的新章节已激活
    final newChapters = allChapters.where((c) => c.sourceUri?.contains('/b/') == true).toList();
    expect(newChapters, hasLength(3));
    expect(newChapters.every((c) => c.retired == false), isTrue);

    // 4. 验证进度已对齐至源 B 的第 2 章（002 风起云涌）
    final progress = await (db.select(db.playbackProgress)..where((t) => t.bookId.equals(bookId))).getSingle();
    final mappedChapter = newChapters.firstWhere((c) => c.title == '002 风起云涌');
    expect(progress.chapterId, mappedChapter.id);
    expect(progress.positionMs, 35000);

    // 5. 验证音频缓存被清理
    expect(cacheRepo.clearedBooks, contains(bookId));
  });

  test('Review Focus 1: A -> B -> A round-trip switch reactivates chapters without unique constraint failure', () async {
    // 第一次换源：A -> B
    await service.switchSource(
      bookId: bookId,
      targetSourceId: 'src_b',
      targetBookUrl: 'http://source-b.test/book/99',
    );

    // 第二次换源：B -> A (切回源 A)
    final result = await service.switchSource(
      bookId: bookId,
      targetSourceId: 'src_a',
      targetBookUrl: 'http://source-a.test/book/1',
    );

    expect(result.isProgressMapped, isTrue);
    expect(result.totalChapters, 2);

    final allChapters = await (db.select(db.chapters)..where((t) => t.bookId.equals(bookId))).get();
    final srcAChapters = allChapters.where((c) => c.sourceUri?.contains('/a/') == true).toList();
    final srcBChapters = allChapters.where((c) => c.sourceUri?.contains('/b/') == true).toList();

    // 源 A 章节重新激活，retired 为 false；源 B 章节变为 retired
    expect(srcAChapters.every((c) => c.retired == false), isTrue);
    expect(srcBChapters.every((c) => c.retired == true), isTrue);

    // 进度再次成功映射回源 A 的第 2 章
    final progress = await (db.select(db.playbackProgress)..where((t) => t.bookId.equals(bookId))).getSingle();
    final chA2 = srcAChapters.firstWhere((c) => c.chapterIndex == 1);
    expect(progress.chapterId, chA2.id);
  });

  test('Review Focus 3: When alignment fails, original progress is locked and preserved pointing to old chapter', () async {
    // 源 C：章节名称完全不同，序号也完全不同（例如合集或分卷差异，从第 100 章开始）
    await db.into(db.libraryRoots).insert(
      LibraryRootsCompanion.insert(
        id: 'root_c',
        type: 'online',
        uri: 'online://legado_c',
        displayName: '源 C 书库根',
        createdAt: DateTime.now().toUtc(),
      ),
    );
    await db.into(db.bookSources).insert(
      BookSourcesCompanion.insert(
        id: 'src_c',
        libraryRootId: 'root_c',
        name: '书源 C',
        sourceUrl: 'http://source-c.test',
        sourceType: 1,
        rawJson: '{}',
        enabled: const Value(true),
        enabledExplore: const Value(true),
        customOrder: const Value(2),
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    discovery.tocsByUrl['http://source-c.test/book/x'] = const SourceToc(
      chapters: [
        SourceChapter(
          index: 100,
          title: '番外篇 昔日往事',
          rawUrl: '/c/c100',
          url: 'http://source-c.test/c100',
          isVip: false,
        ),
      ],
      complete: true,
    );

    final progressBefore = await (db.select(db.playbackProgress)..where((t) => t.bookId.equals(bookId))).getSingle();

    final result = await service.switchSource(
      bookId: bookId,
      targetSourceId: 'src_c',
      targetBookUrl: 'http://source-c.test/book/x',
    );

    expect(result.isProgressMapped, isFalse);

    // 重点验证：未对齐成功时，底层 playback_progress 行完全保持原样，锁死原进度防覆盖！
    final progressAfter = await (db.select(db.playbackProgress)..where((t) => t.bookId.equals(bookId))).getSingle();
    expect(progressAfter.chapterId, progressBefore.chapterId);
    expect(progressAfter.positionMs, progressBefore.positionMs);
  });
}
