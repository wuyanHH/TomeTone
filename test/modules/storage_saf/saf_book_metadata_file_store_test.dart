import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/storage/book_metadata_file_store.dart';
import 'package:tometone/modules/storage_saf/saf_book_metadata_file_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('tometone/saf');
  final List<MethodCall> calls = <MethodCall>[];

  const String treeUri =
      'content://com.android.externalstorage.documents/tree/primary%3AAudiobooks';
  const String sidecarDocumentUri =
      'content://com.android.externalstorage.documents/tree/primary%3AAudiobooks/document/primary%3AAudiobooks%2Fbooks%2Fa%2Ftometone.meta.json';

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
              return sidecarDocumentUri;
            case 'readBytes':
              return Uint8List.fromList(<int>[1, 2, 3]);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('SafBookMetadataFileStore', () {
    test('read 先 documentUri 再 readBytes，返回字节', () async {
      final store = SafBookMetadataFileStore(treeUri);

      final result = await store.read('books/a');

      expect(result, <int>[1, 2, 3]);
      expect(
        calls.map((MethodCall c) => c.method).toList(),
        <String>['documentUri', 'readBytes'],
        reason: '必须严格先解析 document URI 再读取',
      );

      final docCall = calls[0];
      final args = docCall.arguments as Map<Object?, Object?>;
      expect(args['treeUri'], treeUri);
      expect(args['relativePath'], 'books/a/tometone.meta.json');
    });

    test('documentUri 解析不到时返回 null，且不调用 readBytes', () async {
      final store = SafBookMetadataFileStore(treeUri);

      final result = await store.read('books/missing');

      expect(result, isNull);
      expect(
        calls.map((MethodCall c) => c.method).toList(),
        <String>['documentUri'],
      );
    });

    test('write 返回 unsupported，且不调用任何平台方法', () async {
      final store = SafBookMetadataFileStore(treeUri);

      final status = await store.write(
        'books/a',
        Uint8List.fromList(<int>[1, 2, 3]),
      );

      expect(status, BookMetadataWriteStatus.unsupported);
      expect(calls, isEmpty, reason: 'SAF 只读，写绝不能触碰平台通道');
    });
  });
}
