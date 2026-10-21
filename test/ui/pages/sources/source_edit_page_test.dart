import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/ui/pages/sources/source_edit_page.dart';

import 'source_ui_test_support.dart';

class _EditLauncher extends StatelessWidget {
  const _EditLauncher({required this.source});

  final BookSource source;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => SourceEditPage(source: source),
              ),
            );
          },
          child: const Text('打开编辑'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('修改名称保存后写库并返回', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final source = (await sourceService(db).getSource(id))!;

    await pumpSourceUi(
      tester,
      db: db,
      home: _EditLauncher(source: source),
    );
    await tester.tap(find.text('打开编辑'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(SourceEditPageKeys.nameFieldKey), '新的名称');
    await tester.tap(find.byKey(SourceEditPageKeys.saveButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('打开编辑'), findsOneWidget);
    final after = await db.select(db.bookSources).getSingle();
    expect(after.name, '新的名称');
    final root = await db.select(db.libraryRoots).getSingle();
    expect(root.displayName, '新的名称');
  });

  testWidgets('修改原始 JSON 中的 URL 被拒绝', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final source = (await sourceService(db).getSource(id))!;

    await pumpSourceUi(
      tester,
      db: db,
      home: _EditLauncher(source: source),
    );
    await tester.tap(find.text('打开编辑'));
    await tester.pumpAndSettle();

    final raw = jsonDecode(source.rawJson) as Map<String, dynamic>
      ..['bookSourceUrl'] = 'https://other.example/source.json';
    await tester.enterText(
      find.byKey(SourceEditPageKeys.rawFieldKey),
      jsonEncode(raw),
    );
    await tester.tap(find.byKey(SourceEditPageKeys.saveButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('书源 URL 是身份，不能在这里修改'), findsOneWidget);
    expect(find.text('编辑书源'), findsOneWidget);
    final after = await db.select(db.bookSources).getSingle();
    expect(after.sourceUrl, source.sourceUrl);
  });

  testWidgets('非法 JSON 不保存', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final source = (await sourceService(db).getSource(id))!;

    await pumpSourceUi(
      tester,
      db: db,
      home: _EditLauncher(source: source),
    );
    await tester.tap(find.text('打开编辑'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(SourceEditPageKeys.rawFieldKey),
      'not-json',
    );
    await tester.tap(find.byKey(SourceEditPageKeys.saveButtonKey));
    await tester.pumpAndSettle();

    expect(find.textContaining('不是合法的 JSON'), findsOneWidget);
    expect(find.text('编辑书源'), findsOneWidget);
    final after = await db.select(db.bookSources).getSingle();
    expect(after.name, source.name);
  });

  testWidgets('表单名称覆盖原始 JSON 中的名称', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final source = (await sourceService(db).getSource(id))!;

    await pumpSourceUi(
      tester,
      db: db,
      home: _EditLauncher(source: source),
    );
    await tester.tap(find.text('打开编辑'));
    await tester.pumpAndSettle();

    final raw = jsonDecode(source.rawJson) as Map<String, dynamic>
      ..['bookSourceName'] = 'JSON 名称';
    await tester.enterText(
      find.byKey(SourceEditPageKeys.rawFieldKey),
      jsonEncode(raw),
    );
    await tester.enterText(find.byKey(SourceEditPageKeys.nameFieldKey), '表单名称');
    await tester.tap(find.byKey(SourceEditPageKeys.saveButtonKey));
    await tester.pumpAndSettle();

    final after = await db.select(db.bookSources).getSingle();
    expect(after.name, '表单名称');
  });

  testWidgets('320dp、大字体、深色下编辑页不溢出', (tester) async {
    final db = openSourceTestDatabase();
    final id = await seedSource(db);
    final source = (await sourceService(db).getSource(id))!;

    await pumpSourceUi(
      tester,
      db: db,
      home: _EditLauncher(source: source),
      size: const Size(320, 700),
      textScale: 2,
      brightness: Brightness.dark,
    );
    await tester.tap(find.text('打开编辑'));
    await tester.pumpAndSettle();

    expect(find.text('编辑书源'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
