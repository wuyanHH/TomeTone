import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/media/media_source_resolver.dart';

void main() {
  group('libraryRootKindOf', () {
    test("'saf' → saf，'webdav' → webdav", () {
      expect(libraryRootKindOf('saf'), LibraryRootKind.saf);
      expect(libraryRootKindOf('webdav'), LibraryRootKind.webdav);
    });

    test('null / 空串 / 未知类型一律回落 local', () {
      for (final String? type in <String?>[
        null,
        '',
        'local',
        'dropbox',
        'SAF',
      ]) {
        expect(
          libraryRootKindOf(type),
          LibraryRootKind.local,
          reason: 'type=$type',
        );
      }
    });
  });
}
