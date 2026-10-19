import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/storage/directory_picker.dart';
import 'package:tometone/modules/storage_saf/saf_storage_provider.dart';
import 'package:tometone/platform/saf/saf_bridge.dart';

/// 与真机日志完全一致的响应：`Santi` 是目录，documentUri 也正确。
const List<Map<String, Object?>> _rootPayload = <Map<String, Object?>>[
  <String, Object?>{
    'name': 'Santi',
    'isDirectory': true,
    'documentUri': 'content://com.android.externalstorage.documents/tree/primary%3AAudiobooks/document/primary%3AAudiobooks%2FSanti',
    'size': null,
    'lastModified': null,
  },
];

const List<Map<String, Object?>> _volumePayload = <Map<String, Object?>>[
  <String, Object?>{
    'name': 'Vol1',
    'isDirectory': true,
    'documentUri': 'content://com.android.externalstorage.documents/tree/primary%3AAudiobooks/document/primary%3AAudiobooks%2FSanti%2FVol1',
    'size': null,
    'lastModified': null,
  },
];

const List<Map<String, Object?>> _chapterPayload = <Map<String, Object?>>[
  <String, Object?>{
    'name': '001.wav',
    'isDirectory': false,
    'documentUri': 'content://com.android.externalstorage.documents/tree/primary%3AAudiobooks/document/primary%3AAudiobooks%2FSanti%2FVol1%2F001.wav',
    'size': 128044,
    'lastModified': 1760000000000,
  },
  <String, Object?>{
    'name': '002.wav',
    'isDirectory': false,
    'documentUri': 'content://com.android.externalstorage.documents/tree/primary%3AAudiobooks/document/primary%3AAudiobooks%2FSanti%2FVol1%2F002.wav',
    'size': 128044,
    'lastModified': 1760000000000,
  },
];

const String _rootUri =
    'content://com.android.externalstorage.documents/tree/primary%3AAudiobooks';

/// 记录每次列举实际用了哪个 documentUri —— 用来证明缓存是否命中。
class _RecordingBridge implements SafBridge {
  final List<String> listed = <String>[];

  @override
  Future<List<SafEntry>> list(String documentUri) async {
    listed.add(documentUri);
    if (documentUri == _rootUri) {
      return _entries(_rootPayload);
    }
    if (documentUri.endsWith('%2FSanti')) {
      return _entries(_volumePayload);
    }
    if (documentUri.endsWith('%2FVol1')) {
      return _entries(_chapterPayload);
    }
    return const <SafEntry>[];
  }

  @override
  Future<SafEntry?> stat(String documentUri) async => null;

  @override
  Future<PickedDirectory?> pickDirectory() async => null;

  @override
  Future<String?> documentUri({
    required String treeUri,
    required String relativePath,
  }) async => null;

  @override
  Future<Uint8List?> readBytes(String documentUri) async => null;

  @override
  Future<String?> copyToCache({
    required String documentUri,
    required String name,
  }) async => null;

  @override
  Future<bool> release(String rootUri) async => false;

  static List<SafEntry> _entries(List<Map<String, Object?>> payload) {
    return <SafEntry>[
      for (final item in payload)
        SafEntry(
          name: item['name']! as String,
          documentUri: item['documentUri']! as String,
          isDirectory: item['isDirectory']! as bool,
          sizeBytes: (item['size'] as num?)?.toInt(),
          lastModified: null,
        ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SafBridge 解析（伪造通道，与真机 payload 一致）', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('tometone/saf'), (
            MethodCall call,
          ) async {
            if (call.method == 'list') {
              return _rootPayload;
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('tometone/saf'), null);
    });

    test('目录条目必须保留 isDirectory 与 documentUri', () async {
      final entries = await const SafBridge().list(_rootUri);

      expect(entries, hasLength(1));
      expect(entries.single.name, 'Santi');
      expect(
        entries.single.isDirectory,
        isTrue,
        reason: 'Kotlin 返回 dir=true，解析后必须仍为 true',
      );
      expect(entries.single.documentUri, endsWith('%2FSanti'));
    });
  });

  group('SafStorageProvider 递归', () {
    test('列根 → 列子目录 → 列文件，且缓存命中正确 URI', () async {
      final bridge = _RecordingBridge();
      final provider = SafStorageProvider(_rootUri, bridge: bridge);

      final root = await provider.list('');
      expect(root.map((e) => e.name).toList(), <String>['Santi']);
      expect(root.single.isDirectory, isTrue);

      final volume = await provider.list('Santi');
      expect(volume.map((e) => e.name).toList(), <String>['Vol1']);

      final chapters = await provider.list('Santi/Vol1');
      expect(chapters.map((e) => e.name).toList(), <String>[
        '001.wav',
        '002.wav',
      ]);
      expect(chapters.first.isDirectory, isFalse);
      expect(chapters.first.sizeBytes, 128044);

      expect(bridge.listed, hasLength(3), reason: '每层只列举一次');
      expect(bridge.listed[1], endsWith('%2FSanti'));
      expect(bridge.listed[2], endsWith('%2FVol1'));
    });
  });

  group('SafBridge 媒体解析（伪造通道）', () {
    const channel = MethodChannel('tometone/saf');
    final List<MethodCall> calls = <MethodCall>[];

    const String documentUri =
        'content://com.android.externalstorage.documents/tree/primary%3AAudiobooks/document/primary%3AAudiobooks%2FSanti%2F001.wav';

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            calls.add(call);
            final args = call.arguments as Map<Object?, Object?>;
            switch (call.method) {
              case 'documentUri':
                final relativePath = args['relativePath'] as String;
                if (relativePath.contains('missing')) {
                  return null;
                }
                if (relativePath.isEmpty) {
                  return args['treeUri'];
                }
                return documentUri;
              case 'readBytes':
                final target = args['documentUri'] as String;
                if (target.contains('missing')) {
                  return null;
                }
                return Uint8List.fromList(<int>[1, 2, 3]);
              case 'copyToCache':
                final name = args['name'] as String;
                if (name.contains('fail')) {
                  return null;
                }
                return '/data/user/0/tometone/cache/tometone-media/$name';
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('空相对路径解析为 tree URI 本身', () async {
      final resolved = await const SafBridge().documentUri(
        treeUri: _rootUri,
        relativePath: '',
      );

      expect(resolved, _rootUri);
      final call = calls.singleWhere((c) => c.method == 'documentUri');
      expect((call.arguments as Map<Object?, Object?>)['treeUri'], _rootUri);
    });

    test('多层中文 / 空格 / % / # 路径原样透传，不做编解码', () async {
      const relativePath = '三体/第一卷 上/001 章 100% #1.wav';

      final resolved = await const SafBridge().documentUri(
        treeUri: _rootUri,
        relativePath: relativePath,
      );

      expect(resolved, documentUri);
      final call = calls.singleWhere((c) => c.method == 'documentUri');
      expect(
        (call.arguments as Map<Object?, Object?>)['relativePath'],
        relativePath,
        reason: '上层不得对相对路径做 URL 编解码',
      );
    });

    test('找不到的路径返回 null', () async {
      final resolved = await const SafBridge().documentUri(
        treeUri: _rootUri,
        relativePath: 'Santi/missing.wav',
      );

      expect(resolved, isNull);
    });

    test('readBytes 成功返回字节', () async {
      final bytes = await const SafBridge().readBytes(documentUri);

      expect(bytes, <int>[1, 2, 3]);
      final call = calls.singleWhere((c) => c.method == 'readBytes');
      expect(
        (call.arguments as Map<Object?, Object?>)['documentUri'],
        documentUri,
      );
    });

    test('readBytes 平台返回 null 时回落 null', () async {
      final bytes = await const SafBridge().readBytes(
        'content://com.android.externalstorage.documents/document/missing',
      );

      expect(bytes, isNull);
    });

    test('copyToCache 成功返回本地绝对路径', () async {
      final path = await const SafBridge().copyToCache(
        documentUri: documentUri,
        name: 'Santi__001.wav',
      );

      expect(path, '/data/user/0/tometone/cache/tometone-media/Santi__001.wav');
      final call = calls.singleWhere((c) => c.method == 'copyToCache');
      expect(
        (call.arguments as Map<Object?, Object?>)['name'],
        'Santi__001.wav',
      );
    });

    test('copyToCache 平台失败时回落 null', () async {
      final path = await const SafBridge().copyToCache(
        documentUri: documentUri,
        name: 'fail.wav',
      );

      expect(path, isNull);
    });
  });

  group('SafBridge.release（放弃持久化读授权，best-effort）', () {
    const channel = MethodChannel('tometone/saf');
    final List<MethodCall> calls = <MethodCall>[];

    setUp(calls.clear);

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    void mockHandler(Future<Object?> Function(MethodCall call) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            calls.add(call);
            return handler(call);
          });
    }

    test('平台放弃成功返回 true，且透传 tree URI', () async {
      mockHandler((call) async => true);

      final released = await const SafBridge().release(_rootUri);

      expect(released, isTrue);
      final call = calls.singleWhere((c) => c.method == 'releasePermission');
      expect((call.arguments as Map<Object?, Object?>)['treeUri'], _rootUri);
    });

    test('平台返回 false 时回落到 false', () async {
      mockHandler((call) async => false);

      expect(await const SafBridge().release(_rootUri), isFalse);
    });

    test('平台抛 PlatformException 时回落 false，不向上抛', () async {
      mockHandler((call) async => throw PlatformException(code: 'denied'));

      expect(await const SafBridge().release(_rootUri), isFalse);
    });
  });
}
