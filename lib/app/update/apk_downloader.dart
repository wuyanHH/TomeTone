/// APK 下载器（《架构需求文档》2.7 与更新基础设施）。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:tometone/contracts/update/apk_download_state.dart';
import 'package:tometone/contracts/update/update_models.dart';

/// APK 下载器（负责从网络流式拉取 APK、校验 SHA-256 并写入本地临时目录）。
class ApkDownloader {
  /// 创建 APK 下载器。
  ApkDownloader({
    required this.client,
    Future<Directory> Function()? getTargetDirectory,
  }) : _getTargetDirectory = getTargetDirectory ?? _defaultTargetDirectory;

  final http.Client client;
  final Future<Directory> Function() _getTargetDirectory;

  static Future<Directory> _defaultTargetDirectory() async {
    return Directory('${Directory.systemTemp.path}/tometone_updates');
  }

  /// 流式下载指定产物。
  Stream<ApkDownloadState> download({
    required ReleaseAsset asset,
    void Function()? onCancel,
  }) async* {
    if (asset.downloadUrl.isEmpty) {
      yield ApkDownloadState(
        status: ApkDownloadStatus.failed,
        assetName: asset.name,
        error: '下载链接为空',
      );
      return;
    }

    var totalBytes = asset.sizeBytes;
    var receivedBytes = 0;

    yield ApkDownloadState(
      status: ApkDownloadStatus.downloading,
      assetName: asset.name,
      receivedBytes: 0,
      totalBytes: totalBytes,
    );

    File? file;
    IOSink? sink;
    ChunkedConversionSink<List<int>>? hashSink;
    var isCompleted = false;

    try {
      final request = http.Request('GET', Uri.parse(asset.downloadUrl));
      final response = await client.send(request);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        yield ApkDownloadState(
          status: ApkDownloadStatus.failed,
          assetName: asset.name,
          error: '下载失败，HTTP 状态码：${response.statusCode}',
        );
        return;
      }

      if (totalBytes <= 0 && response.contentLength != null) {
        totalBytes = response.contentLength!;
      }

      final dir = await _getTargetDirectory();
      await dir.create(recursive: true);
      file = File('${dir.path}/${asset.name}');
      if (file.existsSync()) {
        await file.delete();
      }

      sink = file.openWrite();
      Digest? calculatedDigest;
      final hashOutput = ChunkedConversionSink<Digest>.withCallback((digests) {
        if (digests.isNotEmpty) {
          calculatedDigest = digests.single;
        }
      });
      hashSink = sha256.startChunkedConversion(hashOutput);

      await for (final chunk in response.stream) {
        sink.add(chunk);
        hashSink.add(chunk);
        receivedBytes += chunk.length;
        yield ApkDownloadState(
          status: ApkDownloadStatus.downloading,
          assetName: asset.name,
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
        );
      }

      await sink.flush();
      await sink.close();
      sink = null;
      hashSink.close();
      hashSink = null;

      if (totalBytes > 0 && receivedBytes < totalBytes) {
        if (file.existsSync()) {
          await file.delete();
        }
        yield ApkDownloadState(
          status: ApkDownloadStatus.failed,
          assetName: asset.name,
          error: '下载不完整：预期 $totalBytes 字节，实际接收 $receivedBytes 字节',
        );
        return;
      }

      // 校验 SHA-256
      final rawDigest = asset.digest?.trim();
      if (rawDigest != null && rawDigest.isNotEmpty) {
        var expectedHash = rawDigest.toLowerCase();
        if (expectedHash.startsWith('sha256:')) {
          expectedHash = expectedHash.substring('sha256:'.length).trim();
        }
        final actualHash = calculatedDigest?.toString().toLowerCase() ?? '';
        if (actualHash != expectedHash) {
          if (file.existsSync()) {
            await file.delete();
          }
          yield ApkDownloadState(
            status: ApkDownloadStatus.failed,
            assetName: asset.name,
            error: '安装包校验失败（SHA-256 不匹配）',
          );
          return;
        }
      }

      isCompleted = true;
      yield ApkDownloadState(
        status: ApkDownloadStatus.completed,
        assetName: asset.name,
        receivedBytes: receivedBytes,
        totalBytes: totalBytes > 0 ? totalBytes : receivedBytes,
        filePath: file.path,
      );
    } catch (e) {
      try {
        await sink?.close();
      } catch (_) {}
      sink = null;
      try {
        hashSink?.close();
      } catch (_) {}
      hashSink = null;
      if (file != null && file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      yield ApkDownloadState(
        status: ApkDownloadStatus.failed,
        assetName: asset.name,
        error: e.toString(),
      );
    } finally {
      if (!isCompleted) {
        try {
          await sink?.close();
        } catch (_) {}
        sink = null;
        try {
          hashSink?.close();
        } catch (_) {}
        hashSink = null;
        if (file != null && file.existsSync()) {
          try {
            await file.delete();
          } catch (_) {}
        }
        onCancel?.call();
      }
    }
  }
}
