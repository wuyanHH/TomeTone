import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/contracts/storage/book_metadata_file_store.dart';
import 'package:tometone/contracts/storage/fake_storage_provider.dart';
import 'package:tometone/contracts/storage/storage_entry.dart';
import 'package:tometone/domain/common/id_generator.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/media/media_metadata.dart';
import 'package:tometone/domain/library/media/media_metadata_reader.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';
import 'package:tometone/domain/library/metadata/book_metadata_codec.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/domain/library/scan/library_scanner.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 18, 3);

/// 确定性 ID 生成器（便于断言"ID 不变"）。
class _SeqIdGenerator implements IdGenerator {
  int _next = 0;

  @override
  String next() => 'ID${(_next++).toString().padLeft(6, '0')}';
}

class _MapMetadataReader implements MediaMetadataReader {
  _MapMetadataReader(this.durations);

  final Map<String, Duration> durations;

  @override
  Future<ChapterMediaMetadata?> read(AudioSourceRef source) async {
    final duration = durations[source.uri];
    return duration == null ? null : ChapterMediaMetadata(duration: duration);
  }
}

AudioSourceRef _sourceOf(String filePath) =>
    LocalFileSource(uri: 'file:///books/$filePath');

/// 内存替身 sidecar store：按书根路径返回预置字节，记录读调用。
class _FakeMetadataStore implements BookMetadataFileStore {
  _FakeMetadataStore(this.files);

  final Map<String, Uint8List> files;
  final List<String> readPaths = <String>[];

  @override
  Future<Uint8List?> read(String bookRootPath) async {
    readPaths.add(bookRootPath);
    return files[bookRootPath];
  }

  @override
  Future<BookMetadataWriteStatus> write(
    String bookRootPath,
    Uint8List bytes,
  ) async {
    return BookMetadataWriteStatus.written;
  }
}

void main() {
  late TomeToneDatabase db;
  late LibraryScanner scanner;

  setUp(() {
    db = TomeToneDatabase(NativeDatabase.memory());
    scanner = LibraryScanner(
      database: db,
      idGenerator: _SeqIdGenerator(),
      clock: () => _t0,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedRoot() async {
    await db
        .into(db.libraryRoots)
        .insert(
          LibraryRootsCompanion.insert(
            id: 'root-1',
            type: 'local',
            uri: '/books',
            displayName: '测试库',
            createdAt: _t0,
          ),
        );
  }

  FakeStorageProvider threeChapterProvider({bool withSecond = true}) {
    return FakeStorageProvider.fromPaths(<String, int>{
      '三体/卷一/001.mp3': 100,
      if (withSecond) '三体/卷一/002.mp3': 100,
      '三体/卷二/001.mp3': 100,
      '三体/cover.jpg': 10,
    });
  }

  group('Phase 1 结构扫描', () {
    test('首次扫描建立书 / 卷 / 章，并更新 lastScanAt', () async {
      await seedRoot();

      final report = await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: threeChapterProvider(),
      );

      expect(report.booksSeen, 1);
      expect(report.booksAdded, 1);
      expect(report.volumesAdded, 2);
      expect(report.chaptersSeen, 3);
      expect(report.chaptersAdded, 3);
      expect(report.ignoredFiles, 1);
      expect(report.failedPaths, isEmpty);
      expect(report.hasChanges, isTrue);

      final books = await db.select(db.books).get();
      expect(books.single.title, '三体');
      expect(books.single.totalChapters, 3);
      expect(books.single.totalDurationMs, 0, reason: 'Phase 1 不读时长');

      final chapters = await db.select(db.chapters).get();
      expect(chapters, hasLength(3));
      expect(
        chapters.every((Chapter chapter) => chapter.durationMs == null),
        isTrue,
        reason: 'Phase 1 绝不读取时长 / 封面',
      );
      expect(chapters.map((Chapter chapter) => chapter.missing).toSet(), <bool>{
        false,
      });

      final root = await db.select(db.libraryRoots).getSingle();
      expect(root.lastScanAt, isNotNull);
    });

    test('二次扫描同一棵树不产生任何写入，且 ID 不变', () async {
      await seedRoot();
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: threeChapterProvider(),
      );
      final idsBefore = (await db.select(db.chapters).get())
          .map((Chapter chapter) => chapter.id)
          .toSet();

      final second = await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: threeChapterProvider(),
      );

      expect(second.hasChanges, isFalse);
      expect(second.chaptersAdded, 0);
      expect(second.chaptersUpdated, 0);
      expect(second.booksUpdated, 0);
      expect(second.volumesAdded, 0);

      final idsAfter = (await db.select(db.chapters).get())
          .map((Chapter chapter) => chapter.id)
          .toSet();
      expect(idsAfter, idsBefore, reason: '章节 ID 不可变（§8.2）');
    });

    test('新增文件只插入新章，已有章 ID 不变', () async {
      await seedRoot();
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: threeChapterProvider(),
      );
      final idsBefore = (await db.select(db.chapters).get())
          .map((Chapter chapter) => chapter.id)
          .toSet();

      final report = await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: FakeStorageProvider.fromPaths(<String, int>{
          '三体/卷一/001.mp3': 100,
          '三体/卷一/002.mp3': 100,
          '三体/卷二/001.mp3': 100,
          // 新书：不改变任何既有书的章序号。
          '新书/001.mp3': 100,
        }),
      );

      expect(report.chaptersAdded, 1);
      expect(report.booksAdded, 1);
      expect(report.chaptersUpdated, 0);

      final idsAfter = (await db.select(db.chapters).get())
          .map((Chapter chapter) => chapter.id)
          .toSet();
      expect(idsAfter.containsAll(idsBefore), isTrue);
      expect(idsAfter, hasLength(4));
    });

    test('在卷中间插入文件会顺延后续章序号（全局 chapterIndex 的必然结果）', () async {
      await seedRoot();
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: threeChapterProvider(),
      );

      final report = await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: FakeStorageProvider.fromPaths(<String, int>{
          '三体/卷一/001.mp3': 100,
          '三体/卷一/002.mp3': 100,
          '三体/卷一/003.mp3': 100,
          '三体/卷二/001.mp3': 100,
        }),
      );

      expect(report.chaptersAdded, 1);
      expect(report.chaptersUpdated, 1, reason: '卷二原第 0 章顺延为 1');
      expect(
        (await db.select(db.chapters).get())
            .firstWhere(
              (Chapter chapter) => chapter.filePath == '三体/卷二/001.mp3',
            )
            .chapterIndex,
        3,
      );
    });
  });

  group('缺失与恢复（数据安全铁律）', () {
    test('文件消失只标记缺失：记录与播放进度都保留，章节总数不变', () async {
      await seedRoot();
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: threeChapterProvider(),
      );

      final bookId = (await db.select(db.books).getSingle()).id;
      final target = (await db.select(db.chapters).get()).firstWhere(
        (Chapter chapter) => chapter.filePath == '三体/卷一/002.mp3',
      );
      await db
          .into(db.playbackProgress)
          .insert(
            PlaybackProgressCompanion.insert(
              bookId: bookId,
              chapterId: target.id,
              positionMs: 99000,
              updatedAt: _t0,
            ),
          );

      final report = await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: threeChapterProvider(withSecond: false),
      );

      expect(report.chaptersMarkedMissing, 1);
      expect(report.chaptersAdded, 0);
      expect(report.booksUpdated, 0, reason: '缺失章仍占位，章节总数不缩水');

      final chapters = await db.select(db.chapters).get();
      expect(chapters, hasLength(3), reason: '绝不删除记录（§9.2）');
      expect(
        chapters.firstWhere((Chapter c) => c.id == target.id).missing,
        isTrue,
      );
      expect(await db.select(db.playbackProgress).get(), hasLength(1));
      expect((await db.select(db.books).getSingle()).totalChapters, 3);
    });

    test('文件恢复后撤销缺失标记', () async {
      await seedRoot();
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: threeChapterProvider(),
      );
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: threeChapterProvider(withSecond: false),
      );

      final report = await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: threeChapterProvider(),
      );

      expect(report.chaptersRestored, 1);
      expect(
        (await db.select(db.chapters).get()).every(
          (Chapter chapter) => !chapter.missing,
        ),
        isTrue,
      );
    });
  });

  group('鲁棒性', () {
    test('不可读目录计入 failedPaths，不中断整次扫描', () async {
      await seedRoot();

      final provider = FakeStorageProvider(
        directories: <String, List<StorageEntry>>{
          '': const <StorageEntry>[
            StorageEntry(name: '三体', path: '三体', isDirectory: true),
          ],
          '三体': const <StorageEntry>[
            StorageEntry(
              name: '001.mp3',
              path: '三体/001.mp3',
              isDirectory: false,
              sizeBytes: 10,
            ),
            StorageEntry(name: '受保护', path: '三体/受保护', isDirectory: true),
          ],
        },
        contents: <String, List<int>>{'三体/001.mp3': List<int>.filled(10, 0)},
      );

      final report = await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: provider,
      );

      expect(report.failedPaths, contains('三体/受保护'));
      expect(report.chaptersAdded, 1);
    });

    test('并发扫描被拒绝', () async {
      await seedRoot();
      final provider = threeChapterProvider();

      final first = scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: provider,
      );
      await expectLater(
        scanner.scanStructure(libraryRootId: 'root-1', provider: provider),
        throwsStateError,
      );
      await first;
    });
  });

  group('Phase 2 元信息回填', () {
    test('回填时长并重算书的累计时长', () async {
      await seedRoot();
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: threeChapterProvider(),
      );

      final report = await scanner.backfillMetadata(
        libraryRootId: 'root-1',
        reader: _MapMetadataReader(<String, Duration>{
          'file:///books/三体/卷一/001.mp3': const Duration(minutes: 11),
          'file:///books/三体/卷二/001.mp3': const Duration(minutes: 5),
        }),
        sourceOf: _sourceOf,
      );

      expect(report.updated, 2);
      expect(report.failed, 1, reason: '002.mp3 无元数据');
      expect(report.remaining, 1);

      final book = await db.select(db.books).getSingle();
      expect(book.totalDurationMs, const Duration(minutes: 16).inMilliseconds);
    });

    test('永久读不出的章在连续失败后退出队列，不饿死后续章节', () async {
      await seedRoot();
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: FakeStorageProvider.fromPaths(<String, int>{
          '书/001.mp3': 10,
          '书/002.mp3': 10,
        }),
      );

      final reader = _MapMetadataReader(<String, Duration>{
        'file:///books/书/002.mp3': const Duration(minutes: 3),
      });

      // 队首的 001 永远读不出：连续 maxMetadataAttempts 轮都只处理它。
      for (var round = 0; round < LibraryScanner.maxMetadataAttempts; round++) {
        final report = await scanner.backfillMetadata(
          libraryRootId: 'root-1',
          reader: reader,
          sourceOf: _sourceOf,
          maxChapters: 1,
        );
        expect(report.updated, 0, reason: '第 ${round + 1} 轮仍是坏文件');
      }

      // 坏文件退出队列后，后面的章必须能被处理到。
      final attempts = (await db.select(db.chapters).get())
          .map((Chapter chapter) => chapter.metadataAttempts)
          .toList();
      expect(attempts, <int>[3, 0], reason: '坏文件累计到上限，正常章未被尝试');

      final report = await scanner.backfillMetadata(
        libraryRootId: 'root-1',
        reader: reader,
        sourceOf: _sourceOf,
        maxChapters: 1,
      );
      expect(report.updated, 1);
      expect(report.remaining, 0, reason: '坏文件已退出队列，不再计入待回填');
    });
  });

  group('封面五级继承（落库）', () {
    test('书根图 → bookRoot', () async {
      await seedRoot();
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: FakeStorageProvider.fromPaths(<String, int>{
          '三体/卷一/001.mp3': 100,
          '三体/cover.jpg': 10,
        }),
      );

      final book = await db.select(db.books).getSingle();
      expect(book.coverPath, '三体/cover.jpg');
      expect(book.coverSourceType, CoverSource.bookRoot);
    });

    test('无书根图 → 首卷反哺', () async {
      await seedRoot();
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: FakeStorageProvider.fromPaths(<String, int>{
          '三体/卷一/001.mp3': 100,
          '三体/卷一/folder.png': 10,
        }),
      );

      final book = await db.select(db.books).getSingle();
      expect(book.coverPath, '三体/卷一/folder.png');
      expect(book.coverSourceType, CoverSource.firstVolumeFeedback);
    });

    test('无任何封面 → 字标兜底且 coverPath 为空', () async {
      await seedRoot();
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: FakeStorageProvider.fromPaths(<String, int>{
          '三体/001.mp3': 100,
        }),
      );

      final book = await db.select(db.books).getSingle();
      expect(book.coverPath, isNull);
      expect(book.coverSourceType, CoverSource.typography);
    });

    test('卷封面：卷目录图优先，否则回退书根图', () async {
      await seedRoot();
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: FakeStorageProvider.fromPaths(<String, int>{
          '三体/cover.jpg': 10,
          '三体/卷一/001.mp3': 100,
          '三体/卷一/poster.png': 10,
          '三体/卷二/001.mp3': 100,
        }),
      );

      final volumes = await db.select(db.volumes).get();
      expect(
        volumes.firstWhere((Volume volume) => volume.path == '卷一').coverPath,
        '三体/卷一/poster.png',
      );
      expect(
        volumes.firstWhere((Volume volume) => volume.path == '卷二').coverPath,
        '三体/cover.jpg',
      );
    });

    test('新增封面图会触发书更新', () async {
      await seedRoot();
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: FakeStorageProvider.fromPaths(<String, int>{
          '三体/001.mp3': 100,
        }),
      );

      final report = await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: FakeStorageProvider.fromPaths(<String, int>{
          '三体/001.mp3': 100,
          '三体/cover.jpg': 10,
        }),
      );

      expect(report.booksUpdated, 1);
      expect(
        (await db.select(db.books).getSingle()).coverSourceType,
        CoverSource.bookRoot,
      );
    });
  });

  group('sidecar 导入（仅本次新增的书）', () {
    test('新书根下 sidecar 的 title/description/tags 进入覆盖层，摘要取 sidecar 名', () async {
      await seedRoot();
      final store = _FakeMetadataStore(<String, Uint8List>{
        '三体': BookMetadataCodec.encode(
          const BookMetadataDraft(
            title: '三体（地球往事）',
            description: '一部科幻',
            tags: ['科幻', '长篇'],
          ),
          updatedAt: _t0,
        ),
      });

      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: threeChapterProvider(),
        metadataStore: store,
      );

      // 摘要（COALESCE 覆盖层）取 sidecar 的 title，而非目录名。
      final summary = (await DriftLibraryQueries(db).listAllBooks()).single;
      expect(summary.title, '三体（地球往事）');
      expect(summary.description, '一部科幻');
      expect(summary.tags, <String>['科幻', '长篇']);

      // 覆盖层 manualEditedAt 为空（扫描自动写入，非手动）。
      final overrides = await db.select(db.bookMetadataOverrides).get();
      expect(overrides.single.manualEditedAt, isNull);
    });

    test('已手动编辑过的书重扫描后字段不变（不读 sidecar）', () async {
      await seedRoot();
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: threeChapterProvider(),
      );
      final bookId = (await db.select(db.books).getSingle()).id;

      // 手动编辑覆盖层。
      await db
          .into(db.bookMetadataOverrides)
          .insert(
            BookMetadataOverridesCompanion.insert(
              bookId: bookId,
              title: const Value<String?>('手填书名'),
              manualEditedAt: Value<DateTime?>(_t0),
              updatedAt: _t0,
            ),
          );

      // 第二次扫描：sidecar 提供新 title，但书已存在 → 不读 sidecar。
      final store = _FakeMetadataStore(<String, Uint8List>{
        '三体': BookMetadataCodec.encode(
          const BookMetadataDraft(title: '不该出现'),
          updatedAt: _t0,
        ),
      });
      await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: threeChapterProvider(),
        metadataStore: store,
      );

      expect(store.readPaths, isEmpty, reason: '老书不读 sidecar，避免每次扫描上千次 IO');
      final row = await (db.select(db.bookMetadataOverrides)
            ..where((t) => t.bookId.equals(bookId)))
          .getSingle();
      expect(row.title, '手填书名');
      expect(row.manualEditedAt, isNotNull);
    });
  });

  group('性能', () {
    test('万级章节结构扫描在目标量级内完成（≤3s 目标的回归护栏）', () async {
      await seedRoot();

      final files = <String, int>{};
      for (var index = 0; index < 10000; index++) {
        final book = '书${index ~/ 1000}';
        final volume = '卷${(index % 1000) ~/ 100}';
        final chapter = (index % 100).toString().padLeft(3, '0');
        files['$book/$volume/$chapter.mp3'] = 128;
      }

      final report = await scanner.scanStructure(
        libraryRootId: 'root-1',
        provider: FakeStorageProvider.fromPaths(files),
      );

      expect(report.booksAdded, 10);
      expect(report.volumesAdded, 100);
      expect(report.chaptersAdded, 10000);
      // 15s 是**宽松护栏**（并行测试下墙钟不可精确断言），
      // 只用于拦截 O(n²) 级别的算法退化；真实目标按附录 D 定标。
      expect(
        report.elapsed.inMilliseconds,
        lessThan(15000),
        reason: '结构扫描退化（万级章节应在秒级完成）',
      );
    });
  });
}
