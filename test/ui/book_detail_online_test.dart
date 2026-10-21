import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/book_metadata_service.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/metadata_providers.dart';
import 'package:tometone/app/providers/online_providers.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/app/sources/book_source_service.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/ui/pages/shelf/book_detail_page.dart';
import 'package:tometone/ui/widgets/network_cover.dart';

import 'ui_test_harness.dart';

void main() {
  testWidgets('在线详情显示网络封面、来源状态、继续收听与移出书架', (tester) async {
    usePhoneViewport(tester);
    final source = _source();
    final queries = _FakeOnlineQueries();
    final detail = _detail(onShelf: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...testOverrides(controller: testController(FakePlaybackEngine())),
          bookDetailProvider.overrideWith((Ref ref, String id) async => detail),
          bookSourceByIdProvider.overrideWith((Ref ref, String id) async {
            return id == source.id ? source : null;
          }),
          onlineLibraryQueriesProvider.overrideWithValue(queries),
        ],
        child: const MaterialApp(home: BookDetailPage(bookId: 'book-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NetworkCover), findsOneWidget);
    expect(find.text('来源正常'), findsOneWidget);
    expect(find.text('开始收听'), findsOneWidget);
    expect(find.byKey(BookDetailKeys.removeShelfKey), findsOneWidget);

    await tester.tap(find.byKey(BookDetailKeys.removeShelfKey));
    await tester.pumpAndSettle();
    expect(queries.shelfCalls, isFalse);
  });

  testWidgets('未上架在线详情显示加入书架与立即收听', (tester) async {
    usePhoneViewport(tester);
    final source = _source();
    final detail = _detail(onShelf: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...testOverrides(controller: testController(FakePlaybackEngine())),
          bookDetailProvider.overrideWith((Ref ref, String id) async => detail),
          bookSourceByIdProvider.overrideWith((Ref ref, String id) async {
            return id == source.id ? source : null;
          }),
          onlineLibraryQueriesProvider.overrideWithValue(_FakeOnlineQueries()),
        ],
        child: const MaterialApp(home: BookDetailPage(bookId: 'book-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('加入书架'), findsOneWidget);
    expect(find.text('立即收听'), findsOneWidget);
    expect(find.byKey(BookDetailKeys.removeShelfKey), findsNothing);
  });

  testWidgets('章节目录 VIP 锁定，retired 章进入已下架分组', (tester) async {
    usePhoneViewport(tester);
    final source = _source();
    final detail = _detail(onShelf: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...testOverrides(controller: testController(FakePlaybackEngine())),
          bookDetailProvider.overrideWith((Ref ref, String id) async => detail),
          bookSourceByIdProvider.overrideWith((Ref ref, String id) async {
            return id == source.id ? source : null;
          }),
          onlineLibraryQueriesProvider.overrideWithValue(_FakeOnlineQueries()),
        ],
        child: const MaterialApp(home: BookDetailPage(bookId: 'book-1')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('章节目录'));
    await tester.pumpAndSettle();

    expect(find.text('已下架 1 章'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);
  });
}

class _FakeOnlineQueries implements OnlineLibraryQueries {
  bool? shelfCalls;

  @override
  Future<void> setBookShelf(
    String bookId, {
    required bool onShelf,
    List<String> tags = const <String>[],
  }) async {
    shelfCalls = onShelf;
  }

  @override
  Future<Map<String, OnlineBookStatus>> bookStatuses({
    required String sourceId,
    required List<String> bookUrls,
  }) async {
    return const <String, OnlineBookStatus>{};
  }

  @override
  Future<void> saveOnlineMetadata(
    String bookId,
    BookMetadataDraft metadata,
  ) async {}

  @override
  Future<String> upsertOnlineBook(OnlineBookUpsert upsert) async => 'book-1';
}

BookSource _source() {
  final now = DateTime.utc(2026);
  return BookSource(
    id: 'source-1',
    libraryRootId: 'root-1',
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

BookDetail _detail({required bool onShelf}) {
  return BookDetail(
    summary: BookSummary(
      id: 'book-1',
      title: '在线书',
      libraryRootId: 'root-1',
      rootPath: 'https://e.test/book/1',
      coverSource: CoverSource.typography,
      totalChapters: 2,
      totalDurationMs: 0,
      missingChapters: 0,
      sourceType: 'online',
      sourceId: 'source-1',
      sourceName: '听友听书',
      sourceEnabled: true,
      sourceDeleted: false,
      onShelf: onShelf,
    ),
    volumes: <VolumeView>[
      VolumeView(
        id: 'vol-1',
        title: '正文',
        volumeIndex: 0,
        chapters: <ChapterView>[
          const ChapterView(
            id: 'ch-1',
            volumeId: 'vol-1',
            title: '正常章',
            chapterIndex: 0,
            filePath: 'online/ch-1',
            missing: false,
            sourceUri: 'https://e.test/play/1',
          ),
          const ChapterView(
            id: 'ch-vip',
            volumeId: 'vol-1',
            title: 'VIP 章',
            chapterIndex: 1,
            filePath: 'online/ch-vip',
            missing: false,
            sourceUri: 'https://e.test/play/2',
            isVip: true,
          ),
          const ChapterView(
            id: 'ch-old',
            volumeId: 'vol-1',
            title: '旧章',
            chapterIndex: 2,
            filePath: 'online/ch-old',
            missing: false,
            sourceUri: 'https://e.test/play/3',
            retired: true,
          ),
        ],
      ),
    ],
    preferences: const PerBookPrefsSnapshot(),
  );
}
