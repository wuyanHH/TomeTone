import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/sources/source_import_loader.dart';
import 'package:tometone/ui/pages/sources/source_import_sheet.dart';

import 'source_ui_test_support.dart';

void main() {
  testWidgets('粘贴合法 JSON 导入成功', (tester) async {
    final db = openSourceTestDatabase();

    await pumpSourceUi(
      tester,
      db: db,
      loader: FakeSourceImportLoader(),
      home: const Scaffold(body: SourceImportSheet()),
    );

    await tester.tap(find.text('粘贴'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(SourceImportSheetKeys.pasteFieldKey),
      sourceFixtureText(),
    );
    await tester.tap(find.byKey(SourceImportSheetKeys.importButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('已导入'), findsOneWidget);
    expect(await db.select(db.bookSources).get(), hasLength(1));
  });

  testWidgets('非法 JSON 显示失败文案且不写库', (tester) async {
    final db = openSourceTestDatabase();

    await pumpSourceUi(
      tester,
      db: db,
      loader: FakeSourceImportLoader(),
      home: const Scaffold(body: SourceImportSheet()),
    );

    await tester.tap(find.text('粘贴'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(SourceImportSheetKeys.pasteFieldKey),
      'not-json',
    );
    await tester.tap(find.byKey(SourceImportSheetKeys.importButtonKey));
    await tester.pumpAndSettle();

    expect(find.textContaining('失败：'), findsOneWidget);
    expect(find.textContaining('不是合法的 JSON'), findsOneWidget);
    expect(await db.select(db.bookSources).get(), isEmpty);
  });

  testWidgets('重复源显示已跳过', (tester) async {
    final db = openSourceTestDatabase();
    await seedSource(db);

    await pumpSourceUi(
      tester,
      db: db,
      loader: FakeSourceImportLoader(),
      home: const Scaffold(body: SourceImportSheet()),
    );

    await tester.tap(find.text('粘贴'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(SourceImportSheetKeys.pasteFieldKey),
      sourceFixtureText(),
    );
    await tester.tap(find.byKey(SourceImportSheetKeys.importButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('已跳过（已存在）'), findsOneWidget);
    expect(await db.select(db.bookSources).get(), hasLength(1));
  });

  testWidgets('打开覆盖开关后显示已更新', (tester) async {
    final db = openSourceTestDatabase();
    await seedSource(db);

    await pumpSourceUi(
      tester,
      db: db,
      loader: FakeSourceImportLoader(),
      home: const Scaffold(body: SourceImportSheet()),
    );

    await tester.tap(find.text('粘贴'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(SourceImportSheetKeys.pasteFieldKey),
      sourceFixtureText(name: '覆盖后的名字'),
    );
    await tester.tap(find.byKey(SourceImportSheetKeys.overwriteSwitchKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SourceImportSheetKeys.importButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('已更新'), findsOneWidget);
    final source = await db.select(db.bookSources).getSingle();
    expect(source.name, '覆盖后的名字');
  });

  testWidgets('文件选择取消不报错，选择后可导入', (tester) async {
    final db = openSourceTestDatabase();
    final loader = FakeSourceImportLoader();

    await pumpSourceUi(
      tester,
      db: db,
      loader: loader,
      home: const Scaffold(body: SourceImportSheet()),
    );

    await tester.tap(find.text('文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SourceImportSheetKeys.pickFileButtonKey));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(loader.fileCalls, 1);

    loader.file = SourceImportFile(
      name: 'source.json',
      content: sourceFixtureText(),
    );
    await tester.tap(find.byKey(SourceImportSheetKeys.pickFileButtonKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('source.json'), findsOneWidget);

    await tester.tap(find.byKey(SourceImportSheetKeys.importButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('已导入'), findsOneWidget);
  });

  testWidgets('URL 读取错误不泄露 query 或 header 值', (tester) async {
    final db = openSourceTestDatabase();
    final loader = FakeSourceImportLoader()
      ..urlError = const HttpException(
        'HTTP 500 at https://example.com/source.json?token=secret',
      );

    await pumpSourceUi(
      tester,
      db: db,
      loader: loader,
      home: const Scaffold(body: SourceImportSheet()),
    );

    await tester.enterText(
      find.byKey(SourceImportSheetKeys.urlFieldKey),
      'https://example.com/source.json',
    );
    await tester.tap(find.byKey(SourceImportSheetKeys.loadUrlButtonKey));
    await tester.pumpAndSettle();

    expect(find.textContaining('HTTP 500'), findsOneWidget);
    expect(find.textContaining('token'), findsNothing);
    expect(find.textContaining('secret'), findsNothing);
    expect(loader.urlCalls, 1);
  });

  testWidgets('320dp、大字体、深色下导入弹层不溢出', (tester) async {
    final db = openSourceTestDatabase();

    await pumpSourceUi(
      tester,
      db: db,
      loader: FakeSourceImportLoader(),
      home: const Scaffold(body: SourceImportSheet()),
      size: const Size(320, 700),
      textScale: 2,
      brightness: Brightness.dark,
    );

    await tester.tap(find.text('粘贴'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(SourceImportSheetKeys.pasteFieldKey),
      sourceFixtureText(),
    );
    await tester.tap(find.byKey(SourceImportSheetKeys.importButtonKey));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
