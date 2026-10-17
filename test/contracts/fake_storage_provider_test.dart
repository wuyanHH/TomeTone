import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/storage/fake_storage_provider.dart';
import 'package:tometone/contracts/storage/provider_capabilities.dart';
import 'package:tometone/contracts/storage/storage_entry.dart';
import 'package:tometone/contracts/storage/storage_error.dart';

import 'storage_provider_conformance.dart';

const String _directoryPath = '/library';
const String _filePath = '/library/vol-1/chapter-001.mp3';

/// 三倍分片长度，保证 `readRange` 会产生多个分片（悬挂流探测需要）。
final List<int> _fileBytes = List<int>.generate(
  FakeStorageProvider.chunkSize * 3,
  (int index) => index % 251,
);

final Map<String, List<int>> _contents = <String, List<int>>{
  _filePath: _fileBytes,
};

final Map<String, List<StorageEntry>> _directories =
    <String, List<StorageEntry>>{
      _directoryPath: const <StorageEntry>[
        StorageEntry(
          name: 'vol-1',
          path: '$_directoryPath/vol-1',
          isDirectory: true,
        ),
        StorageEntry(
          name: 'notes.txt',
          path: '$_directoryPath/notes.txt',
          isDirectory: false,
          sizeBytes: 12,
        ),
      ],
    };

void main() {
  late Directory temp;
  var downloadSeq = 0;

  setUp(() {
    downloadSeq = 0;
    temp = Directory.systemTemp.createTempSync('tometone_contract_');
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  File nextTargetFile() => File(
    '${temp.path}${Platform.pathSeparator}download-${downloadSeq++}.bin',
  );

  FakeStorageProvider createProvider({ProviderCapabilities? capabilities}) {
    final provider = FakeStorageProvider(
      directories: _directories,
      contents: _contents,
      capabilities: capabilities,
    );
    _lastProvider = provider;
    return provider;
  }

  group('支持 Range 的实现', () {
    runStorageProviderConformance(
      createProvider: createProvider,
      directoryPath: _directoryPath,
      filePath: _filePath,
      fileBytes: _fileBytes,
      expectedChildren: const <String>{'vol-1', 'notes.txt'},
      createTargetFile: nextTargetFile,
      liveStreams: () => _lastProvider!.liveStreams,
    );
  });

  group('不支持 Range 的实现（降级路径）', () {
    runStorageProviderConformance(
      createProvider: () => createProvider(
        capabilities: const ProviderCapabilities(
          providerType: 'fake-no-range',
          supportsRange: false,
          supportsWrite: false,
          supportsDigest: false,
          supportsAuth: false,
        ),
      ),
      directoryPath: _directoryPath,
      filePath: _filePath,
      fileBytes: _fileBytes,
      expectedChildren: const <String>{'vol-1', 'notes.txt'},
      createTargetFile: nextTargetFile,
    );
  });

  group('FakeStorageProvider 专属行为', () {
    test('调用流水可观测', () async {
      final provider = createProvider();
      addTearDown(provider.dispose);

      await provider.stat(_directoryPath);
      await provider.list(_directoryPath);

      expect(provider.calls, <String>[
        'stat:$_directoryPath',
        'list:$_directoryPath',
      ]);
    });

    test('初始无悬挂流', () {
      final provider = createProvider();
      addTearDown(provider.dispose);
      expect(provider.liveStreams, 0);
    });

    test('未知文件抛 notFound', () async {
      final provider = createProvider();
      addTearDown(provider.dispose);

      await expectLater(
        provider.stat('/library/vol-1/nope.mp3'),
        throwsStorageError(StorageErrorCode.notFound),
      );
      await expectLater(
        provider.readRange('/library/vol-1/nope.mp3', 0, null),
        throwsStorageError(StorageErrorCode.notFound),
      );
    });

    test('downloadTo 逐分片回调进度并写入完整内容', () async {
      final provider = createProvider();
      addTearDown(provider.dispose);

      final target = nextTargetFile();
      final progress = <int>[];
      await provider.downloadTo(
        _filePath,
        target,
        onProgress: (int received, int total) => progress.add(received),
      );

      expect(progress, <int>[
        FakeStorageProvider.chunkSize,
        FakeStorageProvider.chunkSize * 2,
        FakeStorageProvider.chunkSize * 3,
      ]);
      expect(target.lengthSync(), _fileBytes.length);
    });

    test('dispose 幂等且计数可观测', () async {
      final provider = createProvider();
      await provider.dispose();
      await provider.dispose();

      expect(provider.isDisposed, isTrue);
      expect(provider.disposeCount, 2);
    });

    test('存储异常 toString 不泄漏路径', () {
      const error = StorageError(
        code: StorageErrorCode.authentication,
        path: '/home/alice/private/secret.mp3',
        statusCode: 401,
      );
      expect(error.toString(), isNot(contains('secret')));
      expect(error.toString(), isNot(contains('alice')));
      expect(error.toDiagnosticString(), contains('…/secret.mp3'));
      expect(error.toDiagnosticString(), isNot(contains('alice')));
      expect(error.toDiagnosticString(), contains('401'));
    });
  });
}

/// 由 `liveStreams` 探针引用：契约套件在 `setUp` 中创建 provider，
/// 此处保留最近一次实例以便读取探针值。
FakeStorageProvider? _lastProvider;
