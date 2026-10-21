import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';

void main() {
  test('libraryRoots 不返回在线书源的虚拟根', () async {
    final db = TomeToneDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.utc(2026, 10, 20, 12);

    await db
        .into(db.libraryRoots)
        .insert(
          LibraryRootsCompanion.insert(
            id: 'local-root',
            type: 'local',
            uri: '/tmp/books',
            displayName: '本机书库',
            createdAt: now,
          ),
        );
    await db
        .into(db.libraryRoots)
        .insert(
          LibraryRootsCompanion.insert(
            id: 'online-root',
            type: 'online',
            uri: 'https://example.com/source.json',
            displayName: '在线书源',
            createdAt: now.add(const Duration(seconds: 1)),
          ),
        );

    final roots = await DriftLibraryQueries(db).libraryRoots();

    expect(roots.map((root) => root.id), <String>['local-root']);
  });
}
