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
}
