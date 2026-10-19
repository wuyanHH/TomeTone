import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/library_root_service.dart';
import 'package:tometone/contracts/storage/directory_authorization.dart';
import 'package:tometone/domain/common/id_generator.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/modules/storage_local/local_storage_provider.dart';

class _SeqIdGenerator implements IdGenerator {
  int _next = 0;

  @override
  String next() => 'ID${(_next++).toString().padLeft(6, '0')}';
}

/// 记录调用并可控返回 / 抛错的授权替身（不用 mock 框架）。
class _FakeAuthorization implements DirectoryAuthorization {
  _FakeAuthorization({this.result = true, this.throwOnRelease = false});

  final List<String> released = <String>[];

  /// [release] 的返回值。
  bool result;

  /// 为 true 时 [release] 抛异常，用来验证「放弃失败不影响移除」。
  bool throwOnRelease;

  @override
  Future<bool> release(String rootUri) async {
    released.add(rootUri);
    if (throwOnRelease) {
      throw StateError('release 失败（测试注入）');
    }
    return result;
  }
}

void main() {
  late TomeToneDatabase db;
  late LibraryRootService service;
  late Directory library;

  setUpAll(() {
    // 真实目录树：书库根/三体/卷一/001.mp3、002.mp3，另有一个非音频文件。
    final temp = Directory.systemTemp.createTempSync('tometone_root_service_');
    library = Directory('${temp.path}${Platform.pathSeparator}books');
    final volume = Directory(
      '${library.path}${Platform.pathSeparator}三体${Platform.pathSeparator}卷一',
    );
    volume.createSync(recursive: true);
    for (final name in <String>['001.mp3', '002.mp3']) {
      File('${volume.path}${Platform.pathSeparator}$name')
          .writeAsBytesSync(List<int>.filled(16, 0));
    }
    File('${volume.path}${Platform.pathSeparator}cover.jpg')
        .writeAsBytesSync(List<int>.filled(8, 0));
  });

  tearDownAll(() {
    final parent = library.parent;
    if (parent.existsSync()) {
      parent.deleteSync(recursive: true);
    }
  });

  setUp(() {
    db = TomeToneDatabase(NativeDatabase.memory());
    service = LibraryRootService(
      database: db,
      idGenerator: _SeqIdGenerator(),
      providerFactory: LocalStorageProvider.new,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('addLocalRoot', () {
    test('落库并返回 ID，展示名取目录名', () async {
      final id = await service.addLocalRoot(absolutePath: library.path);

      final roots = await DriftLibraryQueries(db).libraryRoots();
      expect(roots, hasLength(1));
      expect(roots.single.id, id);
      expect(roots.single.type, 'local');
      expect(roots.single.displayName, 'books');
      expect(roots.single.uri, library.path);
    });

    test('目录不存在时抛错且不落库', () async {
      await expectLater(
        service.addLocalRoot(
          absolutePath: '${library.path}${Platform.pathSeparator}missing',
        ),
        throwsStateError,
      );
      expect(await DriftLibraryQueries(db).libraryRoots(), isEmpty);
    });

    test('空路径被拒绝', () async {
      await expectLater(
        service.addLocalRoot(absolutePath: '   '),
        throwsArgumentError,
      );
    });
  });

  group('renameRoot', () {
    test('只改展示名：URI、书目与文件都不动', () async {
      final id = await service.addLocalRoot(absolutePath: library.path);
      await service.scan(id);

      await service.renameRoot(id, '  夜里听的书  ');

      final roots = await DriftLibraryQueries(db).libraryRoots();
      expect(roots.single.displayName, '夜里听的书');
      expect(roots.single.uri, library.path);
      final books = await DriftLibraryQueries(db).listBooks();
      expect(books.single.title, '三体');
      expect(books.single.libraryRootId, id);
    });

    test('空名字被拒绝，不写库', () async {
      final id = await service.addLocalRoot(absolutePath: library.path);

      await expectLater(service.renameRoot(id, '   '), throwsArgumentError);

      final roots = await DriftLibraryQueries(db).libraryRoots();
      expect(roots.single.displayName, 'books');
    });

    test('未知书库根抛错', () async {
      await expectLater(service.renameRoot('missing', '新名字'), throwsStateError);
    });
  });

  group('removeRoot', () {
    test('只删登记：书 / 卷 / 章级联清掉，目录与文件原样保留', () async {
      final id = await service.addLocalRoot(absolutePath: library.path);
      await service.scan(id);
      expect(await DriftLibraryQueries(db).listBooks(), hasLength(1));
      expect(await db.select(db.volumes).get(), hasLength(1));
      expect(await db.select(db.chapters).get(), hasLength(2));

      await service.removeRoot(id);

      expect(await DriftLibraryQueries(db).libraryRoots(), isEmpty);
      expect(await DriftLibraryQueries(db).listBooks(), isEmpty);
      expect(await db.select(db.volumes).get(), isEmpty);
      expect(await db.select(db.chapters).get(), isEmpty);

      // 数据安全铁律（§9.2）：用户目录与文件一个都不能少。
      expect(library.existsSync(), isTrue);
      final chapter = File(
        '${library.path}${Platform.pathSeparator}三体'
        '${Platform.pathSeparator}卷一${Platform.pathSeparator}001.mp3',
      );
      expect(chapter.existsSync(), isTrue);
    });

    test('移除之后重新添加同一目录仍然可扫描（登记可以重建）', () async {
      final id = await service.addLocalRoot(absolutePath: library.path);
      await service.scan(id);
      await service.removeRoot(id);

      final again = await service.addLocalRoot(absolutePath: library.path);
      final report = await service.scan(again);

      expect(report.booksAdded, 1);
      expect(await DriftLibraryQueries(db).listBooks(), hasLength(1));
    });

    test('未知书库根抛错，重复移除第二次也抛错', () async {
      await expectLater(service.removeRoot('missing'), throwsStateError);

      final id = await service.addLocalRoot(absolutePath: library.path);
      await service.removeRoot(id);
      await expectLater(service.removeRoot(id), throwsStateError);
    });
  });

  group('removeRoot 与目录授权（DirectoryAuthorization）', () {
    const String safUri =
        'content://com.android.externalstorage.documents/tree/primary%3AAudiobooks';

    LibraryRootService serviceWith(DirectoryAuthorization? authorization) {
      return LibraryRootService(
        database: db,
        idGenerator: _SeqIdGenerator(),
        providerFactory: LocalStorageProvider.new,
        authorization: authorization,
      );
    }

    test('移除 SAF 根：以该根的 uri 调用 release 一次，登记行随后消失', () async {
      final fake = _FakeAuthorization();
      final withAuth = serviceWith(fake);
      final id = await withAuth.addSafRoot(
        treeUri: safUri,
        displayName: 'Audiobooks',
      );

      await withAuth.removeRoot(id);

      expect(fake.released, <String>[safUri], reason: '恰好放弃这一次的根 URI');
      expect(await DriftLibraryQueries(db).libraryRoots(), isEmpty);
    });

    test('移除本地根：不调用 release', () async {
      final fake = _FakeAuthorization();
      final withAuth = serviceWith(fake);
      final id = await withAuth.addLocalRoot(absolutePath: library.path);

      await withAuth.removeRoot(id);

      expect(fake.released, isEmpty, reason: '本地根没有系统授权可放弃');
      expect(await DriftLibraryQueries(db).libraryRoots(), isEmpty);
    });

    test('release 返回 false：移除照样成功', () async {
      final fake = _FakeAuthorization(result: false);
      final withAuth = serviceWith(fake);
      final id = await withAuth.addSafRoot(
        treeUri: safUri,
        displayName: 'Audiobooks',
      );

      await withAuth.removeRoot(id);

      expect(fake.released, hasLength(1));
      expect(await DriftLibraryQueries(db).libraryRoots(), isEmpty);
    });

    test('release 抛异常：不向上抛，移除照样成功', () async {
      final fake = _FakeAuthorization(throwOnRelease: true);
      final withAuth = serviceWith(fake);
      final id = await withAuth.addSafRoot(
        treeUri: safUri,
        displayName: 'Audiobooks',
      );

      await expectLater(withAuth.removeRoot(id), completes);

      expect(fake.released, hasLength(1));
      expect(await DriftLibraryQueries(db).libraryRoots(), isEmpty);
    });

    test('未注入 authorization（null）：移除仍然成功', () async {
      final id = await service.addSafRoot(
        treeUri: safUri,
        displayName: 'Audiobooks',
      );

      await service.removeRoot(id);

      expect(await DriftLibraryQueries(db).libraryRoots(), isEmpty);
    });
  });

  group('scan', () {
    test('通过真实目录扫描建库（书 / 卷 / 章 + 封面继承）', () async {
      final id = await service.addLocalRoot(absolutePath: library.path);

      final report = await service.scan(id);

      expect(report.booksAdded, 1);
      expect(report.volumesAdded, 1);
      expect(report.chaptersAdded, 2);
      expect(report.failedPaths, isEmpty);

      final books = await DriftLibraryQueries(db).listBooks();
      expect(books.single.title, '三体');
      expect(books.single.totalChapters, 2, reason: 'cover.jpg 不是章节');
      expect(await service.lastScanAt(id), isNotNull);
    });

    test('二次扫描幂等（零写入）', () async {
      final id = await service.addLocalRoot(absolutePath: library.path);
      await service.scan(id);

      final second = await service.scan(id);
      expect(second.hasChanges, isFalse);
    });

    test('未知书库根抛错', () async {
      await expectLater(service.scan('missing'), throwsStateError);
    });
  });
}
