import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/storage/fake_storage_provider.dart';
import 'package:tometone/contracts/storage/storage_error.dart';
import 'package:tometone/modules/storage_local/local_storage_provider.dart';

import '../../contracts/storage_provider_conformance.dart';

void main() {
  late Directory temp;
  late LocalStorageProvider provider;
  var targetSeq = 0;

  final List<int> fileBytes = List<int>.generate(
    FakeStorageProvider.chunkSize * 3,
    (int index) => index % 251,
  );

  setUpAll(() {
    temp = Directory.systemTemp.createTempSync('tometone_local_provider_');
    final library = Directory('${temp.path}${Platform.pathSeparator}library');
    final volume = Directory('${library.path}${Platform.pathSeparator}vol-1');
    volume.createSync(recursive: true);
    File('${volume.path}${Platform.pathSeparator}chapter-001.mp3')
        .writeAsBytesSync(fileBytes);
    File('${library.path}${Platform.pathSeparator}notes.txt')
        .writeAsStringSync('notes');
  });

  tearDownAll(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  setUp(() {
    targetSeq = 0;
    provider = LocalStorageProvider(
      '${temp.path}${Platform.pathSeparator}library',
    );
  });

  group('契约套件', () {
    runStorageProviderConformance(
      createProvider: () =>
          LocalStorageProvider('${temp.path}${Platform.pathSeparator}library'),
      directoryPath: 'vol-1',
      filePath: 'vol-1/chapter-001.mp3',
      fileBytes: fileBytes,
      expectedChildren: const <String>{'chapter-001.mp3'},
      createTargetFile: () => File(
        '${temp.path}${Platform.pathSeparator}download-${targetSeq++}.bin',
      ),
    );
  });

  group('路径安全（关键）', () {
    test('拒绝 .. 穿越', () async {
      for (final path in <String>[
        '../outside.mp3',
        'vol-1/../../outside.mp3',
        r'..\outside.mp3',
      ]) {
        await expectLater(
          provider.list(path),
          throwsA(
            isA<StorageError>().having(
              (StorageError e) => e.code,
              'code',
              StorageErrorCode.invalidPath,
            ),
          ),
          reason: path,
        );
      }
    });

    test('拒绝绝对路径与盘符片段', () async {
      for (final path in <String>['/etc/passwd', r'C:\Windows\win.ini']) {
        await expectLater(
          provider.stat(path),
          throwsA(
            isA<StorageError>().having(
              (StorageError e) => e.code,
              'code',
              StorageErrorCode.invalidPath,
            ),
          ),
          reason: path,
        );
      }
    });

    test('读取不存在的文件抛 notFound', () async {
      await expectLater(
        provider.readRange('vol-1/missing.mp3', 0, null),
        throwsA(
          isA<StorageError>().having(
            (StorageError e) => e.code,
            'code',
            StorageErrorCode.notFound,
          ),
        ),
      );
    });

    test('start 超出文件长度抛 invalidPath', () async {
      await expectLater(
        provider.readRange(
          'vol-1/chapter-001.mp3',
          fileBytes.length + 10,
          null,
        ),
        throwsA(
          isA<StorageError>().having(
            (StorageError e) => e.code,
            'code',
            StorageErrorCode.invalidPath,
          ),
        ),
      );
    });
  });

  group('释放', () {
    test('dispose 后所有操作抛 unsupportedOperation', () async {
      final local = LocalStorageProvider(temp.path);
      await local.dispose();

      await expectLater(
        local.list(''),
        throwsA(
          isA<StorageError>().having(
            (StorageError e) => e.code,
            'code',
            StorageErrorCode.unsupportedOperation,
          ),
        ),
      );
    });
  });
}
