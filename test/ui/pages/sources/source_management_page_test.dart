import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/ui/pages/sources/source_management_page.dart';

import 'source_ui_test_support.dart';

void main() {
  testWidgets('无书源时显示空态与导入入口', (tester) async {
    final db = openSourceTestDatabase();

    await pumpSourceUi(tester, db: db, home: const SourceManagementPage());

    expect(find.text('书源'), findsOneWidget);
    expect(find.text('还没有书源'), findsOneWidget);
    expect(find.byKey(SourceManagementKeys.emptyStateKey), findsOneWidget);
    expect(find.text('导入书源'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('已有书源显示名称、分组、书目数与健康状态', (tester) async {
    final db = openSourceTestDatabase();
    await seedSource(db);

    await pumpSourceUi(tester, db: db, home: const SourceManagementPage());

    expect(find.text('听友听书'), findsOneWidget);
    expect(find.text('听书'), findsOneWidget);
    expect(find.text('书 0'), findsOneWidget);
    expect(find.text('未测试'), findsOneWidget);
  });

  testWidgets('启用开关写库后刷新为非乐观状态', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final row = await db.select(db.bookSources).getSingle();

    await pumpSourceUi(tester, db: db, home: const SourceManagementPage());

    await tester.tap(find.byKey(SourceManagementKeys.enabledSwitchKey(id)));
    await tester.pumpAndSettle();

    final after = await db.select(db.bookSources).getSingle();
    expect(after.enabled, isFalse);
    expect(
      tester
          .widget<Switch>(find.byKey(SourceManagementKeys.enabledSwitchKey(id)))
          .value,
      isFalse,
    );
    expect(row.enabled, isTrue);
  });

  testWidgets('删除默认保留该源书目', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final source = await db.select(db.bookSources).getSingle();
    await seedOnlineBook(db, sourceId: id, libraryRootId: source.libraryRootId);

    await pumpSourceUi(tester, db: db, home: const SourceManagementPage());

    await tester.tap(find.byKey(SourceManagementKeys.menuKey(id)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(find.byKey(SourceManagementKeys.deleteDialogKey), findsOneWidget);
    expect(
      find.byKey(SourceManagementKeys.deleteBooksCheckboxKey),
      findsOneWidget,
    );
    expect(find.text('同时删除该源的已存书目'), findsOneWidget);

    await tester.tap(find.byKey(SourceManagementKeys.deleteConfirmKey));
    await tester.pumpAndSettle();

    expect((await db.select(db.bookSources).getSingle()).deletedAt, isNotNull);
    expect(await db.select(db.books).get(), hasLength(1));
    expect(find.text('还没有书源'), findsOneWidget);
  });

  testWidgets('勾选同时删书后书目消失', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final source = await db.select(db.bookSources).getSingle();
    await seedOnlineBook(db, sourceId: id, libraryRootId: source.libraryRootId);

    await pumpSourceUi(tester, db: db, home: const SourceManagementPage());

    await tester.tap(find.byKey(SourceManagementKeys.menuKey(id)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SourceManagementKeys.deleteBooksCheckboxKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 本'), findsWidgets);

    await tester.tap(find.byKey(SourceManagementKeys.deleteConfirmKey));
    await tester.pumpAndSettle();

    expect((await db.select(db.bookSources).getSingle()).deletedAt, isNotNull);
    expect(await db.select(db.books).get(), isEmpty);
  });

  testWidgets('书数为 0 时删除弹层隐藏复选框', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);

    await pumpSourceUi(tester, db: db, home: const SourceManagementPage());

    await tester.tap(find.byKey(SourceManagementKeys.menuKey(id)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(SourceManagementKeys.deleteBooksCheckboxKey),
      findsNothing,
    );
  });

  testWidgets('320dp、大字体、深色下管理页不溢出', (tester) async {
    final db = openSourceTestDatabase();
    await seedSource(db);

    await pumpSourceUi(
      tester,
      db: db,
      home: const SourceManagementPage(),
      size: const Size(320, 700),
      textScale: 2,
      brightness: Brightness.dark,
    );

    expect(find.text('听友听书'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
