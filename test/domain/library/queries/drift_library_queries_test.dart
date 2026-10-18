import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/domain/library/queries/library_views.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 18, 3);
final DateTime _t1 = _t0.add(const Duration(hours: 1));

void main() {
  late TomeToneDatabase db;
  late LibraryQueries queries;

  setUp(() {
    db = TomeToneDatabase(NativeDatabase.memory());
    queries = DriftLibraryQueries(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed() async {
    await db
        .into(db.libraryRoots)
        .insert(
          LibraryRootsCompanion.insert(
            id: 'root-1',
            type: 'local',
            uri: '/books',
            displayName: '内部存储',
            createdAt: _t0,
          ),
        );

    Future<void> book(
      String id,
      String title,
      DateTime updatedAt, {
      String? coverPath,
      CoverSource coverSource = CoverSource.typography,
    }) async {
      await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              id: id,
              libraryRootId: 'root-1',
              title: title,
              rootPath: title,
              sourceType: 'local',
              coverPath: Value<String?>(coverPath),
              coverSourceType: Value<CoverSource>(coverSource),
              totalChapters: const Value<int>(2),
              totalDurationMs: const Value<int>(600000),
              createdAt: _t0,
              updatedAt: updatedAt,
            ),
          );
    }

    await book('book-a', '三体', _t0);
    await book(
      'book-b',
      '球状闪电',
      _t1,
      coverPath: '球状闪电/cover.jpg',
      coverSource: CoverSource.bookRoot,
    );

    await db
        .into(db.volumes)
        .insert(
          VolumesCompanion.insert(
            id: 'vol-1',
            bookId: 'book-a',
            title: '第一卷',
            volumeIndex: 0,
            path: '',
            updatedAt: _t0,
          ),
        );
    await db
        .into(db.volumes)
        .insert(
          VolumesCompanion.insert(
            id: 'vol-2',
            bookId: 'book-a',
            title: '第二卷',
            volumeIndex: 1,
            path: '卷二',
            coverPath: const Value<String?>('三体/卷二/cover.png'),
            updatedAt: _t0,
          ),
        );

    ChaptersCompanion chapter(
      String id,
      String volumeId,
      int index, {
      bool missing = false,
      int? durationMs = 300000,
    }) {
      return ChaptersCompanion.insert(
        id: id,
        bookId: 'book-a',
        volumeId: volumeId,
        libraryRootId: 'root-1',
        title: '第 $index 章',
        chapterIndex: index,
        filePath: '三体/$id.mp3',
        durationMs: Value<int?>(durationMs),
        missing: Value<bool>(missing),
        updatedAt: _t0,
      );
    }

    await db.into(db.chapters).insert(chapter('ch-0', 'vol-1', 0));
    await db
        .into(db.chapters)
        .insert(chapter('ch-1', 'vol-1', 1, missing: true));
    await db.into(db.chapters).insert(chapter('ch-2', 'vol-2', 2));
  }

  group('listBooks', () {
    test('按最近收听 / 最近加入倒序，并带出封面与缺失计数', () async {
      await seed();

      final books = await queries.listBooks();
      expect(books.map((BookSummary b) => b.id).toList(), <String>[
        'book-b',
        'book-a',
      ], reason: 'book-b 的 updatedAt 更晚');

      final sci = books.first;
      expect(sci.title, '球状闪电');
      expect(sci.coverPath, '球状闪电/cover.jpg');
      expect(sci.coverSource, CoverSource.bookRoot);
      expect(sci.hasProgress, isFalse);

      final threeBody = books.last;
      expect(threeBody.coverSource, CoverSource.typography);
      expect(threeBody.missingChapters, 1);
      expect(threeBody.totalChapters, 2);
    });

    test('有进度的书排到最前，并带出进度章标题', () async {
      await seed();
      await queries.saveProgress(
        bookId: 'book-a',
        chapterId: 'ch-0',
        position: const Duration(seconds: 42),
        updatedAt: _t1.add(const Duration(hours: 1)),
      );

      final books = await queries.listBooks();
      expect(books.first.id, 'book-a');
      expect(books.first.progressPositionMs, 42000);
      expect(books.first.progressChapterTitle, '第 0 章');
      expect(books.first.lastListenedAt, isNotNull);
    });

    test('按书库根筛选', () async {
      await seed();
      expect(await queries.listBooks(libraryRootId: 'root-1'), hasLength(2));
      expect(await queries.listBooks(libraryRootId: 'root-x'), isEmpty);
    });

    test('分页', () async {
      await seed();
      final firstPage = await queries.listBooks(limit: 1);
      expect(firstPage, hasLength(1));

      final secondPage = await queries.listBooks(limit: 1, offset: 1);
      expect(secondPage, hasLength(1));
      expect(secondPage.single.id, isNot(firstPage.single.id));
    });
  });

  group('bookDetail', () {
    test('返回卷 / 章（有序）、偏好与进度', () async {
      await seed();
      await queries.saveProgress(
        bookId: 'book-a',
        chapterId: 'ch-0',
        position: const Duration(seconds: 30),
      );
      await queries.savePreferences(
        'book-a',
        const PerBookPrefsSnapshot(
          speed: 1.5,
          skipIntro: Duration(seconds: 4),
          skipOutro: Duration(seconds: 6),
        ),
      );

      final detail = await queries.bookDetail('book-a');
      expect(detail, isNotNull);

      expect(
        detail!.volumes.map((VolumeView v) => v.volumeIndex).toList(),
        <int>[0, 1],
      );
      expect(detail.volumes.first.chapters, hasLength(2));
      expect(detail.volumes.first.chapters.first.missing, isFalse);
      expect(detail.volumes.first.chapters.last.missing, isTrue);
      expect(detail.volumes.last.coverPath, '三体/卷二/cover.png');

      expect(
        detail.chapters.map((ChapterView c) => c.chapterIndex).toList(),
        <int>[0, 1, 2],
      );
      expect(detail.preferences.speed, 1.5);
      expect(detail.preferences.skipIntro, const Duration(seconds: 4));
      expect(detail.preferences.skipOutro, const Duration(seconds: 6));
      expect(detail.progress?.position, const Duration(seconds: 30));
    });

    test('不存在返回 null', () async {
      await seed();
      expect(await queries.bookDetail('missing'), isNull);
    });

    test('默认偏好', () async {
      await seed();
      final detail = await queries.bookDetail('book-b');
      expect(detail!.preferences.speed, 1.0);
      expect(detail.preferences.skipIntro, Duration.zero);
      expect(detail.volumes, isEmpty);
    });
  });

  group('写入', () {
    test('saveProgress 按书 upsert，只保留一条', () async {
      await seed();
      await queries.saveProgress(
        bookId: 'book-a',
        chapterId: 'ch-0',
        position: const Duration(seconds: 10),
      );
      await queries.saveProgress(
        bookId: 'book-a',
        chapterId: 'ch-2',
        position: const Duration(seconds: 90),
      );

      final rows = await db.select(db.playbackProgress).get();
      expect(rows, hasLength(1));
      expect(rows.single.chapterId, 'ch-2');
      expect(rows.single.positionMs, 90000);
    });

    test('负进度被钳制为 0', () async {
      await seed();
      await queries.saveProgress(
        bookId: 'book-a',
        chapterId: 'ch-0',
        position: const Duration(seconds: -30),
      );
      expect((await db.select(db.playbackProgress).getSingle()).positionMs, 0);
    });

    test('savePreferences 按书 upsert', () async {
      await seed();
      await queries.savePreferences(
        'book-a',
        const PerBookPrefsSnapshot(speed: 1.25),
      );
      await queries.savePreferences(
        'book-a',
        const PerBookPrefsSnapshot(speed: 2, skipOutro: Duration(seconds: 9)),
      );

      final rows = await db.select(db.perBookPrefs).get();
      expect(rows, hasLength(1));
      expect(rows.single.speed, 2.0);
      expect(rows.single.skipOutroSec, 9);
    });
  });

  group('libraryRoots', () {
    test('返回全部书库根', () async {
      await seed();
      final roots = await queries.libraryRoots();
      expect(roots, hasLength(1));
      expect(roots.single.displayName, '内部存储');
      expect(roots.single.type, 'local');
    });
  });
}
