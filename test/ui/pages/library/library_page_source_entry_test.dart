import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/ui/pages/library/library_page.dart';
import 'package:tometone/ui/pages/library/library_roots.dart';

import '../sources/source_ui_test_support.dart';

void main() {
  testWidgets('书库页右上角书源入口打开管理页', (tester) async {
    final db = openSourceTestDatabase();

    await pumpSourceUi(
      tester,
      db: db,
      home: const Scaffold(body: LibraryPage()),
    );

    expect(find.byKey(LibraryRootsKeys.sourcesButtonKey), findsOneWidget);
    await tester.tap(find.byKey(LibraryRootsKeys.sourcesButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('书源'), findsOneWidget);
    expect(find.text('还没有书源'), findsOneWidget);
  });
}
