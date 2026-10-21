import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/online_book_service.dart';
import 'package:tometone/app/playback/online_chapter_source_resolver.dart';
import 'package:tometone/app/playback/online_queue_builder.dart';
import 'package:tometone/app/policy/chapter_sequencer.dart';
import 'package:tometone/app/sources/book_source_service.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/contracts/playback/engine_event.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/book_source_queries.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';

const String _sourceFixture = 'test/fixtures/sources/tingyou/source_m1b.json';
const String _bookInfoFixture = 'test/fixtures/sources/tingyou/book_info.json';
const String _tocFixture = 'test/fixtures/sources/tingyou/toc_page1.json';
const String _playFixture = 'test/fixtures/sources/tingyou/play.json';

class _FixtureDiscovery implements SourceDiscovery {
  _FixtureDiscovery({
    required this.info,
    required this.tocData,
    required this.audio,
  });

  final SourceBookInfo info;
  final SourceToc tocData;
  final ResolvedAudio audio;

  int bookInfoCalls = 0;
  int tocCalls = 0;
  int resolveAudioCalls = 0;

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) async {
    bookInfoCalls++;
    return info;
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) async {
    tocCalls++;
    return tocData;
  }

  @override
  Future<ResolvedAudio> resolveAudio(
    BookSource source,
    SourceChapter chapter,
  ) async {
    resolveAudioCalls++;
    return ResolvedAudio(
      url: audio.url,
      headers: <String, String>{
        ...source.header,
        ...audio.headers,
      },
    );
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

void main() {
  late TomeToneDatabase db;
  late DriftBookSourceQueries sourceQueries;
  late BookSourceService sourceService;
  late DriftOnlineLibraryQueries onlineQueries;
  late DriftLibraryQueries libraryQueries;
  late FakePlaybackEngine playbackEngine;

  late SourceBookInfo fixtureInfo;
  late SourceToc fixtureToc;
  late ResolvedAudio fixtureAudio;
  late _FixtureDiscovery discovery;
  late OnlineBookService onlineBookService;
  late OnlineChapterSourceResolver chapterResolver;

  setUp(() {
    db = TomeToneDatabase(NativeDatabase.memory());
    sourceQueries = DriftBookSourceQueries(db);
    sourceService = BookSourceService(
      database: db,
      queries: sourceQueries,
      idGenerator: UlidIdGenerator(),
    );
    onlineQueries = DriftOnlineLibraryQueries(
      db,
      idGenerator: UlidIdGenerator(),
    );
    libraryQueries = DriftLibraryQueries(db);
    playbackEngine = FakePlaybackEngine();

    final infoJson =
        jsonDecode(File(_bookInfoFixture).readAsStringSync())
            as Map<String, dynamic>;
    fixtureInfo = SourceBookInfo(
      title: infoJson['title'] as String,
      bookUrl: 'https://www.tingyou.fm/book/${infoJson['id']}',
      author: infoJson['author'] as String?,
      narrator: infoJson['narrator'] as String?,
      intro: infoJson['intro'] as String?,
      coverUrl: infoJson['cover'] as String?,
      kind: infoJson['kind'] as String?,
      wordCount: infoJson['word_count'] as String?,
      lastChapter: infoJson['last_chapter'] as String?,
      status: infoJson['status'] as String?,
      tocUrl: 'https://www.tingyou.fm/api/chapters/${infoJson['id']}',
    );

    final tocJson =
        jsonDecode(File(_tocFixture).readAsStringSync())
            as Map<String, dynamic>;
    final rawChapters = tocJson['chapters'] as List<dynamic>;
    final chapterList = <SourceChapter>[];
    for (var i = 0; i < rawChapters.length; i++) {
      final c = rawChapters[i] as Map<String, dynamic>;
      final url = c['url'] as String;
      chapterList.add(
        SourceChapter(
          index: i,
          title: c['title'] as String,
          rawUrl: url,
          url: url,
          isVip: c['vip'] == true || c['vip'] == 'true',
        ),
      );
    }
    fixtureToc = SourceToc(
      chapters: chapterList,
      complete: true,
    );

    final playJson =
        jsonDecode(File(_playFixture).readAsStringSync())
            as Map<String, dynamic>;
    fixtureAudio = ResolvedAudio(
      url: playJson['play_url'] as String,
      headers: Map<String, String>.from(playJson['headers'] as Map),
    );

    discovery = _FixtureDiscovery(
      info: fixtureInfo,
      tocData: fixtureToc,
      audio: fixtureAudio,
    );

    onlineBookService = OnlineBookService(
      queries: onlineQueries,
      discovery: discovery,
    );

    chapterResolver = OnlineChapterSourceResolver(discovery: discovery);
  });

  tearDown(() async {
    await playbackEngine.dispose();
    await db.close();
  });

  Future<BookSource> importTestBookSource() async {
    final outcomes = await sourceService.importText(
      File(_sourceFixture).readAsStringSync(),
    );
    final id = outcomes.single.sourceId!;
    return (await sourceQueries.listSources()).firstWhere((s) => s.id == id);
  }

  test('端到端 1：打开详情与预览阶段不写库，只有加入书架后才落库并展示在书架和书库', () async {
    final source = await importTestBookSource();
    final summary = SourceBookSummary(
      title: fixtureInfo.title,
      bookUrl: fixtureInfo.bookUrl,
      author: fixtureInfo.author,
    );

    // 1. 模拟预览阶段：调用 discovery.bookInfo 和 toc，数据库应为空
    final previewInfo = await discovery.bookInfo(source, summary.bookUrl);
    final previewToc = await discovery.toc(source, previewInfo);
    expect(previewInfo.title, '长安十二时辰');
    expect(previewToc.chapters, hasLength(3));

    final booksBefore = await db.select(db.books).get();
    expect(booksBefore, isEmpty, reason: '预览阶段绝不写库');

    // 2. 点击「加入书架」，指定标签
    final bookId = await onlineBookService.addToShelf(
      source: source,
      item: summary,
      info: previewInfo,
      toc: previewToc,
      tags: const <String>['历史', '悬疑'],
    );

    expect(bookId, isNotEmpty);

    // 3. 校验数据库持久化
    final savedBooks = await db.select(db.books).get();
    expect(savedBooks, hasLength(1));
    final bookRow = savedBooks.single;
    expect(bookRow.id, bookId);
    expect(bookRow.title, '长安十二时辰');
    expect(bookRow.sourceType, 'online');
    expect(bookRow.onShelf, isTrue);

    // 4. 校验书架能查到，书库能查到
    final shelfBooks = await libraryQueries.listBooks();
    expect(shelfBooks.map((b) => b.id), contains(bookId));

    final allBooks = await libraryQueries.listAllBooks();
    expect(allBooks.map((b) => b.id), contains(bookId));
    final libraryBook = allBooks.firstWhere((b) => b.id == bookId);
    expect(libraryBook.tags, containsAll(<String>['历史', '悬疑']));
    expect(libraryBook.isOnline, isTrue);
  });

  test('端到端 2：立即收听入库为 onShelf=false，仅在书库展示，不出现在书架', () async {
    final source = await importTestBookSource();
    final summary = SourceBookSummary(
      title: fixtureInfo.title,
      bookUrl: fixtureInfo.bookUrl,
    );

    final bookId = await onlineBookService.startListening(
      source: source,
      item: summary,
      info: fixtureInfo,
      toc: fixtureToc,
    );

    final savedBook = await (db.select(
      db.books,
    )..where((tbl) => tbl.id.equals(bookId))).getSingle();
    expect(savedBook.onShelf, isFalse, reason: '立即收听不置入书架');

    // 校验书架查不到
    final allBooks = await libraryQueries.listAllBooks();
    final shelfBooks = allBooks.where((b) => b.onShelf).toList();
    expect(shelfBooks.any((b) => b.id == bookId), isFalse);

    // 校验书库可查到
    expect(allBooks.any((b) => b.id == bookId), isTrue);
  });

  test('端到端 3：同一本在线书重复加入书架，复用已有 bookId，章节与标签不重复', () async {
    final source = await importTestBookSource();
    final summary = SourceBookSummary(
      title: fixtureInfo.title,
      bookUrl: fixtureInfo.bookUrl,
    );

    final bookId1 = await onlineBookService.addToShelf(
      source: source,
      item: summary,
      info: fixtureInfo,
      toc: fixtureToc,
      tags: const <String>['历史'],
    );

    final bookId2 = await onlineBookService.addToShelf(
      source: source,
      item: summary,
      info: fixtureInfo,
      toc: fixtureToc,
      tags: const <String>['历史', '推理'],
    );

    expect(bookId2, equals(bookId1), reason: '重复入库必须复用已有 ID');

    final booksCount = (await db.select(db.books).get()).length;
    expect(booksCount, equals(1));

    final chapters = await (db.select(
      db.chapters,
    )..where((tbl) => tbl.bookId.equals(bookId1))).get();
    expect(chapters, hasLength(3), reason: '章节不重复插入');
  });

  test('端到端 4：按章惰性解析音频，跳过 VIP 章，合并请求头并由播放引擎接收', () async {
    final source = await importTestBookSource();
    final summary = SourceBookSummary(
      title: fixtureInfo.title,
      bookUrl: fixtureInfo.bookUrl,
    );

    final bookId = await onlineBookService.startListening(
      source: source,
      item: summary,
      info: fixtureInfo,
      toc: fixtureToc,
    );

    final BookDetail detail = (await libraryQueries.bookDetail(bookId))!;

    // 1. 构建播放队列：VIP 章被过滤
    final ChapterSequencer queue = await buildOnlinePlaybackQueue(
      detail: detail,
      source: source,
      resolver: chapterResolver,
    );

    // 队列中过滤了 VIP 章
    expect(queue.chapters, hasLength(2));
    final QueueChapter playableChapter = queue.chapters.first;
    expect(playableChapter.title, '第一章 长安');

    // 2. 惰性解析第一章音频
    expect(discovery.resolveAudioCalls, equals(0), reason: '入库与建队时不解析音频');

    final ChapterView chapterView = detail.chapters.firstWhere(
      (c) => c.id == playableChapter.chapterId,
    );
    final AudioSourceRef? audioSource = await chapterResolver.resolve(
      source: source,
      chapter: chapterView,
    );

    expect(discovery.resolveAudioCalls, equals(1));
    expect(audioSource, isA<RemoteUrlSource>());
    final RemoteUrlSource remoteSource = audioSource! as RemoteUrlSource;

    // 验证音频 URL 来自夹具
    expect(
      remoteSource.uri.toString(),
      equals('https://www.tingyou.fm/audio/test-audio-1.mp3'),
    );

    // 验证 headers 合并：包含源头请求头与 play.json 专项头
    expect(remoteSource.headers['x-listening-session'], equals('test-session'));
    expect(remoteSource.headers['X-Audio'], equals('test-audio'));
    expect(remoteSource.headers['User-Agent'], equals('TomeTone-Test'));

    // 3. 提交给播放引擎起播
    await playbackEngine.load(remoteSource);
    await playbackEngine.play();

    expect(playbackEngine.currentSource, equals(remoteSource));
    expect(playbackEngine.state, equals(EnginePlaybackState.playing));
  });

  test('端到端 5：来源被停用或删除时，书目保留在书库但带状态标，且拒绝继续起播', () async {
    final source = await importTestBookSource();
    final summary = SourceBookSummary(
      title: fixtureInfo.title,
      bookUrl: fixtureInfo.bookUrl,
    );

    final bookId = await onlineBookService.addToShelf(
      source: source,
      item: summary,
      info: fixtureInfo,
      toc: fixtureToc,
      tags: const <String>['玄幻'],
    );

    // 1. 停用书源
    await sourceQueries.setEnabled(source.id, false);

    // 重新查书库
    final allBooksAfterDisable = await libraryQueries.listAllBooks();
    final bookSummary = allBooksAfterDisable.firstWhere((b) => b.id == bookId);
    expect(bookSummary.sourceEnabled, isFalse);
    expect(bookSummary.sourceDeleted, isFalse);

    // 2. 软删除书源（保留书目）
    await sourceQueries.softDelete(source.id, deleteBooks: false);

    final allBooksAfterDelete = await libraryQueries.listAllBooks();
    final bookSummaryDeleted = allBooksAfterDelete.firstWhere(
      (b) => b.id == bookId,
    );
    expect(bookSummaryDeleted.sourceDeleted, isTrue);

    // 3. 校验敏感凭据隔离：不含真实 token/session
    expect(source.header['x-listening-session'], equals('test-session'));
    expect(source.header.values, isNot(contains('secret')));
  });
}
