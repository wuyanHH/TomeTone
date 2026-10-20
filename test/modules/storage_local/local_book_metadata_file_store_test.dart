import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/storage/book_metadata_file_store.dart';
import 'package:tometone/modules/storage_local/local_book_metadata_file_store.dart';

void main() {
  late Directory temp;
  late LocalBookMetadataFileStore store;

  final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);

  setUp(() {
    temp = Directory.systemTemp.createTempSync('tometone_local_meta_');
    store = LocalBookMetadataFileStore(temp.path);
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  String bookDirPath(String bookRootPath) =>
      '${temp.path}${Platform.pathSeparator}${bookRootPath.replaceAll('/', Platform.pathSeparator)}';

  Directory createBookDir(String bookRootPath) {
    final dir = Directory(bookDirPath(bookRootPath));
    dir.createSync(recursive: true);
    return dir;
  }

  group('本地 sidecar 写入 / 读取', () {
    test('write 后 tometone.meta.json 存在且内容一致，read 返回同一字节', () async {
      createBookDir('books/a');

      final status = await store.write('books/a', bytes);
      expect(status, BookMetadataWriteStatus.written);

      final sidecar = File(
        '${bookDirPath('books/a')}${Platform.pathSeparator}tometone.meta.json',
      );
      expect(sidecar.existsSync(), isTrue);
      expect(sidecar.readAsBytesSync(), bytes);

      expect(await store.read('books/a'), bytes);
    });

    test('写入后音频文件字节未变', () async {
      final dir = createBookDir('books/a');
      final audio = File('${dir.path}${Platform.pathSeparator}001.mp3');
      final audioBytes = <int>[9, 8, 7];
      audio.writeAsBytesSync(audioBytes);

      await store.write('books/a', bytes);

      expect(audio.readAsBytesSync(), audioBytes);
    });

    test('超过 256 KB 的 read 返回 null', () async {
      final dir = createBookDir('books/a');
      final big = File('${dir.path}${Platform.pathSeparator}tometone.meta.json');
      big.writeAsBytesSync(List<int>.filled(256 * 1024 + 1, 0));

      expect(await store.read('books/a'), isNull);
    });

    test('目标目录不存在时 write 返回 failed，且不留临时文件', () async {
      final status = await store.write('books/missing', bytes);
      expect(status, BookMetadataWriteStatus.failed);

      final tempFile = File(
        '${bookDirPath('books/missing')}'
        '${Platform.pathSeparator}tometone.meta.json.tmp',
      );
      expect(tempFile.existsSync(), isFalse);
    });

    test('read 不存在的书根返回 null', () async {
      expect(await store.read('books/nope'), isNull);
    });
  });
}
