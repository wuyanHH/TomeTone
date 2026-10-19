import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/contracts/storage/directory_picker.dart';
import 'package:tometone/modules/storage_saf/saf_media_source_resolver.dart';
import 'package:tometone/platform/saf/saf_bridge.dart';

const String _rootUri =
    'content://com.android.externalstorage.documents/tree/primary%3AAudiobooks';

const String _documentUri =
    'content://com.android.externalstorage.documents/tree/primary%3AAudiobooks/document/primary%3AAudiobooks%2FSanti%2F001.wav';

/// 记录调用并返回预设结果的伪桥。
class _FakeBridge implements SafBridge {
  _FakeBridge({
    required this.documentUriResult,
    this.cachedPath,
    this.bytes,
    this.throwOnDocumentUri = false,
  });

  final String? documentUriResult;
  final String? cachedPath;
  final Uint8List? bytes;
  final bool throwOnDocumentUri;

  String? lastTreeUri;
  String? lastRelativePath;
  String? lastDocumentUri;
  String? lastCacheName;

  @override
  Future<String?> documentUri({
    required String treeUri,
    required String relativePath,
  }) async {
    lastTreeUri = treeUri;
    lastRelativePath = relativePath;
    if (throwOnDocumentUri) {
      throw Exception('boom');
    }
    return documentUriResult;
  }

  @override
  Future<Uint8List?> readBytes(String documentUri) async {
    lastDocumentUri = documentUri;
    return bytes;
  }

  @override
  Future<String?> copyToCache({
    required String documentUri,
    required String name,
  }) async {
    lastDocumentUri = documentUri;
    lastCacheName = name;
    return cachedPath;
  }

  @override
  Future<List<SafEntry>> list(String documentUri) async => const <SafEntry>[];

  @override
  Future<SafEntry?> stat(String documentUri) async => null;

  @override
  Future<PickedDirectory?> pickDirectory() async => null;

  @override
  Future<bool> release(String rootUri) async => false;
}

void main() {
  group('resolveAudio', () {
    test('默认分支把 document URI 原样交给引擎（借用 LocalFileSource）', () async {
      final bridge = _FakeBridge(documentUriResult: _documentUri);
      final resolver = SafMediaSourceResolver(_rootUri, bridge: bridge);

      final source = await resolver.resolveAudio(relativePath: 'Santi/001.wav');

      expect(source, isA<LocalFileSource>());
      expect(
        source!.uri,
        _documentUri,
        reason: '必须是 content:// 原样，不能被 fromPath 包成 file://',
      );
      expect(source.uri, startsWith('content://'));
      expect(bridge.lastTreeUri, _rootUri);
      expect(bridge.lastRelativePath, 'Santi/001.wav');
      expect(bridge.lastCacheName, isNull, reason: '直传分支不应复制缓存');
    });

    test('document URI 解析不出时返回 null', () async {
      final bridge = _FakeBridge(documentUriResult: null);
      final resolver = SafMediaSourceResolver(_rootUri, bridge: bridge);

      expect(
        await resolver.resolveAudio(relativePath: 'Santi/001.wav'),
        isNull,
      );
    });

    test('preferCachedCopy 为 true 时复制到缓存并返回本地路径', () async {
      final bridge = _FakeBridge(
        documentUriResult: _documentUri,
        cachedPath: '/data/user/0/tometone/cache/tometone-media/Santi__001.wav',
      );
      final resolver = SafMediaSourceResolver(_rootUri, bridge: bridge);

      final source = await resolver.resolveAudio(
        relativePath: 'Santi/001.wav',
        preferCachedCopy: true,
      );

      expect(source, isA<LocalFileSource>());
      expect(
        source!.uri,
        Uri.file('/data/user/0/tometone/cache/tometone-media/Santi__001.wav')
            .toString(),
      );
      expect(bridge.lastDocumentUri, _documentUri);
      expect(
        bridge.lastCacheName,
        'Santi__001.wav',
        reason: '缓存名必须带库内路径信息，避免不同书同名章节互相覆盖',
      );
    });

    test('缓存复制失败时返回 null', () async {
      final bridge = _FakeBridge(documentUriResult: _documentUri);
      final resolver = SafMediaSourceResolver(_rootUri, bridge: bridge);

      expect(
        await resolver.resolveAudio(
          relativePath: 'Santi/001.wav',
          preferCachedCopy: true,
        ),
        isNull,
      );
    });

    test('桥抛异常时回落 null，不向上抛', () async {
      final bridge = _FakeBridge(
        documentUriResult: null,
        throwOnDocumentUri: true,
      );
      final resolver = SafMediaSourceResolver(_rootUri, bridge: bridge);

      expect(
        await resolver.resolveAudio(relativePath: 'Santi/001.wav'),
        isNull,
      );
    });
  });

  group('readBytes', () {
    test('命中时返回字节', () async {
      final bridge = _FakeBridge(
        documentUriResult: _documentUri,
        bytes: Uint8List.fromList(<int>[9, 8, 7]),
      );
      final resolver = SafMediaSourceResolver(_rootUri, bridge: bridge);

      final result = await resolver.readBytes(relativePath: 'Santi/cover.jpg');

      expect(result, <int>[9, 8, 7]);
      expect(bridge.lastDocumentUri, _documentUri);
    });

    test('读不到时回落 null', () async {
      final bridge = _FakeBridge(documentUriResult: _documentUri);
      final resolver = SafMediaSourceResolver(_rootUri, bridge: bridge);

      expect(await resolver.readBytes(relativePath: 'Santi/cover.jpg'), isNull);
    });

    test('document URI 解析不出时返回 null', () async {
      final bridge = _FakeBridge(
        documentUriResult: null,
        bytes: Uint8List.fromList(<int>[1]),
      );
      final resolver = SafMediaSourceResolver(_rootUri, bridge: bridge);

      expect(await resolver.readBytes(relativePath: 'Santi/cover.jpg'), isNull);
    });
  });
}
