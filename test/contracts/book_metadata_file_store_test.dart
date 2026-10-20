import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/storage/book_metadata_file_store.dart';

/// 内存替身：只用于验证契约测试套件本身（对应 `fake_storage_provider_test`）。
class _InMemoryStore implements BookMetadataFileStore {
  _InMemoryStore(this.rootUri);

  final String rootUri;
  final Map<String, Uint8List> _files = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String bookRootPath) async => _files[bookRootPath];

  @override
  Future<BookMetadataWriteStatus> write(
    String bookRootPath,
    Uint8List bytes,
  ) async {
    _files[bookRootPath] = bytes;
    return BookMetadataWriteStatus.written;
  }
}

void main() {
  group('BookMetadataFileStore 契约', () {
    test('BookMetadataWriteStatus 仅含 written / unsupported / failed', () {
      expect(
        BookMetadataWriteStatus.values,
        <BookMetadataWriteStatus>[
          BookMetadataWriteStatus.written,
          BookMetadataWriteStatus.unsupported,
          BookMetadataWriteStatus.failed,
        ],
      );
    });

    test('工厂 typedef 可构造出 store', () {
      const BookMetadataFileStoreFactory factory = _InMemoryStore.new;
      final store = factory('/tmp/root');
      expect(store, isA<BookMetadataFileStore>());
    });

    test('read 不存在返回 null', () async {
      final store = _InMemoryStore('/tmp/root');
      expect(await store.read('books/nope'), isNull);
    });

    test('write 后 read 返回同一字节', () async {
      final store = _InMemoryStore('/tmp/root');
      final bytes = Uint8List.fromList(<int>[1, 2, 3]);

      expect(await store.write('books/a', bytes), BookMetadataWriteStatus.written);
      expect(await store.read('books/a'), bytes);
    });
  });
}
