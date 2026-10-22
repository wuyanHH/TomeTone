import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/batch_refresh_controller.dart';
import 'package:tometone/app/library/online_book_service.dart';
import 'package:tometone/app/playback/audio_preload_manager.dart';
import 'package:tometone/app/playback/online_chapter_source_resolver.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/contracts/network/network_monitor.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/contracts/sources/source_http.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/book_source_queries.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/modules/audio/audio_cache_repository_impl.dart';

class _FixtureDiscovery implements SourceDiscovery {
  final Map<String, SourceToc> tocsByUrl = {};
  bool tocShouldFail = false;

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) async {
    return SourceBookInfo(
      bookUrl: bookUrl,
      tocUrl: '$bookUrl/toc',
      title: '遮天全集',
      author: '辰东',
    );
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) async {
    if (tocShouldFail) {
      throw const SocketException('模拟网络超时');
    }
    final toc = tocsByUrl[info.bookUrl];
    if (toc != null) return toc;
    return const SourceToc(chapters: [], complete: true);
  }

  @override
  Future<ResolvedAudio> resolveAudio(BookSource source, SourceChapter chapter) async {
    return ResolvedAudio(
      url: 'http://audio.cdn.test/${chapter.url.hashCode}.mp3',
      headers: {'User-Agent': 'TomeTone/1.0'},
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNetworkMonitor implements NetworkMonitor {
  _FakeNetworkMonitor({this.isWifi = true});

  bool isWifi;

  @override
  Future<bool> get isWifiConnected async => isWifi;

  @override
  Stream<bool> get isWifiConnectedStream => Stream.value(isWifi);
}

class _FakeSourceHttpClient implements SourceHttpClient {
  @override
  Future<SourceHttpResponse> send(SourceHttpRequest request) async {
    return SourceHttpResponse(
      finalUrl: request.url,
      statusCode: 200,
      bytes: Uint8List.fromList(List<int>.filled(500, 42)),
      headers: const {},
    );
  }
}

void main() {
  late Directory tempDir;
  late TomeToneDatabase db;
  late DriftBookSourceQueries sourceQueries;
  late DriftOnlineLibraryQueries onlineQueries;
  late DriftLibraryQueries libraryQueries;
  late AudioCacheRepositoryImpl cacheRepo;
  late _FakeNetworkMonitor networkMonitor;
  late _FixtureDiscovery discovery;
  late OnlineBookService onlineBookService;
  late OnlineChapterSourceResolver chapterResolver;
  late AudioPreloadManager preloadManager;

  late BookSource sourceA;
  late BookSource sourceB;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tometone_m1d_fixture_');
    db = TomeToneDatabase(NativeDatabase.memory());
    sourceQueries = DriftBookSourceQueries(db);
    onlineQueries = DriftOnlineLibraryQueries(db, idGenerator: UlidIdGenerator());
    libraryQueries = DriftLibraryQueries(db);
    cacheRepo = AudioCacheRepositoryImpl(
      cacheRoot: tempDir,
    );
    networkMonitor = _FakeNetworkMonitor(isWifi: true);
    discovery = _FixtureDiscovery();

    onlineBookService = OnlineBookService(
      queries: onlineQueries,
      discovery: discovery,
      sourceQueries: sourceQueries,
      cacheRepository: cacheRepo,
    );

    chapterResolver = OnlineChapterSourceResolver(
      discovery: discovery,
      cacheRepository: cacheRepo,
    );

    preloadManager = AudioPreloadManager(
      networkMonitor: networkMonitor,
      cacheRepository: cacheRepo,
      discovery: discovery,
      httpClient: _FakeSourceHttpClient(),
      preloadCount: 2,
    );

    final now = DateTime.now().toUtc();

    // 建立源 A 与源 B 虚拟根与记录
    await db.into(db.libraryRoots).insert(
      LibraryRootsCompanion.insert(
        id: 'root_a',
        type: 'online',
        uri: 'online://src_a',
        displayName: '源 A',
        createdAt: now,
      ),
    );
    await db.into(db.libraryRoots).insert(
      LibraryRootsCompanion.insert(
        id: 'root_b',
        type: 'online',
        uri: 'online://src_b',
        displayName: '源 B',
        createdAt: now,
      ),
    );

    await db.into(db.bookSources).insert(
      BookSourcesCompanion.insert(
        id: 'src_a',
        libraryRootId: 'root_a',
        name: '听友源 A',
        sourceUrl: 'http://src-a.test',
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
        name: '听友源 B',
        sourceUrl: 'http://src-b.test',
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

    // 源 A 目录：5 个章节
    discovery.tocsByUrl['http://src-a.test/book/1'] = SourceToc(
      chapters: [
        for (var i = 1; i <= 5; i++)
          SourceChapter(
            index: i - 1,
            title: '第 $i 章 遮天第$i回',
            rawUrl: '/a/c$i',
            url: 'http://src-a.test/c$i',
            isVip: false,
          ),
      ],
      complete: true,
    );

    // 源 B 目录：6 个章节（带微小标题格式差异）
    discovery.tocsByUrl['http://src-b.test/book/2'] = SourceToc(
      chapters: [
        for (var i = 1; i <= 6; i++)
          SourceChapter(
            index: i - 1,
            title: '00$i 遮天第$i回',
            rawUrl: '/b/c$i',
            url: 'http://src-b.test/c$i',
            isVip: false,
          ),
      ],
      complete: true,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('M1-D E2E Full Lifecycle Sandbox Integration Verification', () async {
    // -------------------------------------------------------------------------
    // Step 1: 书目入库与首次收听
    // -------------------------------------------------------------------------
    final bookId = await onlineBookService.addToShelf(
      source: sourceA,
      item: const SourceBookSummary(
        bookUrl: 'http://src-a.test/book/1',
        title: '遮天全集',
        author: '辰东',
      ),
      toc: discovery.tocsByUrl['http://src-a.test/book/1'],
      tags: ['玄幻', '神作'],
    );

    final detail1 = await libraryQueries.bookDetail(bookId);
    expect(detail1, isNotNull);
    expect(detail1!.chapters, hasLength(5));

    final ch1 = detail1.chapters[0];
    final ch2 = detail1.chapters[1];

    // 初始化播放进度在第 1 章 10 秒
    await libraryQueries.saveProgress(
      bookId: bookId,
      chapterId: ch1.id,
      position: const Duration(seconds: 10),
    );

    // -------------------------------------------------------------------------
    // Step 2: 播放进度推进至 60% (>= 50%)，触发静默未来预下载
    // -------------------------------------------------------------------------
    await preloadManager.onPlaybackPositionUpdate(
      bookId: bookId,
      source: sourceA,
      currentChapterId: ch1.id,
      progress: 0.6,
      upcomingChapters: detail1.chapters,
    );

    // 重点验证：当前正在播放的第 1 章严禁进入预载，未来第 2 章已在沙盒缓存中就绪！
    final cachedCh1 = await cacheRepo.getCachedAudioFile(bookId, ch1.id);
    expect(cachedCh1, isNull);

    final cachedCh2 = await cacheRepo.getCachedAudioFile(bookId, ch2.id);
    expect(cachedCh2, isNotNull);

    // 播放器切换到第 2 章时，通过 resolver 验证命中 LocalFileSource 离线文件
    final resolvedCh2 = await chapterResolver.resolve(
      source: sourceA,
      bookId: bookId,
      chapter: ch2,
    );
    expect(resolvedCh2, isA<LocalFileSource>());

    // -------------------------------------------------------------------------
    // Step 3: 平滑换源（源 A -> 源 B），章节标题对齐，旧缓存清理
    // -------------------------------------------------------------------------
    // 设置当前播放进度在第 2 章
    await libraryQueries.saveProgress(
      bookId: bookId,
      chapterId: ch2.id,
      position: const Duration(seconds: 35),
    );

    final switchResult = await onlineBookService.switchSource(
      bookId: bookId,
      targetSourceId: sourceB.id,
      targetSource: sourceB,
      targetBookUrl: 'http://src-b.test/book/2',
      targetToc: discovery.tocsByUrl['http://src-b.test/book/2'],
    );

    expect(switchResult.isProgressMapped, isTrue);
    expect(switchResult.totalChapters, 6);

    // 验证换源后旧源的音频缓存已被清理
    final oldCachePostSwitch = await cacheRepo.getCachedAudioFile(bookId, ch2.id);
    expect(oldCachePostSwitch, isNull);

    // 验证源 A 的 5 个旧章节已进入 retired 状态
    final allChaptersPostSwitch = await (db.select(db.chapters)
          ..where((t) => t.bookId.equals(bookId)))
        .get();
    final retiredSrcA = allChaptersPostSwitch.where((c) => c.sourceUri?.contains('/a/') == true).toList();
    expect(retiredSrcA, hasLength(5));
    expect(retiredSrcA.every((c) => c.retired == true), isTrue);

    // 验证新源的第 2 章（002 遮天第2回）对齐成功
    final progressPostSwitch = await libraryQueries.bookDetail(bookId);
    expect(progressPostSwitch!.progress, isNotNull);
    final mappedCh = progressPostSwitch.chapters.firstWhere((c) => c.id == progressPostSwitch.progress!.chapterId);
    expect(mappedCh.title, '002 遮天第2回');

    // 验证 A -> B -> A 往返切换无唯一键冲突
    final switchBackResult = await onlineBookService.switchSource(
      bookId: bookId,
      targetSourceId: sourceA.id,
      targetSource: sourceA,
      targetBookUrl: 'http://src-a.test/book/1',
      targetToc: discovery.tocsByUrl['http://src-a.test/book/1'],
    );
    expect(switchBackResult.isProgressMapped, isTrue);
    expect(switchBackResult.totalChapters, 5);

    // -------------------------------------------------------------------------
    // Step 4: 部分刷新中途中断防丢保护 (Review Focus 2)
    // -------------------------------------------------------------------------
    // 模拟远端目录只抓到了第 1 章，complete == false
    discovery.tocsByUrl['http://src-a.test/book/1'] = const SourceToc(
      chapters: [
        SourceChapter(
          index: 0,
          title: '第 1 章 遮天第1回',
          rawUrl: '/a/c1',
          url: 'http://src-a.test/c1',
          isVip: false,
        ),
      ],
      complete: false,
      warnings: ['网络超时，第 2 页加载失败'],
    );

    final refreshResult = await onlineBookService.refreshBookToc(bookId, source: sourceA);
    expect(refreshResult.isComplete, isFalse);

    // 核心断言：虽然只返回了第 1 章，但因为 complete==false，绝不 retire 其余 4 章！
    final detailPostPartial = await libraryQueries.bookDetail(bookId);
    expect(detailPostPartial!.chapters, hasLength(5));
    expect(detailPostPartial.chapters.every((c) => !c.retired && !c.missing), isTrue);

    // -------------------------------------------------------------------------
    // Step 5: 全局批量刷新集成与控制器
    // -------------------------------------------------------------------------
    // 恢复正常全量目录
    discovery.tocsByUrl['http://src-a.test/book/1'] = SourceToc(
      chapters: [
        for (var i = 1; i <= 7; i++) // 远端更新了第 6、7 章
          SourceChapter(
            index: i - 1,
            title: '第 $i 章 遮天第$i回',
            rawUrl: '/a/c$i',
            url: 'http://src-a.test/c$i',
            isVip: false,
          ),
      ],
      complete: true,
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final batchController = container.read(batchRefreshControllerProvider.notifier);
    await batchController.startRefresh(
      queries: onlineQueries,
      service: onlineBookService,
    );

    final finalDetail = await libraryQueries.bookDetail(bookId);
    expect(finalDetail!.chapters, hasLength(7));

    // -------------------------------------------------------------------------
    // Step 6: 安全删除分级验证（移出书架 vs 彻底删除）
    // -------------------------------------------------------------------------
    // 1. 仅移出书架
    await onlineQueries.setBookShelf(bookId, onShelf: false);
    final offShelfBook = await (db.select(db.books)..where((t) => t.id.equals(bookId))).getSingle();
    expect(offShelfBook.onShelf, isFalse);
    expect(finalDetail.chapters, isNotEmpty); // 章节完好保留

    // 2. 彻底删除
    await libraryQueries.deleteBookRecord(bookId);
    final deletedBook = await (db.select(db.books)..where((t) => t.id.equals(bookId))).getSingleOrNull();
    expect(deletedBook, isNull);
    final remainingChapters = await (db.select(db.chapters)..where((t) => t.bookId.equals(bookId))).get();
    expect(remainingChapters, isEmpty); // 级联删除全部清理
  });
}
