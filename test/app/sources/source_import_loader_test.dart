import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/io_source_import_loader.dart';
import 'package:tometone/contracts/sources/source_import_loader.dart';

class _FakeLoader implements SourceImportLoader {
  _FakeLoader({this.file});

  final SourceImportFile? file;
  final List<String> loadedUrls = <String>[];
  int pickCount = 0;

  @override
  Future<String> loadFromUrl(String url) async {
    loadedUrls.add(url);
    return '{"bookSourceName":"fake"}';
  }

  @override
  Future<SourceImportFile?> pickJsonFile() async {
    pickCount++;
    return file;
  }
}

void main() {
  group('SourceImportLoader 契约', () {
    test('SourceImportFile 原样保存文件名与内容', () {
      const file = SourceImportFile(name: 'source.json', content: '{}');

      expect(file.name, 'source.json');
      expect(file.content, '{}');
    });

    test('fake loader 返回 URL 内容、文件与取消', () async {
      const picked = SourceImportFile(name: 'picked.json', content: '[]');
      final loader = _FakeLoader(file: picked);

      expect(
        await loader.loadFromUrl('https://example.com/source.json'),
        isNotEmpty,
      );
      expect(loader.loadedUrls, <String>['https://example.com/source.json']);
      expect(await loader.pickJsonFile(), same(picked));
      expect(loader.pickCount, 1);

      final cancelled = _FakeLoader(file: null);
      expect(await cancelled.pickJsonFile(), isNull);
    });
  });

  group('IoSourceImportLoader 错误分支（不访问网络）', () {
    const loader = IoSourceImportLoader();

    test('拒绝非 http(s) 与缺 host 的 URL', () async {
      for (final url in <String>[
        '',
        'not a url',
        'ftp://example.com/source.json',
        'file:///tmp/source.json',
        'content://sources/1',
        'javascript:alert(1)',
        'http://',
        'https:///path',
      ]) {
        await expectLater(
          loader.loadFromUrl(url),
          throwsArgumentError,
          reason: url,
        );
      }
    });
  });
}
