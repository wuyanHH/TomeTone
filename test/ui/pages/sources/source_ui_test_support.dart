import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/source_engine_providers.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/app/sources/book_source_service.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/contracts/sources/source_import_loader.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/sources/book_source_queries.dart';
import 'package:tometone/ui/theme/app_color_palette.dart';
import 'package:tometone/ui/theme/app_theme.dart';

const String sourceFixturePath = 'test/fixtures/sources/tingyou/source.json';

final DateTime sourceTestTime = DateTime.utc(2026, 10, 20, 12);

String sourceFixtureText({
  String? name,
  String? sourceUrl,
  Map<String, Object?>? extra,
}) {
  final map = jsonDecode(
    File(sourceFixturePath).readAsStringSync(),
  ) as Map<String, dynamic>;
  if (name != null) {
    map['bookSourceName'] = name;
  }
  if (sourceUrl != null) {
    map['bookSourceUrl'] = sourceUrl;
  }
  if (extra != null) {
    map.addAll(extra);
  }
  return jsonEncode(map);
}

TomeToneDatabase openSourceTestDatabase() {
  final db = TomeToneDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

BookSourceService sourceService(TomeToneDatabase db) {
  return BookSourceService(
    database: db,
    queries: DriftBookSourceQueries(db),
    idGenerator: UlidIdGenerator(),
  );
}

Future<String> seedSource(
  TomeToneDatabase db, {
  String? name,
  String? sourceUrl,
  Map<String, Object?>? extra,
}) async {
  final outcomes = await sourceService(db).importText(
    sourceFixtureText(name: name, sourceUrl: sourceUrl, extra: extra),
  );
  return outcomes.single.sourceId!;
}

Future<void> seedOnlineBook(
  TomeToneDatabase db, {
  required String sourceId,
  required String libraryRootId,
  String id = 'book-1',
  String title = '在线书',
  String sourceUri = 'https://www.tingyou.fm/book/1',
  String? rootPath,
  bool onShelf = false,
}) async {
  final actualRootPath = rootPath ?? sourceUri;
  await db
      .into(db.books)
      .insert(
        BooksCompanion.insert(
          id: id,
          libraryRootId: libraryRootId,
          title: title,
          rootPath: actualRootPath,
          sourceType: 'online',
          sourceUri: Value<String?>(sourceUri),
          onShelf: Value<bool>(onShelf),
          sourceId: Value<String?>(sourceId),
          createdAt: sourceTestTime,
          updatedAt: sourceTestTime,
        ),
      );
  await db
      .into(db.volumes)
      .insert(
        VolumesCompanion.insert(
          id: 'vol-$id',
          bookId: id,
          title: '第一卷',
          volumeIndex: 0,
          path: '',
          updatedAt: sourceTestTime,
        ),
      );
  await db
      .into(db.chapters)
      .insert(
        ChaptersCompanion.insert(
          id: 'ch-$id',
          bookId: id,
          volumeId: 'vol-$id',
          libraryRootId: libraryRootId,
          title: '第一章',
          chapterIndex: 0,
          filePath: 'online/ch-$id',
          updatedAt: sourceTestTime,
        ),
      );
}

class FakeSourceImportLoader implements SourceImportLoader {
  FakeSourceImportLoader({this.file});

  String? urlContent;
  SourceImportFile? file;
  Exception? urlError;
  Exception? fileError;
  int urlCalls = 0;
  int fileCalls = 0;

  @override
  Future<String> loadFromUrl(String url) async {
    urlCalls++;
    if (urlError != null) {
      throw urlError!;
    }
    return urlContent ?? sourceFixtureText();
  }

  @override
  Future<SourceImportFile?> pickJsonFile() async {
    fileCalls++;
    if (fileError != null) {
      throw fileError!;
    }
    return file;
  }
}

Future<void> pumpSourceUi(
  WidgetTester tester, {
  required TomeToneDatabase db,
  required Widget home,
  SourceImportLoader? loader,
  SourceDiscovery? discovery,
  List<Override> extra = const <Override>[],
  Size size = const Size(360, 780),
  double textScale = 1,
  Brightness brightness = Brightness.light,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        if (loader != null)
          sourceImportLoaderProvider.overrideWithValue(loader),
        if (discovery != null)
          sourceDiscoveryProvider.overrideWithValue(discovery),
        ...extra,
      ],
      child: MaterialApp(
        theme: AppTheme.build(),
        darkTheme: AppTheme.build(
          palette: AppColorPalettes.fallback,
          brightness: Brightness.dark,
        ),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: disableAnimations,
            ),
            child: child!,
          );
        },
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
