import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/domain/library/queries/library_views.dart';

void main() {
  late TomeToneDatabase db;
  late DriftLibraryQueries queries;

  setUp(() {
    db = TomeToneDatabase(NativeDatabase.memory());
    queries = DriftLibraryQueries(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('在线书摘要投影来源字段，active/retired 章分离', () async {
    final now = DateTime.utc(2026, 10, 21);
    await db
        .into(db.libraryRoots)
        .insert(
          LibraryRootsCompanion.insert(
            id: 'online-root',
            type: 'online',
            uri: 'https://source.test',
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
            sourceUrl: 'https://source.test',
            name: '听友听书',
            sourceType: 1,
            rawJson: '{}',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            id: 'online-book',
            libraryRootId: 'online-root',
            title: '在线书名',
            rootPath: 'https://source.test/book/1',
            coverUrl: const Value<String?>('https://img.test/1.jpg'),
            description: const Value<String?>('简介'),
            kind: const Value<String?>('历史'),
            wordCount: const Value<String?>('10 万字'),
            lastChapter: const Value<String?>('第 2 章'),
            sourceType: 'online',
            sourceUri: const Value<String?>('https://source.test/book/1'),
            sourceId: const Value<String?>('source-1'),
            onShelf: const Value<bool>(false),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.volumes)
        .insert(
          VolumesCompanion.insert(
            id: 'online-vol',
            bookId: 'online-book',
            title: '正文',
            volumeIndex: 0,
            path: '',
            updatedAt: now,
          ),
        );
    await db
        .into(db.chapters)
        .insert(
          ChaptersCompanion.insert(
            id: 'ch-active',
            bookId: 'online-book',
            volumeId: 'online-vol',
            libraryRootId: 'online-root',
            title: '第一章',
            chapterIndex: 0,
            filePath: 'online/active',
            sourceUri: const Value<String?>(
              'https://source.test/play/1,{"headers":{"X":"1"}}',
            ),
            isVip: const Value<bool>(true),
            updatedAt: now,
          ),
        );
    await db
        .into(db.chapters)
        .insert(
          ChaptersCompanion.insert(
            id: 'ch-retired',
            bookId: 'online-book',
            volumeId: 'online-vol',
            libraryRootId: 'online-root',
            title: '旧章',
            chapterIndex: 1,
            filePath: 'online/retired',
            retired: const Value<bool>(true),
            updatedAt: now,
          ),
        );

    final all = await queries.listAllBooks();
    final BookSummary summary = all.single;
    expect(summary.isOnline, isTrue);
    expect(summary.onShelf, isFalse);
    expect(summary.sourceName, '听友听书');
    expect(summary.sourceEnabled, isTrue);
    expect(summary.sourceDeleted, isFalse);
    expect(summary.coverUrl, 'https://img.test/1.jpg');
    expect(summary.kind, '历史');
    expect(summary.wordCount, '10 万字');
    expect(summary.lastChapter, '第 2 章');

    final BookDetail detail = (await queries.bookDetail('online-book'))!;
    expect(detail.chapters.map((ChapterView chapter) => chapter.id), <String>[
      'ch-active',
    ]);
    expect(detail.chapters.single.isVip, isTrue);
    expect(detail.chapters.single.sourceUri, contains('X'));
    expect(
      detail.retiredChapters.map((ChapterView chapter) => chapter.id),
      <String>['ch-retired'],
    );
  });
}
