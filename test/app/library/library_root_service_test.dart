import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/library_root_service.dart';
import 'package:tometone/domain/common/id_generator.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/modules/storage_local/local_storage_provider.dart';

class _SeqIdGenerator implements IdGenerator {
  int _next = 0;

  @override
  String next() => 'ID${(_next++).toString().padLeft(6, '0')}';
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
