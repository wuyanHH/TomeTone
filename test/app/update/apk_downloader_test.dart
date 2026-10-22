import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tometone/app/update/apk_downloader.dart';
import 'package:tometone/contracts/update/apk_download_state.dart';
import 'package:tometone/contracts/update/update_models.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('apk_downloader_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  group('ApkDownloader 单元测试', () {
    test('下载链接为空直接返回 failed 且不发起网络请求', () async {
      var requestSent = false;
      final client = MockClient((_) async {
        requestSent = true;
        return http.Response('ok', 200);
      });

      final downloader = ApkDownloader(
        client: client,
        getTargetDirectory: () async => tempDir,
      );

      const asset = ReleaseAsset(
        name: 'test.apk',
        sizeBytes: 100,
        downloadUrl: '',
      );

      final states = await downloader.download(asset: asset).toList();

      expect(requestSent, isFalse);
      expect(states.length, 1);
      expect(states.first.status, ApkDownloadStatus.failed);
      expect(states.first.assetName, 'test.apk');
      expect(states.first.error, '下载链接为空');
    });

    test('正常流式下载：检查字节累加、进度变化、SHA-256校验通过与文件成功落盘', () async {
      final chunk1 = [1, 2, 3, 4];
      final chunk2 = [5, 6, 7];
      final chunk3 = [8, 9, 10];
      final totalData = <int>[...chunk1, ...chunk2, ...chunk3];
      final expectedSha = sha256.convert(totalData).toString();

      final client = MockClient.streaming((request, bodyStream) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://example.com/test.apk');
        return http.StreamedResponse(
          Stream.fromIterable([chunk1, chunk2, chunk3]),
          200,
          contentLength: totalData.length,
        );
      });

      final downloader = ApkDownloader(
        client: client,
        getTargetDirectory: () async => tempDir,
      );

      final asset = ReleaseAsset(
        name: 'test.apk',
        sizeBytes: totalData.length,
        downloadUrl: 'https://example.com/test.apk',
        digest: 'sha256:$expectedSha',
      );

      final states = await downloader.download(asset: asset).toList();

      // 状态序列：初始 downloading -> chunk1 -> chunk2 -> chunk3 -> completed
      expect(states.length, 5);

      expect(states[0].status, ApkDownloadStatus.downloading);
      expect(states[0].receivedBytes, 0);
      expect(states[0].totalBytes, 10);
      expect(states[0].progress, 0.0);

      expect(states[1].status, ApkDownloadStatus.downloading);
      expect(states[1].receivedBytes, 4);
      expect(states[1].totalBytes, 10);
      expect(states[1].progress, 0.4);

      expect(states[2].status, ApkDownloadStatus.downloading);
      expect(states[2].receivedBytes, 7);
      expect(states[2].totalBytes, 10);
      expect(states[2].progress, 0.7);

      expect(states[3].status, ApkDownloadStatus.downloading);
      expect(states[3].receivedBytes, 10);
      expect(states[3].totalBytes, 10);
      expect(states[3].progress, 1.0);

      expect(states[4].status, ApkDownloadStatus.completed);
      expect(states[4].receivedBytes, 10);
      expect(states[4].totalBytes, 10);
      expect(states[4].filePath, '${tempDir.path}/test.apk');

      final savedFile = File('${tempDir.path}/test.apk');
      expect(savedFile.existsSync(), isTrue);
      expect(savedFile.readAsBytesSync(), totalData);
    });

    test('纯十六进制摘要（无 sha256: 前缀）且大小写不敏感时校验通过', () async {
      final data = utf8.encode('apk-content-sample');
      final expectedSha = sha256.convert(data).toString().toUpperCase();

      final client = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.fromIterable([data]),
          200,
          contentLength: data.length,
        );
      });

      final downloader = ApkDownloader(
        client: client,
        getTargetDirectory: () async => tempDir,
      );

      final asset = ReleaseAsset(
        name: 'sample.apk',
        sizeBytes: data.length,
        downloadUrl: 'https://example.com/sample.apk',
        digest: expectedSha,
      );

      final states = await downloader.download(asset: asset).toList();
      expect(states.last.status, ApkDownloadStatus.completed);
      expect(File(states.last.filePath!).existsSync(), isTrue);
    });

    test('sizeBytes 为 0 时可由 response.contentLength 推断总字节数', () async {
      final data = [1, 2, 3];
      final client = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.fromIterable([data]),
          200,
          contentLength: data.length,
        );
      });

      final downloader = ApkDownloader(
        client: client,
        getTargetDirectory: () async => tempDir,
      );

      const asset = ReleaseAsset(
        name: 'inferred.apk',
        sizeBytes: 0,
        downloadUrl: 'https://example.com/inferred.apk',
      );

      final states = await downloader.download(asset: asset).toList();
      expect(states.first.totalBytes, 0);
      expect(states[1].totalBytes, 3);
      expect(states.last.status, ApkDownloadStatus.completed);
      expect(states.last.totalBytes, 3);
    });

    test('SHA-256 校验不匹配时触发 failed 且自动删除下载文件', () async {
      final data = [1, 2, 3, 4, 5];
      final client = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.fromIterable([data]),
          200,
          contentLength: data.length,
        );
      });

      final downloader = ApkDownloader(
        client: client,
        getTargetDirectory: () async => tempDir,
      );

      const asset = ReleaseAsset(
        name: 'tampered.apk',
        sizeBytes: 5,
        downloadUrl: 'https://example.com/tampered.apk',
        digest: 'sha256:0000000000000000000000000000000000000000000000000000000000000000',
      );

      final states = await downloader.download(asset: asset).toList();
      final lastState = states.last;

      expect(lastState.status, ApkDownloadStatus.failed);
      expect(lastState.error, '安装包校验失败（SHA-256 不匹配）');

      final targetFile = File('${tempDir.path}/tampered.apk');
      expect(targetFile.existsSync(), isFalse);
    });

    test('HTTP 404 返回 failed 且不创建本地文件', () async {
      final client = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          const Stream.empty(),
          404,
        );
      });

      final downloader = ApkDownloader(
        client: client,
        getTargetDirectory: () async => tempDir,
      );

      const asset = ReleaseAsset(
        name: 'not_found.apk',
        sizeBytes: 100,
        downloadUrl: 'https://example.com/not_found.apk',
      );

      final states = await downloader.download(asset: asset).toList();
      expect(states.length, 2);
      expect(states.first.status, ApkDownloadStatus.downloading);
      expect(states.last.status, ApkDownloadStatus.failed);
      expect(states.last.error, contains('404'));

      final targetFile = File('${tempDir.path}/not_found.apk');
      expect(targetFile.existsSync(), isFalse);
    });

    test('HTTP 500 返回 failed 且不创建本地文件', () async {
      final client = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          const Stream.empty(),
          500,
        );
      });

      final downloader = ApkDownloader(
        client: client,
        getTargetDirectory: () async => tempDir,
      );

      const asset = ReleaseAsset(
        name: 'server_error.apk',
        sizeBytes: 100,
        downloadUrl: 'https://example.com/server_error.apk',
      );

      final states = await downloader.download(asset: asset).toList();
      expect(states.last.status, ApkDownloadStatus.failed);
      expect(states.last.error, contains('500'));
      expect(File('${tempDir.path}/server_error.apk').existsSync(), isFalse);
    });

    test('网络传输发生异常时捕获为 failed 并自动清理未完成文件', () async {
      final controller = StreamController<List<int>>();
      final client = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          controller.stream,
          200,
          contentLength: 100,
        );
      });

      final downloader = ApkDownloader(
        client: client,
        getTargetDirectory: () async => tempDir,
      );

      const asset = ReleaseAsset(
        name: 'interrupted.apk',
        sizeBytes: 100,
        downloadUrl: 'https://example.com/interrupted.apk',
      );

      final statesFuture = downloader.download(asset: asset).toList();

      controller.add([1, 2, 3]);
      await Future<void>.delayed(Duration.zero);
      controller.addError(http.ClientException('网络中断'));
      await controller.close();

      final states = await statesFuture;
      expect(states.last.status, ApkDownloadStatus.failed);
      expect(states.last.error, contains('网络中断'));
      expect(File('${tempDir.path}/interrupted.apk').existsSync(), isFalse);
    });

    test('主动取消订阅时触发 onCancel 并安全清理未下载完成的文件', () async {
      final controller = StreamController<List<int>>();
      final client = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          controller.stream,
          200,
          contentLength: 100,
        );
      });

      var onCancelCalled = false;
      final downloader = ApkDownloader(
        client: client,
        getTargetDirectory: () async => tempDir,
      );

      const asset = ReleaseAsset(
        name: 'cancelled.apk',
        sizeBytes: 100,
        downloadUrl: 'https://example.com/cancelled.apk',
      );

      final stream = downloader.download(
        asset: asset,
        onCancel: () {
          onCancelCalled = true;
        },
      );

      final receivedStates = <ApkDownloadState>[];
      final subscription = stream.listen(receivedStates.add);

      controller.add([1, 2, 3]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(receivedStates.length, greaterThanOrEqualTo(2));
      final cancelFuture = subscription.cancel();
      await controller.close();
      await cancelFuture;

      expect(onCancelCalled, isTrue);
      expect(File('${tempDir.path}/cancelled.apk').existsSync(), isFalse);
    });
  });
}
