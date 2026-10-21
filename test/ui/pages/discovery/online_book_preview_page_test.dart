import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/book_source_queries.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';
import 'package:tometone/domain/sources/discovery/source_failure.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/pages/discovery/online_book_preview_page.dart';
import 'package:tometone/ui/widgets/network_cover.dart';

import '../sources/source_ui_test_support.dart';

void main() {
  testWidgets('加载书信息与两页目录，且打开前后不写 books/chapters', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final source = (await DriftBookSourceQueries(db).sourceById(id))!;
    final fake = _FakeDiscovery(
      info: _info(title: '完整书名', intro: '一段简介', author: '作者甲', narrator: '演播乙'),
      toc: const SourceToc(
        complete: true,
        chapters: <SourceChapter>[
          SourceChapter(
            index: 0,
            title: '第一章',
            rawUrl: 'https://example.com/1',
            url: 'https://example.com/1',
            isVip: false,
          ),
          SourceChapter(
            index: 1,
            title: '第二章',
            rawUrl: 'https://example.com/2',
            url: 'https://example.com/2',
            isVip: true,
          ),
        ],
      ),
    );

    final beforeBooks = await db.select(db.books).get();
    final beforeChapters = await db.select(db.chapters).get();

    await pumpSourceUi(
      tester,
      db: db,
      discovery: fake,
      home: OnlineBookPreviewPage(source: source, item: _item()),
    );

    expect(find.byKey(OnlineBookPreviewKeys.previewNoticeKey), findsOneWidget);
    expect(find.text('预览模式 · 不会写入书库'), findsOneWidget);
    expect(find.text('完整书名'), findsOneWidget);
    expect(find.text('目录 · 2 章'), findsOneWidget);
    expect(find.text('第一章'), findsOneWidget);
    expect(find.text('第二章'), findsOneWidget);
    expect(find.byKey(OnlineBookPreviewKeys.chapterKey(0)), findsOneWidget);
    expect(find.byKey(OnlineBookPreviewKeys.chapterKey(1)), findsOneWidget);
    expect(find.text('加入书架'), findsOneWidget);
    expect(find.text('立即收听'), findsOneWidget);
    expect(find.byKey(NetworkCover.fallbackKey), findsOneWidget);

    final afterBooks = await db.select(db.books).get();
    final afterChapters = await db.select(db.chapters).get();
    expect(afterBooks.length, beforeBooks.length);
    expect(afterChapters.length, beforeChapters.length);
    expect(afterBooks, isEmpty);
    expect(afterChapters, isEmpty);
  });

  testWidgets('书信息失败时保留摘要并显示可读错误与重试', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final source = (await DriftBookSourceQueries(db).sourceById(id))!;
    final fake = _FakeDiscovery(
      infoFailure: const SourceFailure(
        kind: SourceFailureKind.network,
        stage: SourceStage.bookInfo,
        message: '网络不可用',
      ),
    );

    await pumpSourceUi(
      tester,
      db: db,
      discovery: fake,
      home: OnlineBookPreviewPage(source: source, item: _item()),
    );

    expect(find.text('摘要书名'), findsOneWidget);
    expect(find.text('网络不可用'), findsOneWidget);
    expect(find.byKey(OnlineBookPreviewKeys.errorKey), findsOneWidget);
    expect(find.byKey(OnlineBookPreviewKeys.retryKey), findsOneWidget);
    expect(find.byKey(OnlineBookPreviewKeys.tocListKey), findsNothing);
    expect(fake.tocCalls, 0);
  });

  testWidgets('目录失败时保留书信息并单独重试', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final source = (await DriftBookSourceQueries(db).sourceById(id))!;
    final fake = _FakeDiscovery(
      info: _info(title: '完整书名', intro: '一段简介'),
      tocFailure: const SourceFailure(
        kind: SourceFailureKind.timeout,
        stage: SourceStage.toc,
        message: '请求超时',
      ),
    );

    await pumpSourceUi(
      tester,
      db: db,
      discovery: fake,
      home: OnlineBookPreviewPage(source: source, item: _item()),
    );

    expect(find.text('完整书名'), findsOneWidget);
    expect(find.text('目录暂不可用 · 请求超时'), findsOneWidget);
    expect(find.byKey(OnlineBookPreviewKeys.tocRetryKey), findsOneWidget);
    expect(find.byKey(OnlineBookPreviewKeys.tocListKey), findsNothing);
  });

  testWidgets('目录不完整时显示部分抓取提示', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final source = (await DriftBookSourceQueries(db).sourceById(id))!;
    final fake = _FakeDiscovery(
      info: _info(title: '完整书名'),
      toc: const SourceToc(
        complete: false,
        chapters: <SourceChapter>[
          SourceChapter(
            index: 0,
            title: '第一章',
            rawUrl: 'https://example.com/1',
            url: 'https://example.com/1',
            isVip: false,
          ),
          SourceChapter(
            index: 1,
            title: '第二章',
            rawUrl: 'https://example.com/2',
            url: 'https://example.com/2',
            isVip: false,
          ),
        ],
      ),
    );

    await pumpSourceUi(
      tester,
      db: db,
      discovery: fake,
      home: OnlineBookPreviewPage(source: source, item: _item()),
    );

    expect(find.byKey(OnlineBookPreviewKeys.partialTocKey), findsOneWidget);
    expect(find.text('目录未完整抓取，共 2 章'), findsOneWidget);
  });

  testWidgets('320dp、大字体、深色下长书名与简介不溢出', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final source = (await DriftBookSourceQueries(db).sourceById(id))!;
    final fake = _FakeDiscovery(
      info: _info(
        title: '一个非常长的在线书名用于验证窄屏下的换行与截断行为',
        intro: List<String>.filled(30, '这是一段很长的简介内容。').join(),
        author: '一个名字很长的作者',
        narrator: '一个名字同样很长的演播者',
      ),
      toc: const SourceToc(
        complete: true,
        chapters: <SourceChapter>[
          SourceChapter(
            index: 0,
            title: '一个非常长的章节标题用于验证窄屏下的换行与截断行为',
            rawUrl: 'https://example.com/1',
            url: 'https://example.com/1',
            isVip: false,
          ),
        ],
      ),
    );

    await pumpSourceUi(
      tester,
      db: db,
      discovery: fake,
      home: OnlineBookPreviewPage(source: source, item: _item()),
      size: const Size(320, 700),
      textScale: 2,
      brightness: Brightness.dark,
    );

    expect(find.byKey(OnlineBookPreviewKeys.titleKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

SourceBookSummary _item() {
  return const SourceBookSummary(
    title: '摘要书名',
    bookUrl: 'https://example.com/book/1',
    author: '摘要作者',
    intro: '摘要简介',
  );
}

SourceBookInfo _info({
  required String title,
  String? intro,
  String? author,
  String? narrator,
  String? coverUrl,
}) {
  return SourceBookInfo(
    title: title,
    bookUrl: 'https://example.com/book/1',
    tocUrl: 'https://example.com/book/1/toc',
    author: author,
    narrator: narrator,
    intro: intro,
    coverUrl: coverUrl,
    kind: '有声书',
    wordCount: '12 万',
    status: '完结',
  );
}

class _FakeDiscovery implements SourceDiscovery {
  _FakeDiscovery({
    SourceBookInfo? info,
    this.infoFailure,
    SourceToc? toc,
    this.tocFailure,
  }) : infoResult = info,
       tocResult = toc;

  final SourceBookInfo? infoResult;
  final SourceFailure? infoFailure;
  final SourceToc? tocResult;
  final SourceFailure? tocFailure;
  int tocCalls = 0;

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) async {
    final SourceFailure? failure = infoFailure;
    if (failure != null) {
      throw failure;
    }
    return infoResult!;
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) async {
    tocCalls++;
    final SourceFailure? failure = tocFailure;
    if (failure != null) {
      throw failure;
    }
    return tocResult!;
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
  Future<ResolvedAudio> resolveAudio(BookSource source, SourceChapter chapter) {
    throw UnimplementedError('测试未配置音频解析');
  }

  @override
  Future<SourceTestReport> test(BookSource source) {
    throw UnimplementedError();
  }
}
