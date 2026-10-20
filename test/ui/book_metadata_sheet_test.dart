import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/book_metadata_service.dart';
import 'package:tometone/app/providers/metadata_providers.dart';
import 'package:tometone/contracts/storage/book_metadata_file_store.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';
import 'package:tometone/domain/library/metadata/book_metadata_codec.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/pages/shelf/book_metadata_sheet.dart';

import 'ui_test_harness.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 20, 3);

class _FakeStore implements BookMetadataFileStore {
  _FakeStore({this.writeStatus = BookMetadataWriteStatus.written});

  final BookMetadataWriteStatus writeStatus;
  final Map<String, Uint8List> files = <String, Uint8List>{};
  final List<String> writtenPaths = <String>[];

  @override
  Future<Uint8List?> read(String bookRootPath) async => files[bookRootPath];

  @override
  Future<BookMetadataWriteStatus> write(
    String bookRootPath,
    Uint8List bytes,
  ) async {
    writtenPaths.add(bookRootPath);
    if (writeStatus == BookMetadataWriteStatus.written) {
      files[bookRootPath] = bytes;
    }
    return writeStatus;
  }
}

void main() {
  late TomeToneDatabase db;

  setUp(() {
    db = TomeToneDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  BookSummary book() => testSummary(
    title: '三体',
    author: '刘慈欣',
    narrator: '李野默',
    seriesName: '地球往事',
    seriesIndex: 1,
    description: '黑暗森林之前的故事。',
    tags: <String>['科幻', '长篇'],
  );

  Future<void> seedBook() async {
    await db
        .into(db.libraryRoots)
        .insert(
          LibraryRootsCompanion.insert(
            id: testRootId,
            type: 'local',
            uri: testRootUri,
            displayName: '测试书库',
            createdAt: _t0,
          ),
        );
    await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            id: 'book-1',
            libraryRootId: testRootId,
            title: '三体',
            rootPath: 'books/book-1',
            sourceType: 'local',
            totalChapters: const Value<int>(4),
            totalDurationMs: const Value<int>(0),
            createdAt: _t0,
            updatedAt: _t0,
          ),
        );
  }

  BookMetadataService serviceFor(_FakeStore store) {
    return BookMetadataService(
      queries: DriftLibraryQueries(db),
      storeFactory: (String uri) => store,
      clock: () => _t0,
    );
  }

  Future<void> pumpSheet(
    WidgetTester tester, {
    required BookSummary summary,
    required BookMetadataDraft initial,
    required BookMetadataService service,
  }) async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        bookMetadataServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      testApp(
        container,
        Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: FilledButton(
                onPressed: () async {
                  await showBookMetadataSheet(
                    context,
                    book: summary,
                    rootUri: testRootUri,
                    initial: initial,
                  );
                },
                child: const Text('打开编辑'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开编辑'));
    await tester.pumpAndSettle();
  }

  testWidgets('预填现有元数据，保存作者与归一化标签并双写', (WidgetTester tester) async {
    usePhoneViewport(tester);
    await seedBook();
    final _FakeStore store = _FakeStore();
    final BookSummary summary = book();

    await pumpSheet(
      tester,
      summary: summary,
      initial: BookMetadataDraft(
        title: summary.title,
        author: summary.author,
        narrator: summary.narrator,
        seriesName: summary.seriesName,
        seriesIndex: summary.seriesIndex,
        description: summary.description,
        tags: summary.tags,
      ),
      service: serviceFor(store),
    );

    expect(find.text('编辑元数据'), findsOneWidget);
    expect(find.text('三体'), findsOneWidget);
    expect(find.text('刘慈欣'), findsOneWidget);
    expect(find.text('李野默'), findsOneWidget);
    expect(find.text('科幻'), findsOneWidget);
    expect(find.text('长篇'), findsOneWidget);

    // 作者 → 新作者；标签 → 含重复、中文逗号与顿号。
    await tester.enterText(find.byType(TextFormField).at(1), '新作者');
    await tester.enterText(find.byType(TextFormField).at(5), '武侠，长篇、武侠');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('已保存到应用与书根'), findsOneWidget);
    expect(find.text('编辑元数据'), findsNothing, reason: '保存成功应关闭弹层');

    final Uint8List? bytes = store.files['books/book-1'];
    expect(bytes, isNotNull);
    final BookMetadataDraft? saved = BookMetadataCodec.decode(bytes!);
    expect(saved?.author, '新作者');
    expect(saved?.tags, <String>['武侠', '长篇']);
  });

  testWidgets('空书名被拦下，不调用保存', (WidgetTester tester) async {
    usePhoneViewport(tester);
    await seedBook();
    final _FakeStore store = _FakeStore();
    final BookSummary summary = book();

    await pumpSheet(
      tester,
      summary: summary,
      initial: BookMetadataDraft(title: summary.title),
      service: serviceFor(store),
    );

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('书名不能为空'), findsOneWidget);
    expect(store.writtenPaths, isEmpty);
    expect(find.text('编辑元数据'), findsOneWidget, reason: '校验失败不关闭弹层');
  });

  testWidgets('SAF 只读：保存成功但提示书根未写入', (WidgetTester tester) async {
    usePhoneViewport(tester);
    await seedBook();
    final _FakeStore store = _FakeStore(
      writeStatus: BookMetadataWriteStatus.unsupported,
    );
    final BookSummary summary = book();

    await pumpSheet(
      tester,
      summary: summary,
      initial: BookMetadataDraft(title: summary.title),
      service: serviceFor(store),
    );

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('已保存到应用内，书根文件未写入'), findsOneWidget);
    expect(store.writtenPaths, <String>['books/book-1']);
    expect(find.text('编辑元数据'), findsNothing);
  });
}
