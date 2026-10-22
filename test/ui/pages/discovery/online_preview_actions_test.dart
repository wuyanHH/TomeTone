import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/online_book_service.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/online_providers.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/book_source_queries.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/pages/discovery/online_book_preview_page.dart';
import 'package:tometone/ui/pages/shelf/add_to_shelf_sheet.dart';
import 'package:tometone/ui/pages/shelf/book_detail_page.dart';

import '../sources/source_ui_test_support.dart';

void main() {
  testWidgets('加入书架弹层选分类并调用服务，随后替换为详情页', (tester) async {
    final db = openSourceTestDatabase();
    final source = await _source(db);
    final service = _FakeOnlineBookService();

    await pumpSourceUi(
      tester,
      db: db,
      discovery: const _PreviewDiscovery(),
      extra: <Override>[
        onlineBookServiceProvider.overrideWithValue(service),
        bookDetailProvider.overrideWith(
          (Ref ref, String id) async => _detail(),
        ),
      ],
      home: OnlineBookPreviewPage(source: source, item: _item),
    );

    expect(find.byKey(OnlineBookPreviewKeys.addToShelfKey), findsOneWidget);
    await tester.tap(find.byKey(OnlineBookPreviewKeys.addToShelfKey));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(AddToShelfKeys.newTagKey), '历史');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AddToShelfKeys.saveKey));
    await tester.pumpAndSettle();

    expect(service.addCalls, 1);
    expect(service.lastTags, <String>['历史']);
    expect(find.byType(BookDetailPage), findsOneWidget);
  });

  testWidgets('立即收听调用服务', (tester) async {
    final db = openSourceTestDatabase();
    final source = await _source(db);
    final service = _FakeOnlineBookService();

    await pumpSourceUi(
      tester,
      db: db,
      discovery: const _PreviewDiscovery(),
      extra: <Override>[
        onlineBookServiceProvider.overrideWithValue(service),
        bookDetailProvider.overrideWith((Ref ref, String id) async => null),
      ],
      home: OnlineBookPreviewPage(source: source, item: _item),
    );

    await tester.tap(find.byKey(OnlineBookPreviewKeys.listenKey));
    await tester.pumpAndSettle();

    expect(service.listenCalls, 1);
  });
}

const SourceBookSummary _item = SourceBookSummary(
  title: '摘要书名',
  bookUrl: 'https://e.test/book/1',
);

BookDetail _detail() {
  return const BookDetail(
    summary: BookSummary(
      id: 'book-1',
      title: '摘要书名',
      libraryRootId: 'root-1',
      rootPath: 'https://e.test/book/1',
      coverSource: CoverSource.typography,
      totalChapters: 1,
      totalDurationMs: 0,
      missingChapters: 0,
      sourceType: 'online',
      sourceId: 'source-1',
      onShelf: true,
    ),
    volumes: <VolumeView>[
      VolumeView(
        id: 'vol-1',
        title: '正文',
        volumeIndex: 0,
        chapters: <ChapterView>[
          ChapterView(
            id: 'ch-1',
            volumeId: 'vol-1',
            title: '第一章',
            chapterIndex: 0,
            filePath: 'online/ch-1',
            missing: false,
            sourceUri: 'https://e.test/play/1',
          ),
        ],
      ),
    ],
    preferences: PerBookPrefsSnapshot(),
  );
}

class _FakeOnlineBookService implements OnlineBookService {
  int addCalls = 0;
  int listenCalls = 0;
  List<String> lastTags = const <String>[];

  @override
  Future<String> addToShelf({
    required BookSource source,
    required SourceBookSummary item,
    SourceBookInfo? info,
    SourceToc? toc,
    required List<String> tags,
  }) async {
    addCalls++;
    lastTags = tags;
    return 'book-1';
  }

  @override
  Future<String> startListening({
    required BookSource source,
    required SourceBookSummary item,
    SourceBookInfo? info,
    SourceToc? toc,
  }) async {
    listenCalls++;
    return 'book-1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PreviewDiscovery implements SourceDiscovery {
  const _PreviewDiscovery();

  @override
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl) async {
    return const SourceBookInfo(
      title: '详情书名',
      bookUrl: 'https://e.test/book/1',
      tocUrl: 'https://e.test/toc',
    );
  }

  @override
  Future<SourceToc> toc(BookSource source, SourceBookInfo info) async {
    return const SourceToc(
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
  }

  @override
  Future<ResolvedAudio> resolveAudio(BookSource source, SourceChapter chapter) {
    throw UnimplementedError();
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

Future<BookSource> _source(TomeToneDatabase db) async {
  final id = await seedSource(db);
  return (await DriftBookSourceQueries(db).sourceById(id))!;
}
