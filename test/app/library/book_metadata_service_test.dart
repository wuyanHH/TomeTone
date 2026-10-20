import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/book_metadata_service.dart';
import 'package:tometone/contracts/storage/book_metadata_file_store.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';
import 'package:tometone/domain/library/metadata/book_metadata_codec.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/domain/library/queries/library_views.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 18, 3);

/// 内存替身 store：可配置写入结果 / 抛错，记录调用路径。
class _FakeStore implements BookMetadataFileStore {
  _FakeStore({this.writeStatus = BookMetadataWriteStatus.written});

  final BookMetadataWriteStatus writeStatus;
  final Map<String, Uint8List> files = <String, Uint8List>{};
  final List<String> writtenPaths = <String>[];
  bool throwOnWrite = false;

  @override
  Future<Uint8List?> read(String bookRootPath) async => files[bookRootPath];

  @override
  Future<BookMetadataWriteStatus> write(
    String bookRootPath,
    Uint8List bytes,
  ) async {
    writtenPaths.add(bookRootPath);
    if (throwOnWrite) {
      throw StateError('write 失败（测试注入）');
    }
    if (writeStatus == BookMetadataWriteStatus.written) {
      files[bookRootPath] = bytes;
    }
    return writeStatus;
  }
}

BookSummary _book() {
  return const BookSummary(
    id: 'book-1',
    title: '目录名',
    libraryRootId: 'root-1',
    rootPath: '三体',
    coverSource: CoverSource.typography,
    totalChapters: 1,
    totalDurationMs: 0,
    missingChapters: 0,
  );
}

void main() {
  late TomeToneDatabase db;

  setUp(() {
    db = TomeToneDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedBook() async {
    await db
        .into(db.libraryRoots)
        .insert(
          LibraryRootsCompanion.insert(
            id: 'root-1',
            type: 'local',
            uri: '/books',
            displayName: '书库',
            createdAt: _t0,
          ),
        );
    await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            id: 'book-1',
            libraryRootId: 'root-1',
            title: '目录名',
            rootPath: '三体',
            sourceType: 'local',
            totalChapters: const Value<int>(1),
            totalDurationMs: const Value<int>(0),
            createdAt: _t0,
            updatedAt: _t0,
          ),
        );
  }

  BookMetadataService service(_FakeStore store) {
    return BookMetadataService(
      queries: DriftLibraryQueries(db),
      storeFactory: (String uri) => store,
      clock: () => _t0,
    );
  }

  /// 预置一份手填覆盖层（manualEditedAt 非空），供「重新导入」语义断言用。
  Future<void> seedManualOverride() async {
    await db
        .into(db.bookMetadataOverrides)
        .insert(
          BookMetadataOverridesCompanion.insert(
            bookId: 'book-1',
            title: const Value<String?>('旧标题'),
            author: const Value<String?>('旧作者'),
            description: const Value<String?>('旧简介'),
            manualEditedAt: Value<DateTime?>(_t0),
            updatedAt: _t0,
          ),
        );
  }

  /// sidecar 只含 title 与 description，不含 author（缺字段场景）。
  void seedSidecarWithoutAuthor(_FakeStore store) {
    store.files['三体'] = BookMetadataCodec.encode(
      const BookMetadataDraft(title: '新标题', description: '新简介'),
      updatedAt: _t0,
    );
  }

  group('save', () {
    test('写库（manual: true）并向可写 store 写入编码字节，返回 written', () async {
      await seedBook();
      final store = _FakeStore();
      final serviceUnderTest = service(store);

      final result = await serviceUnderTest.save(
        book: _book(),
        rootUri: '/books',
        draft: const BookMetadataDraft(title: '三体正传', tags: ['科幻']),
      );

      expect(result.sidecarStatus, BookMetadataWriteStatus.written);
      expect(store.writtenPaths, <String>['三体']);

      // 覆盖层已写入，且 manualEditedAt 非空（手动编辑）。
      final row = await (db.select(db.bookMetadataOverrides)
            ..where((t) => t.bookId.equals('book-1')))
          .getSingle();
      expect(row.title, '三体正传');
      expect(row.manualEditedAt, isNotNull);

      // sidecar 字节可解码，含书名。
      final decoded = BookMetadataCodec.decode(store.files['三体']!);
      expect(decoded!.title, '三体正传');
      expect(decoded.tags, <String>['科幻']);
    });

    test('store 返回 unsupported 时，数据库仍保存成功，返回 unsupported', () async {
      await seedBook();
      final store = _FakeStore(
        writeStatus: BookMetadataWriteStatus.unsupported,
      );

      final result = await service(store).save(
        book: _book(),
        rootUri: '/books',
        draft: const BookMetadataDraft(title: '三体正传'),
      );

      expect(result.sidecarStatus, BookMetadataWriteStatus.unsupported);
      final row = await (db.select(db.bookMetadataOverrides)
            ..where((t) => t.bookId.equals('book-1')))
          .getSingle();
      expect(row.title, '三体正传', reason: 'SAF 只读根：库仍保存，sidecar 不写');
    });

    test('store 写抛异常时折叠为 failed，库已保存成功不因 sidecar 失败回滚', () async {
      await seedBook();
      final store = _FakeStore()..throwOnWrite = true;

      final result = await service(store).save(
        book: _book(),
        rootUri: '/books',
        draft: const BookMetadataDraft(title: '三体正传'),
      );

      expect(result.sidecarStatus, BookMetadataWriteStatus.failed);
      final row = await (db.select(db.bookMetadataOverrides)
            ..where((t) => t.bookId.equals('book-1')))
          .getSingle();
      expect(row.title, '三体正传', reason: 'DB 保存成功不因 sidecar 失败回滚');
    });
  });

  group('importFromBookRoot', () {
    test('读到 title 但没有 author：不把手动作者清空，手动覆盖层不变', () async {
      await seedBook();
      // 已手动编辑过的覆盖层（manualEditedAt 非空）。
      await db
          .into(db.bookMetadataOverrides)
          .insert(
            BookMetadataOverridesCompanion.insert(
              bookId: 'book-1',
              title: const Value<String?>('手填书名'),
              author: const Value<String?>('手填作者'),
              manualEditedAt: Value<DateTime?>(_t0),
              updatedAt: _t0,
            ),
          );

      // sidecar 只有 title，没有 author。
      final store = _FakeStore();
      store.files['三体'] = BookMetadataCodec.encode(
        const BookMetadataDraft(title: '侧书名'),
        updatedAt: _t0,
      );

      final draft = await service(store).importFromBookRoot(
        book: _book(),
        rootUri: '/books',
      );

      expect(draft, isNotNull);
      expect(draft!.title, '侧书名');
      expect(draft.author, isNull);

      // overwriteManual 默认 false → onlyFillEmpty → 手填过则 no-op。
      final row = await (db.select(db.bookMetadataOverrides)
            ..where((t) => t.bookId.equals('book-1')))
          .getSingle();
      expect(row.title, '手填书名', reason: '手动覆盖层不变');
      expect(row.author, '手填作者', reason: '缺失字段不清空手填作者');
    });

    test('read 不到 sidecar 返回 null', () async {
      await seedBook();
      final store = _FakeStore();

      expect(
        await service(store).importFromBookRoot(
          book: _book(),
          rootUri: '/books',
        ),
        isNull,
      );
    });

    test('overwriteManual: true 只覆盖 JSON 出现的字段，缺字段保留手填值、不清 manualEditedAt', () async {
      await seedBook();
      await seedManualOverride();

      final store = _FakeStore();
      seedSidecarWithoutAuthor(store);

      final draft = await service(store).importFromBookRoot(
        book: _book(),
        rootUri: '/books',
        overwriteManual: true,
      );

      expect(draft, isNotNull);
      expect(draft!.title, '新标题');
      expect(draft.description, '新简介');
      expect(draft.author, isNull, reason: 'sidecar 未提供 author');

      final row = await (db.select(db.bookMetadataOverrides)
            ..where((t) => t.bookId.equals('book-1')))
          .getSingle();
      expect(row.title, '新标题', reason: 'JSON 出现的字段被覆盖');
      expect(row.description, '新简介');
      expect(row.author, '旧作者', reason: '缺字段（author）不清空手填值');
      expect(row.manualEditedAt, isNotNull, reason: '重新导入不清 manualEditedAt');
    });

    test('overwriteManual: false 同样的 sidecar 不会覆盖 title/description（只填空语义）', () async {
      await seedBook();
      await seedManualOverride();

      final store = _FakeStore();
      seedSidecarWithoutAuthor(store);

      await service(store).importFromBookRoot(
        book: _book(),
        rootUri: '/books',
      );

      final row = await (db.select(db.bookMetadataOverrides)
            ..where((t) => t.bookId.equals('book-1')))
          .getSingle();
      expect(row.title, '旧标题', reason: '手动编辑过 → onlyFillEmpty no-op，不覆盖');
      expect(row.description, '旧简介');
      expect(row.author, '旧作者');
    });

    test('sidecar 为坏 JSON 时返回 null', () async {
      await seedBook();
      final store = _FakeStore();
      store.files['三体'] = Uint8List.fromList(<int>[1, 2, 3]);

      expect(
        await service(store).importFromBookRoot(
          book: _book(),
          rootUri: '/books',
        ),
        isNull,
      );
    });
  });
}
