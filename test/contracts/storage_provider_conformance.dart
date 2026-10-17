import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/storage/storage_entry.dart';
import 'package:tometone/contracts/storage/storage_error.dart';
import 'package:tometone/contracts/storage/storage_provider.dart';

/// 断言"抛出了指定错误码的 `StorageError`"。
Matcher throwsStorageError(StorageErrorCode code) =>
    throwsA(isA<StorageError>().having((error) => error.code, 'code', code));

/// StorageProvider 统一契约测试套件（《架构需求文档》§5.3、§7.1、§12）。
///
/// 任何 [StorageProvider] 实现（本地 / SAF / WebDAV / SMB）都必须跑通本套件。
///
/// [liveStreams] 可选：实现若能观测"存活流数量"，套件会额外断言
/// **取消订阅后底层传输确实被释放**（连接池 / 句柄泄漏的通用体检项）。
/// 传入该探针时，[fileBytes] 必须足以产生多个分片。
void runStorageProviderConformance({
  required StorageProvider Function() createProvider,
  required String directoryPath,
  required String filePath,
  required List<int> fileBytes,
  required Set<String> expectedChildren,
  required File Function() createTargetFile,
  int Function()? liveStreams,
}) {
  group('StorageProvider 契约', () {
    late StorageProvider provider;

    setUp(() {
      provider = createProvider();
    });

    tearDown(() async {
      await provider.dispose();
    });

    test('能力声明可用', () {
      expect(provider.capabilities.providerType, isNotEmpty);
    });

    test('list 返回直接子项', () async {
      final entries = await provider.list(directoryPath);
      expect(
        entries.map((StorageEntry entry) => entry.name).toSet(),
        expectedChildren,
      );
    });

    test('list 不存在的路径抛 notFound', () async {
      await expectLater(
        provider.list('$directoryPath/__missing__'),
        throwsStorageError(StorageErrorCode.notFound),
      );
    });

    test('stat 文件返回大小，stat 不存在抛 notFound', () async {
      final info = await provider.stat(filePath);
      expect(info.isDirectory, isFalse);
      expect(info.sizeBytes, fileBytes.length);

      final directoryInfo = await provider.stat(directoryPath);
      expect(directoryInfo.isDirectory, isTrue);

      await expectLater(
        provider.stat('$directoryPath/__missing__'),
        throwsStorageError(StorageErrorCode.notFound),
      );
    });

    test('readRange 读全文内容一致', () async {
      final whole = await _drain(await provider.readRange(filePath, 0, null));
      expect(whole, fileBytes);
    });

    test('readRange 越界端点被钳制到文件末尾', () async {
      final whole = await _drain(
        await provider.readRange(filePath, 0, fileBytes.length + 1000),
      );
      expect(whole, fileBytes);
    });

    test('readRange 分段读取内容正确（仅支持 Range 的实现）', () async {
      if (!provider.capabilities.supportsRange) {
        return;
      }
      final half = fileBytes.length ~/ 2;
      final head = await _drain(
        await provider.readRange(filePath, 0, half - 1),
      );
      expect(head, fileBytes.sublist(0, half));

      final tail = await _drain(
        await provider.readRange(filePath, half, fileBytes.length - 1),
      );
      expect(tail, fileBytes.sublist(half));
    });

    test('readRange 非法区间抛 invalidPath', () async {
      await expectLater(
        provider.readRange(filePath, 5, 1),
        throwsStorageError(StorageErrorCode.invalidPath),
      );
      await expectLater(
        provider.readRange(filePath, -1, null),
        throwsStorageError(StorageErrorCode.invalidPath),
      );
    });

    test('不支持 Range 的实现必须在 start > 0 时抛 serverUnsupported', () async {
      if (provider.capabilities.supportsRange) {
        return; // 该实现支持 Range，降级路径不适用。
      }
      await expectLater(
        provider.readRange(filePath, 1, null),
        throwsStorageError(StorageErrorCode.serverUnsupported),
      );
    });

    test('downloadTo 落盘内容一致且 onProgress 收敛到 total', () async {
      final target = createTargetFile();
      final progress = <int>[];

      await provider.downloadTo(
        filePath,
        target,
        onProgress: (int received, int total) {
          expect(received, lessThanOrEqualTo(total));
          progress.add(received);
        },
      );

      expect(target.readAsBytesSync(), fileBytes);
      expect(progress, isNotEmpty);
      expect(progress.last, fileBytes.length);
    });

    if (liveStreams != null) {
      test('取消订阅后底层传输被释放（无悬挂流）', () async {
        final stream = await provider.readRange(filePath, 0, null);
        final started = Completer<void>();
        late StreamSubscription<List<int>> subscription;
        subscription = stream.listen((_) {
          // 收到首个分片后立刻暂停：使生成器停在**中途**，
          // 从而能区分"仅仅跑完了"与"真的被取消"。
          subscription.pause();
          if (!started.isCompleted) {
            started.complete();
          }
        });

        await started.future;
        expect(liveStreams(), greaterThan(0), reason: '生成器应停在中途');

        await subscription.cancel();
        expect(liveStreams(), 0);
      });

      test('完整消费后底层传输被释放', () async {
        await _drain(await provider.readRange(filePath, 0, null));
        expect(liveStreams(), 0);
      });
    }

    test('dispose 幂等，释放后调用抛 unsupportedOperation', () async {
      await provider.dispose();
      await provider.dispose();

      await expectLater(
        provider.list(directoryPath),
        throwsStorageError(StorageErrorCode.unsupportedOperation),
      );
      await expectLater(
        provider.stat(filePath),
        throwsStorageError(StorageErrorCode.unsupportedOperation),
      );
      await expectLater(
        provider.readRange(filePath, 0, null),
        throwsStorageError(StorageErrorCode.unsupportedOperation),
      );
    });
  });
}

Future<List<int>> _drain(Stream<List<int>> stream) async {
  final buffer = <int>[];
  await for (final chunk in stream) {
    buffer.addAll(chunk);
  }
  return buffer;
}
